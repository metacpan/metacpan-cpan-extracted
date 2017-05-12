#include "perlOIS.h"
#include <string>

// #include "PerlOISJoyStickListener.h"
#include "PerlOISKeyListener.h"
#include "PerlOISMouseListener.h"

// These instances just sit around until needed by setEventCallback.
// OIS only allows one listener each, so this should be okay I think.

//PerlOISJoyStickListener poisJoyStickListener;
PerlOISKeyListener poisKeyListener;
PerlOISMouseListener poisMouseListener;


using namespace std;
using namespace OIS;


MODULE = OIS		PACKAGE = OIS

PROTOTYPES: ENABLE

## Type enum
static int
OIS::OISUnknown()
  ALIAS:
    OIS::OISKeyboard = 1
    OIS::OISMouse = 2
    OIS::OISJoyStick = 3
    OIS::OISTablet = 4
  CODE:
    switch (ix) {
        case 0: RETVAL = OIS::OISUnknown; break;
        case 1: RETVAL = OIS::OISKeyboard; break;
        case 2: RETVAL = OIS::OISMouse; break;
        case 3: RETVAL = OIS::OISJoyStick; break;
        case 4: RETVAL = OIS::OISTablet; break;
    }
  OUTPUT:
    RETVAL

## ComponentType enum
static int
OIS::OIS_Unknown()
  ALIAS:
    OIS::OIS_Button = 1
    OIS::OIS_Axis = 2
    OIS::OIS_Slider = 3
    OIS::OIS_POV = 4
    OIS::OIS_Vector3 = 5
  CODE:
    switch (ix) {
        case 0: RETVAL = OIS::OIS_Unknown; break;
        case 1: RETVAL = OIS::OIS_Button; break;
        case 2: RETVAL = OIS::OIS_Axis; break;
        case 3: RETVAL = OIS::OIS_Slider; break;
        case 4: RETVAL = OIS::OIS_POV; break;
        case 5: RETVAL = OIS::OIS_Vector3; break;
    }
  OUTPUT:
    RETVAL


## include all other .xs files
INCLUDE: perl -e "print qq{INCLUDE: \$_\$/} for <xs/*.xs>" |
