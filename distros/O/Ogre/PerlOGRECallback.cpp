#include "PerlOGRECallback.h"

PerlOGRECallback::PerlOGRECallback(SV *pobj)
{
    if (pobj != (SV *)NULL && sv_isobject(pobj)) {
        mPerlObj = newSVsv(pobj);   // copy the SV*
    } else {
        croak("Argument isn't an object, so Perl callback can't be set.\n");
    }
}

PerlOGRECallback::~PerlOGRECallback()
{
    if (mPerlObj != (SV *)NULL && SvREFCNT(mPerlObj)) {
        SvREFCNT_dec(mPerlObj);  // delete our copy
    }
}

// check whether the Perl object has a callback method implemented
// (xxx: is there a perl API method or something easier than this?)
bool PerlOGRECallback::perlCallbackCan(string const &cbmeth)
{
    int count;
    SV *methret;
    bool can;

    dSP;

    ENTER;
    SAVETMPS;

    // call `can' to see if they implemented the callback
    PUSHMARK(SP);
    XPUSHs(mPerlObj);
    XPUSHs(sv_2mortal(newSVpv(cbmeth.c_str(), 0)));
    PUTBACK;

    count = call_method("can", G_SCALAR);
    SPAGAIN;
    if (count != 1) {
        croak("can (%s) didn't return a single value?", cbmeth.c_str());
    }

    methret = POPs;
    PUTBACK;

    can = SvTRUE(methret);

    FREETMPS;
    LEAVE;

    return can;
}

// before calling this, push the callback args onto the mCallbackArgs vector
bool PerlOGRECallback::callPerlCallback(string const &cbmeth) const
{
    int count;
    SV *methret;
    bool retval = true;

    if (mCanMap[cbmeth] == false) {
        // method not implemented, just return true
        return retval;
    }

    dSP;

    ENTER;
    SAVETMPS;

    // call the callback
    PUSHMARK(SP);
    XPUSHs(mPerlObj);
    for (CBArgList::iterator it = mCallbackArgs.begin(); it != mCallbackArgs.end(); ++it) {
        XPUSHs(sv_2mortal(*it));
    }
    PUTBACK;

    count = call_method(cbmeth.c_str(), G_SCALAR);
    SPAGAIN;
    if (count != 1) {
        croak("Callback must return a single (boolean) value");
    }

    methret = POPs;
    PUTBACK;

    retval = SvTRUE(methret) ? true : false;

    FREETMPS;
    LEAVE;

    mCallbackArgs.clear();

    return retval;
}

// xxx: dumb how much copy/paste the next two methods have

// before calling this, push the callback args onto the mCallbackArgs vector
Ogre::Real PerlOGRECallback::callPerlCallbackReal(string const &cbmeth) const
{
    int count;
    SV *methret;
    Ogre::Real retval = 0;

    if (mCanMap[cbmeth] == false) {
        // method not implemented, just return 0
        return retval;
    }

    dSP;

    ENTER;
    SAVETMPS;

    // call the callback
    PUSHMARK(SP);
    XPUSHs(mPerlObj);
    for (CBArgList::iterator it = mCallbackArgs.begin(); it != mCallbackArgs.end(); ++it) {
        XPUSHs(sv_2mortal(*it));
    }
    PUTBACK;

    count = call_method(cbmeth.c_str(), G_SCALAR);
    SPAGAIN;
    if (count != 1) {
        croak("Callback must return a single (Real) value");
    }

    methret = POPs;
    PUTBACK;

    retval = (Ogre::Real)SvNV(methret);

    FREETMPS;
    LEAVE;

    mCallbackArgs.clear();

    return retval;
}

// before calling this, push the callback args onto the mCallbackArgs vector
void PerlOGRECallback::callPerlCallbackVoid(string const &cbmeth) const
{
    int count;

    if (mCanMap[cbmeth] == false) {
        // method not implemented, just return
        return;
    }

    dSP;

    ENTER;
    SAVETMPS;

    // call the callback
    PUSHMARK(SP);
    XPUSHs(mPerlObj);
    for (CBArgList::iterator it = mCallbackArgs.begin(); it != mCallbackArgs.end(); ++it) {
        XPUSHs(sv_2mortal(*it));
    }
    PUTBACK;

    count = call_method(cbmeth.c_str(), G_SCALAR);
    SPAGAIN;
    if (count != 0) {
        croak("Callback must not return a value");
    }

    FREETMPS;
    LEAVE;

    mCallbackArgs.clear();
}
