MODULE = OIS     PACKAGE = OIS::MouseEvent

## These are "public attributes", not methods.

const MouseState *
MouseEvent::state()
  CODE:
    // MouseState *state = new MouseState;
    // *state = THIS->state;
    // RETVAL = state;
    RETVAL = &(THIS->state);
  OUTPUT:
    RETVAL
