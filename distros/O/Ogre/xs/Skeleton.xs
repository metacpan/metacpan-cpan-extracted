MODULE = Ogre     PACKAGE = Ogre::Skeleton

Bone *
Skeleton::createBone(...)
  CODE:
    // createBone()
    if (items == 1) {
        RETVAL = THIS->createBone();
    }
    // createBone(String name, unsigned short handle)
    else if (items == 3) {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;

        unsigned short handle = (unsigned short)SvUV(ST(2));

        RETVAL = THIS->createBone(name, handle);
    }
    else if (items == 2) {
        if (looks_like_number(ST(1))) {
            unsigned short handle = (unsigned short)SvUV(ST(1));
            RETVAL = THIS->createBone(handle);
        }
        else {
            char * xstmpchr = (char *) SvPV_nolen(ST(1));
            String name = xstmpchr;
            RETVAL = THIS->createBone(name);
        }
    }
  OUTPUT:
    RETVAL

unsigned short
Skeleton::getNumBones()

Bone *
Skeleton::getRootBone()

## BoneIterator Skeleton::getRootBoneIterator()

## BoneIterator Skeleton::getBoneIterator()

Bone *
Skeleton::getBone(...)
  CODE:
    if (looks_like_number(ST(1))) {
        unsigned short handle = (unsigned short)SvUV(ST(1));
        RETVAL = THIS->getBone(handle);
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;
        RETVAL = THIS->getBone(name);
    }
  OUTPUT:
    RETVAL

void
Skeleton::setBindingPose()

void
Skeleton::reset(bool resetManualBones=false)

Animation *
Skeleton::createAnimation(String name, Real length)

## xxx: left off last arg
##  getAnimation(String name, const LinkedSkeletonAnimationSource **linker=0)
Animation *
Skeleton::getAnimation(...)
  CODE:
    if (looks_like_number(ST(1))) {
        unsigned short handle = (unsigned short)SvUV(ST(1));
        RETVAL = THIS->getAnimation(handle);
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;
        RETVAL = THIS->getAnimation(name);
    }
  OUTPUT:
    RETVAL

bool
Skeleton::hasAnimation(String name)

void
Skeleton::removeAnimation(String name)

void
Skeleton::setAnimationState(animSet)
    const AnimationStateSet * animSet
  C_ARGS:
    *animSet

unsigned short
Skeleton::getNumAnimations()

int
Skeleton::getBlendMode()

void
Skeleton::setBlendMode(int state)
  C_ARGS:
    (SkeletonAnimationBlendMode)state

void
Skeleton::optimiseAllAnimations(bool preservingIdentityNodeTracks=false)

void
Skeleton::addLinkedSkeletonAnimationSource(String skelName, Real scale=1.0f)

void
Skeleton::removeAllLinkedSkeletonAnimationSources()

## LinkedSkeletonAnimSourceIterator Skeleton::getLinkedSkeletonAnimationSourceIterator()

bool
Skeleton::getManualBonesDirty()

bool
Skeleton::hasManualBones()
