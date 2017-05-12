MODULE = OIS     PACKAGE = OIS::Object

Type
Object::type()

string
Object::vendor()

bool
Object::buffered()

void
Object::setBuffered(buffered)
    bool  buffered

InputManager *
Object::getCreator()

void
Object::capture()

int
Object::getID()

## xxx: not yet wrapped:
## Interface * queryInterface(Interface::IType type)
