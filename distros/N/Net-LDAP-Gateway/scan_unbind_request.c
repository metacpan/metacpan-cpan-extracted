#include "ldap.h"

void
scan_unbind_request(const char **src, const char *max, HV *out) {
    STRLEN len;
    scan_length(src, max, &len);
    if (len != 0)
	croak("scan_unbind_request: unexpected data in packet");
}
