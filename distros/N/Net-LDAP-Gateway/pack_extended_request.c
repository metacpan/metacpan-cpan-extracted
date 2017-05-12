#include "pack.h"
#include "util.h"

void
pack_extended_request_args(SV *dest, SV *oid, SV *value) {
    STRLEN offset = start_constructed(dest,
				      ASN1_APPLICATION|ASN1_CONSTRUCTED,
				      LDAP_OP_EXTENDED_REQUEST);
    pack_raw_utf8(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, 0, oid);
    if (value && SvOK(value))
	pack_raw_utf8(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, 1, value);
    end_constructed(dest, offset);
}

void
pack_extended_request_ref(SV *dest, HV *hv) {
    pack_extended_request_args(dest, 
				    hv_fetchs_def_undef(hv, "oid"),
				    hv_fetchs_def_undef(hv, "value"));
}
