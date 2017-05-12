#include "pack.h"
#include "util.h"

void
pack_modify_dn_request_args(SV *dest, SV *dn, SV *new_rdn,
				 I32 delete_old_rdn, SV *new_superior) {
    STRLEN offset = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_MODIFY_DN_REQUEST);
    pack_string_utf8(dest, dn);
    pack_string_utf8(dest, new_rdn);
    pack_bool(dest, delete_old_rdn);
    if (new_superior && SvOK(new_superior))
	pack_raw_utf8(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, 0, new_superior);
    end_constructed(dest, offset);
}

void
pack_modify_dn_request_ref(SV *dest, HV *hv) {
    pack_modify_dn_request_args(dest,
				     hv_fetchs_def_undef(hv, "dn"),
				     hv_fetchs_def_undef(hv, "new_rdn"),
				     SvTRUE(hv_fetchs_def_undef(hv, "delete_old_rdn")),
				     hv_fetchs_def_undef(hv, "new_superior"));
}
