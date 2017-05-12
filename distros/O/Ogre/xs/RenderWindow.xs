MODULE = Ogre     PACKAGE = Ogre::RenderWindow

# this is almost all wrapped


# I think Root::createRenderWindow is the same, no?
## void create(const String &name, unsigned int width, unsigned int height, bool fullScreen, const NameValuePairList *miscParams)

void
RenderWindow::setFullscreen(fullScreen, width, height)
    bool          fullScreen
    unsigned int  width
    unsigned int  height

void
RenderWindow::destroy()

void
RenderWindow::resize(width, height)
    unsigned int  width
    unsigned int  height

void
RenderWindow::windowMovedOrResized()

void
RenderWindow::reposition(left, top)
    int  left
    int  top

bool
RenderWindow::isVisible()

void
RenderWindow::setVisible(visible)
    bool  visible

bool
RenderWindow::isClosed()

void
RenderWindow::swapBuffers(waitForVSync=true)
    bool  waitForVSync


# two versions, one in RenderTarget
#void
#RenderWindow::update(swapBuffers)
#    bool  swapBuffers

bool
RenderWindow::isFullScreen()


## C++ version uses output parameters (pointers),
## this Perl version will return a list instead:
## ($w, $h, $d, $l, $t) = $win->getMetrics();
## (wow, that was painful to get working :)
## (note: there is a different version in RenderTarget)
void
RenderWindow::getMetrics(OUTLIST unsigned int width, OUTLIST unsigned int height, OUTLIST unsigned int colourDepth, OUTLIST int left, OUTLIST int top)
  C_ARGS:
    width, height, colourDepth, left, top
