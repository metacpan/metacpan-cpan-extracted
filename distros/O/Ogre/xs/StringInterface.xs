MODULE = Ogre     PACKAGE = Ogre::StringInterface

bool
StringInterface::setParameter(name, value)
    String  name
    String  value

String
StringInterface::getParameter(name)
    String  name

void
StringInterface::copyParametersTo(dest)
    StringInterface * dest

static void
StringInterface::cleanupDictionary()
