/* -*- Mode: C -*- */

#include "common.h"

#include "enums.h"
#include "asn1.h"
#include "scan.h"
#include "pack.h"
#include "ldap.h"
#include "enum2sv.h"

typedef AV AV_opt;
typedef HV HV_opt;

#define RESERVE_HEAD 20

static SV *
new_message_sv(void) {
    SV *sv = sv_2mortal(newSV(2048));
    SvPOK_on(sv);
    return sv;
}

static STRLEN
start_ldap_message(SV *dest, U32 msgid) {
    start_sequence(dest);
    pack_int(dest, msgid);
}

static void
end_ldap_message(SV *dest) {
    end_sequence(dest, 1);
}

static void
ldap_pack_message_ref(SV *dest, U32 op, HV *data, SV *controls) {
    switch (op) {
    case LDAP_OP_BIND_REQUEST:
	pack_bind_request_ref(dest, data);
	break;
    case LDAP_OP_BIND_RESPONSE:
	pack_bind_response_ref(dest, data);
	break;
    case LDAP_OP_UNBIND_REQUEST:
	pack_unbind_request_ref(dest, data);
	break;
    case LDAP_OP_SEARCH_REQUEST:
	pack_search_request_ref(dest, data);
	break;
    case LDAP_OP_ADD_REQUEST:
	pack_add_request_ref(dest, data);
	break;
    case LDAP_OP_SEARCH_ENTRY_RESPONSE:
	pack_search_entry_response_ref(dest, data);
	break;
    case LDAP_OP_SEARCH_REFERENCE_RESPONSE:
	pack_search_reference_response_ref(dest, data);
	break;
    case LDAP_OP_MODIFY_REQUEST:
	pack_modify_request_ref(dest, data);
	break;
    case LDAP_OP_DELETE_REQUEST:
	pack_delete_request_ref(dest, data);
	break;
    case LDAP_OP_MODIFY_DN_REQUEST:
	pack_modify_dn_request_ref(dest, data);
	break;
    case LDAP_OP_COMPARE_REQUEST:
	pack_compare_request_ref(dest, data);
	break;
    case LDAP_OP_ABANDON_REQUEST:
	pack_abandon_request_ref(dest, data);
	break;
    case LDAP_OP_EXTENDED_REQUEST:
	pack_extended_request_ref(dest, data);
	break;
    case LDAP_OP_EXTENDED_RESPONSE:
	pack_extended_response_ref(dest, data);
	break;
    case LDAP_OP_INTERMEDIATE_RESPONSE:
	pack_intermediate_response_ref(dest, data);
	break;
    case LDAP_OP_SEARCH_DONE_RESPONSE:
    case LDAP_OP_MODIFY_RESPONSE:
    case LDAP_OP_ADD_RESPONSE:
    case LDAP_OP_DELETE_RESPONSE:
    case LDAP_OP_MODIFY_DN_RESPONSE:
	pack_result_response_ref(dest, op, data);
	break;
    default:
	croak("unsupported operation %u", (unsigned int)op);
	break;
    }
    pack_controls(dest, controls);
}

MODULE = Net::LDAP::Gateway		PACKAGE = Net::LDAP::Gateway

BOOT:
    init_constants();

SV *
ldap_dn_normalize(dn)
    SV * dn
CODE:
    RETVAL = dn_normalize(dn);
OUTPUT:
    RETVAL

SV *
ldap_peek_message(buffer)
    SV *buffer
