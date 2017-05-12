#include "scan.h"

void
scan_modify_dn_request(const char** src, const char* max, HV *out) {
    STRLEN len;
    SV *sv;
    U32 del;

    sv = newSV(0);
    hv_stores(out, "dn", sv);
    scan_string_utf8(src, max, sv);

    sv = newSV(0);
    hv_stores(out, "new_rdn", sv);
    scan_string_utf8(src, max, sv);

    scan_bool(src, max, &del);
    if (del)
	hv_stores(out, "delete_old_rdn", newSVsv(&PL_sv_yes));

    if (*src < max) {
	U8 type;
	U32 tag;
	sv = newSV(0);
	hv_stores(out, "new_superior", sv);
	scan_raw(src, max, &type, &tag, sv);
	if (type != (ASN1_CONTEXT_SPECIFIC|ASN1_PRIMITIVE) || tag != 0)
	    croak("scan_modify_dn_request: bad value");

	if (!sv_utf8_decode(sv))
	    croak("scan_string_utf8: invalid UTF8 data received");
    }
}
	


    
    
