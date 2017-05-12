MODULE = Ogre     PACKAGE = Ogre::BillboardSet

## I finally figured out why DESTROY methods
## cause segfaults; for objects like this (a MovableObject)
## that are managed by SceneManager,
## there is a method destroyAllMovableObjects being called,
## and this was implicitly calling "delete THIS" here
## before that. But if I destroyBillboardSet here, basically it seems
## to get destroyed as soon as the Perl object goes out of scope,
## which is rarely what we want... So you have to just create
## these through SceneManager instead of using ->new.
##BillboardSet *
##BillboardSet::new(name, poolSize=20, externalDataSource=false)
##    String  name
##    unsigned int  poolSize
##    bool  externalDataSource
##
##void
##BillboardSet::DESTROY()
##  CODE:
##    SceneManager *sm = THIS->_getManager();
##    if (sm)
##      sm->destroyBillboardSet(THIS);

## xxx: Billboard * BillboardSet::createBillboard(const Vector3 &position, const ColourValue &colour=ColourValue::White)
Billboard *
BillboardSet::createBillboard(x, y, z, colour=&ColourValue::White)
    Real  x
    Real  y
    Real  z
    const ColourValue * colour
  C_ARGS:
    x, y, z, *colour

int
BillboardSet::getNumBillboards()

void
BillboardSet::setAutoextend(bool autoextend)

bool
BillboardSet::getAutoextend()

void
BillboardSet::setSortingEnabled(bool sortenable)

bool
BillboardSet::getSortingEnabled()

void
BillboardSet::setPoolSize(size_t size)

unsigned int
BillboardSet::getPoolSize()

void
BillboardSet::clear()

Billboard *
BillboardSet::getBillboard(unsigned int index)

## xxx: void BillboardSet::removeBillboard(Billboard *pBill)
void
BillboardSet::removeBillboard(unsigned int index)

void
BillboardSet::setBillboardOrigin(int origin)
  C_ARGS:
    (BillboardOrigin)origin

int
BillboardSet::getBillboardOrigin()

void
BillboardSet::setBillboardRotationType(int rotationType)
  C_ARGS:
    (BillboardRotationType)rotationType

int
BillboardSet::getBillboardRotationType()

void
BillboardSet::setDefaultDimensions(Real width, Real height)

void
BillboardSet::setDefaultWidth(Real width)

Real
BillboardSet::getDefaultWidth()

void
BillboardSet::setDefaultHeight(Real height)

Real
BillboardSet::getDefaultHeight()

void
BillboardSet::setMaterialName(name)
    String  name

String
BillboardSet::getMaterialName()

void
BillboardSet::beginBillboards(size_t numBillboards=0)

void
BillboardSet::injectBillboard(bb)
    const Billboard * bb
  C_ARGS:
    *bb

void
BillboardSet::endBillboards()

void
BillboardSet::setBounds(box, radius)
    const AxisAlignedBox * box
    Real  radius
  C_ARGS:
    *box, radius

## const AxisAlignedBox & BillboardSet::getBoundingBox()

Real
BillboardSet::getBoundingRadius()

## const MaterialPtr & BillboardSet::getMaterial()

## void BillboardSet::getRenderOperation(RenderOperation &op)

## void BillboardSet::getWorldTransforms(Matrix4 *xform)

## const Quaternion & BillboardSet::getWorldOrientation()

## const Vector3 & BillboardSet::getWorldPosition()

bool
BillboardSet::getCullIndividually()

void
BillboardSet::setCullIndividually(bool cullIndividual)

void
BillboardSet::setBillboardType(int bbt)
  C_ARGS:
    (BillboardType)bbt

int
BillboardSet::getBillboardType()

void
BillboardSet::setCommonDirection(vec)
    const Vector3 * vec
  C_ARGS:
    *vec

## const Vector3 & BillboardSet::getCommonDirection()

void
BillboardSet::setCommonUpVector(vec)
    const Vector3 * vec
  C_ARGS:
    *vec

## const Vector3 & BillboardSet::getCommonUpVector()

void
BillboardSet::setUseAccurateFacing(bool acc)

bool
BillboardSet::getUseAccurateFacing()

String
BillboardSet::getMovableType()

Real
BillboardSet::getSquaredViewDepth(cam)
    const Camera * cam

## const LightList & BillboardSet::getLights()

void
BillboardSet::setBillboardsInWorldSpace(bool ws)

## Ogre::TRect< Float >
## void BillboardSet::setTextureCoords(Ogre::FloatRect const *coords, uint16 numCoords)

void
BillboardSet::setTextureStacksAndSlices(uchar stacks, uchar slices)

## Ogre::FloatRect const * BillboardSet::getTextureCoords(uint16 *oNumCoords)

void
BillboardSet::setPointRenderingEnabled(bool enabled)

bool
BillboardSet::isPointRenderingEnabled()

uint32
BillboardSet::getTypeFlags()
