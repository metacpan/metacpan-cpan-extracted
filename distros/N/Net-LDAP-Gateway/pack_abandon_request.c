#include "common.h"
#include "pack.h"
#include "util.h"

void
pack_abandon_request_args(SV *dest, U32 msgid) {
    pack_unsigned_numeric(dest, ASN1_APPLICATION|ASN1_PRIMITIVE, LDAP_OP_ABANDON_REQUEST, msgid);
}

void
pack_abandon_request_ref(SV *dest, HV *hv) {
    pack_abandon_request_args(dest,
			      SvIV(hv_fetchs_def_undef(hv, "message_id")));
}

