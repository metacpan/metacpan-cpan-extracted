#ifndef PACK_H_INCLUDED
#define PACK_H_INCLUDED

#include "common.h"
#include "enums.h"
#include "asn1.h"

/* ASN1 entities */

STRLEN pack_length_p(char *p, STRLEN l);
void pack_length(SV *dest,STRLEN l);

void pack_tag(SV* dest, U8 type, U32 tag);

void pack_unsigned_numeric_notag(SV* dest, U32 val);
void pack_asn1_numeric_notag(SV* dest, I32 val);
void pack_unsigned_numeric(SV* dest, U8 type, U32 tag, U32 val);
void pack_asn1_numeric(SV* dest, U8 type, U32 tag, I32 val);

#define pack_int(dest, l) pack_numeric(dest,ASN1_UNIVERSAL|ASN1_PRIMITIVE,ASN1_INTEGER,l)
#define pack_bool(dest, l) pack_numeric(dest,ASN1_UNIVERSAL|ASN1_PRIMITIVE,ASN1_BOOLEAN, ((l) ? -1 : 0))
#define pack_enum(dest, l) pack_unsigned_numeric(dest,ASN1_UNIVERSAL|ASN1_PRIMITIVE,ASN1_ENUMERATED,l)

void pack_raw_pvn_notag(SV *dest, const char* c, STRLEN l);
void pack_raw_pvn(SV* dest, U8 type, U32 tag, const char* c, STRLEN l);
void pack_raw(SV* dest, U8 type, U32 tag, SV *sv);
void pack_raw_utf8(SV* dest, U8 type, U32 tag, SV *sv);
void pack_array_of_raw_utf8_v(SV *dest, U8 type, U32 tag, SV **args, I32 n);
void pack_array_of_raw_utf8(SV *dest, U8 type, U32 tag, SV *sv);
void pack_sequence_of_raw_utf8(SV *dest, U8 type, U32 tag, SV *sv);
void pack_set_of_raw_utf8(SV *dest, U8 type, U32 tag, SV *sv);

#define pack_string_utf8(dest, s) pack_raw_utf8(dest, ASN1_UNIVERSAL|ASN1_PRIMITIVE, ASN1_OCTET_STRING, s)
#define pack_sequence_of_string_utf8(dest, s) pack_sequence_of_raw_utf8(dest, ASN1_UNIVERSAL|ASN1_PRIMITIVE, ASN1_OCTET_STRING, s)
#define pack_set_of_string_utf8(dest, s) pack_set_of_raw_utf8(dest, ASN1_UNIVERSAL|ASN1_PRIMITIVE, ASN1_OCTET_STRING, s)
#define pack_array_of_string_utf8(dest, s) pack_array_of_raw_utf8(dest, ASN1_UNIVERSAL|ASN1_PRIMITIVE, ASN1_OCTET_STRING, s)
#define pack_array_of_string_utf8_v(dest, args, n) pack_array_of_raw_utf8_v(dest, ASN1_UNIVERSAL|ASN1_PRIMITIVE, ASN1_OCTET_STRING, args, n)

STRLEN start_constructed_notag(SV *dest);
STRLEN start_constructed(SV *dest, U8 type, U32 tag);
void end_constructed(SV *dest, STRLEN offset);

#define start_sequence(dest) start_constructed((dest), ASN1_UNIVERSAL|ASN1_CONSTRUCTED, ASN1_SEQUENCE)
#define end_sequence(dest, offset) end_constructed((dest), (offset))
#define start_set(dest) start_constructed((dest), ASN1_UNIVERSAL|ASN1_CONSTRUCTED, ASN1_SET)
#define end_set(dest, offset) end_constructed((dest), (offset))




/* LDAP messages */


void pack_message(SV* dest, U32 messageid, U32 op, STRLEN len);

void pack_bind_request_args(SV* dest, U32 version, SV *dn, I32 method, SV *arg1, SV *arg2);
void pack_bind_request_ref(SV *dest, HV *hv);

void pack_bind_response_args(SV *dest, I32 result,
				  SV *matched_dn, SV *message, SV *referrals,
				  SV *sasl_credentials);
void pack_bind_response_ref(SV *dest, HV *hv);

void pack_unbind_request_args(SV *dest);
void pack_unbind_request_ref(SV *dest, HV *out);

void pack_search_request_args(SV *dest, SV *base_dn,
				   enum ldap_scope scope, enum ldap_deref_aliases deref,
				   U32 size_limit, U32 time_limit, U32 types_only,
				   AV *filter, SV *attributes);
void pack_search_entry_response_args(SV *dest, SV *dn, SV **args, U32 n);
void pack_search_entry_response_ref(SV *dest, HV *hv);

void pack_search_reference_response_args(SV *dest, SV **args, I32 n);
void pack_search_reference_response_ref(SV *dest, HV *hv);

void pack_modify_request_args(SV *dest, SV *dn, SV **args, I32 n);
void pack_modify_request_ref(SV *dest, HV *hv);

void pack_delete_request_args(SV *dest, SV *dn);
void pack_delete_request_ref(SV *dest, HV *hv);

void pack_compare_request_args(SV *dest, SV *dn, SV *attribute, SV *value);
void pack_compare_request_ref(SV *dest, HV *hv);

void pack_modify_dn_request_args(SV *dest, SV *dn, SV *new_rdn,
				      I32 delete_old_rdn, SV *new_superior);
void pack_modify_dn_request_ref(SV *dest, HV *hv);

void pack_abandon_request_args(SV *dest, U32 msgid);
void pack_abandon_request_ref(SV *dest, HV *hv);

void pack_result_response_ref(SV *dest, U32 op, HV *hv);
void pack_result_response_args(SV *dest, U32 op, I32 result,
				    SV *matched_dn, SV *message, SV *referrals);
void pack_result_response_nowrap(SV *dest, I32 result,
				      SV *matched_dn, SV *message, SV *referrals);

void pack_extended_request_args(SV *dest, SV *oid, SV *value);
void pack_extended_request_ref(SV *dest, HV *hv);

void pack_extended_response_args(SV *dest, I32 result,
				      SV *matched_dn, SV *message, SV *referrals,
				      SV *name, SV *value);
void pack_extended_response_ref(SV *dest, HV *hv);

void pack_intermediate_response_args(SV *dest, SV *name, SV *value);
void pack_intermediate_response_ref(SV *dest, HV *hv);

void pack_controls(SV *dest, SV *controls);



#endif
