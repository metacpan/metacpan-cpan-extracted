#include "scan.h"

void
scan_intermediate_response(const char **src, const char *max, HV *out) {
    if (*src < max) {
	SV *sv;
	U8 type;
	U32 tag;
	scan_tag(src, max, &type, &tag);
	if (tag == 0) {
	    SV *name;
	    if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_PRIMITIVE))
		croak("scan_intermediate_response: bad packet data");
	    name = newSV(0);
	    hv_stores(out, "name", name);
	    scan_raw_notag(src, max, name);
	    if (*src == max) return;
	    scan_tag(src, max, &type, &tag);
	}
	if (tag == 1) {
	    SV *value;
	    if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_PRIMITIVE))
		croak("scan_intermediate_response: bad packet data");
	    value = newSV(0);
	    hv_stores(out, "value", value);
	    scan_raw_notag(src, max, value);
	    if (*src == max) return;
	}
	croak("scan_intermediate_response: bad packet data");
    }
}
