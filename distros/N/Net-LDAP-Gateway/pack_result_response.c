#include "pack.h"
#include "util.h"

void
pack_result_response_nowrap(SV *dest, I32 result,
				 SV *matched_dn, SV *message, SV *referrals) {
    pack_enum(dest, result);
    pack_string_utf8(dest, matched_dn);
    pack_string_utf8(dest, message);
    if (referrals && SvOK(referrals)) {
	STRLEN offset = start_constructed(dest, ASN1_CONTEXT_SPECIFIC|ASN1_CONSTRUCTED, 3);
	pack_array_of_string_utf8(dest, referrals);
	end_constructed(dest, offset);
    }
}

void
pack_result_response_args(SV *dest, U32 op, I32 result,
			       SV *matched_dn, SV *message, SV *referrals) {
    STRLEN offset = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, op);
    pack_result_response_nowrap(dest, result, matched_dn, message, referrals);
    end_constructed(dest, offset);
}

void
pack_result_response_ref(SV *dest, U32 op, HV *hv) {
    SV *referrals;
    pack_result_response_args(dest, op,
				   SvIV(hv_fetchs_def_undef(hv, "result")),
				   hv_fetchs_def_null(hv, "matched_dn"),
				   hv_fetchs_def_null(hv, "message"),
				   hv_fetchs_def_null(hv, "referrals"));
}
