#include "PerlOGREControllerValue.h"

PerlOGREControllerValue::PerlOGREControllerValue(SV *pobj)
    : PerlOGRECallback(pobj)
{
    mCanMap["getValue"] = perlCallbackCan("getValue");
    mCanMap["setValue"] = perlCallbackCan("setValue");
}

Ogre::Real PerlOGREControllerValue::getValue() const
{
    return callPerlCallbackReal("getValue");
}

void PerlOGREControllerValue::setValue(Ogre::Real value)
{
    // arg 1 for perl stack
    SV *perlval = newSV(0);
    sv_setnv(perlval, (Ogre::Real)value);
    mCallbackArgs.push_back(perlval);

    // call the callback
    return callPerlCallbackVoid("setValue");
}
