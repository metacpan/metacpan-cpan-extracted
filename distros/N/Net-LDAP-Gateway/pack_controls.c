#include "pack.h"
#include "util.h"

static void
pack_control(SV *dest, SV *control) {
    if (SvOK(control)) {
	HV *hv;
	SV **svp;
	STRLEN offset = start_sequence(dest);
	if (SvROK(control) &&
	    (hv = (HV*)SvRV(control)) &&
	    (SvTYPE(hv) == SVt_PVHV)) {
	    pack_string_utf8(dest, hv_fetchs_def_undef(hv, "type"));

	    svp = hv_fetchs(hv, "criticality", 0);
	    if (svp && *svp && SvTRUE(*svp))
		pack_bool(dest, 1);

	    svp = hv_fetchs(hv, "value", 0);
	    if (svp && *svp && SvOK(*svp))
		pack_string_utf8(dest, *svp);
	}
	else
	    pack_string_utf8(dest, control);
	end_sequence(dest, offset);
    }
}

void
pack_controls(SV *dest, SV *controls) {
    if (controls && SvOK(controls)) {
	STRLEN offset = start_constructed(dest, ASN1_CONTEXT_SPECIFIC|ASN1_CONSTRUCTED, 0);
	AV *av;
	if (SvROK(controls) &&
	    (av = (AV*)SvRV(controls)) &&
	    SvTYPE(av) == SVt_PVAV) {
	    U32 n = av_len(av);
	    U32 i;
	    for (i = 0; i <= n; i++)
		pack_control(dest, av_fetch_def_undef(av, i));
	}
	else
	    pack_control(dest, controls);
	    
	end_constructed(dest, offset);
    }
}
