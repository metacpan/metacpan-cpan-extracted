#include "scan.h"

void
scan_search_reference_response(const char **src, const char *max, HV *hv) {
    AV *av = newAV();
    hv_stores(hv, "uris", newRV_noinc((SV*)av));
    scan_array_of_string_utf8(src, max, av);
}