PPCODE:
{
    int n = 0;
    STRLEN bytes, request_len, src_len;
    const char *start, *src, *max;
    sv_utf8_downgrade(buffer, 0);
    start = src = SvPV(buffer, src_len);
    max = start + src_len;
    if (peek_sequence(&src, max, &request_len)) {
	mXPUSHu((src - start) + request_len);
	n++;
	if (GIMME_V == G_ARRAY) {
	    U32 msgid;
	    if (peek_unsigned_numeric(&src, max, &msgid)) {
		U8 type;
		U32 op;
		STRLEN len;
		mXPUSHu(msgid);
		n++;
		if (peek_tag(&src, max, &type, &op)) {
		    XPUSHs(ldap_op2sv_noinc(op));
		    n++;
		    if (type & ASN1_CONSTRUCTED) {
			if (peek_length(&src, max, &len)) {
			    if (max - src > len)
				max = src + len;
			    switch(op) {
			    case LDAP_OP_BIND_REQUEST:
			    {
				I32 v;
				/* skip version, return binding dn */
				if (!peek_int(&src, max, &v))
				    break;
				/* else fall through */
			    }
			    case LDAP_OP_SEARCH_REQUEST:
			    case LDAP_OP_MODIFY_REQUEST:
			    case LDAP_OP_ADD_REQUEST:
			    case LDAP_OP_MODIFY_DN_REQUEST:
			    case LDAP_OP_COMPARE_REQUEST:
			    case LDAP_OP_SEARCH_ENTRY_RESPONSE:
			    {
				/* extract dn */
				SV *dn = sv_newmortal();
				if (peek_string_utf8(&src, max, dn)) {
				    XPUSHs(dn);
				    n++;
				}
				break;
			    }
			    case LDAP_OP_BIND_RESPONSE:
			    case LDAP_OP_SEARCH_DONE_RESPONSE:
			    case LDAP_OP_MODIFY_RESPONSE:
			    case LDAP_OP_ADD_RESPONSE:
			    case LDAP_OP_DELETE_RESPONSE:
			    case LDAP_OP_MODIFY_DN_RESPONSE:
			    case LDAP_OP_COMPARE_RESPONSE:
			    case LDAP_OP_EXTENDED_RESPONSE:
			    {
				/* extract result code */
				I32 r;
				if (peek_enum(&src, max, &r)) {
				    XPUSHs(ldap_error2sv_noinc(r));
				    n++;
				}
				break;
			    }
			    case LDAP_OP_EXTENDED_REQUEST:
			    case LDAP_OP_SEARCH_REFERENCE_RESPONSE:
			    default:
				/* no extra info available */
				break;
			    }
			}
		    }
		    else {
			switch(op) {
			case LDAP_OP_DELETE_REQUEST:
			{
			    SV *dn = sv_newmortal();
			    if (peek_raw_utf8_notag(&src, max, dn)) {
				XPUSHs(dn);
				n++;
			    }
			    break;
			}
			case LDAP_OP_ABANDON_REQUEST:
			{
			    U32 target;
			    if (peek_numeric_notag(&src, max, &target)) {
				mXPUSHu(target);
				n++;
			    }
			    break;
			}
			case LDAP_OP_UNBIND_REQUEST:
			    break;
			default:
			    croak("bad packet");
			    break;
			}
		    }
		}
	    }
	}
    }
    XSRETURN(n);
}

void
ldap_shift_message(SV *buffer)
PPCODE:
{
    STRLEN src_len, message_len;
    const char *start = SvPV(buffer, src_len);
    const char *src = start;
    const char *max = start + src_len;
    const char *save_max = max;
    U32 msgid, op;
    HV *out = newHV();
    SV *out_ref = sv_2mortal(newRV_noinc((SV*)out));
    AV *controls;
    SV *controls_ref = 0;
    U8 type;
    scan_message_head(&src, max, &msgid, &op, &type, &message_len);
    max = src + message_len;
    if (type & ASN1_CONSTRUCTED) {
	STRLEN body_len;
	const char *body_max;
	scan_length(&src, max, &body_len);
	body_max = src + body_len;
	switch(op) {
	case LDAP_OP_BIND_REQUEST:
	    scan_bind_request(&src, body_max, out);
	    break;
	case LDAP_OP_UNBIND_REQUEST:
	    scan_unbind_request(&src, body_max, out);
	    break;
	case LDAP_OP_SEARCH_REQUEST:
	    scan_search_request(&src, body_max, out);
	    break;
	case LDAP_OP_ADD_REQUEST:
	    scan_add_request(&src, body_max, out);
	    break;
	case LDAP_OP_MODIFY_REQUEST:
	    scan_modify_request(&src, body_max, out);
	    break;
	case LDAP_OP_MODIFY_DN_REQUEST:
	    scan_modify_dn_request(&src, body_max, out);
	    break;
	case LDAP_OP_COMPARE_REQUEST:
	    scan_compare_request(&src, body_max, out);
	    break;
	case LDAP_OP_EXTENDED_REQUEST:
	    scan_extended_request(&src, body_max, out);
	    break;
	case LDAP_OP_SEARCH_DONE_RESPONSE:
	case LDAP_OP_MODIFY_RESPONSE:
	case LDAP_OP_ADD_RESPONSE:
	case LDAP_OP_DELETE_RESPONSE:
	case LDAP_OP_MODIFY_DN_RESPONSE:
	case LDAP_OP_COMPARE_RESPONSE:
	    scan_result_response(&src, body_max, out);
	    break;
	case LDAP_OP_BIND_RESPONSE:
	    scan_bind_response(&src, body_max, out);
	    break;
	case LDAP_OP_SEARCH_ENTRY_RESPONSE:
	    scan_search_entry_response(&src, body_max, out);
	    break;
	case LDAP_OP_SEARCH_REFERENCE_RESPONSE:
	    scan_search_reference_response(&src, body_max, out);
	    break;
	case LDAP_OP_EXTENDED_RESPONSE:
	    scan_extended_response(&src, body_max, out);
	    break;
	case LDAP_OP_INTERMEDIATE_RESPONSE:
	    scan_intermediate_response(&src, body_max, out);
	    break;
	default:
	    croak("ldap_shift_request: unimplemented operation %u", (unsigned int)op);
	    break;
	}
	if (src < body_max)
	    croak("unexpected data in packet");
    }
    else {
	switch(op) {
	case LDAP_OP_DELETE_REQUEST:
	    scan_delete_request(&src, max, out);
	    break;
	case LDAP_OP_ABANDON_REQUEST:
	    scan_abandon_request(&src, max, out);
	    break;
	case LDAP_OP_UNBIND_REQUEST:
	    scan_unbind_request(&src, max, out);
	    break;
	default:
	    croak("ldap_shift_request: unimplemented operation %u", (unsigned int)op);
	    break;
	}
    }
    if (src < max) {
	controls = newAV();
	controls_ref = sv_2mortal(newRV_noinc((SV*)controls));
	scan_controls(&src, max, controls);
    }
    if (src != max || src > save_max)
	croak("ldap_shift_request: internal error, scaning functions overread");
    if (src < save_max) {
	sv_chop(buffer, max);
	SvSETMAGIC(buffer);
    }
    else
	sv_setpvn_mg(buffer, "", 0);
    XPUSHs(sv_2mortal(newSViv(msgid)));
    XPUSHs(ldap_op2sv_noinc(op));
    XPUSHs(out_ref);
    if (controls_ref) {
	XPUSHs(controls_ref);
	XSRETURN(4);
    }
    else
	XSRETURN(3);
}

