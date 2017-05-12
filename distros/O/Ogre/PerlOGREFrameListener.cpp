#include "PerlOGREFrameListener.h"

// class implementing Ogre::FrameListener interface,
// but using Perl callbacks; pobj is an instance of a Perl class
// that (maybe) has frameStarted and/or frameEnded methods

PerlOGREFrameListener::PerlOGREFrameListener(SV *pobj)
    : PerlOGRECallback(pobj)
{
    mCanMap["frameStarted"] = perlCallbackCan("frameStarted");
    mCanMap["frameEnded"] = perlCallbackCan("frameEnded");
}

bool PerlOGREFrameListener::frameStarted(const Ogre::FrameEvent &evt)
{
    // arg 1 for perl stack
    SV *perlevt = newSV(0);
    sv_setref_pv(perlevt, "Ogre::FrameEvent", (void *) &evt);  // TMOGRE_OUT
    mCallbackArgs.push_back(perlevt);

    // call the callback
    return callPerlCallback("frameStarted");
}

bool PerlOGREFrameListener::frameEnded(const Ogre::FrameEvent &evt)
{
    // arg 1 for perl stack
    SV *perlevt = newSV(0);
    sv_setref_pv(perlevt, "Ogre::FrameEvent", (void *) &evt);  // TMOGRE_OUT
    mCallbackArgs.push_back(perlevt);

    // call the callback
    return callPerlCallback("frameEnded");
}
