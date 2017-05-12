
#include "common.h"

SV *
hv_fetch_def(HV *hv, const char *key, I32 klen, SV *def) {
    SV **psv = hv_fetch(hv, key, klen, 0);
    return (psv ? *psv : def);
}

SV *
av_fetch_def(AV *av, I32 key, SV *def) {
    SV **psv = av_fetch(av, key, 0);
    return (psv ? *psv : def);
}
