#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "sxmuni.h"

#include "fmsj0213.h"
#include "tosj0213.h"

#define PkgName "ShiftJIS::X0213::MapUTF"

#define Is_SJIS_SNG(i)   (0x00<=(i) && (i)<=0x7F || 0xA1<=(i) && (i)<=0xDF)
#define Is_SJIS_LED(i)   (0x81<=(i) && (i)<=0x9F || 0xE0<=(i) && (i)<=0xFC)
#define Is_SJIS_TRL(i)   (0x40<=(i) && (i)<=0x7E || 0x80<=(i) && (i)<=0xFC)

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


#define STMT_ASSIGN_LENDST(maxlen)		\
    s = (U8*)SvPV(src,srclen);			\
    e = s + srclen;				\
    dstlen = srclen * maxlen + 1;		\
    dst = sv_2mortal(newSV(dstlen));		\
    (void)SvPOK_only(dst);


#define STMT_GET_MBLEN				\
    mblen = Is_SJIS_LED(*(p)) && 2 <= (e - p)	\
	? (Is_SJIS_TRL((p)[1])) ? 2 : 0		\
	: Is_SJIS_SNG(*(p)) ? 1 : 0;


#define STMT_GET_UV_FROM_MB			\
    lb = fmsjis0213_tbl[*p];			\
    uv = lb.tbl ? lb.tbl[p[1]] : lb.sbc;	\
    if (!use2004 && isADDED2004(uv))		\
	uv = 0;


#define STMT_FETCH_FROM_UV_AND_UV2		\
    j = 0;					\
    if (p < e && isbase(uv)) {			\
	uv2 = id_utf				\
	    ? ord_uv(p, e - p, &retlen)		\
	    : utf8n_to_uvuni(p, (e - p), &retlen, 0);	\
	if (retlen)				\
	    j = (U16)getcomposite(uv, uv2);	\
	if (j)					\
	    p += retlen;			\
    }						\
    if (!use2004 && isADDED2004(uv))		\
	j = 0;					\
    else if (!j) {				\
        tbl_plain = Is_VALID_UTF(uv)		\
	    ? tosjis0213_tbl[uv >> 16]		\
	    : NULL;				\
	tbl_row = tbl_plain			\
	    ? tbl_plain[(uv >> 8) & 0xff]	\
	    : NULL;				\
	j = tbl_row ? tbl_row[uv & 0xff] : 0;	\
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

#define NUM_toUTF    (6)
#define NUM_fromUTF  (8)

static char* funcname_to[2 * NUM_toUTF] = {
    "sjis2004_to_unicode",
    "sjis2004_to_utf8",
    "sjis2004_to_utf16le",
    "sjis2004_to_utf16be",
    "sjis2004_to_utf32le",
    "sjis2004_to_utf32be",
    "sjis0213_to_unicode",
    "sjis0213_to_utf8",
    "sjis0213_to_utf16le",
    "sjis0213_to_utf16be",
    "sjis0213_to_utf32le",
    "sjis0213_to_utf32be",
};

static char* funcname_fm[2 * NUM_fromUTF] = {
    "unicode_to_sjis2004",
       "utf8_to_sjis2004",
    "utf16le_to_sjis2004",
    "utf16be_to_sjis2004",
    "utf32le_to_sjis2004",
    "utf32be_to_sjis2004",
      "utf16_to_sjis2004",
      "utf32_to_sjis2004",
    "unicode_to_sjis0213",
       "utf8_to_sjis0213",
    "utf16le_to_sjis0213",
    "utf16be_to_sjis0213",
    "utf32le_to_sjis0213",
    "utf32be_to_sjis0213",
      "utf16_to_sjis0213",
      "utf32_to_sjis0213",
};

static STRLEN maxlen_to[NUM_toUTF] = {
    MaxLenToUni,
    MaxLenToU8,
    MaxLenToU16,
    MaxLenToU16,
    MaxLenToU32,
    MaxLenToU32,
};

static STRLEN maxlen_fm[NUM_fromUTF] = {
    MaxLenFmUni,
    MaxLenFmU8,
    MaxLenFmU16,
    MaxLenFmU16,
    MaxLenFmU32,
    MaxLenFmU32,
    MaxLenFmU16,
    MaxLenFmU32,
};

static U8* (*app_uv_in[NUM_toUTF])(U8*, UV) = {
    NULL,
    app_in_utf8,
    app_in_utf16le,
    app_in_utf16be,
    app_in_utf32le,
    app_in_utf32be,
};

static UV (*ord_uv_in[NUM_fromUTF])(U8 *, STRLEN, STRLEN *) = {
    NULL,
    ord_in_utf8,
    ord_in_utf16le,
    ord_in_utf16be,
    ord_in_utf32le,
    ord_in_utf32be,
    ord_in_utf16be, /* w/o BOM*/
    ord_in_utf32be, /* w/o BOM*/
};

MODULE = ShiftJIS::X0213::MapUTF	PACKAGE = ShiftJIS::X0213::MapUTF

PROTOTYPES: DISABLE

void
sjis2004_to_unicode (...)
  ALIAS:
    sjis2004_to_utf8    = 1
    sjis2004_to_utf16le = 2
    sjis2004_to_utf16be = 3
    sjis2004_to_utf32le = 4
    sjis2004_to_utf32be = 5
    sjis0213_to_unicode = 6
    sjis0213_to_utf8    = 7
    sjis0213_to_utf16le = 8
    sjis0213_to_utf16be = 9
    sjis0213_to_utf32le = 10
    sjis0213_to_utf32be = 11
  PREINIT:
    SV *src, *dst, *cvref;
    STRLEN srclen, dstlen, mblen, ulen;
    U8 *s, *e, *p, *d, uni[UTF8_MAXLEN + 1];
    UV uv, u_temp;
    struct leading lb;
    U8* (*app_uv)(U8*, UV);
    int  id_utf, use2004;
  PPCODE:
    use2004 = ix < NUM_toUTF;
    id_utf  = ix % NUM_toUTF;

    STMT_ASSIGN_CVREF_AND_SRC(funcname_to[ix])
    if (SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_downgrade(src, 0);
    }
    STMT_ASSIGN_LENDST(maxlen_to[id_utf])
    if (id_utf == 0)
	SvUTF8_on(dst);

    app_uv = app_uv_in[id_utf];

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
		if (Is_VALID_UTF(uv)) {
		    ulen = id_utf ? app_uv(uni, uv) - uni
				  : uvuni_to_utf8(uni, uv) - uni;
		    sv_catpvn(dst, (char*)uni, ulen);
		}
		else {
		    u_temp = (uv >> 16);
		    ulen = id_utf ? app_uv(uni, u_temp) - uni
				  : uvuni_to_utf8(uni, u_temp) - uni;
		    sv_catpvn(dst, (char*)uni, ulen);

		    u_temp = (uv & 0xFFFF);
		    ulen = id_utf ? app_uv(uni, u_temp) - uni
				  : uvuni_to_utf8(uni, u_temp) - uni;
		    sv_catpvn(dst, (char*)uni, ulen);
		}
	    }
	    else
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
		if (Is_VALID_UTF(uv)) {
		    d = id_utf ? app_uv(d, uv) : uvuni_to_utf8(d, uv);
		}
		else {
		    u_temp = (uv >> 16);
		    d = id_utf ? app_uv(d, u_temp) : uvuni_to_utf8(d, u_temp);

		    u_temp = (uv & 0xFFFF);
		    d = id_utf ? app_uv(d, u_temp) : uvuni_to_utf8(d, u_temp);
		}
	    }
	}
	*d = '\0';
	SvCUR_set(dst, d - (U8*)SvPVX(dst));
    }
    XPUSHs(dst);


