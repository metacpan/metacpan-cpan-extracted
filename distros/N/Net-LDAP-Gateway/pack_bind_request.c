#include "pack.h"
#include "util.h"

#include <string.h>

void
pack_bind_request_args(SV* dest, U32 version, SV *dn, I32 method, SV *arg1, SV *arg2) {
    STRLEN offset = start_constructed(dest,
				      ASN1_APPLICATION|ASN1_CONSTRUCTED,
				      LDAP_OP_BIND_REQUEST);

    pack_int(dest, version);
    pack_string_utf8(dest, dn);

    switch(method) {
    case LDAP_AUTH_SIMPLE:
	pack_raw_utf8(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, LDAP_AUTH_SIMPLE, arg1);
	break;
    case LDAP_AUTH_SASL:
	
    default:
	croak("unsupported authentication schema %d", (int)method);
	break;
    }

    end_constructed(dest, offset);
}

void
pack_bind_request_ref(SV *dest, HV *hv) {
    I32 method;
    SV **svp;

    STRLEN offset = start_constructed(dest,
				      ASN1_APPLICATION|ASN1_CONSTRUCTED,
				      LDAP_OP_BIND_REQUEST);
    svp = hv_fetchs(hv, "version", 0);
    pack_int(dest, (svp ? SvIV(*svp) : 3));
    pack_string_utf8(dest, hv_fetchs_def_no(hv, "dn"));
    svp = hv_fetchs(hv, "method", 0);
    method = (svp ? SvIV(*svp) : LDAP_AUTH_SIMPLE);
    switch(method) {
    case LDAP_AUTH_SIMPLE:
	pack_raw_utf8(dest,
		      ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE,
		      LDAP_AUTH_SIMPLE,
		      hv_fetchs_def_no(hv, "password"));
	break;
    case LDAP_AUTH_SASL:
    default:
	croak("unsupported authentication schema %d", (int)method);
	break;
    }
    end_constructed(dest, offset);
}
