MODULE = Ogre     PACKAGE = Ogre::Log

String
Log::getName()

bool
Log::isDebugOutputEnabled()

bool
Log::isFileOutputSuppressed()

void
Log::logMessage(String message, int lml, bool maskDebug)
  C_ARGS:
    message, (LogMessageLevel)lml, maskDebug

void
Log::setLogDetail(int ll)
  C_ARGS:
    (LoggingLevel)ll

int
Log::getLogDetail()

## void Log::addListener(LogListener *listener)
## void Log::removeListener(LogListener *listener)

