#include "scan.h"
#include "enum2sv.h"

void
scan_bind_request(const char** src, const char* max, HV *out) {
    U8 type;
    I32 version;
    U32 method;
    SV *dn = newSV(0);
    hv_stores(out, "dn", dn);

    scan_int(src, max, &version);
    hv_stores(out, "version", newSViv(version));

    scan_string_utf8(src, max, dn);

    scan_tag(src, max, &type, &method);
    hv_stores(out, "method", newSVsv(ldap_auth2sv_noinc(method)));

    switch (method) {
    case 0:
    {
	STRLEN len;
	SV *sv;
	if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_PRIMITIVE))
	    croak("scan_bind_request: bad value type: %u, method: %u",
		  type, (unsigned int)method);

	sv = newSV(0);
	hv_stores(out, "password", sv);
	scan_raw_utf8_notag(src, max, sv);
	break;
    }
    case 3:
    {
	STRLEN len;
	SV *sv;
	if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_CONSTRUCTED))
	    croak("scan_bind_request: bad value type: %u, method: %u",
		  type, (unsigned int)method);

	scan_length(src, max, &len);
	max = *src + len;
	sv = newSV(0);
	hv_stores(out, "sasl_mechanism", sv);
	scan_string_utf8(src, max, sv);
	if (*src < max) {
	    sv = newSV(0);
	    hv_stores(out, "sasl_credentials", sv);
	    scan_string(src, max, sv);
	}
	break;
    }
    default:
	croak("scan_bind_request: unknown authentication");
	break;
    }
}
