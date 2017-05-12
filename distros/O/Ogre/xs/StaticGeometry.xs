MODULE = Ogre     PACKAGE = Ogre::StaticGeometry

String
StaticGeometry::getName()

## XXX: no defaults yet
## void addEntity(Entity *ent, const Vector3 &position, const Quaternion &orientation=Quaternion::IDENTITY, const Vector3 &scale=Vector3::UNIT_SCALE)
void
StaticGeometry::addEntity(ent, position, orientation, scale)
    Entity * ent
    Vector3 * position
    Quaternion * orientation
    Vector3 * scale
  C_ARGS:
    ent, *position, *orientation, *scale

void
StaticGeometry::addSceneNode(node)
    SceneNode * node

void
StaticGeometry::build()

void
StaticGeometry::destroy()

void
StaticGeometry::reset()

void
StaticGeometry::setRenderingDistance(dist)
    Real  dist

Real
StaticGeometry::getRenderingDistance()

Real
StaticGeometry::getSquaredRenderingDistance()

void
StaticGeometry::setVisible(visible)
    bool  visible

bool
StaticGeometry::isVisible()

void
StaticGeometry::setCastShadows(castShadows)
    bool castShadows

bool
StaticGeometry::getCastShadows()

void
StaticGeometry::setRegionDimensions(size)
    Vector3 * size
  C_ARGS:
    *size

## const Vector3 & 	getRegionDimensions (void) const

void
StaticGeometry::setOrigin(origin)
    Vector3 * origin
  C_ARGS:
    *origin

## const Vector3 & 	getOrigin (void) const

void
StaticGeometry::setRenderQueueGroup(queueID)
    uint8  queueID

uint8
StaticGeometry::getRenderQueueGroup()

## RegionIterator 	getRegionIterator (void)

void
StaticGeometry::dump(filename)
    String  filename
