#include "PerlOGREWindowEventListener.h"

// class implementing Ogre::WindowEventListener interface,
// but using Perl callbacks; pobj is an instance of a Perl class
// that (maybe) has implemented (some of) the WindowEventListener methods

PerlOGREWindowEventListener::PerlOGREWindowEventListener(SV *pobj)
    : PerlOGRECallback(pobj)
{
    mCanMap["windowMoved"] = perlCallbackCan("windowMoved");
    mCanMap["windowResized"] = perlCallbackCan("windowResized");
    mCanMap["windowClosed"] = perlCallbackCan("windowClosed");
    mCanMap["windowFocusChange"] = perlCallbackCan("windowFocusChange");
}

void PerlOGREWindowEventListener::windowMoved(Ogre::RenderWindow *win)
{
    // arg 1 for perl stack
    SV *perlevt = newSV(0);
    sv_setref_pv(perlevt, "Ogre::RenderWindow", (void *) win);  // TMOGRE_OUT
    mCallbackArgs.push_back(perlevt);

    // call the callback
    callPerlCallback("windowMoved");
}

void PerlOGREWindowEventListener::windowResized(Ogre::RenderWindow *win)
{
    // arg 1 for perl stack
    SV *perlevt = newSV(0);
    sv_setref_pv(perlevt, "Ogre::RenderWindow", (void *) win);  // TMOGRE_OUT
    mCallbackArgs.push_back(perlevt);

    // call the callback
    callPerlCallback("windowResized");
}

void PerlOGREWindowEventListener::windowClosed(Ogre::RenderWindow *win)
{
    // arg 1 for perl stack
    SV *perlevt = newSV(0);
    sv_setref_pv(perlevt, "Ogre::RenderWindow", (void *) win);  // TMOGRE_OUT
    mCallbackArgs.push_back(perlevt);

    // call the callback
    callPerlCallback("windowClosed");
}

void PerlOGREWindowEventListener::windowFocusChange(Ogre::RenderWindow *win)
{
    // arg 1 for perl stack
    SV *perlevt = newSV(0);
    sv_setref_pv(perlevt, "Ogre::RenderWindow", (void *) win);  // TMOGRE_OUT
    mCallbackArgs.push_back(perlevt);

    // call the callback
    callPerlCallback("windowFocusChange");
}
