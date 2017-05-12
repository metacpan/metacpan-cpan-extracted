#include "common.h"
#include "pack.h"

STRLEN
pack_length_p(char *p, STRLEN l) {
    if (l<128) {
	*p = l;
	return 1;
    }
    else {
	char *p1 = p + 1;
	int i = sizeof(l);
	STRLEN bytes;
	while (--i > 0)
	    if (l >> (i * 8)) break;

	do {
	    *p1++ = ((l >> (i * 8)) & 0xff);
	} while (--i >= 0);

	bytes = p1 - p;
	*p = ((bytes - 1) | 0x80);
	return bytes;	    
    }
}

void
pack_length(SV* dest, STRLEN l) {
    char buffer[12];
    STRLEN len = pack_length_p(buffer, l);
    if (len > sizeof(buffer))
	croak("pack_length: internal error, overflow");
    sv_catpvn(dest, buffer, len);
}
