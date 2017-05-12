MODULE = Ogre     PACKAGE = Ogre::WindowEventUtilities

static void
WindowEventUtilities::messagePump()

static void
WindowEventUtilities::addWindowEventListener(win, perlListener)
    RenderWindow * win
    SV * perlListener
  CODE:
    pogreCallbackManager.addWindowEventListener(perlListener, win);

static void
WindowEventUtilities::removeWindowEventListener(win, perlListener)
    RenderWindow * win
    SV * perlListener
  CODE:
    pogreCallbackManager.removeWindowEventListener(perlListener, win);
