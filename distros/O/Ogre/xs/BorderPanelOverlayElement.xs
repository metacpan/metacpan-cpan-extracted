MODULE = Ogre     PACKAGE = Ogre::BorderPanelOverlayElement

void
BorderPanelOverlayElement::initialise()

String
BorderPanelOverlayElement::getTypeName()

void
BorderPanelOverlayElement::setBorderSize(Real size)
  CODE:
    if (items == 2) {
        THIS->setBorderSize((Real)SvNV(ST(1)));
    }
    else if (items == 3) {
        THIS->setBorderSize((Real)SvNV(ST(1)), (Real)SvNV(ST(2)));
    }
    else if (items == 5) {
        THIS->setBorderSize((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3)), (Real)SvNV(ST(4)));
    }

Real
BorderPanelOverlayElement::getLeftBorderSize()

Real
BorderPanelOverlayElement::getRightBorderSize()

Real
BorderPanelOverlayElement::getTopBorderSize()

Real
BorderPanelOverlayElement::getBottomBorderSize()

void
BorderPanelOverlayElement::setLeftBorderUV(Real u1, Real v1, Real u2, Real v2)

void
BorderPanelOverlayElement::setRightBorderUV(Real u1, Real v1, Real u2, Real v2)

void
BorderPanelOverlayElement::setTopBorderUV(Real u1, Real v1, Real u2, Real v2)

void
BorderPanelOverlayElement::setBottomBorderUV(Real u1, Real v1, Real u2, Real v2)

void
BorderPanelOverlayElement::setTopLeftBorderUV(Real u1, Real v1, Real u2, Real v2)

void
BorderPanelOverlayElement::setTopRightBorderUV(Real u1, Real v1, Real u2, Real v2)

void
BorderPanelOverlayElement::setBottomLeftBorderUV(Real u1, Real v1, Real u2, Real v2)

void
BorderPanelOverlayElement::setBottomRightBorderUV(Real u1, Real v1, Real u2, Real v2)

String
BorderPanelOverlayElement::getLeftBorderUVString()

String
BorderPanelOverlayElement::getRightBorderUVString()

String
BorderPanelOverlayElement::getTopBorderUVString()

String
BorderPanelOverlayElement::getBottomBorderUVString()

String
BorderPanelOverlayElement::getTopLeftBorderUVString()

String
BorderPanelOverlayElement::getTopRightBorderUVString()

String
BorderPanelOverlayElement::getBottomLeftBorderUVString()

String
BorderPanelOverlayElement::getBottomRightBorderUVString()

void
BorderPanelOverlayElement::setBorderMaterialName(String name)

String
BorderPanelOverlayElement::getBorderMaterialName()

void
BorderPanelOverlayElement::setMetricsMode(int gmm)
  C_ARGS:
    (GuiMetricsMode)gmm
