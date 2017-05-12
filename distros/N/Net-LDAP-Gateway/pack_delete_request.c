#include "pack.h"
#include "util.h"

void
pack_delete_request_args(SV *dest, SV *dn) {
    pack_raw_utf8(dest, ASN1_APPLICATION|ASN1_PRIMITIVE, LDAP_OP_DELETE_REQUEST, dn);
}

void
pack_delete_request_ref(SV *dest, HV *hv) {
    pack_delete_request_args(dest, hv_fetchs_def_undef(hv, "dn"));
}

