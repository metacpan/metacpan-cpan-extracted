#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#include "ppport.h"

#include "lcss.h"

MODULE = String::LCSS_XS		PACKAGE = String::LCSS_XS		

void
_compute_all_lcss(s, t, min = 1)
    SV* s
    SV* t
    int min
PROTOTYPE: $$;$
ALIAS:
    lcss     = 1
    lcss_all = 2
PREINIT:
    int list_cx;
    int wide;
    SV* rv;
PPCODE:
    if (!SvOK(s) || !SvOK(t))
        XSRETURN_UNDEF;

    list_cx = GIMME_V == G_ARRAY;

    SvPV_nolen(s);  /* Process magic and stringify */
    SvPV_nolen(t);

    wide = SvUTF8(s) || SvUTF8(t);
    if (wide) {
        sv_utf8_upgrade_nomg(s);
        sv_utf8_upgrade_nomg(t);
    }

    rv = lcss(
        wide,
        SvPVX(s), SvCUR(s),
        SvPVX(t), SvCUR(t),
        min,
        list_cx,
        list_cx && ix == 2
    );

    if (rv == &PL_sv_undef) {
        XSRETURN_UNDEF;
    }
    else if (SvTYPE(rv) != SVt_PVAV) {
        XPUSHs(sv_2mortal(rv));
        XSRETURN(1);
    }
    else {
        I32 num_items = av_len((AV*)rv) + 1;
        I32 i;
        EXTEND(sp, num_items);
        for (i=num_items; i--; )
            ST(i) = sv_2mortal(av_pop((AV*)rv));
        sv_2mortal(rv);
        XSRETURN(num_items);
    }
