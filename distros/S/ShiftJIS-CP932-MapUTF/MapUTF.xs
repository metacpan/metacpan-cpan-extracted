#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "scmuni.h"

#include "fmcp932.h"
#include "tocp932.h"

#define PkgName "ShiftJIS::CP932::MapUTF"

#define Is_CP932_LED(i)   (0x81<=(i) && (i)<=0x9F || 0xE0<=(i) && (i)<=0xFC)
#define Is_CP932_TRL(i)   (0x40<=(i) && (i)<=0x7E || 0x80<=(i) && (i)<=0xFC)
#define Is_CP932_EUDC(i)  (0xF0<=(i) && (i)<=0xF9)
#define Is_CP932_UDSB(i)  ((i)==0x80 || (i)==0xA0 || 0xFD<=(i) && (i)<=0xFF)
#define Is_CP932_SNG(i)   (0x00<=(i) && (i)<=0x80 || 0xA0<=(i) && (i)<=0xDF \
			|| 0xFD<=(i) && (i)<=0xFF)

#define CP932_UDSB2PUA(i) ((i) == 0x80 ? 0x80 : (i) == 0xA0 ? 0xF8F0 \
				: (i) + 0xF8F0 - 0xFC)

#define Is_CP932_PUAe(uv) (0xE000 <= (uv) && (uv) <= 0xE757)
#define Is_CP932_PUAs(uv) ((uv)==0x80 || 0xF8F0 <= (uv) && (uv) <= 0xF8F3)
#define Is_CP932_L1FB(uv) ((uv)==0x3094 || 0xA0 <= (uv) && (uv) <= 0xFF)

#define CP932_PUA_BASE    (0xE000)
#define CP932_PUA2UDSB(uv)  ((uv) == 0x80 ? 0x80 : (uv) == 0xF8F0 ? 0xA0 \
				: (uv) - 0xF8F0 + 0xFC)
#define CP932_FB2MB(uv)   ((uv) == 0x3094 ? 0x8394 \
				: fb_latin1_to_cp932[0x7f & ((uv) - 0xA0)])


#define STMT_ASSIGN_CVREF_AND_SRC(func_name)	\
    cvref = NULL;				\
    if (SvROK(ST(0))) {				\
	if (SvTYPE(SvRV(ST(0))) == SVt_PVCV)	\
	    cvref = SvRV(ST(0));		\
	else					\
	    croak("RV other than CODEREF "	\
	    "cannot be used in %s", func_name);	\
    }						\
    src = cvref					\
	? (1 < items) ? ST(1) : &PL_sv_undef	\
	: ST(0);				\
    mod = cvref					\
	? (2 < items) ? ST(2) : &PL_sv_no	\
	: (1 < items) ? ST(1) : &PL_sv_no;


#define STMT_ASSIGN_LENDST(maxlen)		\
    s = (U8*)SvPV(src,srclen);			\
    e = s + srclen;				\
    dstlen = srclen * maxlen + 1;		\
    dst = sv_2mortal(newSV(dstlen));		\
    (void)SvPOK_only(dst);


#define STMT_GET_MBLEN					\
    mblen = Is_CP932_LED(*(p)) && 2 <= (e - p)		\
	? (!mod_t || Is_CP932_TRL((p)[1])) ? 2 : 0	\
	: Is_CP932_SNG(*(p)) ? 1 : 0;


#define STMT_GET_UV_FROM_MB				\
    if (mod_g && Is_CP932_EUDC(*(p)) &&			\
	Is_CP932_TRL((p)[1]) ) {			\
	uv = 0xE000 + 188 * (*(p) - 0xF0) +		\
	    (p)[1] - ((p)[1] > 0x7E ? 0x41 : 0x40);	\
    }							\
    else if (mod_s && Is_CP932_UDSB(*(p))) {		\
	uv = (UV) CP932_UDSB2PUA(*(p));			\
    }							\
    else {						\
	lb = fmcp932_tbl[*p];				\
	uv = lb.tbl ? lb.tbl[p[1]] : lb.sbc;		\
    }


/* Perl 5.6.1 ? */
#ifndef uvuni_to_utf8
#define uvuni_to_utf8   uv_to_utf8
#endif /* uvuni_to_utf8 */

/* Perl 5.6.1 ? */
#ifndef utf8n_to_uvuni
#define utf8n_to_uvuni  utf8_to_uv
#endif /* utf8n_to_uvuni */

static void
sv_cat_retcvref (SV *dst, SV *cv, SV *sv, bool isbyte)
{
    dSP;
    int count;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    if (isbyte)
	XPUSHs(&PL_sv_undef);
    XPUSHs(sv_2mortal(sv));
    PUTBACK;
    count = call_sv(cv, (G_EVAL|G_SCALAR));
    SPAGAIN;
    if (SvTRUE(ERRSV) || count != 1) {
	croak("died in XS, " PkgName "\n");
    }
    sv_catsv(dst,POPs);
    PUTBACK;
    FREETMPS;
    LEAVE;
}

