#include "pack.h"
#include "util.h"

void
pack_search_reference_response_args(SV *dest, SV **args, I32 n) {
    STRLEN offset = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_SEARCH_REFERENCE_RESPONSE);
    pack_array_of_string_utf8_v(dest, args, n);
    end_constructed(dest, offset);
}

void
pack_search_reference_response_ref(SV *dest, HV *hv) {
    STRLEN offset = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_SEARCH_REFERENCE_RESPONSE);
    pack_array_of_string_utf8(dest, hv_fetchs_def_undef(hv, "uris"));
    end_constructed(dest, offset);
}
