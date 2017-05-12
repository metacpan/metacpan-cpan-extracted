#include "scan.h"
#include "enum2sv.h"

void
scan_modify_request(const char** src, const char* max, HV *out) {
    STRLEN len;
    SV *dn = newSV(0);
    AV *changes;

    hv_stores(out, "dn", dn);
    scan_string_utf8(src, max, dn);
    scan_sequence(src, max, &len);

    if (len != max - *src)
	croak("scan_modify_request: packet too short");

    changes = newAV();
    hv_stores(out, "changes", newRV_noinc((SV*)changes));

    while (*src <  max) {
	const char *operation_max;
	HV *change;
	I32 operation;
	SV *attribute;
	AV *values;
	
	change = newHV();
	av_push(changes, newRV_noinc((SV*)change));
	scan_sequence(src, max, &len);
	operation_max = *src + len;

	scan_enum(src, operation_max, &operation);
	hv_stores(change, "operation", newSVsv(ldap_modop2sv_noinc(operation)));

	scan_sequence(src, max, &len);
	if (len != operation_max - *src)
	    croak("scan_modify_request: packet too short");

	attribute = newSV(0);
	hv_stores(change, "attribute", attribute);
	scan_string_utf8(src, operation_max, attribute);
	
	scan_set(src, operation_max, &len);
	if (len != operation_max - *src)
	    croak("scan_modify_request: packet too short");

	values = newAV();
	hv_stores(change, "values", newRV_noinc((SV*)values));
	while (*src < operation_max) {
	    SV *v = newSV(0);
	    av_push(values, v);
	    scan_string_utf8(src, operation_max, v);
	}
    }
}

