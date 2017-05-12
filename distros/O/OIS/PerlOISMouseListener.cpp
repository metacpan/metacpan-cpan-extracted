#include "PerlOISMouseListener.h"

// class implementing OIS::MouseListener interface,
// but using Perl callbacks

PerlOISMouseListener::PerlOISMouseListener() : mPerlObj((SV *)NULL)
{
}

PerlOISMouseListener::~PerlOISMouseListener()
{
    if (mPerlObj != (SV *)NULL && SvREFCNT(mPerlObj)) {
        SvREFCNT_dec(mPerlObj);
    }
    mCanMap.clear();
}

bool PerlOISMouseListener::mouseMoved(const OIS::MouseEvent &evt)
{
    // no "int" arg for mouseMoved, so passing 0
    return callPerlCallback("mouseMoved", evt, 0);
}

bool PerlOISMouseListener::mousePressed(const OIS::MouseEvent &evt, OIS::MouseButtonID id)
{
    return callPerlCallback("mousePressed", evt, id);
}

bool PerlOISMouseListener::mouseReleased(const OIS::MouseEvent &evt, OIS::MouseButtonID id)
{
    return callPerlCallback("mouseReleased", evt, id);
}

void PerlOISMouseListener::setPerlObject(SV *pobj)
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

void PerlOISMouseListener::setCans()
{
    mCanMap["mouseMoved"] = perlCallbackCan("mouseMoved");
    mCanMap["mousePressed"] = perlCallbackCan("mousePressed");
    mCanMap["mouseReleased"] = perlCallbackCan("mouseReleased");
}

// check whether the Perl object has a callback method implemented
// (is there a perl API method or something easier than this?)
bool PerlOISMouseListener::perlCallbackCan(string const &cbmeth)
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

bool PerlOISMouseListener::callPerlCallback(string const &cbmeth, const OIS::MouseEvent &evt, int buttonID)
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

        SV *mouseevt = sv_newmortal();
        TMOIS_OUT(mouseevt, &evt, MouseEvent);  // put C++ object into Perl

        PUSHMARK(SP);
        XPUSHs(mPerlObj);
        XPUSHs(mouseevt);
        XPUSHs(sv_2mortal(newSViv(buttonID)));
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
