#include "scan.h"

int
peek_tag(const char **src, const char *max, U8 *type, U32* tag) {
    if (*src >= max) return 0;

    *type = **src & ASN1_TYPE_MASK;

    if ((**src & 0x1f) == 0x1f) {
	U32 t = 0;
	for (;;) {
	    (*src)++;
	    if (*src >= max) return 0;
	    if (t > ((~(U32)0) >> 7))
		croak("scan_tag: integer overflow");
	    t <<= 7;
	    t += *(unsigned char *)*src & 0x7F;
	    if (!(**src & 0x80)) break;
	}
	(*src)++;
	*tag = t;
    } else
	*tag = *(*src)++ & 0x1f;

    return 1;
}

void
scan_tag(const char **src, const char *max, U8 *type, U32* tag) {
    if (!peek_tag(src, max, type, tag))
	croak("scan_tag: packet too short");
}

int
peek_tag_with_tt(const char **src,  const char *max,
		   U8 expected_type, U32 expected_tag) {
    U8 type;
    U32 tag;
    if (peek_tag(src, max, &type, &tag)) {
	if (type != expected_type ||
	    tag != expected_tag )
	    croak("peek_tag_with_tt: bad packet");
	return 1;
    }
    return 0;
}

void
scan_tag_with_tt(const char **src, const char *max,
		   U8 expected_type, U32 expected_tag) {
    if (!peek_tag_with_tt(src, max, expected_type, expected_tag))
	croak("scan_tag_with_tt: bad packet");
}
