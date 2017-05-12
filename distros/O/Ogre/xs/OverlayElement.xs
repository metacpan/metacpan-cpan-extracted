MODULE = Ogre     PACKAGE = Ogre::OverlayElement

void
OverlayElement::initialise()

String
OverlayElement::getName()

void
OverlayElement::show()

void
OverlayElement::hide()

bool
OverlayElement::isVisible()

bool
OverlayElement::isEnabled()

void
OverlayElement::setEnabled(bool b)

void
OverlayElement::setDimensions(Real width, Real height)

void
OverlayElement::setPosition(Real left, Real top)

void
OverlayElement::setWidth(Real width)

Real
OverlayElement::getWidth()

void
OverlayElement::setHeight(Real height)

Real
OverlayElement::getHeight()

void
OverlayElement::setLeft(Real left)

Real
OverlayElement::getLeft()

void
OverlayElement::setTop(Real top)

Real
OverlayElement::getTop()

String
OverlayElement::getMaterialName()

void
OverlayElement::setMaterialName(String matName)

## const MaterialPtr & 	getMaterial (void) 

## void 	getWorldTransforms (Matrix4 *xform)

String
OverlayElement::getTypeName()

## XXX: Caption methods actually take DisplayString,
## which typedefs to either String or UTFString (utf-16),
## but the code I see in the examples just uses String,
## and UTFString converts back and forth with String automatically,
## and it is easier so thats what I used.
void
OverlayElement::setCaption(String text)

String
OverlayElement::getCaption()

void
OverlayElement::setColour(col)
    ColourValue * col
  C_ARGS:
    *col

## const ColourValue & 	getColour (void) const


void
OverlayElement::setMetricsMode(int gmm)
  C_ARGS:
    (GuiMetricsMode)gmm

int
OverlayElement::getMetricsMode()

void
OverlayElement::setHorizontalAlignment(int gha)
  C_ARGS:
    (GuiHorizontalAlignment)gha

int
OverlayElement::getHorizontalAlignment()

void
OverlayElement::setVerticalAlignment(int gva)
  C_ARGS:
    (GuiVerticalAlignment)gva

int
OverlayElement::getVerticalAlignment()

bool
OverlayElement::contains(Real x, Real y)

OverlayElement *
OverlayElement::findElementAt(Real x, Real y)

bool
OverlayElement::isContainer()

bool
OverlayElement::isKeyEnabled()

bool
OverlayElement::isCloneable()

void
OverlayElement::setCloneable(bool c)

OverlayContainer *
OverlayElement::getParent()

unsigned short
OverlayElement::getZOrder()

Real
OverlayElement::getSquaredViewDepth(cam)
    Camera * cam

## const LightList & 	getLights (void) const

void
OverlayElement::copyFromTemplate(templateOverlay)
    OverlayElement * templateOverlay

OverlayElement *
OverlayElement::clone(instanceName)
    String  instanceName

const OverlayElement *
OverlayElement::getSourceTemplate()
