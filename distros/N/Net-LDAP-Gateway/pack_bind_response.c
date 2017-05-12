#include "pack.h"
#include "util.h"

void
pack_bind_response_args(SV *dest, I32 result,
			     SV *matched_dn, SV *message, SV *referrals,
			     SV *sasl_credentials) {

    STRLEN offset = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_BIND_RESPONSE);
    pack_result_response_nowrap(dest, result, matched_dn, message, referrals);
    if (sasl_credentials && SvOK(sasl_credentials))
	pack_raw_utf8(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, 7, sasl_credentials);

    end_constructed(dest, offset);
}

void
pack_bind_response_ref(SV *dest, HV *hv) {
    pack_bind_response_args(dest,
				 SvIV(hv_fetchs_def_no(hv, "result")),
				 hv_fetchs_def_no(hv, "matched_dn"),
				 hv_fetchs_def_no(hv, "message"),
				 hv_fetchs_def_undef(hv, "referrals"),
				 hv_fetchs_def_undef(hv, "sasl_credentials"));
}
