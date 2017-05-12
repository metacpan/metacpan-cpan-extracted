#include "scan.h"

void
scan_delete_request(const char** src, const char* max, HV *out) {
    SV *sv;
    if (*src > max)
	croak("scan_request: packet too short");
    sv = newSV(0);
    hv_stores(out, "dn", sv);
    scan_raw_utf8_notag(src, max, sv);
}