static char* funcname_to[] = {
    "cp932_to_unicode",
    "cp932_to_utf8",
    "cp932_to_utf16le",
    "cp932_to_utf16be",
    "cp932_to_utf32le",
    "cp932_to_utf32be",
};

static char* funcname_fm[] = {
    "unicode_to_cp932",
    "utf8_to_cp932",
    "utf16le_to_cp932",
    "utf16be_to_cp932",
    "utf32le_to_cp932",
    "utf32be_to_cp932",
    "utf16_to_cp932",
    "utf32_to_cp932"
};

static STRLEN maxlen_to[] = {
    MaxLenToUni,
    MaxLenToU8,
    MaxLenToU16,
    MaxLenToU16,
    MaxLenToU32,
    MaxLenToU32,
};

static STRLEN maxlen_fm[] = {
    MaxLenFmUni,
    MaxLenFmU8,
    MaxLenFmU16,
    MaxLenFmU16,
    MaxLenFmU32,
    MaxLenFmU32,
    MaxLenFmU16,
    MaxLenFmU32,
};

static U8* (*app_uv_in[])(U8*, UV) = {
    NULL,
    app_in_utf8,
    app_in_utf16le,
    app_in_utf16be,
    app_in_utf32le,
    app_in_utf32be,
};

static UV (*ord_uv_in[])(U8 *, STRLEN, STRLEN *) = {
    NULL,
    ord_in_utf8,
    ord_in_utf16le,
    ord_in_utf16be,
    ord_in_utf32le,
    ord_in_utf32be,
    ord_in_utf16be, /* w/o BOM*/
    ord_in_utf32be, /* w/o BOM*/
};


MODULE = ShiftJIS::CP932::MapUTF	PACKAGE = ShiftJIS::CP932::MapUTF

PROTOTYPES: DISABLE

void
cp932_to_unicode(...)
  ALIAS:
    cp932_to_utf8    = 1
    cp932_to_utf16le = 2
    cp932_to_utf16be = 3
    cp932_to_utf32le = 4
    cp932_to_utf32be = 5
  PREINIT:
    SV *src, *dst, *cvref, *mod;
    STRLEN srclen, dstlen, modlen, mblen, ulen;
    U8 *s, *e, *p, *d, *m, *m_e, uni[UTF8_MAXLEN + 1];
    UV uv;
    struct leading lb;
    U8* (*app_uv)(U8*, UV);
    bool mod_g, mod_s, mod_t;
  PPCODE:
    STMT_ASSIGN_CVREF_AND_SRC(funcname_to[ix])
    if (SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_downgrade(src, 0);
    }
    STMT_ASSIGN_LENDST(maxlen_to[ix])
    if (ix == 0)
	SvUTF8_on(dst);

    m = (U8*)SvPV(mod, modlen);
    for (p = m, m_e = m + modlen; p < m_e; p++) {
	if (*p == 'g' || *p == 's' || *p == 't')
	    continue;
    	croak("Unknown option in %s: '%c'", funcname_to[ix], *p);
    }
    mod_g = memchr((void*)m, 'g', modlen) != NULL;
    mod_s = memchr((void*)m, 's', modlen) != NULL;
    mod_t = memchr((void*)m, 't', modlen) != NULL;

    app_uv = app_uv_in[ix];

    if (cvref) {
	for (p = s; p < e; p += mblen) {
	    STMT_GET_MBLEN

	    if (!mblen) {
		sv_cat_retcvref(dst, cvref, newSVuv((UV)*p), TRUE);
		p++;
		continue;
	    }

	    STMT_GET_UV_FROM_MB

	    if (uv || !*p) {
		ulen = ix ? app_uv(uni, uv) - uni
			  : uvuni_to_utf8(uni, uv) - uni;
		sv_catpvn(dst, (char*)uni, ulen);
	    } else
		sv_cat_retcvref(dst, cvref, newSVpvn((char*)p, mblen), FALSE);
	}
    }
    else {
	d = (U8*)SvPVX(dst);
	for (p = s; p < e; p += mblen) {
	    STMT_GET_MBLEN

	    if (!mblen) {
		p++;
		continue;
	    }

	    STMT_GET_UV_FROM_MB

	    if (uv || !*p) {
		d = ix ? app_uv(d, uv) : uvuni_to_utf8(d, uv);
	    }
	}
	*d = '\0';
	SvCUR_set(dst, d - (U8*)SvPVX(dst));
    }
    XPUSHs(dst);


