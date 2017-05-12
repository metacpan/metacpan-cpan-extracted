MODULE = Ogre     PACKAGE = Ogre::AnimationState

# this is all wrapped
# except the overridden == and != operators

String
AnimationState::getAnimationName()

Real
AnimationState::getTimePosition()

void
AnimationState::setTimePosition(Real timePos)

Real
AnimationState::getLength()

void
AnimationState::setLength(Real len)

Real
AnimationState::getWeight()

void
AnimationState::setWeight(Real weight)

void
AnimationState::addTime(Real offset)

bool
AnimationState::hasEnded()

bool
AnimationState::getEnabled()

void
AnimationState::setEnabled(bool enabled)

bool
AnimationState::getLoop()

void
AnimationState::setLoop(bool loop)

void
AnimationState::copyStateFrom(animState)
    AnimationState * animState
  C_ARGS:
    *animState

AnimationStateSet *
AnimationState::getParent()
