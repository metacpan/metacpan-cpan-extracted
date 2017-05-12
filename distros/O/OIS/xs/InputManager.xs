MODULE = OIS     PACKAGE = OIS::InputManager

## This class is completely wrapped

## Note: there are two different versions of this, handled in OIS/InputManager.pm
## static InputManager* OIS::InputManager::createInputSystem(std::size_t winHandle)
## static InputManager* OIS::InputManager::createInputSystem(ParamList &paramList)
static InputManager *
InputManager::createInputSystemPtr(winHandle)
    size_t winHandle
  CODE:
    RETVAL = OIS::InputManager::createInputSystem(winHandle);
  OUTPUT:
    RETVAL

static InputManager *
InputManager::createInputSystemPL(key, value)
    string  key
    string  value
  CODE:
    OIS::ParamList pl;
    pl.insert(std::make_pair(key, value));
    RETVAL = OIS::InputManager::createInputSystem(pl);
  OUTPUT:
    RETVAL

static void
InputManager::destroyInputSystem(manager)
    InputManager * manager

## Note: there is only one method in the C++ API:
## Object* OIS::InputManager::createInputObject(Type iType, bool bufferMode)
## However, the Object* is really a Joystick*, Keyboard*, or Mouse*,
## which would normally be static_cast<OIS::Joystick *> (etc.) in C++;
## dunno how to do that with Perl, so I made three separate methods.
JoyStick *
InputManager::createInputObjectJoyStick(bufferMode)
    bool  bufferMode
  CODE:
    try {
        RETVAL = static_cast<JoyStick *>(THIS->createInputObject(OISJoyStick, bufferMode));
    }
    catch (const OIS::Exception &e) {
        // XXX: not sure if this actually works....
        SV *errsv = get_sv("@", TRUE);
        SV *exception_object = sv_newmortal();
        TMOIS_OUT(exception_object, &e, Exception);
        sv_setsv(errsv, exception_object);
        croak(Nullch);
    }
  OUTPUT:
    RETVAL

Keyboard *
InputManager::createInputObjectKeyboard(bufferMode)
    bool  bufferMode
  CODE:
    try {
        RETVAL = static_cast<Keyboard *>(THIS->createInputObject(OISKeyboard, bufferMode));
    }
    catch (const OIS::Exception &e) {
        // XXX: not sure if this actually works....
        SV *errsv = get_sv("@", TRUE);
        SV *exception_object = sv_newmortal();
        TMOIS_OUT(exception_object, &e, Exception);
        sv_setsv(errsv, exception_object);
        croak(Nullch);
    }
  OUTPUT:
    RETVAL

Mouse *
InputManager::createInputObjectMouse(bufferMode)
    bool  bufferMode
  CODE:
    try {
        RETVAL = static_cast<Mouse *>(THIS->createInputObject(OISMouse, bufferMode));
    }
    catch (const OIS::Exception &e) {
        // XXX: not sure if this actually works....
        SV *errsv = get_sv("@", TRUE);
        SV *exception_object = sv_newmortal();
        TMOIS_OUT(exception_object, &e, Exception);
        sv_setsv(errsv, exception_object);
        croak(Nullch);
    }
  OUTPUT:
    RETVAL

void
InputManager::destroyInputObject(obj)
    Object * obj


static unsigned int
InputManager::getVersionNumber()

## for some reason, this is no longer a class method...
string
InputManager::getVersionName()
  CODE:
    RETVAL = THIS->getVersionNumber();
  OUTPUT:
    RETVAL

## const std::string& OIS::InputManager::inputSystemName
string
InputManager::inputSystemName()

## these used to be around in 1.0...
int
InputManager::numJoySticks()
  CODE:
    RETVAL = THIS->getNumberOfDevices(OIS::OISJoyStick);
  OUTPUT:
    RETVAL

int
InputManager::numMice()
  CODE:
    RETVAL = THIS->getNumberOfDevices(OIS::OISMouse);
  OUTPUT:
    RETVAL

int
InputManager::numKeyboards()
  CODE:
    RETVAL = THIS->getNumberOfDevices(OIS::OISKeyboard);
  OUTPUT:
    RETVAL
