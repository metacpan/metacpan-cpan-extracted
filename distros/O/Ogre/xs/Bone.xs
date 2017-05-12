MODULE = Ogre     PACKAGE = Ogre::Bone

Bone *
Bone::createChild(handle, translate=&Vector3::ZERO, rotate=&Quaternion::IDENTITY)
    unsigned short  handle
    const Vector3 * translate
    const Quaternion * rotate
  C_ARGS:
    handle, *translate, *rotate

unsigned short
Bone::getHandle()

void
Bone::setBindingPose()

void
Bone::reset()

void
Bone::setManuallyControlled(bool manuallyControlled)

bool
Bone::isManuallyControlled()

void
Bone::needUpdate(bool forceParentUpdate=false)
