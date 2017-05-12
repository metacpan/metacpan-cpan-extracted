#include "pack.h"
#include <string.h>

#define DEFAULT_LENGTH 3

STRLEN
start_constructed_notag(SV *dest) {
    STRLEN offset = SvCUR(dest);
    sv_catpvn(dest, "**********", DEFAULT_LENGTH);
    return offset;
}

STRLEN
start_constructed(SV *dest, U8 type, U32 tag) {
    STRLEN offset;
    pack_tag(dest, type, tag);
    offset = SvCUR(dest);
    sv_catpvn(dest, "**********", DEFAULT_LENGTH);
    return offset;
}

void
end_constructed(SV *dest,
		     STRLEN offset) {
    char buffer[12];
    STRLEN len = pack_length_p(buffer, SvCUR(dest) - DEFAULT_LENGTH - offset);
    if (len == DEFAULT_LENGTH)
	memcpy(SvPVX(dest) + offset, buffer, DEFAULT_LENGTH);
    else {
	if (len > sizeof(buffer))
	    croak("end_constructed: internal error, overflow");
	sv_insert(dest, offset, DEFAULT_LENGTH, buffer, len);
    }
}
