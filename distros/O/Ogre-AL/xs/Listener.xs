MODULE = Ogre::AL   PACKAGE = Ogre::AL::Listener

static Listener *
Listener::getSingletonPtr()

void
Listener::setGain(Real gain)

Real
Listener::getGain()

void
Listener::setPosition(...)
  CODE:
    PLOGREAL_VEC_OR_REALS(setPosition)

const Vector3 *
Listener::getPosition()
  CODE:
    RETVAL = &(THIS->getPosition());
  OUTPUT:
    RETVAL

void
Listener::setDirection(...)
  CODE:
    PLOGREAL_VEC_OR_REALS(setDirection)

const Vector3 *
Listener::getDirection()
  CODE:
    RETVAL = &(THIS->getDirection());
  OUTPUT:
    RETVAL

void
Listener::setVelocity(...)
  CODE:
    PLOGREAL_VEC_OR_REALS(setVelocity)

const Vector3 *
Listener::getVelocity()
  CODE:
    RETVAL = &(THIS->getVelocity());
  OUTPUT:
    RETVAL

const Vector3 *
Listener::getDerivedPosition()
  CODE:
    RETVAL = &(THIS->getDerivedPosition());
  OUTPUT:
    RETVAL

const Vector3 *
Listener::getDerivedDirection()
  CODE:
    RETVAL = &(THIS->getDerivedDirection());
  OUTPUT:
    RETVAL

String
Listener::getMovableType()

const AxisAlignedBox *
Listener::getBoundingBox()
  CODE:
    RETVAL = &(THIS->getBoundingBox());
  OUTPUT:
    RETVAL

Real
Listener::getBoundingRadius()

## ogre 1.5
## void visitRenderables(Ogre::Renderable::Visitor* visitor, bool debugRenderables = false)
