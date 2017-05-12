#include <stdlib.h>
#include "scan.h"

void 
scan_search_entry_response(const char** src, const char* max, HV *out) {
    SV *dn, *key;
    STRLEN len;
    dn = newSV(0);
    hv_stores(out, "dn", dn);
    scan_string_utf8(src, max, dn);

    scan_sequence(src, max, &len);
    if (len != max - *src)
	croak("scan_search_entry_response: packet too short");
    
    key = sv_newmortal();
    while (*src < max) {
	const char *attribute_max;
	AV *values;
	scan_sequence(src, max, &len);
	attribute_max = *src + len;
	scan_string_utf8(src, max, key);
	values = newAV();
	hv_store_ent(out, key, newRV_noinc((SV*)values), 0);
	scan_set(src, max, &len);
	if (attribute_max != *src + len)
	    croak("bad packet");
	while (*src < attribute_max) {
	    SV *v = newSV(0);
	    av_push(values, v);
	    scan_string_utf8(src, attribute_max, v);
	}
    }
}
