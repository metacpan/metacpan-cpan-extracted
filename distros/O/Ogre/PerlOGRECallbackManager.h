#ifndef _PERLOGRE_CALLBACKMANAGER_H_
#define _PERLOGRE_CALLBACKMANAGER_H_

/*
  In OGRE, there can be multiple FrameListeners added by Root->addFrameListener,
  and they can be deleted later by passing in the FrameListener
  to Root->removeFrameListener. Since we're implementing FrameListeners
  in Perl, we have to instantiate the C++ object to be passed to
  Root->addFrameListener.
*/

#include <map>
#include "perlOGRE.h"
#include "PerlOGREFrameListener.h"
#include "PerlOGREWindowEventListener.h"

using namespace std;

class PerlOGRECallbackManager
{
 private:
    // Perl pkgname mapped to single C++ FrameListener
    typedef map<string, Ogre::FrameListener*> FrameListenerMap;
    FrameListenerMap mFrameListenerMap;

    // Perl pkgname mapped to single C++ WindowEventListener
    typedef map<string, Ogre::WindowEventListener*> WinEvtListenerMap;
    WinEvtListenerMap mWinEvtListenerMap;
    // Perl pkgname mapped to multiple C++ RenderWindows
    typedef multimap<string, Ogre::RenderWindow*> WinEvtListenerWindowMMap;
    WinEvtListenerWindowMMap mWinEvtListenerWindowMMap;

 public:
    PerlOGRECallbackManager();
    ~PerlOGRECallbackManager();

    void addFrameListener(SV *pobj, Ogre::Root *root);
    void removeFrameListener(SV *pobj, Ogre::Root *root);

    void addWindowEventListener(SV *pobj, Ogre::RenderWindow *win);
    void removeWindowEventListener(SV *pobj, Ogre::RenderWindow *win);
};


#endif  /* define _PERLOGRE_CALLBACKMANAGER_H_ */
