#include "scan.h"
#include <stdlib.h>

void
scan_add_request(const char **src, const char* max, HV *out) {
    STRLEN len;
    SV *key;
    SV *dn = newSV(0);
    hv_stores(out, "dn", dn);
    scan_string_utf8(src, max, dn);
    scan_sequence(src, max, &len);

    key = sv_newmortal();
    while (*src < max) {
	STRLEN attribute_len;
	const char *attribute_max;
	AV *values;
	scan_sequence(src, max, &attribute_len);
	if (attribute_len > max - *src)
	    croak("scan_add_request: packet too short");
	attribute_max = *src + attribute_len;
	
	scan_string_utf8(src, attribute_max, key);
	scan_set(src, attribute_max, &attribute_len);
	if (attribute_len != attribute_max - *src)
	    croak("scan_add_request: packet too short");

	values = newAV();
	hv_store_ent(out, key, newRV_noinc((SV*)values), 0);

	while (*src < attribute_max) {
	    SV *v = newSV(0);
	    av_push(values, v);
	    scan_string_utf8(src, attribute_max, v);
	}
    }
}

