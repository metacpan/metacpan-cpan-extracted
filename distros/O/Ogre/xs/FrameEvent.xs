MODULE = Ogre     PACKAGE = Ogre::FrameEvent

## These are "public attributes", not methods.

Real
FrameEvent::timeSinceLastEvent()
  CODE:
    RETVAL = (*THIS).timeSinceLastEvent;
  OUTPUT:
    RETVAL

Real
FrameEvent::timeSinceLastFrame()
  CODE:
    RETVAL = (*THIS).timeSinceLastFrame;
  OUTPUT:
    RETVAL
