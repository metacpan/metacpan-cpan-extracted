#include "pack.h"

STRLEN
pack_tag_p(char *p, U8 type, U32 tag) {
    if (tag < 0x1f) {
	*p = type + tag;
	return 1;
    }
    else {
	char *p1 = p;
	int i = (sizeof(U32) * 8 + 6) / 7;

	*p1++ = type + 0x1f;

	while (--i > 0)
	    if (tag >> (i * 7)) break;

	do {
	    *p1++ = (((tag >> (i * 7)) & 0x7f) | (i ? 0x80 : 0));
	} while (--i >= 0);
	
	return p1 - p;
    }
}   

void pack_tag(SV* dest, U8 type, U32 tag) {
    char buffer[12];
    STRLEN len = pack_tag_p(buffer, type, tag);
    if (len > sizeof(buffer))
	croak("pack_tag_p: internal error, overflow");
    sv_catpvn(dest, buffer, len);
}
