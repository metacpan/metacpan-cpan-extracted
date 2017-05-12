MODULE = Ogre     PACKAGE = Ogre::TextAreaOverlayElement

void
TextAreaOverlayElement::initialise()

## see note in OverlayElement setCaption
void
TextAreaOverlayElement::setCaption(String text)

void
TextAreaOverlayElement::setCharHeight(Real height)

Real
TextAreaOverlayElement::getCharHeight()

void
TextAreaOverlayElement::setSpaceWidth(Real width)

Real
TextAreaOverlayElement::getSpaceWidth()

void
TextAreaOverlayElement::setFontName(String font)

String
TextAreaOverlayElement::getFontName()

String
TextAreaOverlayElement::getTypeName()

void
TextAreaOverlayElement::getRenderOperation(OUTLIST RenderOperation *op)
  C_ARGS:
    *op

void
TextAreaOverlayElement::setMaterialName(String matName)

void
TextAreaOverlayElement::setColour(const ColourValue *col)
  C_ARGS:
    *col

const ColourValue *
TextAreaOverlayElement::getColour()
  CODE:
    RETVAL = &(THIS->getColour());
  OUTPUT:
    RETVAL

void
TextAreaOverlayElement::setColourBottom(const ColourValue *col)
  C_ARGS:
    *col

const ColourValue *
TextAreaOverlayElement::getColourBottom()
  CODE:
    RETVAL = &(THIS->getColourBottom());
  OUTPUT:
    RETVAL

void
TextAreaOverlayElement::setColourTop(const ColourValue *col)
  C_ARGS:
    *col

const ColourValue *
TextAreaOverlayElement::getColourTop()
  CODE:
    RETVAL = &(THIS->getColourTop());
  OUTPUT:
    RETVAL

void
TextAreaOverlayElement::setAlignment(int a)
  C_ARGS:
    (TextAreaOverlayElement::Alignment)a

int
TextAreaOverlayElement::getAlignment()

void
TextAreaOverlayElement::setMetricsMode(int gmm)
  C_ARGS:
    (GuiMetricsMode)gmm
