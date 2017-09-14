
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sub::Inject PACKAGE = Sub::Inject

PROTOTYPES: DISABLE

#ifndef intro_my /* perl 5.22+ */
# define intro_my()      Perl_intro_my(aTHX)
#endif

#define is_code(sv) (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV)

void
sub_inject(...)
  CODE:
    int argi;
    PADLIST *pl;
    PADOFFSET off;
    if (!PL_compcv)
        Perl_croak(aTHX_
                "sub_inject can only be called at compile time");
    if (items % 2)
        Perl_croak(aTHX_
                "Odd number of elements in sub_inject");

    pl = CvPADLIST(PL_compcv);
    ENTER;
    SAVESPTR(PL_comppad_name); PL_comppad_name = PadlistNAMES(pl);
    SAVESPTR(PL_comppad);      PL_comppad      = PadlistARRAY(pl)[1];
    SAVESPTR(PL_curpad);       PL_curpad       = PadARRAY(PL_comppad);
    for (argi=0; argi < items; argi += 2) {
        if (!is_code(ST(argi+1)))
            Perl_croak(aTHX_
                    "Not a subroutine reference at sub_inject() argument %d", argi+1);
        SV *name = ST(argi);
        CV *cv   = (CV *)SvRV(ST(argi+1));
        off = pad_add_name_sv(sv_2mortal(newSVpvf("&%"SVf,name)),
                            padadd_STATE, 0, 0);
        SvREFCNT_dec(PL_curpad[off]);
        PL_curpad[off] = SvREFCNT_inc(cv);
    }
    LEAVE;
    intro_my();
