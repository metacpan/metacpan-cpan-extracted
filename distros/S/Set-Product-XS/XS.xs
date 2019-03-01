#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifndef CvISXSUB
#  define CvISXSUB(cv) CvXSUB(cv)
#endif

#include "multicall.h"


MODULE = Set::Product::XS     PACKAGE = Set::Product::XS

void
product (code, ...)
    SV *code
PROTOTYPE: &@
PREINIT:
    int i, j, *idx;
    AV **in;
    SV **out;
    CV *cv;
    HV *stash;
    GV *gv;
PPCODE:
    cv = sv_2cv(code, &stash, &gv, 0);
    if (! cv)
      croak("Not a subroutine reference");

    if (2 > items)
        XSRETURN_UNDEF;

    items--;
    for (i = items; i > 0; i--) {
        SvGETMAGIC(ST(i));
        if (! SvROK(ST(i)) || SVt_PVAV != SvTYPE(SvRV(ST(i))))
            croak("Not an array reference");
    }
    for (i = items; i > 0; i--)
        if (0 > av_len((AV *)SvRV(ST(i))))
            XSRETURN_UNDEF;

    Newx(in, items, AV*);
    for (i = items - 1; i >= 0; i--)
        in[i] = (AV *)SvRV(ST(i+1));
    Newx(out, items, SV*);
    for (i = items - 1; i >= 0; i--)
        out[i] = AvARRAY(in[i])[0];
    Newxz(idx, items, int);

    SAVEFREEPV(in);
    SAVEFREEPV(out);
    SAVEFREEPV(idx);

    if (! CvISXSUB(cv)) {
        I32 gimme = G_VOID;
        /* localize @_ */
        AV *av = save_ary(PL_defgv);
        /* @_ doesn't refcount it's contents. */
        AvREAL_off(av);

        dMULTICALL;
        PUSH_MULTICALL(cv);

        for (i = 0; i >= 0; ) {
            av_fill(av, items - 1);

            for (j = items - 1; j >= 0; j--)
                AvARRAY(av)[j] = out[j];

            ENTER;
            SAVETMPS;
            MULTICALL;
            FREETMPS;
            LEAVE;

            for (i = items - 1; i >= 0; i--) {
                idx[i]++;
                if (idx[i] > av_len(in[i])) {
                    idx[i] = 0;
                    out[i] = AvARRAY(in[i])[0];
                }
                else {
                    out[i] = AvARRAY(in[i])[idx[i]];
                    break;
                }
            }
        }

        POP_MULTICALL;
    }
    else {
        for (i = 0; i >= 0; ) {
            int j;

            PUSHMARK(SP);
            EXTEND(SP, items);
            for (j = 0; j < items; j++)
                PUSHs(out[j]);
            PUTBACK;

            call_sv((SV *)cv, G_DISCARD | G_VOID);

            SPAGAIN;

            for (i = items - 1; i >= 0; i--) {
                idx[i]++;
                if (idx[i] > av_len(in[i])) {
                    idx[i] = 0;
                    out[i] = AvARRAY(in[i])[0];
                }
                else {
                    out[i] = AvARRAY(in[i])[idx[i]];
                    break;
                }
            }
        }
    }

    XSRETURN_UNDEF;
