#include "pack.h"
#include "util.h"

void
pack_extended_response_args(SV *dest, I32 result,
				 SV *matched_dn, SV *message, SV *referrals,
				 SV *name, SV *value) {
    STRLEN offset = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_EXTENDED_RESPONSE);
    pack_result_response_nowrap(dest, result, matched_dn, message, referrals);
    if (name && SvOK(name))
	pack_raw_utf8(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, 10, name);
    if (value && SvOK(value))
	pack_raw_utf8(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, 11, value);
    end_constructed(dest, offset);
}

void
pack_extended_response_ref(SV *dest, HV *hv) {
    pack_extended_response_args(dest,
				     SvIV(hv_fetchs_def_undef(hv, "result")),
				     hv_fetchs_def_null(hv, "matched_dn"),
				     hv_fetchs_def_null(hv, "message"),
				     hv_fetchs_def_null(hv, "referrals"),
				     hv_fetchs_def_null(hv, "name"),
				     hv_fetchs_def_null(hv, "value"));
}