void
ldap_pack_message_ref(msgid, op, data, controls = 0)
    U32 msgid
    U32 op
    HV *data
    SV *controls
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    ldap_pack_message_ref(dest, op, data, controls);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
_ldap_pack_message_ref(msgid, data, controls = 0)
    U32 msgid
    HV *data
    SV *controls
ALIAS:
    ldap_pack_bind_request_ref = LDAP_OP_BIND_REQUEST
    ldap_pack_bind_response_ref = LDAP_OP_BIND_RESPONSE
    ldap_pack_unbind_request_ref = LDAP_OP_UNBIND_REQUEST
    ldap_pack_search_request_ref = LDAP_OP_SEARCH_REQUEST
    ldap_pack_search_entry_response_ref = LDAP_OP_SEARCH_ENTRY_RESPONSE
    ldap_pack_search_reference_response_ref = LDAP_OP_SEARCH_REFERENCE_RESPONSE
    ldap_pack_search_done_response_ref = LDAP_OP_SEARCH_DONE_RESPONSE
    ldap_pack_modify_request_ref = LDAP_OP_MODIFY_REQUEST
    ldap_pack_modify_response_ref = LDAP_OP_MODIFY_RESPONSE
    ldap_pack_add_request_ref = LDAP_OP_ADD_REQUEST
    ldap_pack_add_response_ref = LDAP_OP_ADD_RESPONSE
    ldap_pack_delete_request_ref = LDAP_OP_DELETE_REQUEST
    ldap_pack_delete_response_ref = LDAP_OP_DELETE_RESPONSE
    ldap_pack_modify_dn_request_ref = LDAP_OP_MODIFY_DN_REQUEST
    ldap_pack_modify_dn_response_ref = LDAP_OP_MODIFY_DN_RESPONSE
    ldap_pack_compare_request_ref = LDAP_OP_COMPARE_REQUEST
    ldap_pack_compare_response_ref = LDAP_OP_COMPARE_RESPONSE
    ldap_pack_abandon_request_ref = LDAP_OP_ABANDON_REQUEST
    ldap_pack_extended_request_ref = LDAP_OP_EXTENDED_REQUEST
    ldap_pack_extended_response_ref = LDAP_OP_EXTENDED_RESPONSE
    ldap_pack_intermediate_response_ref = LDAP_OP_INTERMEDIATE_RESPONSE
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    ldap_pack_message_ref(dest, ix, data, controls);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_bind_request(msgid, version = 3, dn = 0, method = LDAP_AUTH_SIMPLE, arg1 = 0, arg2 = 0)
    U32 msgid
    U32 version
    SV *dn
    U32 method
    SV *arg1
    SV *arg2
