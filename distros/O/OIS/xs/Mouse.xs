MODULE = OIS     PACKAGE = OIS::Mouse

## This is a bit different than the C++ API,
## but not too much. You create a Perl class that
## implements the OIS::KeyListener interface (two methods),
## then pass an object of that class here.
## Behind the scenes, there is a C++ class PerlOISKeyListener
## that handles calling your Perl code from the C++ callback.
## (perlKeyListener below is instantiated "globally" in OIS.xs.)
void
Mouse::setEventCallback(mouseListener)
    SV * mouseListener
  CODE:
    poisMouseListener.setPerlObject(mouseListener);
    THIS->setEventCallback(&poisMouseListener);

## hmm, not sure why you would want to get this...
MouseListener *
Mouse::getEventCallback()

const MouseState *
Mouse::getMouseState()
  CODE:
    // MouseState *state = new MouseState;
    // *state = THIS->getMouseState();
    // RETVAL = state;
    // This is how you do it?!?
    RETVAL = &(THIS->getMouseState());
  OUTPUT:
    RETVAL


## MouseButtonID enum
static int
Mouse::MB_Left()
  ALIAS:
    OIS::Mouse::MB_Right = 1
    OIS::Mouse::MB_Middle = 2
    OIS::Mouse::MB_Button3 = 3
    OIS::Mouse::MB_Button4 = 4
    OIS::Mouse::MB_Button5 = 5
    OIS::Mouse::MB_Button6 = 6
    OIS::Mouse::MB_Button7 = 7
  CODE:
    switch (ix) {
        case 0: RETVAL = OIS::MB_Left; break;
        case 1: RETVAL = OIS::MB_Right; break;
        case 2: RETVAL = OIS::MB_Middle; break;
        case 3: RETVAL = OIS::MB_Button3; break;
        case 4: RETVAL = OIS::MB_Button4; break;
        case 5: RETVAL = OIS::MB_Button5; break;
        case 6: RETVAL = OIS::MB_Button6; break;
        case 7: RETVAL = OIS::MB_Button7; break;
    }
  OUTPUT:
    RETVAL
