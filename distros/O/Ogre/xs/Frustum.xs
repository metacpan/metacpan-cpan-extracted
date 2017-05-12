MODULE = Ogre     PACKAGE = Ogre::Frustum

## note: if constructor/destructor ever added, refer to BillboardSet.xs

void
Frustum::setNearClipDistance(Real nearDist)

void
Frustum::setFarClipDistance(Real farDist)

void
Frustum::setAspectRatio(Real ratio)

Real
Frustum::getAspectRatio()
