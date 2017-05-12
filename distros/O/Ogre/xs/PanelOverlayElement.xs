MODULE = Ogre     PACKAGE = Ogre::PanelOverlayElement

void
PanelOverlayElement::initialise()

void
PanelOverlayElement::setTiling(Real x, Real y, unsigned short layer=0)

Real
PanelOverlayElement::getTileX(unsigned short layer=0)

Real
PanelOverlayElement::getTileY(unsigned short layer=0)

void
PanelOverlayElement::setUV(Real u1, Real v1, Real u2, Real v2)

## note: Perl version returns a list
void
PanelOverlayElement::getUV(OUTLIST Real u1, OUTLIST Real v1, OUTLIST Real u2, OUTLIST Real v2)
  C_ARGS:
    u1, v1, u2, v2

void
PanelOverlayElement::setTransparent(bool isTransparent)

bool
PanelOverlayElement::isTransparent()

String
PanelOverlayElement::getTypeName()

void
PanelOverlayElement::getRenderOperation(OUTLIST RenderOperation *op)
  C_ARGS:
    *op

void
PanelOverlayElement::setMaterialName(String matName)
