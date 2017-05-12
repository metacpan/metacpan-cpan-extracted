MODULE = Ogre     PACKAGE = Ogre::Overlay

OverlayContainer *
Overlay::getChild(name)
    String  name

String
Overlay::getName()

void
Overlay::setZOrder(zorder)
    unsigned short  zorder

unsigned short
Overlay::getZOrder()

bool
Overlay::isVisible()

bool
Overlay::isInitialised()

void
Overlay::show()

void
Overlay::hide()

void
Overlay::add2D(cont)
    OverlayContainer * cont

void
Overlay::remove2D(cont)
    OverlayContainer * cont

void
Overlay::add3D(node)
    SceneNode * node

void
Overlay::remove3D(node)
    SceneNode * node

void
Overlay::clear()

void
Overlay::setScroll(x, y)
    Real  x
    Real  y

Real
Overlay::getScrollX()

Real
Overlay::getScrollY()

void
Overlay::scroll(xoff, yoff)
    Real xoff
    Real yoff

void
Overlay::setRotate(angle)
    DegRad * angle
  C_ARGS:
    *angle

# Degree &getRotate()

void
Overlay::rotate(angle)
    DegRad * angle
  C_ARGS:
    *angle

void
Overlay::setScale(x, y)
    Real  x
    Real  y

Real
Overlay::getScaleX()

Real
Overlay::getScaleY()

OverlayElement *
Overlay::findElementAt(x, y)
    Real  x
    Real  y

String
Overlay::getOrigin()
