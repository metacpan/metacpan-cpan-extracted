MODULE = OIS     PACKAGE = OIS::MouseState

int
MouseState::buttonDown(button)
    int button
  C_ARGS:
    (OIS::MouseButtonID)button

## These are "public attributes", not methods.
## Not sure how useful these are, but there you go...
int
MouseState::width()
  CODE:
    RETVAL = THIS->width;
  OUTPUT:
    RETVAL

int
MouseState::height()
  CODE:
    RETVAL = THIS->height;
  OUTPUT:
    RETVAL

## setWidth and setHeight are special for Perl
void
MouseState::setWidth(width)
    int  width
  CODE:
    THIS->width = width;

void
MouseState::setHeight(height)
    int  height
  CODE:
    THIS->height = height;

int
MouseState::buttons()
  CODE:
    RETVAL = THIS->buttons;
  OUTPUT:
    RETVAL

Axis *
MouseState::X()
  CODE:
    RETVAL = &(THIS->X);
  OUTPUT:
    RETVAL

Axis *
MouseState::Y()
  CODE:
    RETVAL = &(THIS->Y);
  OUTPUT:
    RETVAL

Axis *
MouseState::Z()
  CODE:
    RETVAL = &(THIS->Z);
  OUTPUT:
    RETVAL
