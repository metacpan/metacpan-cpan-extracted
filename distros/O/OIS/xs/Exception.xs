MODULE = OIS     PACKAGE = OIS::Exception

Exception *
Exception::new(err, str, line, file)
    OIS_ERROR  err
    char *     str
    int        line
    char *     file

void
Exception::DESTROY()

## these are "public attributes", not methods
OIS_ERROR
Exception::eType()
  CODE:
    RETVAL = (*THIS).eType;
  OUTPUT:
    RETVAL

int
Exception::eLine()
  CODE:
    RETVAL = (*THIS).eLine;
  OUTPUT:
    RETVAL

const char *
Exception::eFile()
  CODE:
    RETVAL = (*THIS).eFile;
  OUTPUT:
    RETVAL

const char *
Exception::eText()
  CODE:
    RETVAL = (*THIS).eText;
  OUTPUT:
    RETVAL


## technically these are in OIS namespace, not OIS::Exception
## OIS_ERROR enum
static int
Exception::E_InputDisconnected()
  ALIAS:
    OIS::Exception::E_InputDeviceNonExistant = 1
    OIS::Exception::E_InputDeviceNotSupported = 2
    OIS::Exception::E_DeviceFull = 3
    OIS::Exception::E_NotSupported = 4
    OIS::Exception::E_NotImplemented = 5
    OIS::Exception::E_Duplicate = 6
    OIS::Exception::E_InvalidParam = 7
    OIS::Exception::E_General = 8
  CODE:
    switch (ix) {
        case 0: RETVAL = OIS::E_InputDisconnected; break;
        case 1: RETVAL = OIS::E_InputDeviceNonExistant; break;
        case 2: RETVAL = OIS::E_InputDeviceNotSupported; break;
        case 3: RETVAL = OIS::E_DeviceFull; break;
        case 4: RETVAL = OIS::E_NotSupported; break;
        case 5: RETVAL = OIS::E_NotImplemented; break;
        case 6: RETVAL = OIS::E_Duplicate; break;
        case 7: RETVAL = OIS::E_InvalidParam; break;
        case 8: RETVAL = OIS::E_General; break;
    }
  OUTPUT:
    RETVAL
