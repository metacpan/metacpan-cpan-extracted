#include "scan.h"
#include "enum2sv.h"

void
scan_extended_response(const char **src, const char *max, HV *out) {
    I32 r;
    SV *sv;
    U8 type;
    U32 tag;

    scan_enum(src, max, &r);
    hv_stores(out, "result", newSVsv(ldap_error2sv_noinc(r)));

    sv = newSV(0);
    hv_stores(out, "matched_dn", sv);
    scan_string_utf8(src, max, sv);

    sv = newSV(0);
    hv_stores(out, "message", sv);
    scan_string_utf8(src, max, sv);

    if (*src == max) return;
    scan_tag(src, max, &type, &tag);
    if (tag == 3) { /* referral */
	AV *referrals;
	const char *nmax;
	STRLEN len;

	if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_CONSTRUCTED))
	    croak("bad packed data");
	scan_length(src, max, &len);
	if (len > max - *src)
	    croak("scan_result_response: packet too short");
	nmax = *src + len;
	referrals = newAV();
	hv_stores(out, "referrals", newRV_noinc((SV*)referrals));

	while (*src < nmax) {
	    SV *v = newSV(0);
	    av_push(referrals, v);
	    scan_string_utf8(src, nmax, v);
	}

	if (*src == max) return;
	scan_tag(src, max, &type, &tag);
    }
    if (tag == 10) {
	SV *name;
	if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_PRIMITIVE))
	    croak("bad packet data");
	name = newSV(0);
	hv_stores(out, "name", name);
	scan_raw_notag(src, max, name);
	if (*src == max) return;
	scan_tag(src, max, &type, &tag);
    }
    if (tag == 11) {
	SV *value;
	if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_PRIMITIVE))
	    croak("bad packet data");
	value = newSV(0);
	hv_stores(out, "value", value);
	scan_raw_notag(src, max, value);
	if (*src == max) return;
    }    
    croak("bad packet data");
}
