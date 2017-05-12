#include "scan.h"

void
scan_extended_request(const char **src, const char *max, HV *out) {
    U8 type;
    U32 tag;
    SV *sv = newSV(0);
    hv_stores(out, "oid", sv);
    scan_raw(src, max, &type, &tag, sv);
    if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_PRIMITIVE) || tag != 0)
	croak("scan_extended_request: bad value");
    if (!sv_utf8_decode(sv))
	croak("scan_string_utf8: invalid UTF8 data received");

    if (*src < max) {
	sv = newSV(0);
	hv_stores(out, "value", sv);
	scan_raw(src, max, &type, &tag, sv);
	if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_PRIMITIVE) || tag != 1)
	    croak("scan_extended_request: bad value");
    }
}
