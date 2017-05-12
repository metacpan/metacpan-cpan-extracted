#include "pack.h"
#include "util.h"

void
pack_raw_pvn(SV* dest, U8 type, U32 tag, const char* c, STRLEN l) {
    pack_tag(dest, type, tag);
    pack_length(dest, l);
    if (l)
	sv_catpvn(dest, c, l);
}

void
pack_raw_pvn_notag(SV *dest, const char* c, STRLEN l) {
    pack_length(dest, l);
    sv_catpvn(dest, c, l);
}

void
pack_raw(SV* dest, U8 type, U32 tag, SV *sv) {
    pack_tag(dest, type, tag);
    if (sv) {
	STRLEN len;
	const char *pv;
	sv_utf8_downgrade(sv, 0);
	pv = SvPV(sv, len);
	if (len) {
	  pack_length(dest, len);
	    sv_catpvn(dest, pv, len);
	    return;
	}
    }
    pack_length(dest, 0);
}

void
pack_raw_utf8(SV* dest, U8 type, U32 tag, SV *sv) {
    pack_tag(dest, type, tag);
    if (sv) {
	STRLEN len;
	const char *pv = SvPVutf8(sv, len);
	if (len) {
	    pack_length(dest, len);
	    sv_catpvn(dest, pv, len);
	    return;
	}
    }
    pack_length(dest, 0);
}

void
pack_array_of_raw_utf8_v(SV *dest, U8 type, U32 tag, SV **args, I32 n) {
    I32 i;
    for (i = 0; i < n; i++)
	pack_raw_utf8(dest, type, tag, args[i]);
}

void
pack_array_of_raw_utf8(SV *dest, U8 type, U32 tag, SV *sv) {
    AV *av;
    if (sv && SvOK(sv)) {
	if (SvROK(sv) && (av = (AV*)SvRV(sv)) && (SvTYPE((SV*)av) == SVt_PVAV)) {
	    U32 i, size = av_len(av) + 1;
	    for (i = 0; i < size; i++)
		pack_raw_utf8(dest, type, tag, av_fetch_def_undef(av, i));
	}
	else
	    pack_raw_utf8(dest, type, tag, sv);
    }
}

void
pack_sequence_of_raw_utf8(SV *dest, U8 type, U32 tag, SV *sv) {
    STRLEN offset = start_sequence(dest);
    pack_array_of_raw_utf8(dest, type, tag, sv);
    end_sequence(dest, offset);
}

void
pack_set_of_raw_utf8(SV *dest, U8 type, U32 tag, SV *sv) {
    STRLEN offset = start_set(dest);
    pack_array_of_raw_utf8(dest, type, tag, sv);
    end_set(dest, offset);
}