void
unicode_to_cp932(...)
  ALIAS:
    utf8_to_cp932    = 1
    utf16le_to_cp932 = 2
    utf16be_to_cp932 = 3
    utf32le_to_cp932 = 4
    utf32be_to_cp932 = 5
    utf16_to_cp932   = 6
    utf32_to_cp932   = 7
  PREINIT:
    SV *src, *dst, *cvref, *mod;
    STRLEN srclen, dstlen, modlen, retlen;
    U8 *s, *e, *p, *d, *m, *m_e, mbc[3];
    U16 j, *t;
    UV uv;
    UV (*ord_uv)(U8 *, STRLEN, STRLEN *);
    bool mod_g, mod_s, mod_f;
  PPCODE:
    STMT_ASSIGN_CVREF_AND_SRC(funcname_fm[ix])
    if (ix == 0 && !SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_upgrade(src);
    }
    else if (ix && SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_downgrade(src, FALSE);
    }
    STMT_ASSIGN_LENDST(maxlen_fm[ix])

    m = (U8*)SvPV(mod, modlen);
    for (p = m, m_e = m + modlen; p < m_e; p++) {
	if (*p == 'g' || *p == 's' || *p == 'f')
	    continue;
    	croak("Unknown option in %s: '%c'", funcname_fm[ix], *p);
    }
    mod_g = memchr((void*)m, 'g', modlen) != NULL;
    mod_s = memchr((void*)m, 's', modlen) != NULL;
    mod_f = memchr((void*)m, 'f', modlen) != NULL;

    ord_uv = ord_uv_in[ix];

    if (ix == 6 && 2 <= e - s) { /* UTF-16 */
	if (memEQ("\xFF\xFE",s,2)) {
	    s += 2;
	    ord_uv = ord_in_utf16le;
	}
	else if (memEQ("\xFE\xFF",s,2)) {
	    s += 2;
	}
    }
    else if (ix == 7 && 4 <= e - s) {  /* UTF-32 */
	if (memEQ("\xFF\xFE\x00\x00",s,4)) {
	    s += 4;
	    ord_uv = ord_in_utf32le;
	}
	else if (memEQ("\x00\x00\xFE\xFF",s,4)) {
	    s += 4;
	}
    }

    if (cvref) {
	for (p = s; p < e;) {
	    uv = ix
		? ord_uv(p, e - p, &retlen)
		: utf8n_to_uvuni(p, (e - p), &retlen, 0);

	    if (retlen)
		p += retlen;
	    else {
		sv_cat_retcvref(dst, cvref, newSVuv((UV)*p), TRUE);
		p++;
		continue;
	    }

	    if (mod_g && Is_CP932_PUAe(uv)) {
		uv -= CP932_PUA_BASE;
		mbc[0] = (U8)((uv / 188) + 0xF0);
		mbc[1] = (U8)(uv % 188 + (uv % 188 > 0x3E ? 0x41 : 0x40));
		sv_catpvn(dst, (char*)mbc, 2);
		continue;
	    }
	    if (mod_s && Is_CP932_PUAs(uv)) {
		mbc[0] = (U8) CP932_PUA2UDSB(uv);
		sv_catpvn(dst, (char*)mbc, 1);
		continue;
	    }

	    t = uv < 0x10000 ? tocp932_tbl[uv >> 8] : NULL;
	    j = t ? t[uv & 0xff] : 0;

	    if (mod_f && j == 0 && Is_CP932_L1FB(uv)) {
		j = (U16) CP932_FB2MB(uv);
	    }

	    if (j || !uv) {
		if (j >= 256) {
		    mbc[0] = (U8)(j >> 8);
		    mbc[1] = (U8)(j & 0xff);
		    sv_catpvn(dst, (char*)mbc, 2);
		}
		else {
		    mbc[0] = (U8)(j & 0xff);
		    sv_catpvn(dst, (char*)mbc, 1);
		}
	    } else
		sv_cat_retcvref(dst, cvref, newSVuv(uv), FALSE);
	}
    }
    else {
	d = (U8*)SvPVX(dst);
	for (p = s; p < e;) {
	    uv = ix
		? ord_uv(p, e - p, &retlen)
		: utf8n_to_uvuni(p, (e - p), &retlen, 0);

	    if (retlen)
		p += retlen;
	    else {
		p++;
		continue;
	    }

	    if (mod_g && Is_CP932_PUAe(uv)) {
		uv -= CP932_PUA_BASE;
		*d++ = (U8)((uv / 188) + 0xF0);
		*d++ = (U8)(uv % 188 + (uv % 188 > 0x3E ? 0x41 : 0x40));
		continue;
	    }
	    if (mod_s && Is_CP932_PUAs(uv)) {
		*d++ = (U8) CP932_PUA2UDSB(uv);
		continue;
	    }

	    t = uv < 0x10000 ? tocp932_tbl[uv >> 8] : NULL;
	    j = t ? t[uv & 0xff] : 0;

	    if (mod_f && j == 0 && Is_CP932_L1FB(uv)) {
		j = (U16) CP932_FB2MB(uv);
	    }

	    if (j || !uv) {
		if (j >= 256)
		    *d++ = (U8)(j >> 8);
		*d++ = (U8)(j & 0xff);
	    }
	}
	*d = '\0';
	SvCUR_set(dst, d - (U8*)SvPVX(dst));
    }
    XPUSHs(dst);

