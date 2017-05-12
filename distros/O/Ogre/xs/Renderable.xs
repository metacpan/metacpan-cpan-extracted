MODULE = Ogre     PACKAGE = Ogre::Renderable

## MaterialPtr & 	getMaterial (void) const =0
## virtual Technique * 	getTechnique (void) const 
## virtual void 	getRenderOperation (RenderOperation &op)=0

## callbacks:
## virtual bool 	preRender (SceneManager *sm, RenderSystem *rsys)
## virtual void 	postRender (SceneManager *sm, RenderSystem *rsys)

## virtual void 	getWorldTransforms (Matrix4 *xform) const =0
##Matrix4 *
##Renderable::getWorldTransforms()

unsigned short
Renderable::getNumWorldTransforms()

void
Renderable::setUseIdentityProjection(bool useIdentityProjection)

bool
Renderable::getUseIdentityProjection()

void
Renderable::setUseIdentityView(bool useIdentityView)

bool
Renderable::getUseIdentityView()

Real
Renderable::getSquaredViewDepth(cam)
    Camera * cam

## virtual const LightList & 	getLights (void) const =0

bool
Renderable::getCastsShadows()

## void 	setCustomParameter (size_t index, const Vector4 &value)
## const Vector4 & 	getCustomParameter (size_t index) const 

void
Renderable::setPolygonModeOverrideable(override)
    bool  override

bool
Renderable::getPolygonModeOverrideable()

## virtual void 	setUserAny (const Any &anything)
## virtual const Any & 	getUserAny (void) const 

## virtual RenderSystemData * 	getRenderSystemData () const 
## virtual void 	setRenderSystemData (RenderSystemData *val) const 
