#include "pack.h"

void pack_unsigned_numeric_notag(SV* dest, U32 l) {
    char buffer[10];
    char *p = buffer + 1;
    int len, i = sizeof(U32);

    while (--i > 0)
	if (l >> (i * 8)) break;

    if ((l >> (i * 8)) & 0x80)
	*p++ = 0;

    do {
	*p++ = ((l >> (i * 8)) & 0xff);
    } while (--i >= 0);

    len = p - buffer;
    buffer[0] = len - 1;
    sv_catpvn(dest, buffer, len);
}

void pack_numeric_notag(SV* dest, I32 l) {
    if (l >= 0)
	pack_unsigned_numeric_notag(dest, l);
    else {
	char buffer[10];
	char *p = buffer + 1;
	int len, i = sizeof(I32);
	
	while(--i > 0)
	    if (((l >> (i * 8)) & 0xff) != 0xff) break;
	
	if (!(l >> (i * 8) & 0x80))
	    *p++ = 0xff;
	
	do {
	    *p++ = ((l >> (i * 8)) & 0xff);
	} while (--i >= 0);

	len = p - buffer;
	buffer[0] = len - 1;
	sv_catpvn(dest, buffer, len);
    }
}

void pack_unsigned_numeric(SV* dest, U8 type, U32 tag, U32 l) {
    pack_tag(dest, type, tag);
    pack_unsigned_numeric_notag(dest, l);
}

void pack_numeric(SV* dest, U8 type, U32 tag, I32 l) {
    pack_tag(dest, type, tag);
    pack_numeric_notag(dest, l);
}
