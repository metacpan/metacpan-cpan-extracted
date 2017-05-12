MODULE = Ogre     PACKAGE = Ogre::MovableObject

String
MovableObject::getName()

String
MovableObject::getMovableType()

Node *
MovableObject::getParentNode()

SceneNode *
MovableObject::getParentSceneNode()

bool
MovableObject::isAttached()

void
MovableObject::detachFromParent()

bool
MovableObject::isInScene()

## const AxisAlignedBox & MovableObject::getBoundingBox()

Real
MovableObject::getBoundingRadius()

## const AxisAlignedBox & MovableObject::getWorldBoundingBox(bool derive=false)
## const Sphere & MovableObject::getWorldBoundingSphere(bool derive=false)

void
MovableObject::setVisible(bool visible)

bool
MovableObject::getVisible()

bool
MovableObject::isVisible()

void
MovableObject::setRenderingDistance(Real dist)

Real
MovableObject::getRenderingDistance()

## xxx: cool
## void MovableObject::setUserObject(UserDefinedObject *obj)
## UserDefinedObject * MovableObject::getUserObject()
## void MovableObject::setUserAny(const Any &anything)
## const Any & MovableObject::getUserAny()

void
MovableObject::setRenderQueueGroup(uint8 queueID)

uint8
MovableObject::getRenderQueueGroup()

## virtual const Matrix4 & 	_getParentNodeFullTransform (void) const

void
MovableObject::setQueryFlags(uint32 flags)

void
MovableObject::addQueryFlags(uint32 flags)

void
MovableObject::removeQueryFlags(unsigned long flags)

uint32
MovableObject::getQueryFlags()

void
MovableObject::setVisibilityFlags(uint32 flags)

void
MovableObject::addVisibilityFlags(uint32 flags)

void
MovableObject::removeVisibilityFlags(uint32 flags)

uint32
MovableObject::getVisibilityFlags()

## cool...
## void MovableObject::setListener(Listener *listener)
## Listener * MovableObject::getListener()

## const LightList & MovableObject::queryLights()
## virtual LightList * 	_getLightList ()

EdgeData *
MovableObject::getEdgeList()

bool
MovableObject::hasEdgeList()

## ShadowRenderableListIterator MovableObject::getShadowVolumeRenderableIterator(ShadowTechnique shadowTechnique, const Light *light, HardwareIndexBufferSharedPtr *indexBuffer, bool extrudeVertices, Real extrusionDist, unsigned long flags=0)

## const AxisAlignedBox & MovableObject::getLightCapBounds()

## const AxisAlignedBox & MovableObject::getDarkCapBounds(const Light &light, Real dirLightExtrusionDist)

void
MovableObject::setCastShadows(bool enabled)

bool
MovableObject::getCastShadows()

Real
MovableObject::getPointExtrusionDistance(const Light *l)

uint32
MovableObject::getTypeFlags()

## virtual void 	visitRenderables (Renderable::Visitor *visitor, bool debugRenderables=false)=0

void
MovableObject::setDebugDisplayEnabled(bool enabled)

bool
MovableObject::isDebugDisplayEnabled()
