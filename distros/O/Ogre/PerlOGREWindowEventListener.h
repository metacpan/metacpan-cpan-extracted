#ifndef _PERLOGRE_WINDOWEVENTLISTENER_H_
#define _PERLOGRE_WINDOWEVENTLISTENER_H_

#include "PerlOGRECallback.h"

using namespace std;

// this class implements Ogre::WindowEventListener,
// so it can be passed to WindowEventUtilities::addWindowEventListener
// but still allowing implementing the callbacks from Perl

class PerlOGREWindowEventListener : public PerlOGRECallback, public Ogre::WindowEventListener
{
 public:
    PerlOGREWindowEventListener(SV *pobj);

    // WindowEventListener interface
    void windowMoved(Ogre::RenderWindow *win);
    void windowResized(Ogre::RenderWindow *win);
    void windowClosed(Ogre::RenderWindow *win);
    void windowFocusChange(Ogre::RenderWindow *win);
};


#endif  /* define _PERLOGRE_WINDOWEVENTLISTENER_H_ */
