#include "PerlOISKeyListener.h"

// class implementing OIS::KeyListener interface,
// but using Perl callbacks

PerlOISKeyListener::PerlOISKeyListener() : mPerlObj((SV *)NULL)
{
}

PerlOISKeyListener::~PerlOISKeyListener()
{
    if (mPerlObj != (SV *)NULL && SvREFCNT(mPerlObj)) {
        SvREFCNT_dec(mPerlObj);
    }
    mCanMap.clear();
}

bool PerlOISKeyListener::keyPressed(const OIS::KeyEvent &evt)
{
    return callPerlCallback("keyPressed", evt);
}

bool PerlOISKeyListener::keyReleased(const OIS::KeyEvent &evt)
{
    return callPerlCallback("keyReleased", evt);
}

void PerlOISKeyListener::setPerlObject(SV *pobj)
{
    if (pobj != (SV *)NULL && sv_isobject(pobj)) {
        // copy the SV *
        if (mPerlObj == (SV *)NULL) {
            // first time, create new SV *
            mPerlObj = newSVsv(pobj);
        } else {
            // just overwrite existing SV *
            SvSetSV(mPerlObj, pobj);
        }
    } else {
        croak("Argument wasn't an object, so KeyListener wasn't set.\n");
    }

    setCans();
}

void PerlOISKeyListener::setCans()
{
    mCanMap["keyPressed"] = perlCallbackCan("keyPressed");
    mCanMap["keyReleased"] = perlCallbackCan("keyReleased");
}

// check whether the Perl object has a callback method implemented
// (is there a perl API method or something easier than this?)
bool PerlOISKeyListener::perlCallbackCan(string const &cbmeth)
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

bool PerlOISKeyListener::callPerlCallback(string const &cbmeth, const OIS::KeyEvent &evt)
{
    int count;
    SV *methret;
    bool retval = true;   // default to returning true

    if (! (mCanMap[cbmeth] == true)) {
        // method not implemented, just return true
        return retval;
    }

    if (mPerlObj != (SV *)NULL) {
        // see `perldoc perlcall`
        dSP;

        ENTER;
        SAVETMPS;

        SV *keyevt = sv_newmortal();
        TMOIS_OUT(keyevt, &evt, KeyEvent);  // put C++ object into Perl

        PUSHMARK(SP);
        XPUSHs(mPerlObj);
        XPUSHs(keyevt);
        PUTBACK;

        count = call_method(cbmeth.c_str(), G_SCALAR);
        SPAGAIN;
        if (count != 1) {
            croak("Callbacks must return a single (boolean) value");
        }

        methret = POPs;
        PUTBACK;

        retval = SvTRUE(methret) ? true : false;

        FREETMPS;
        LEAVE;
    }

    return retval;
}
