#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "RPM.h"

static CV* err_callback;

/*
  This was static, but it needs to be accessible from other modules, as well.
*/
SV* rpm_errSV;

/*
  This is a callback routine that the bootstrapper will register with the RPM
  lib so as to catch any errors. (I hope)
*/
static void rpm_catch_errors(void)
{
    /* Because rpmErrorSetCallback expects (void)fn(void), we have to declare
       our thread context here */
    dTHX;
    int error_code;
    const char* error_string;

    error_code = rpmErrorCode();
    error_string = rpmErrorString();

    /* Set the string part, first */
    sv_setpv(rpm_errSV, error_string);
    /* Set the IV part */
    sv_setiv(rpm_errSV, error_code);
    /* Doing that didn't erase the PV part, but it cleared the flag: */
    SvPOK_on(rpm_errSV);

    /* If there is a current callback, invoke it: */
    if (err_callback != Nullcv)
    {
        /* This is just standard boilerplate for calling perl from C */
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(sp);
        XPUSHs(sv_2mortal(newSViv(error_code)));
        XPUSHs(sv_2mortal(newSVpv((char*)error_string, strlen(error_string))));
        PUTBACK;

        /* The actual call */
        call_sv((SV *)err_callback, G_DISCARD);

        /* More boilerplate */
        SPAGAIN;
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    return;
}

static
SV* set_error_callback(pTHX_ SV* newcb)
{
    SV* oldcb;

    oldcb = (err_callback) ? newRV((SV *)err_callback) : newSVsv(&PL_sv_undef);

    if (SvROK(newcb)) newcb = SvRV(newcb);
    if (SvTYPE(newcb) == SVt_PVCV)
        err_callback = (CV *)newcb;
    else if (SvPOK(newcb))
    {
        STRLEN len;
        const char *name = SvPV(newcb, len);

        if (strstr(name, "::"))
            err_callback = get_cv(name, FALSE);
        else {
            SV *sv = sv_2mortal(newSVpvn("main::", 6));
            sv_catpvn(sv, name, len);
            err_callback = get_cv(SvPV_nolen(sv), FALSE);
        }
    }
    else
    {
        err_callback = Nullcv;
    }

    return oldcb;
}


MODULE = RPM::Error     PACKAGE = RPM::Error           


SV*
set_error_callback(newcb)
    SV* newcb;
    PROTOTYPE: $
    CODE:
    RETVAL = set_error_callback(aTHX_ newcb);
    OUTPUT:
    RETVAL

void
clear_errors()
    PROTOTYPE:
    CODE:
/* This is just to offer an easy way to clear both sides of $RPM::err */
    sv_setpv(rpm_errSV, "");
    sv_setiv(rpm_errSV, 0);
    SvPOK_on(rpm_errSV);

void
rpm_error(code, message)
    int code;
    char* message;
    PROTOTYPE: $$
    CODE:
    rpmError(code, "%s", message);


BOOT:
{
    rpm_errSV = get_sv("RPM::err", GV_ADD|GV_ADDMULTI);
    rpmErrorSetCallback(rpm_catch_errors);
    err_callback = Nullcv;
}
