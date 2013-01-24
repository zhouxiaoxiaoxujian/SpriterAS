package treefortress.spriter
{
	import treefortress.spriter.core.Animation;
	import treefortress.spriter.core.Child;
	import treefortress.spriter.core.ChildReference;
	import treefortress.spriter.core.Mainline;
	import treefortress.spriter.core.MainlineKey;
	import treefortress.spriter.core.Piece;
	import treefortress.spriter.core.Timeline;
	import treefortress.spriter.core.TimelineKey;
	

	public class AnimationSet
	{
		public var prefix:String;
		public var animationList:Vector.<Animation>;
		public var pieces:Vector.<Piece>;
		public var name:String;
		
		protected var animationsByName:Object = {};
		public static var scale:Number;
		
		public function AnimationSet(data:XML, scale:Number = NaN, parentFolder:String = null){
			prefix = parentFolder || "";
			if(prefix != ""){ prefix += "/"; }
			
			if(!isNaN(AnimationSet.scale) && isNaN(scale)){
				scale = AnimationSet.scale;
			} else if(isNaN(scale)){
				scale = 1;
			}
			
			pieces = new <Piece>[];
			for each(var folderXml:XML in data.folder){
				for each(var file:XML in folderXml.file){
					var piece:Piece = new Piece();
					piece.id = file.@id;
					piece.name = prefix + file.@name;
					piece.name = piece.name.split(".")[0];
					
					piece.width = file.@width * scale;
					piece.height = file.@height * scale;
					pieces.push(piece);					
				}
			}
			
			animationList = new Vector.<Animation>;
			var anim:Animation;
			
			var mainlineKeys:Vector.<MainlineKey>;
			var mainlineKey:MainlineKey;
			
			var timelineKeys:Vector.<TimelineKey>;
			var timelineKey:TimelineKey;
			
			for each(var animData:XML in data.entity.animation) {
				anim = new Animation();
				anim.id = animData.@id;
				anim.name = animData.@name;
				anim.length = animData.@length;
				anim.looping = (animData.@looping == undefined);
				//trace(anim.name, anim.looping);
				//Add timelines
				for each(var timelineData:XML in animData.timeline) {
					timelineKeys = new <TimelineKey>[];
					anim.timelineList.push(new Timeline(timelineData.@id, timelineKeys));
					
					//Add TimelineKeys
					for each(var keyData:XML in timelineData.key) {
						timelineKey = new TimelineKey();
						timelineKey.id = keyData.@id;
						timelineKey.time = keyData.@time;
						timelineKey.spin = keyData.@spin;
						
						var isBone:Boolean = false;
						var childData:XML = keyData..object[0];
						if(!childData){ //If not an object, it must be a bone.
							childData = keyData..bone[0];
							isBone = true;
						}
						var child:Child = new Child();
						child.x = childData.@x * scale;
						child.y = childData.@y * scale;
						child.angle = childData.@angle;
						
						//Convert to flash degrees (spriters uses 0-360, flash used 0-180 and -180 to -1)
						var rotation:Number = child.angle;
						if(rotation >= 180){ rotation = 360 - rotation;
						} else { rotation = -rotation; }
						child.angle = rotation;
						
						if(!isBone){
							child.piece = pieces[childData.@file];
							child.pivotX = (childData.@pivot_x == undefined)? 0 : childData.@pivot_x;
							child.pivotY = (childData.@pivot_y == undefined)? 1 : childData.@pivot_y;
							child.pixelPivotX = child.piece.width * child.pivotX;
							child.pixelPivotY = child.piece.height * (1 - child.pivotY);
						}
						child.scaleX = (childData.@scale_x == undefined)? 1 : childData.@scale_x;
						child.scaleY = (childData.@scale_y == undefined)? 1 : childData.@scale_y;
						
						timelineKey.child = child;
						timelineKeys.push(timelineKey);
					}
				}
				
				//Add Mainline
				mainlineKeys = new <MainlineKey>[];
				for each(var mainKey:XML in animData.mainline.key) {
					
					//Add Main Keyframes
					mainlineKey = new MainlineKey();
					mainlineKey.id = mainKey.@id;
					mainlineKey.time = mainKey.@time;
					mainlineKeys.push(mainlineKey);
					
					//Add Object to KeyFrame
					mainlineKey.refs = new <ChildReference>[];
					for each(var refData:XML in mainKey.object_ref) {
						var ref:ChildReference = new ChildReference();
						ref.id = refData.@id;
						ref.timeline = refData.@timeline; //timelineId
						ref.key = refData.@key; //timelineKey
						ref.zIndex = refData.@z_index;
						mainlineKey.refs.push(ref);
					}
					
				}
				anim.mainline = new Mainline(mainlineKeys);
				animationsByName[anim.name] = anim;
				animationList.push(anim);
				//_animations.push(new DataAnimation(anim, _folders, onAnimChangeFrame));
			}
		}
		
		public function getByName(name:String):Animation {
			return animationsByName[name];
		}
	}
}