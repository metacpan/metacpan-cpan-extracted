#include "pack.h"
#include "util.h"

static void
ldap_pack_modop(SV *dest, SV *change) {
    if (change && SvOK(change)) {
	HV *hv;
	STRLEN offset1, offset2;
	if (!SvROK(change) || !(hv = (HV*)SvRV(change)) || (SvTYPE(hv) != SVt_PVHV))
	    croak("bad change description");
	
	offset1 = start_sequence(dest);
	pack_enum(dest, SvIV(hv_fetchs_def_undef(hv, "operation")));
	offset2 = start_sequence(dest);
	pack_string_utf8(dest, hv_fetchs_def_undef(hv, "attribute"));
	pack_set_of_string_utf8(dest, hv_fetchs_def_undef(hv, "values"));
	end_sequence(dest, offset2);
	end_sequence(dest, offset1);
    }
}

void
pack_modify_request_args(SV *dest, SV *dn, SV **args, I32 n) {
    STRLEN offset1, offset2;
    I32 i;
    offset1 = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_MODIFY_REQUEST);
    pack_string_utf8(dest, dn);
    offset2 = start_sequence(dest);
    for (i = 0; i < n; i++)
	ldap_pack_modop(dest, args[i]);
    end_sequence(dest, offset2);
    end_constructed(dest, offset1);
}

void
pack_modify_request_ref(SV *dest, HV *hv) {
    STRLEN offset1, offset2;
    SV *changes;
    offset1 = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_MODIFY_REQUEST);
    pack_string_utf8(dest, hv_fetchs_def_undef(hv, "dn"));
    offset2 = start_sequence(dest);
    changes = hv_fetchs_def_undef(hv, "changes");
    if (changes && SvOK(changes)) {
	AV *av;
	I32 i, len;
	if (SvROK(changes) && (av = (AV*)SvRV(changes)) && (SvTYPE(av) == SVt_PVAV)) {
	    len = av_len(av);
	    for (i = 0; i <= len; i++)
		ldap_pack_modop(dest, av_fetch_def_undef(av, i));
	}
	else
	    ldap_pack_modop(dest, changes);
    }
    end_sequence(dest, offset2);
    end_constructed(dest, offset1);
}
