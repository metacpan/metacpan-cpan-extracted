#include "scan.h"

void
scan_message_head(const char** src,const char* max,
		  U32* messageid, U32* op, U8 *type, STRLEN *len) {
    STRLEN len1;
    scan_sequence(src, max, &len1);
    max = *src + len1;
    scan_unsigned_numeric(src, max, (I32*)messageid);
    scan_tag(src, max, type, op);
    if ((*type & ASN1_DOMAIN_MASK) != ASN1_APPLICATION)
	croak("scan_message_head: invalid value type: %u", *type);
    *len = max - *src;
}
