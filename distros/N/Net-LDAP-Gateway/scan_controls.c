#include "scan.h"

void
scan_controls(const char **src, const char *max, AV *controls) {
    STRLEN len;
    U8 type;
    U32 tag;
    scan_tag(src, max, &type, &tag);
    if (type != (ASN1_CONTEXT_SPECIFIC | ASN1_CONSTRUCTED) || tag != 0)
	croak("scan_controls: bad packet");
    scan_length(src, max, &len);
    max = *src + len;

    while (*src < max) {
	HV *control;
	SV *sv;
	STRLEN control_len;
	const char *control_max;
	scan_sequence(src, max, &control_len);
	control_max = *src + control_len;
	control = newHV();
	av_push(controls, newRV_noinc((SV*)control));
	sv = newSV(0);
	hv_stores(control, "type", sv);
	scan_string_utf8(src, control_max, sv);

	if (*src == control_max) continue;
	scan_tag(src, control_max, &type, &tag);
	if (type != (ASN1_UNIVERSAL | ASN1_PRIMITIVE))
	    croak("scan_controls: bad packet");
	if (tag == ASN1_BOOLEAN) {
	    I32 criticality;
	    scan_numeric_notag(src, control_max, &criticality);
	    if (criticality) 
		hv_stores(control, "criticality", newSVsv(&PL_sv_yes));
	    if (*src == control_max) continue;
	    scan_tag(src, control_max, &type, &tag);
	    if (type != (ASN1_UNIVERSAL | ASN1_PRIMITIVE))
		croak("scan_controls: bad packet");
	}
	if (tag == ASN1_OCTET_STRING) {
	    sv = newSV(0);
	    hv_stores(control, "value", sv);
	    scan_raw_notag(src, control_max, sv);
	    if (*src == control_max) continue;
	}
	croak("scan_controls: bad packet");
    }
}
