#include "pack.h"
#include "util.h"

#define EHEAD "pack_search_filter: bad filter specification, usage: "

static void
pack_search_filter(SV *dest, AV *filter) {
    if (filter) {
	SV **svp;
	I32 type;
	I32 len = av_len(filter) + 1;
	svp = av_fetch(filter, 0, 0);
	if (!svp || !*svp)
	    croak(EHEAD "[$filter_type, @args]");
	type = SvIV(*svp);
	if (type == LDAP_FILTER_PRESENT) {
	    SV **svp = av_fetch(filter, 1, 0);
	    if (!svp || !*svp)
		croak(EHEAD "[LDAP_FILTER_PRESENT, $attribute]");
	    pack_raw_utf8(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, type, *svp);
	}
	else {
	    STRLEN offset = start_constructed(dest, ASN1_CONTEXT_SPECIFIC|ASN1_CONSTRUCTED, type);
	    switch(type) {
	    case LDAP_FILTER_NOT:
		if (len != 2)
		    croak(EHEAD "[LDAP_FILTER_NOT, \\@child]");
		/* fall through */
	    case LDAP_FILTER_AND:
	    case LDAP_FILTER_OR:
	    {
		I32 i;
		if (len < 2)
		    croak(EHEAD "[LDAP_FILTER_AND, \\@child1, ...]");
		for (i = 1; i < len; i++) {
		    AV *child;
		    SV **svp = av_fetch(filter, i, 0);
		    if (!svp || !*svp || !SvROK(*svp) ||
			!(child = (AV*)SvRV(*svp)) ||
			(SvTYPE(child) != SVt_PVAV))
			croak(EHEAD "[LDAP_FILTER_AND, \\@child1, \\@child2, ...]");
		    pack_search_filter(dest, child);
		}
		break;
	    }
	    case LDAP_FILTER_EQ:
	    case LDAP_FILTER_GE:
	    case LDAP_FILTER_LE:
	    case LDAP_FILTER_APPROX:
	    {
		SV **attr = av_fetch(filter, 1, 0);
		SV **val = av_fetch(filter, 2, 0);
		if (!attr || !*attr || !val || !*val)
		    croak(EHEAD "[LDAP_FILTER_EQ, $attribute, $value]");
		pack_string_utf8(dest, *attr);
		pack_string_utf8(dest, *val);
		break;
	    }
	    case LDAP_FILTER_SUBSTRINGS:
	    {
		I32 i;
		SV **attr = av_fetch(filter, 1, 0);
		STRLEN offset;
		if (!attr || !*attr || len < 4)
		    croak(EHEAD "[LDAP_FILTER_SUBSTRINGS, $attribute, $start, @middle, $end]");
                pack_string_utf8(dest, *attr);
                offset = start_sequence(dest);
		for (i = 2; i < len; i++) {
		    int stype;
		    SV **str = av_fetch(filter, i, 0);
		    if (!str || !*str || !SvOK(*str) || !sv_len(*str)) continue;
		    if (i == 2)
			stype = 0;
		    else if (i == len - 1)
			stype = 2;
		    else
			stype = 1;
		    pack_raw_utf8(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, stype, *str);
		}
		end_sequence(dest, offset);
                break;
	    }
	    default:
		croak("bad filter type %d", (int)type);
		break;
	    }
	    end_constructed(dest, offset);
	}
    }
    else
	pack_raw_pvn(dest, ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE, LDAP_FILTER_PRESENT, "objectClass", 11);
}

void
pack_search_request_args(SV *dest,
			      SV *base_dn,
			      enum ldap_scope scope,
			      enum ldap_deref_aliases deref,
			      U32 size_limit,
			      U32 time_limit,
			      U32 types_only,
			      AV *filter,
			      SV *attributes) {
    STRLEN offset = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_SEARCH_REQUEST);
    pack_string_utf8(dest, base_dn);
    pack_enum(dest, scope);
    pack_enum(dest, deref);
    pack_int(dest, size_limit);
    pack_int(dest, time_limit);
    pack_bool(dest, (types_only ? 1 : 0));
    pack_search_filter(dest, filter);
    pack_sequence_of_string_utf8(dest, attributes);
    end_constructed(dest, offset);
}

void
pack_search_request_ref(SV *dest, HV *hv) {
    SV *sv;
    AV *filter;
    STRLEN offset = start_constructed(dest, ASN1_APPLICATION|ASN1_CONSTRUCTED, LDAP_OP_SEARCH_REQUEST);
    pack_string_utf8(dest, hv_fetchs_def_no(hv, "base_dn"));
    pack_enum(dest, SvIV(hv_fetchs_def_no(hv, "scope")));
    pack_enum(dest, SvIV(hv_fetchs_def_no(hv, "deref_aliases")));
    pack_int(dest, SvIV(hv_fetchs_def_no(hv, "size_limit")));
    pack_int(dest, SvIV(hv_fetchs_def_no(hv, "time_limit")));
    pack_bool(dest, SvTRUE(hv_fetchs_def_no(hv, "types_only")));
    sv = hv_fetchs_def_undef(hv, "filter");
    if (sv && SvOK(sv)) {
	if (!SvROK(sv) || !(filter = (AV*)SvRV(sv)) || (SvTYPE(filter) != SVt_PVAV))
	    croak("pack_search_request_ref: bad filter specification, usage "
		  "[$filter_type, @args]");
    }
    else filter = 0;
    pack_search_filter(dest, filter);
    pack_sequence_of_string_utf8(dest, hv_fetchs_def_undef(hv, "attributes"));
    end_constructed(dest, offset);
}