void
unicode_to_sjis2004 (...)
  ALIAS:
       utf8_to_sjis2004 = 1
    utf16le_to_sjis2004 = 2
    utf16be_to_sjis2004 = 3
    utf32le_to_sjis2004 = 4
    utf32be_to_sjis2004 = 5
      utf16_to_sjis2004 = 6
      utf32_to_sjis2004 = 7
    unicode_to_sjis0213 = 8
       utf8_to_sjis0213 = 9
    utf16le_to_sjis0213 = 10
    utf16be_to_sjis0213 = 11
    utf32le_to_sjis0213 = 12
    utf32be_to_sjis0213 = 13
      utf16_to_sjis0213 = 14
      utf32_to_sjis0213 = 15
  PREINIT:
    SV *src, *dst, *cvref;
    STRLEN srclen, dstlen, retlen;
    U8 *s, *e, *p, *d, mbc[3];
    U16 j, *tbl_row, **tbl_plain;
    UV uv, uv2;
    UV (*ord_uv)(U8 *, STRLEN, STRLEN *);
    int  id_utf, use2004;
  PPCODE:
    use2004 = ix < NUM_fromUTF;
    id_utf  = ix % NUM_fromUTF;

    STMT_ASSIGN_CVREF_AND_SRC(funcname_fm[ix])
    if (id_utf == 0 && !SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_upgrade(src);
    }
    else if (id_utf && SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_downgrade(src, FALSE);
    }
    STMT_ASSIGN_LENDST(maxlen_fm[id_utf])

    ord_uv = ord_uv_in[id_utf];

    if (id_utf == 6 && 2 <= e - s) { /* UTF-16 */
	if (memEQ("\xFF\xFE",s,2)) {
	    s += 2;
	    ord_uv = ord_in_utf16le;
	}
	else if (memEQ("\xFE\xFF",s,2)) {
	    s += 2;
	}
    }
    else if (id_utf == 7 && 4 <= e - s) { /* UTF-32 */
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
	    uv = id_utf
		? ord_uv(p, e - p, &retlen)
		: utf8n_to_uvuni(p, (e - p), &retlen, 0);

	    if (retlen)
		p += retlen;
	    else {
		sv_cat_retcvref(dst, cvref, newSVuv((UV)*p), TRUE);
		p++;
		continue;
	    }

	    STMT_FETCH_FROM_UV_AND_UV2

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
	    }
	    else
		sv_cat_retcvref(dst, cvref, newSVuv(uv), FALSE);
	}
    }
    else {
	d = (U8*)SvPVX(dst);

	for (p = s; p < e;) {
	    uv = id_utf
		? ord_uv(p, e - p, &retlen)
		: utf8n_to_uvuni(p, (e - p), &retlen, 0);

	    if (retlen)
		p += retlen;
	    else {
		p++;
		continue;
	    }

	    STMT_FETCH_FROM_UV_AND_UV2

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

