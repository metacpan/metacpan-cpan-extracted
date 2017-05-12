MODULE = Ogre     PACKAGE = Ogre::RenderTarget

## Viewport * addViewport(Camera *cam, int ZOrder=0, Real left=0.0f, Real top=0.0f, Real width=1.0f, Real height=1.0f)
Viewport *
RenderTarget::addViewport(cam, ZOrder=0, left=0, top=0, width=1, height=1)
    Camera * cam
    int      ZOrder
    Real    left
    Real    top
    Real    width
    Real    height

## C++ version uses output parameters (pointers),
## this Perl version will return a list instead:
## ($w, $h, $d) = $win->getMetrics();
## (note: there is a different version in RenderWindow)
void
RenderTarget::getMetrics(OUTLIST unsigned int width, OUTLIST unsigned int height, OUTLIST unsigned int colourDepth)
  C_ARGS:
    width, height, colourDepth

#void
#RenderTarget::getStatistics(OUTLIST Real lastFPS, OUTLIST Real avgFPS, OUTLIST Real bestFPS, OUTLIST Real worstFPS)
#  C_ARGS:
#    lastFPS, avgFPS, bestFPS, worstFPS

## Note: there are methods for getting each attribute of FrameStats directly
## instead of getting a FrameStats object (as a working alternative to this...)
## XXX: I tried several ways, but I cant get fucking xsubpp to recognize
## FrameStats or RenderTarget::FrameStats as correct types
#FrameStats *
#RenderTarget::getStatistics()
#  CODE:
#    // xxx: I doubt this works...
#    FrameStats *stats;
#    *stats = THIS->getStatistics();
#    RETVAL = stats;
#  OUTPUT:
#    RETVAL

void
RenderTarget::resetStatistics()

Real
RenderTarget::getLastFPS()

Real
RenderTarget::getAverageFPS()

Real
RenderTarget::getBestFPS()

Real
RenderTarget::getWorstFPS()

Real
RenderTarget::getBestFrameTime()

Real
RenderTarget::getWorstFrameTime()

size_t
RenderTarget::getTriangleCount()

size_t
RenderTarget::getBatchCount()

void
RenderTarget::update()

bool
RenderTarget::isPrimary()

bool
RenderTarget::isActive()

void
RenderTarget::setActive(state)
    bool  state

bool
RenderTarget::isAutoUpdated()

void
RenderTarget::setAutoUpdated(autoupdate)
    bool  autoupdate

String
RenderTarget::getName()

unsigned int
RenderTarget::getWidth()

unsigned int
RenderTarget::getHeight()

unsigned int
RenderTarget::getColourDepth()

unsigned short
RenderTarget::getNumViewports()

Viewport *
RenderTarget::getViewport(index)
    unsigned short  index

void
RenderTarget::removeViewport(zOrder)
    int  zOrder

void
RenderTarget::removeAllViewports()

uchar
RenderTarget::getPriority()

void
RenderTarget::setPriority(priority)
    uchar  priority

void
RenderTarget::writeContentsToFile(filename)
    String  filename

String
RenderTarget::writeContentsToTimestampedFile(filenamePrefix, filenameSuffix)
    String  filenamePrefix
    String  filenameSuffix

bool
RenderTarget::requiresTextureFlipping()


## XXX: not sure if this will work right in all cases,
## the C++ API returns a void* in the 2nd input parameter,
## while here we just return a string. I have no idea what
## all "custom attributes" there are, so I just implemented
## a few types to cover some of the bases (let me know if there
## are particular ones that are missing).
## void getCustomAttribute(const String &name, void *pData)
size_t
RenderTarget::getCustomAttributePtr(name)
    String  name
  PREINIT:
    size_t pData;
  CODE:
    THIS->getCustomAttribute(name, &pData);
    RETVAL = pData;
  OUTPUT:
    RETVAL

int
RenderTarget::getCustomAttributeInt(name)
    String  name
  PREINIT:
    int pData;
  CODE:
    THIS->getCustomAttribute(name, &pData);
    RETVAL = pData;
  OUTPUT:
    RETVAL

Real
RenderTarget::getCustomAttributeFloat(name)
    String  name
  PREINIT:
    Real pData;
  CODE:
    THIS->getCustomAttribute(name, &pData);
    RETVAL = pData;
  OUTPUT:
    RETVAL

String
RenderTarget::getCustomAttributeStr(name)
    String  name
  PREINIT:
    String pData;
  CODE:
    THIS->getCustomAttribute(name, &pData);
    RETVAL = pData;
  OUTPUT:
    RETVAL

bool
RenderTarget::getCustomAttributeBool(name)
    String  name
  PREINIT:
    bool pData;
  CODE:
    THIS->getCustomAttribute(name, &pData);
    RETVAL = pData;
  OUTPUT:
    RETVAL
