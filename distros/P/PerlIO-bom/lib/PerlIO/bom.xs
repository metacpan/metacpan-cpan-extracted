#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

#ifndef STR_WITH_LEN
#define STR_WITH_LEN(s) (s ""), (sizeof(s)-1)
#endif

static IV S_push_utf8(pTHX_ PerlIO* f, const char* mode) {
    PerlIO_funcs* encoding = PerlIO_find_layer(aTHX_ STR_WITH_LEN("utf8_strict"), 1);
    return PerlIO_push(aTHX_ f, encoding, mode, NULL) == f ? 0 : -1;
}
#define push_utf8(f, mode) S_push_utf8(aTHX_ f, mode)

static IV S_push_encoding_sv(pTHX_ PerlIO* f, const char* mode, SV* encoding) {
    PerlIO_funcs* layer = PerlIO_find_layer(aTHX_ STR_WITH_LEN("encoding"), 1);
    return PerlIO_push(aTHX_ f, layer , mode, encoding) == f ? 0 : -1;
}
#define push_encoding_sv(f, mode, encoding) S_push_encoding_sv(aTHX_ f, mode, encoding)
#define push_encoding_pvs(f, mode, encoding) push_encoding_sv(f, mode, sv_2mortal(newSVpvs(encoding)))

int S_is_utf8(pTHX_ SV* arg) {
	if (!arg || !SvOK(arg))
		return TRUE;

	STRLEN len;
	const char* fallback = SvPV(arg, len);
	return len >= 4 &&
		(memcmp(fallback, "utf", 3) == 0 || memcmp(fallback, "UTF", 3) == 0) &&
		fallback[3] == '8' || (len >= 5 && fallback[3] == '-' && fallback[4] == '8');
}
#define is_utf8(arg) S_is_utf8(aTHX_ arg)

static IV PerlIOBom_pushed(pTHX_ PerlIO *f, const char *mode, SV *arg, PerlIO_funcs *tab) {
	if (!PerlIOValid(f))
		return -1;
	else if (!PerlIO_fast_gets(f)) {
		char mode[8];
		PerlIO_push(aTHX_ f, &PerlIO_perlio, PerlIO_modestr(f,mode), Nullsv);
		if (!f) {
			Perl_warn(aTHX_ "panic: cannot push :perlio for %p",f);
			return -1;
		}
	}
	if (mode[0] == 'r' || mode[0] == 'w' && mode[1] == '+') {
		PerlIO_fill(f);
		Size_t count = PerlIO_get_cnt(f);
		char* buffer = PerlIO_get_ptr(f);
		if (count >= 3 && memcmp(buffer, "\xEF\xBB\xBF", 3) == 0) {
			PerlIO_set_ptrcnt(f, buffer + 3, count - 3);
			return push_utf8(f, mode);
		}
		else if (count >= 4 && memcmp(buffer, "\x00\x00\xFE\xFF", 4) == 0) {
			PerlIO_set_ptrcnt(f, buffer + 4, count - 4);
			return push_encoding_pvs(f, mode, "UTF32-BE");
		}
		else if (count >= 4 && memcmp(buffer, "\xFF\xFE\x00\x00", 4) == 0) {
			PerlIO_set_ptrcnt(f, buffer + 4, count - 4);
			return push_encoding_pvs(f, mode, "UTF32-LE");
		}
		else if (count >= 2 && memcmp(buffer, "\xFE\xFF", 2) == 0) {
			PerlIO_set_ptrcnt(f, buffer + 2, count - 2);
			return push_encoding_pvs(f, mode, "UTF16-BE");
		}
		else if (count >= 2 && memcmp(buffer, "\xFF\xFE", 2) == 0) {
			PerlIO_set_ptrcnt(f, buffer + 2, count - 2);
			return push_encoding_pvs(f, mode, "UTF16-LE");
		}
		if (is_utf8(arg))
			return push_utf8(f, mode);
		else
			return push_encoding_sv(f, mode, arg);
	}
	else if (mode[0] == 'w') {
		if (!arg || SvOK(arg) && !is_utf8(arg))
			push_encoding_sv(f, mode, arg);
		else
			push_utf8(f, mode);

		return PerlIO_write(f, "\xEF\xBB\xBF", 3) == 3 ? 0 : -1;
	}
	else
		return -1;
}

PerlIO_funcs PerlIO_bom = {
    sizeof(PerlIO_funcs),
    "bom",
    0,
    0,
    PerlIOBom_pushed,
    NULL,
#if PERL_VERSION >= 14
    PerlIOBase_open,
#else
    PerlIOBuf_open,
#endif
};

MODULE = PerlIO::bom				PACKAGE = PerlIO::bom

PROTOTYPES: DISABLED

BOOT:
    PerlIO_define_layer(aTHX_ &PerlIO_bom);

