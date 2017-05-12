#include "scan.h"

int
peek_length(const char **src, const char *max, STRLEN *length) {
    if (*src >= max) return 0;
    if (**src & 0x80) {
	STRLEN l = 0;
	STRLEN chars = (*(*src)++ & 0x7f);
	if (chars > sizeof(*length))
	    croak("peek_length: length out of bounds (%u bytes)", (unsigned int)chars);
	if (chars > max - *src)
	    return 0;
	while (chars--) {
	    l <<= 8;
	    l |= *(unsigned char *)(*src)++;
	}
	*length = l;
    }
    else
	*length = *(*src)++;
    return 1;
}

void
scan_length(const char **src, const char *max, STRLEN *length) {
    if (peek_length(src, max, length))
	if (max - *src >= *length) return;
    croak("scan_length: packet too short");
}
