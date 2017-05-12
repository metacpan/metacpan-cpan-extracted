MODULE = Ogre     PACKAGE = Ogre::TransformKeyFrame

void
TransformKeyFrame::setTranslate(trans)
    const Vector3 * trans
  C_ARGS:
    *trans

Vector3 *
TransformKeyFrame::getTranslate()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getTranslate();
  OUTPUT:
    RETVAL

void
TransformKeyFrame::setScale(scale)
    const Vector3 * scale
  C_ARGS:
    *scale

Vector3 *
TransformKeyFrame::getScale()
  CODE:
    RETVAL = new Vector3;
    *RETVAL = THIS->getScale();
  OUTPUT:
    RETVAL

void
TransformKeyFrame::setRotation(rot)
    const Quaternion * rot
  C_ARGS:
    *rot

Quaternion *
TransformKeyFrame::getRotation()
  CODE:
    RETVAL = new Quaternion;
    *RETVAL = THIS->getRotation();
  OUTPUT:
    RETVAL
