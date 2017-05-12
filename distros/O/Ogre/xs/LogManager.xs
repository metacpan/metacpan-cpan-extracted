MODULE = Ogre     PACKAGE = Ogre::LogManager

static LogManager *
LogManager::getSingletonPtr()

## XXX: as usual, this is not what the C++ API has
void
LogManager::logMessage(message)
    String  message
