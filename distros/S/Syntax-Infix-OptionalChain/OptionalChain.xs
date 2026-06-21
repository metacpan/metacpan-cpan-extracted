#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

static SV *
my_navigate(pTHX_ SV *obj, SV *key)
{
    if (!SvOK(obj))
        return newSV(0);                 /* undef */

    if (sv_isobject(obj)) {
        HV *stash = SvSTASH(SvRV(obj));
        GV *gv = gv_fetchmethod_autoload(stash, SvPV_nolen(key), FALSE);
        if (gv && isGV(gv) && GvCV(gv)) {
            dSP;
            int count;
            SV *out;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(obj);                 /* the invocant */
            PUTBACK;
            count = call_sv((SV *)GvCV(gv), G_SCALAR);
            SPAGAIN;
            out = newSVsv(count ? POPs : &PL_sv_undef);   /* copy out */
            PUTBACK;
            FREETMPS;
            LEAVE;
            return out;
        }
        /* blessed but no such method: fall through to structural access */
    }

    if (SvROK(obj)) {
        SV *rv = SvRV(obj);
        if (SvTYPE(rv) == SVt_PVHV) {
            HE *he = hv_fetch_ent((HV *)rv, key, 0, 0);
            return he ? newSVsv(HeVAL(he)) : newSV(0);
        }
        if (SvTYPE(rv) == SVt_PVAV) {
            SV **ele = av_fetch((AV *)rv, SvIV(key), 0);
            return (ele && *ele) ? newSVsv(*ele) : newSV(0);
        }
        croak("Syntax::Infix::OptionalChain: cannot navigate '%" SVf
              "' into a %s reference", SVfARG(key), sv_reftype(rv, 0));
    }

    croak("Syntax::Infix::OptionalChain: cannot navigate '%" SVf
          "' into a non-reference scalar", SVfARG(key));
}

MODULE = Syntax::Infix::OptionalChain   PACKAGE = Syntax::Infix::OptionalChain

SV *
_nav(obj, key)
    SV *obj
    SV *key
CODE:
    RETVAL = my_navigate(aTHX_ obj, key);
OUTPUT:
    RETVAL
