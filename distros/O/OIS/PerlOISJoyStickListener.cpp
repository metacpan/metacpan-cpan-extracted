#include "PerlOISJoyStickListener.h"

// class implementing OIS::JoyStickListener interface,
// but using Perl callbacks

PerlOISJoyStickListener::PerlOISJoyStickListener() : mPerlObj((SV *)NULL)
{
}

PerlOISJoyStickListener::~PerlOISJoyStickListener()
{
    if (mPerlObj != (SV *)NULL && SvREFCNT(mPerlObj)) {
        SvREFCNT_dec(mPerlObj);
    }
    mCanMap.clear();
}

bool PerlOISJoyStickListener::buttonPressed(const OIS::JoyStickEvent &evt, int button)
{
    return callPerlCallback("buttonPressed", evt, button);
}

bool PerlOISJoyStickListener::buttonReleased(const OIS::JoyStickEvent &evt, int button)
{
    return callPerlCallback("buttonReleased", evt, button);
}

bool PerlOISJoyStickListener::axisMoved(const OIS::JoyStickEvent &evt, int axis)
{
    return callPerlCallback("axisMoved", evt, axis);
}

bool PerlOISJoyStickListener::sliderMoved(const OIS::JoyStickEvent &evt, int slider)
{
    return callPerlCallback("sliderMoved", evt, slider);
}

bool PerlOISJoyStickListener::povMoved(const OIS::JoyStickEvent &evt, int pov)
{
    return callPerlCallback("povMoved", evt, pov);
}

void PerlOISJoyStickListener::setPerlObject(SV *pobj)
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
        croak("Argument wasn't an object, so MouseListener wasn't set.\n");
    }

    setCans();
}

void PerlOISJoyStickListener::setCans()
{
    mCanMap["buttonPressed"] = perlCallbackCan("buttonPressed");
    mCanMap["buttonReleased"] = perlCallbackCan("buttonReleased");
    mCanMap["axisMoved"] = perlCallbackCan("axisMoved");
    mCanMap["sliderMoved"] = perlCallbackCan("sliderMoved");
    mCanMap["povMoved"] = perlCallbackCan("povMoved");
}

// check whether the Perl object has a callback method implemented
// (is there a perl API method or something easier than this?)
bool PerlOISJoyStickListener::perlCallbackCan(string const &cbmeth)
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

bool PerlOISJoyStickListener::callPerlCallback(string const &cbmeth, const OIS::JoyStickEvent &evt, int thingID)
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

        SV *joyevt = sv_newmortal();
        TMOIS_OUT(joyevt, &evt, JoyStickEvent);  // put C++ object into Perl

        PUSHMARK(SP);
        XPUSHs(mPerlObj);
        XPUSHs(joyevt);
        XPUSHs(sv_2mortal(newSViv(thingID)));
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
