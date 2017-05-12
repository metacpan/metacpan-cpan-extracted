#include "scan.h"

void
scan_abandon_request(const char **src, const char *max, HV *out) {
    I32 mid;
    scan_numeric_notag(src, max, &mid);
    hv_stores(out, "message_id", newSViv(mid));
}
