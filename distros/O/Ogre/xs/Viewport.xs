MODULE = Ogre     PACKAGE = Ogre::Viewport

# this is almost all wrapped


void
Viewport::update()

RenderTarget *
Viewport::getTarget()

Camera *
Viewport::getCamera()

void
Viewport::setCamera(cam)
    Camera * cam

int
Viewport::getZOrder()

Real
Viewport::getLeft()

Real
Viewport::getTop()

Real
Viewport::getWidth()

Real
Viewport::getHeight()

int
Viewport::getActualLeft()

int
Viewport::getActualTop()

int
Viewport::getActualWidth()

int
Viewport::getActualHeight()

void
Viewport::setDimensions(left, top, width, height)
    Real  left
    Real  top
    Real  width
    Real  height

void
Viewport::setBackgroundColour(colour)
    ColourValue *colour
  C_ARGS:
    *colour

# getBackgroundColour

void
Viewport::setClearEveryFrame(clear, buffers=FBT_COLOUR|FBT_DEPTH)
    bool          clear
    unsigned int  buffers

bool
Viewport::getClearEveryFrame()

unsigned int
Viewport::getClearBuffers()

void
Viewport::setMaterialScheme(schemeName)
    String  schemeName

String
Viewport::getMaterialScheme()

# this returns the values as a list instead of the C++ arg reference way
void
Viewport::getActualDimensions(OUTLIST int left, OUTLIST int top, OUTLIST int width, OUTLIST int height)
  C_ARGS:
    left, top, width, height

void
Viewport::setOverlaysEnabled(enabled)
    bool  enabled

bool
Viewport::getOverlaysEnabled()

void
Viewport::setSkiesEnabled(enabled)
    bool  enabled

bool
Viewport::getSkiesEnabled()

void
Viewport::setShadowsEnabled(enabled)
    bool  enabled

bool
Viewport::getShadowsEnabled()

void
Viewport::setVisibilityMask(mask)
    uint32  mask

uint32
Viewport::getVisibilityMask()

# virtual
void
Viewport::setRenderQueueInvocationSequenceName(sequenceName)
    String  sequenceName

String
Viewport::getRenderQueueInvocationSequenceName()


