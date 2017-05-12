#include "scan.h"

static int
peek_raw_notag(const char **src, const char *max, SV *sv) {
    const char *s;
    STRLEN len;
    if (peek_length(src, max, &len)) {
	if (max - *src >= len) {
	    sv_setpvn(sv, *src, len);
	    *src += len;
	    return 1;
	}
    }
    return 0;
}

int
peek_raw_utf8_notag(const char **src, const char *max, SV *sv) {
    if (peek_raw_notag(src, max, sv)) {
	if (!sv_utf8_decode(sv))
	    croak("scan_raw_utf8: invalid UTF8 data received");
	return 1;
    }
    return 0;
}
int
peek_raw(const char **src, const char *max, U8 *type, U32 *tag, SV *sv) {
    return (peek_tag(src, max, type, tag) &&
	    peek_raw_notag(src, max, sv));
}

void
scan_raw_notag(const char **src, const char *max, SV *sv) {
    const char *s;
    STRLEN len;
    scan_length(src, max, &len);
    if (len > max - *src)
	croak("scan_raw_notag: packet too short");
    sv_setpvn(sv, *src, len);
    *src += len;
}

void
scan_raw_utf8_notag(const char **src, const char *max, SV *sv) {
    scan_raw_notag(src, max, sv);
    if (!sv_utf8_decode(sv))
	croak("scan_raw_utf8_notag: invalid UTF8 data received");
}

void
scan_raw(const char **src, const char *max, U8 *type, U32* tag, SV *sv) {
    scan_tag(src, max, type, tag);
    scan_raw_notag(src, max, sv);
}

void
scan_raw_utf8(const char **src, const char *max,
		      U8 *type, U32* tag, SV *sv) {
    scan_raw(src, max, type, tag, sv);
    if (!sv_utf8_decode(sv))
	croak("scan_raw_utf8: invalid UTF8 data received");
}

void
scan_raw_with_small_tt(const char **src, const char *max, U8 tt, SV *sv) {
    scan_small_tag_with_tt(src, max, tt);
    scan_raw_notag(src, max, sv);
}

void
scan_raw_utf8_with_small_tt(const char **src, const char *max, U8 tt, SV *sv) {
    scan_small_tag_with_tt(src, max, tt);
    scan_raw_notag(src, max, sv);
    if (!sv_utf8_decode(sv))
	croak("scan_raw_utf8: invalid UTF8 data received");
}

int
peek_raw_with_small_tt(const char **src, const char *max, U8 tt, SV *sv) {
    return (peek_small_tag_with_tt(src, max, tt) &&
	    peek_raw_notag(src, max, sv));
}

int
peek_raw_utf8_with_small_tt(const char **src, const char *max, U8 tt, SV *sv) {
    if (peek_small_tag_with_tt(src, max, tt) &&
	peek_raw_notag(src, max, sv)) {
	if (!sv_utf8_decode(sv))
	    croak("scan_raw_utf8: invalid UTF8 data received");
	return 1;
    }
    return 0;
}

void
scan_array_of_raw_utf8_with_small_tt(const char **src, const char *max, U8 tt, AV *av) {
    while (*src < max) {
	SV *sv = newSV(0);
	av_push(av, sv);
	scan_raw_utf8_with_small_tt(src, max, tt, sv);
    }	
}
