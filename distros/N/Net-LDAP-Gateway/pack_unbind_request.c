#include "pack.h"

void
pack_unbind_request_args(SV *dest) {
    pack_tag(dest, ASN1_APPLICATION|ASN1_PRIMITIVE, LDAP_OP_UNBIND_REQUEST);
    pack_length(dest, 0);
}

void
pack_unbind_request_ref(SV *dest, HV *hv) {
    pack_unbind_request_args(dest);
}
