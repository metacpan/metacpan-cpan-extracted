#include "pack.h"
#include "util.h"

void
pack_compare_request_args(SV *dest, SV *dn, SV *attribute, SV *value) {
    STRLEN offset1, offset2;
    offset1 = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_COMPARE_REQUEST);
    pack_string_utf8(dest, dn);
    offset2 = start_sequence(dest);
    pack_string_utf8(dest, attribute);
    pack_string_utf8(dest, value);
    end_sequence(dest, offset2);
    end_constructed(dest, offset1);
}

void
pack_compare_request_ref(SV *dest, HV *hv) {
    pack_compare_request_args(dest,
				   hv_fetchs_def_undef(hv, "dn"),
				   hv_fetchs_def_undef(hv, "attribute"),
				   hv_fetchs_def_undef(hv, "value"));
}
