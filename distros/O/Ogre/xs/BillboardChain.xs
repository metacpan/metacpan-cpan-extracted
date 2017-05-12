MODULE = Ogre     PACKAGE = Ogre::BillboardChain

## note: if constructor/destructor ever added, refer to BillboardSet.xs

void
BillboardChain::setMaxChainElements(size_t maxElements)

size_t
BillboardChain::getMaxChainElements()

void
BillboardChain::setNumberOfChains(size_t numChains)

size_t
BillboardChain::getNumberOfChains()

void
BillboardChain::setUseTextureCoords(bool use)

bool
BillboardChain::getUseTextureCoords()

void
BillboardChain::setTextureCoordDirection(int dir)
  C_ARGS:
    (BillboardChain::TexCoordDirection)dir

int
BillboardChain::getTextureCoordDirection()

void
BillboardChain::setOtherTextureCoordRange(Real start, Real end)

## const Real * BillboardChain::getOtherTextureCoordRange()

void
BillboardChain::setUseVertexColours(bool use)

bool
BillboardChain::getUseVertexColours()

void
BillboardChain::setDynamic(bool dyn)

bool
BillboardChain::getDynamic()

## note: Ogre::BillboardChain::Element
## void BillboardChain::addChainElement(size_t chainIndex, const Element *billboardChainElement)

void
BillboardChain::removeChainElement(size_t chainIndex)

## note: Ogre::BillboardChain::Element
## void BillboardChain::updateChainElement(size_t chainIndex, size_t elementIndex, const Element &billboardChainElement)

## const Element & BillboardChain::getChainElement(size_t chainIndex, size_t elementIndex)

void
BillboardChain::clearChain(size_t chainIndex)

void
BillboardChain::clearAllChains()

String
BillboardChain::getMaterialName()

void
BillboardChain::setMaterialName(String name)

Real
BillboardChain::getSquaredViewDepth(const Camera *cam)

Real
BillboardChain::getBoundingRadius()

## too lazy to do this at the moment
## const AxisAlignedBox & BillboardChain::getBoundingBox()

## const MaterialPtr & BillboardChain::getMaterial()

String
BillboardChain::getMovableType()

## note: c.f.  xs/Node.xs
## void BillboardChain::getRenderOperation(RenderOperation &)

## void BillboardChain::getWorldTransforms(Matrix4 *)

## const Quaternion & BillboardChain::getWorldOrientation()

## const Vector3 & BillboardChain::getWorldPosition()

## const LightList & BillboardChain::getLights()
