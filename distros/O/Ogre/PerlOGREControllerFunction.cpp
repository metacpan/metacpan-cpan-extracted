#include "PerlOGREControllerFunction.h"

PerlOGREControllerFunction::PerlOGREControllerFunction(SV *pobj)
    : PerlOGRECallback(pobj),
      Ogre::ControllerFunction<Ogre::Real>::ControllerFunction(false)  // wow, that's ugly
{
    mCanMap["calculate"] = perlCallbackCan("calculate");
}

Ogre::Real PerlOGREControllerFunction::calculate(Ogre::Real sourceValue)
{
    // arg 1 for perl stack
    SV *perlval = newSV(0);
    sv_setnv(perlval, (Ogre::Real)sourceValue);
    mCallbackArgs.push_back(perlval);

    // call the callback
    return callPerlCallbackReal("calculate");
}
