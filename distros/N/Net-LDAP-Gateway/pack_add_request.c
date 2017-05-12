#include "pack.h"
#include "util.h"

void
pack_add_request_args(SV *dest, SV *dn, SV **args, U32 n) {
    STRLEN offset1, offset2;
    U32 i = 0;
    offset1 = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_ADD_REQUEST);
    pack_string_utf8(dest, dn);
    offset2 = start_sequence(dest);
    while (i < n) {
	STRLEN offset = start_sequence(dest);
	pack_string_utf8(dest, args[i++]);
	pack_sequence_of_string_utf8(dest, args[i++]);
	end_sequence(dest, offset);
    }
    end_sequence(dest, offset2);
    end_constructed(dest, offset1);
}

void
pack_add_request_ref(SV *dest, HV *hv) {
    STRLEN offset1, offset2;
    HE *key;
    SV *dn = hv_fetchs_def_undef(hv, "dn");
    offset1 = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_ADD_REQUEST);
    pack_string_utf8(dest, dn);
    offset2 = start_sequence(dest);
    hv_iterinit(hv);
    while (key = hv_iternext(hv)) {
	STRLEN key_len;
	SV *key_sv = hv_iterkeysv(key);
	const char *key_char = SvPVutf8(key_sv, key_len);
	if (key_len != 2 || strncmp(key_char, "dn", 2)) {
	    SV *val_sv = hv_iterval(hv, key);
	    STRLEN offset = start_sequence(dest);
	    pack_string_utf8(dest, key_sv);
	    pack_set_of_string_utf8(dest, val_sv);
	    end_sequence(dest, offset);
	}
    }
    end_sequence(dest, offset2);
    end_constructed(dest, offset1);
}
