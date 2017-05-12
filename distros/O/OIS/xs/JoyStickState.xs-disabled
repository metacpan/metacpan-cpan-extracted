MODULE = OIS     PACKAGE = OIS::JoyStickState

int
JoyStickState::buttonDown(button)
    int button


## not sure how useful this is, but there you go
## (I think these are just not completely implemented in OIS yet)
int
JoyStickState::buttons()
  CODE:
    RETVAL = (*THIS).buttons;
  OUTPUT:
    RETVAL

## I think Axis, Pov, and Slider must not be completely
## implemented in OIS yet; the only way these are exposed
## are through member variables.
## So...I have not wrapped those yet.
