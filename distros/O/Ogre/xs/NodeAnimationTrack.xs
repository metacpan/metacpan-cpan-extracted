MODULE = Ogre     PACKAGE = Ogre::NodeAnimationTrack

TransformKeyFrame *
NodeAnimationTrack::createNodeKeyFrame(Real timePos)

Node *
NodeAnimationTrack::getAssociatedNode()

void
NodeAnimationTrack::setAssociatedNode(node)
    Node * node

void
NodeAnimationTrack::applyToNode(node, timeIndex, weight=1.0, scale=1.0f)
    Node * node
    const TimeIndex * timeIndex
    Real weight
    Real scale
  C_ARGS:
    node, *timeIndex, weight, scale

void
NodeAnimationTrack::setUseShortestRotationPath(bool useShortestPath)

bool
NodeAnimationTrack::getUseShortestRotationPath()

# note: C++ API passes in pointer with void return
# xxx: I used TransformKeyFrame instead of KeyFrame.
# I hope that is ok... the API says KeyFrame, but a *working*
# example used TransformKeyFrame, and I was getting segfaults
# with KeyFrame, so...
TransformKeyFrame *
NodeAnimationTrack::getInterpolatedKeyFrame(timeIndex)
    const TimeIndex *timeIndex
  PREINIT:
    // xxx: I guess this will never be freed...
    TransformKeyFrame *kf = new TransformKeyFrame(0, 0);
  CODE:
    THIS->getInterpolatedKeyFrame(*timeIndex, kf);
    RETVAL = kf;
  OUTPUT:
    RETVAL

void
NodeAnimationTrack::apply(timeIndex, weight=1.0, scale=1.0f)
    const TimeIndex * timeIndex
    Real  weight
    Real  scale
  C_ARGS:
    *timeIndex, weight, scale

TransformKeyFrame *
NodeAnimationTrack::getNodeKeyFrame(unsigned short index)

bool
NodeAnimationTrack::hasNonZeroKeyFrames()

void
NodeAnimationTrack::optimise()
