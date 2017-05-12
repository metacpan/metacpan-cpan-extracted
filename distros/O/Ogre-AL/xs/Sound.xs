MODULE = Ogre::AL     PACKAGE = Ogre::AL::Sound

## constructors are protected, so not wrappable


## xxx: need to add addSoundFinishedHandler and addSoundLoopedHandler (callbacks)

bool
Sound::play()

bool
Sound::isPlaying()

bool
Sound::pause()

bool
Sound::isPaused()

bool
Sound::stop()

bool
Sound::isStopped()

bool
Sound::isInitial()

void
Sound::setPitch(Real pitch)

Real
Sound::getPitch()

void
Sound::setGain(Real gain)

Real
Sound::getGain()

void
Sound::setMaxGain(Real maxGain)

Real
Sound::getMaxGain()

void
Sound::setMinGain(Real minGain)

Real
Sound::getMinGain()

## xxx: this is not actually in the .cpp file!
##void
##Sound::setGainValues(Real maxGain, Real minGain, Real gain)

void
Sound::setMaxDistance(Real maxDistance)

Real
Sound::getMaxDistance()

void
Sound::setRolloffFactor(Real rolloffFactor)

Real
Sound::getRolloffFactor()

void
Sound::setReferenceDistance(Real refDistance)

Real
Sound::getReferenceDistance()

void
Sound::setDistanceValues(Real maxDistance, Real rolloffFactor, Real refDistance)

void
Sound::setVelocity(...)
  CODE:
    PLOGREAL_VEC_OR_REALS(setVelocity)

const Vector3 *
Sound::getVelocity()
  CODE:
    RETVAL = &(THIS->getVelocity());
  OUTPUT:
    RETVAL

void
Sound::setRelativeToListener(bool relative)

bool
Sound::isRelativeToListener()

void
Sound::setPosition(...)
  CODE:
    PLOGREAL_VEC_OR_REALS(setPosition)

const Vector3 *
Sound::getPosition()
  CODE:
    RETVAL = &(THIS->getPosition());
  OUTPUT:
    RETVAL

void
Sound::setDirection(...)
  CODE:
    PLOGREAL_VEC_OR_REALS(setDirection)

const Vector3 *
Sound::getDirection()
  CODE:
    RETVAL = &(THIS->getDirection());
  OUTPUT:
    RETVAL

void
Sound::setOuterConeGain(Real outerConeGain)

Real
Sound::getOuterConeGain()

void
Sound::setInnerConeAngle(Real innerConeAngle)

Real
Sound::getInnerConeAngle()

void
Sound::setOuterConeAngle(Real outerConeAngle)

Real
Sound::getOuterConeAngle()

void
Sound::setLoop(bool loop)

bool
Sound::isLooping()

bool
Sound::isStreaming()

void
Sound::setPriority(Priority priority)

Priority
Sound::getPriority()

Real
Sound::getSecondDuration()

void
Sound::setSecondOffset(Real seconds)

Real
Sound::getSecondOffset()

const Vector3 *
Sound::getDerivedPosition()
  CODE:
    RETVAL = &(THIS->getDerivedPosition());
  OUTPUT:
    RETVAL

const Vector3 *
Sound::getDerivedDirection()
  CODE:
    RETVAL = &(THIS->getDerivedDirection());
  OUTPUT:
    RETVAL

String
Sound::getFileName()

String
Sound::getMovableType()

const AxisAlignedBox *
Sound::getBoundingBox()
  CODE:
    RETVAL = &(THIS->getBoundingBox());
  OUTPUT:
    RETVAL

Real
Sound::getBoundingRadius()

## ogre 1.5
## void visitRenderables(Ogre::Renderable::Visitor* visitor, bool debugRenderables = false)

