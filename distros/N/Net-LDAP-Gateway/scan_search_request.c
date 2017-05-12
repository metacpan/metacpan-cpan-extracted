#include "scan.h"
#include "enum2sv.h"
#include "enums.h"

static void
scan_search_filter(const char** src, const char* max, SV *filter_ref) {
    U8 type;
    U32 filter_type;
    AV *filter = newAV();
    sv_upgrade(filter_ref, SVt_RV);
    SvRV_set(filter_ref, (SV*)filter);
    SvROK_on(filter_ref);

    scan_tag(src, max, &type, &filter_type);

    av_push(filter, newSVsv(ldap_filter2sv_noinc(filter_type)));

    if (type == (ASN1_CONTEXT_SPECIFIC | ASN1_PRIMITIVE)) {
	SV *attr;
	if (filter_type != LDAP_FILTER_PRESENT)
	    croak("scan_search_filter: bad packet");
	attr = newSV(0);
	av_push(filter, attr);
	scan_raw_utf8_notag(src, max, attr);
    }
    else {
	STRLEN len;
	if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_CONSTRUCTED))
	    croak("scan_search_filter: bad packet");
	scan_length(src, max, &len);
	max = *src + len;

	switch (filter_type) {
	case LDAP_FILTER_AND:
	case LDAP_FILTER_OR:
	    if (len) {
		while (*src < max) {
		    SV *child = newSV(0);
		    av_push(filter, child);
		    scan_search_filter(src, max, child);
		}
	    }
	    break;
	case LDAP_FILTER_NOT:
	{
	    SV *child = newSV(0);
	    av_push(filter, child);
	    scan_search_filter(src, max, child);
	    break;
	}
	case LDAP_FILTER_EQ:
	case LDAP_FILTER_GE:
	case LDAP_FILTER_LE:
	case LDAP_FILTER_APPROX:
	{
	    SV *desc = newSV(0);
	    SV *value = newSV(0);
	    av_push(filter, desc);
	    av_push(filter, value);
	    scan_string_utf8(src, max, desc);
	    scan_string_utf8(src, max, value);
	    break;
	}
	case LDAP_FILTER_SUBSTRINGS:
	{
	    SV *attr = newSV(0);
	    int last_state;
	    av_push(filter, attr);
	    scan_string_utf8(src, max, attr);
	    
	    scan_sequence(src, max, &len);
	    
	    last_state = 0;
	    max = *src + len;
	    while (*src < max) {
		U8 type;
		U32 state;
		SV *substr = newSV(0);
		av_push(filter, substr);
		scan_raw_utf8(src, max, &type, &state, substr);
		if (state > 2 || state < last_state) goto error;
		
		switch (state) {
		case 0:
		    state = 1;
		    break;
		case 2:
		    state = 3;
		case 1:
		    if (last_state == 0) {
			av_pop(filter);
			av_push(filter, &PL_sv_undef);
			av_push(filter, substr);
		    }
		    break;
		default:
		    goto error;
		}
		last_state = state;
	    }
	    if (last_state < 2)
		av_push(filter, &PL_sv_undef);

	    break;
	  error:
	    croak("scan_search_filter: bad substring chain");
	    break;
	}
	case LDAP_FILTER_EXT:
	{
	    U8 type;
	    U32 tag;
	    HV *hv = newHV();
	    av_push(filter, newRV_noinc((SV*)hv));
	    scan_tag(src, max, &type, &tag);
	    if (tag == 1 && type == ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE) {
		SV *sv = newSV(0);
		hv_stores(hv, "matching_rule_id", sv);
		scan_raw_utf8_notag(src, max, sv);
		scan_tag(src, max, &type, &tag);
	    }
	    if (tag == 2 && type == ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE) {
		SV *sv = newSV(0);
		hv_stores(hv, "attribute", sv);
		scan_raw_utf8_notag(src, max, sv);
		scan_tag(src, max, &type, &tag);
	    }
	    if (tag == 3 && type == ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE) {
		SV *sv = newSV(0);
		hv_stores(hv, "value", sv);
		scan_raw_utf8_notag(src, max, sv);
		if (*src == max) break;
		scan_tag(src, max, &type, &tag);
		if (tag == 4 && type == ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE) {
		    I32 v;
		    scan_numeric_notag(src, max, &v);
		    if (v)
			hv_stores(hv, "dn_attributes", newSVsv(&PL_sv_yes));
		    break;
		}
	    }
	    croak("scan_search_filter: bad packet, invalid MatchingRuleAssertion element");
	    break;
	}   
	default:
	    croak("scan_search_filter: unknown filter type %d", (int)filter_type);
	}
    }
}

void scan_search_request(const char** src, const char* max, HV *out) {

    U32 e;
    STRLEN len;
    SV *filter;
    SV *sv;
    
    sv = newSV(0);
    hv_stores(out, "base_dn", sv);
    scan_string_utf8(src, max, sv);

    scan_enum(src, max, &e);
    if (e > 2) croak("scan_search_request: bad value scope: %u", (unsigned int)e);
    hv_stores(out, "scope", newSVsv(ldap_scope2sv_noinc(e)));

    scan_enum(src, max, &e);
    if (e > 3) croak("scan_search_request: bad value deref aliases: %u", (unsigned int)e);
    hv_stores(out, "deref_aliases", newSVsv(ldap_deref_aliases2sv_noinc(e)));

    scan_unsigned_numeric(src, max, &e);
    if (e < 0) croak("scan_search_request: bad value size limit: %u", (unsigned int)e);
    if (e) hv_stores(out, "size_limit", newSVuv(e));

    scan_int(src, max, &e);
    if (e < 0) croak("scan_search_request: bad value time limit: %d", (unsigned int)e);
    if (e) hv_stores(out, "time_limit", newSVuv(e));

    scan_bool(src, max, &e);
    if (e) hv_stores(out, "types_only", newSVsv(&PL_sv_yes));

    filter = newSV(0);
    hv_stores(out, "filter", filter);
    scan_search_filter(src, max, filter);

    /* now for the attributelist */
    scan_sequence(src, max, &len);
    if (len > max - *src)
	croak("scan_search_request: packet too short");
    
    if (len) {
	AV *attrs = newAV();
	hv_stores(out, "attributes", newRV_noinc((SV*)attrs));
	scan_array_of_string_utf8(src, *src + len, attrs);
    }
}
