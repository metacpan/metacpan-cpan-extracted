MODULE = OIS     PACKAGE = OIS::KeyEvent

## These are "public attributes", not methods.

int
KeyEvent::key()
  CODE:
    RETVAL = (*THIS).key;
  OUTPUT:
    RETVAL

unsigned int
KeyEvent::text()
  CODE:
    RETVAL = (*THIS).text;
  OUTPUT:
    RETVAL