PPCODE:
{
    SV *dest = new_message_sv();
    if (version > 3)
	croak("bad LDAP protocol version %u", (unsigned int)version);
    start_ldap_message(dest, msgid);
    pack_bind_request_args(dest, version, dn, method, arg1, arg2);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_unbind_request(msgid)
    U32 msgid
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_unbind_request_args(dest);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_search_request(msgid, base_dn = 0, scope = LDAP_SCOPE_BASE_OBJECT, \
			 deref = LDAP_DEREF_ALIASES_NEVER, \
			 size_limit = 0, time_limit = 0, types_only = 0, \
			 filter = 0, \
			 attributes = 0)
    U32 msgid
    SV *base_dn
    U32 scope
    U32 deref
    U32 size_limit
    U32 time_limit
    U32 types_only
    AV_opt *filter
    SV *attributes
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_search_request_args(dest,
				  base_dn, scope, deref,
				  size_limit, time_limit, types_only,
				  filter, attributes);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_search_entry_response(msgid, dn, ...)
    U32 msgid
    SV *dn
PPCODE:
{
    SV *dest = new_message_sv();
    if (items & 1)
	croak("Usage: Net::LDAP::Gateway::search_entry_response("
	      "$msgid, $dn, attr => \\@values, attr => \\@values, ...)");
    start_ldap_message(dest, msgid);
    pack_search_entry_response_args(dest, dn, &(ST(2)), items - 2);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_search_reference_response(msgid, ...)
    U32 msgid
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_search_reference_response_args(dest, &(ST(1)), items - 1);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_modify_request(msgid, dn, ...)
    U32 msgid
    SV *dn
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_modify_request_args(dest, dn, &(ST(2)), items - 2);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_add_request(msgid, dn, ...)
    U32 msgid
    SV *dn
PPCODE:
{
    SV *dest = new_message_sv();
    if (items & 1)
	croak("Usage: Net::LDAP::Gateway::add_request("
	      "$msgid, $dn, attr => \\@values, attr => \\@values, ...)");
    start_ldap_message(dest, msgid);
    pack_add_request_args(dest, dn, &(ST(2)), items - 2);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void 
ldap_pack_delete_request(msgid, dn)
    U32 msgid
    SV *dn
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_delete_request_args(dest, dn);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_modify_dn_request(msgid, dn, new_rdn, delete_old_rdn = 0, new_superior = 0)
    U32 msgid
    SV *dn
    SV *new_rdn
    I32 delete_old_rdn
    SV *new_superior
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_modify_dn_request_args(dest, dn, new_rdn, delete_old_rdn, new_superior);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_compare_request(msgid, dn, attribute, value)
    U32 msgid
    SV *dn
    SV *attribute
    SV *value
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_compare_request_args(dest, dn, attribute, value);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_abandon_request(msgid, target_msgid)
    U32 msgid
    U32 target_msgid
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_abandon_request_args(dest, target_msgid);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
_ldap_pack_extended_request(msgid, oid, value = 0)
    U32 msgid
    SV *oid
    SV *value
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_extended_request_args(dest, oid, value);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_extended_response(msgid, result = 0, matched_dn = 0, \
			    message = 0, referrals = 0, \
			    name = 0, value = 0)
    U32 msgid
    I32 result
    SV *matched_dn
    SV *message
    SV *referrals
    SV *name
    SV *value
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_extended_response_args(dest, result, matched_dn, message,
				     referrals, name, value);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
ldap_pack_intermediate_response(msgid, oid = 0, value = 0)
    U32 msgid
    SV *oid
    SV *value
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_intermediate_response_args(dest, oid, value);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

void
_ldap_pack_result_response(msgid, result = LDAP_SUCCESS, matched_dn = 0, message = 0, referrals = 0)
    U32 msgid
    I32 result
    SV *matched_dn
    SV *message
    SV *referrals
ALIAS:
    ldap_pack_bind_response = LDAP_OP_BIND_RESPONSE
    ldap_pack_search_done_response = LDAP_OP_SEARCH_DONE_RESPONSE
    ldap_pack_modify_response = LDAP_OP_MODIFY_RESPONSE
    ldap_pack_add_response = LDAP_OP_ADD_RESPONSE
    ldap_pack_delete_response = LDAP_OP_DELETE_RESPONSE
    ldap_pack_modify_dn_response = LDAP_OP_MODIFY_DN_RESPONSE
    ldap_pack_compare_response = LDAP_OP_COMPARE_RESPONSE
PPCODE:
{
    SV *dest = new_message_sv();
    start_ldap_message(dest, msgid);
    pack_result_response_args(dest, ix, result, matched_dn, message, referrals);
    end_ldap_message(dest);
    XPUSHs(dest);
    XSRETURN(1);
}

