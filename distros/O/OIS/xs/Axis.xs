MODULE = OIS     PACKAGE = OIS::Axis

## These are "public attributes", not methods.

int
Axis::abs()
  CODE:
    RETVAL = (*THIS).abs;
  OUTPUT:
    RETVAL

int
Axis::rel()
  CODE:
    RETVAL = (*THIS).rel;
  OUTPUT:
    RETVAL

bool
Axis::absOnly()
  CODE:
    RETVAL = (*THIS).absOnly;
  OUTPUT:
    RETVAL
