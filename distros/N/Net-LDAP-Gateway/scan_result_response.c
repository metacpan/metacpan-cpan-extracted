#include "scan.h"
#include "enum2sv.h"

void scan_result_response(const char** src, const char* max, HV *out) {
    I32 r;
    SV *sv;

    scan_enum(src, max, &r);
    hv_stores(out, "result", newSVsv(ldap_error2sv_noinc(r)));

    sv = newSV(0);
    hv_stores(out, "matched_dn", sv);
    scan_string_utf8(src, max, sv);

    sv = newSV(0);
    hv_stores(out, "message", sv);
    scan_string_utf8(src, max, sv);

    if (*src < max) {
	U8 type;
	U32 tag;
	STRLEN len;
	AV *referrals;
	scan_tag(src, max, &type, &tag);
	if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_CONSTRUCTED) || tag != 3)
	    croak("bad packed data");
	scan_length(src, max, &len);
	if (len != max - *src)
	    croak("scan_result_response: packet too short");

	referrals = newAV();
	hv_stores(out, "referrals", newRV_noinc((SV*)referrals));

	while (*src < max) {
	    SV *v = newSV(0);
	    av_push(referrals, v);
	    scan_string_utf8(src, max, v);
	}
    }
}

