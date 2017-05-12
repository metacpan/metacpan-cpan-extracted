#include "scan.h"

void
scan_compare_request(const char **src, const char *max, HV *out) {
    SV *sv;
    STRLEN len;
    
    sv = newSV(0);
    hv_stores(out, "dn", sv);
    scan_string_utf8(src, max, sv);

    scan_sequence(src, max, &len);
    if (len != max - *src)
	croak("scan_compare_request: packet too short");

    sv = newSV(0);
    hv_stores(out, "attribute", sv);
    scan_string_utf8(src, max, sv);

    sv = newSV(0);
    hv_stores(out, "value", sv);
    scan_string_utf8(src, max, sv);
}
