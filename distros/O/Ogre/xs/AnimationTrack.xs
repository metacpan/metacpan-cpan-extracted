MODULE = Ogre     PACKAGE = Ogre::AnimationTrack

unsigned short
AnimationTrack::getHandle()

unsigned short
AnimationTrack::getNumKeyFrames()

KeyFrame *
AnimationTrack::getKeyFrame(unsigned short index)

Real
AnimationTrack::getKeyFramesAtTime(timeIndex, keyFrame1, keyFrame2, firstKeyIndex=0)
    const TimeIndex * timeIndex
    KeyFrame * keyFrame1
    KeyFrame * keyFrame2
    unsigned short  firstKeyIndex
  C_ARGS:
    *timeIndex, &keyFrame1, &keyFrame2, &firstKeyIndex

KeyFrame *
AnimationTrack::createKeyFrame(Real timePos)

void
AnimationTrack::removeKeyFrame(unsigned short index)

void
AnimationTrack::removeAllKeyFrames()

# note: C++ API passes in pointer with void return
KeyFrame *
AnimationTrack::getInterpolatedKeyFrame(timeIndex)
    const TimeIndex * timeIndex
  PREINIT:
    KeyFrame * kf;
  CODE:
    THIS->getInterpolatedKeyFrame(*timeIndex, kf);
    RETVAL = kf;
  OUTPUT:
    RETVAL

void
AnimationTrack::apply(timeIndex, weight=1.0, scale=1.0f)
    const TimeIndex * timeIndex
    Real  weight
    Real  scale
  C_ARGS:
    *timeIndex, weight, scale

bool
AnimationTrack::hasNonZeroKeyFrames()

void
AnimationTrack::optimise()
