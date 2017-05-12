MODULE = OIS     PACKAGE = OIS::JoyStick

## This is a bit different than the C++ API,
## but not too much. You create a Perl class that
## implements the OIS::KeyListener interface (two methods),
## then pass an object of that class here.
## Behind the scenes, there is a C++ class PerlOISKeyListener
## that handles calling your Perl code from the C++ callback.
## (perlKeyListener below is instantiated "globally" in OIS.xs.)
void
JoyStick::setEventCallback(joyListener)
    SV * joyListener
  CODE:
    poisJoyStickListener.setPerlObject(joyListener);
    THIS->setEventCallback(&poisJoyStickListener);

## hmm, not sure why you would want to get this...
JoyStickListener *
JoyStick::getEventCallback()

short
JoyStick::buttons()

short
JoyStick::axes()

short
JoyStick::hats()

JoyStickState *
JoyStick::getJoyStickState()
  PREINIT:
    JoyStickState state;
  CODE:
    // xxx: I doubt this works...
    state = THIS->getJoyStickState();
    RETVAL = &state;
  OUTPUT:
    RETVAL
