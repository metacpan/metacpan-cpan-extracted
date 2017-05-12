#include "pack.h"
#include "util.h"

void
pack_intermediate_response_args(SV *dest, SV *name, SV *value) {
    STRLEN offset = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_INTERMEDIATE_RESPONSE);
    if (name && SvOK(name))
	pack_raw_utf8(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, 0, name);
    if (value && SvOK(value))
	pack_raw_utf8(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, 1, value);
    end_constructed(dest, offset);
}

void
pack_intermediate_response_ref(SV *dest, HV *hv) {
    pack_intermediate_response_args(dest,
					 hv_fetchs_def_undef(hv, "name"),
					 hv_fetchs_def_undef(hv, "value"));
}
