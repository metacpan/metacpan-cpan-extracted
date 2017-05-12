#ifndef SCMUNI_H
#define SCMUNI_H

#define VALID_UTF_MAX		(0x10FFFF)
#define Is_VALID_UTF(uv)	((uv) <= VALID_UTF_MAX)

#define UTF16_IS_SURROG(uv)	(0xD800 <= (uv) && (uv) <= 0xDFFF)
#define UTF16_HI_SURROG(uv)	(0xD800 <= (uv) && (uv) <= 0xDBFF)
#define UTF16_LO_SURROG(uv)	(0xDC00 <= (uv) && (uv) <= 0xDFFF)

#define UTF8A_SKIP(uv)	\
	( (uv) < 0x80           ? 1 : \
	  (uv) < 0x800          ? 2 : \
	  (uv) < 0x10000        ? 3 : \
	  (uv) < 0x200000       ? 4 : \
	  (uv) < 0x4000000      ? 5 : \
	  (uv) < 0x80000000     ? 6 : 7 )

#define UTF8A_TRAIL(c)	(((c) & 0xC0) == 0x80)

static UV
ord_in_utf16le(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    UV uv, luv;
    U8 *p = s;

    if (curlen < 2) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    uv = (UV)((p[1] << 8) | p[0]);
    p += 2;

    if (UTF16_HI_SURROG(uv) && (4 <= curlen)) {
	luv = (UV)((p[1] << 8) | p[0]);

	if (UTF16_LO_SURROG(luv)) {
	    uv = 0x10000 + ((uv-0xD800) * 0x400) + (luv-0xDC00);
	    p += 2;
	}
    }

    if (retlen)
	*retlen = p - s;
    return uv;
}


static UV
ord_in_utf16be(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    UV uv, luv;
    U8 *p = s;

    if (curlen < 2) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    uv = (UV)((p[0] << 8) | p[1]);
    p += 2;

    if (UTF16_HI_SURROG(uv) && (4 <= curlen)) {
	luv = (UV)((p[0] << 8) | p[1]);

	if (UTF16_LO_SURROG(luv)) {
	    uv = 0x10000 + ((uv-0xD800) * 0x400) + (luv-0xDC00);
	    p += 2;
	}
    }

    if (retlen)
	*retlen = p - s;
    return uv;
}


static UV
ord_in_utf32le(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    if (curlen < 4) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    if (retlen)
	*retlen = 4;
    return (UV)((s[3] << 24) | (s[2] << 16) | (s[1] << 8) | s[0]);
}


static UV
ord_in_utf32be(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    if (curlen < 4) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    if (retlen)
	*retlen = 4;
    return (UV)((s[0] << 24) | (s[1] << 16) | (s[2] << 8) | s[3]);
}


static UV
ord_in_utf8(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    UV uv = 0;
    STRLEN len, i;

    if (curlen == 0) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    len = *s < 0x80 ? 1 :
	  *s < 0xC0 ? 0 :
	  *s < 0xE0 ? 2 :
	  *s < 0xF0 ? 3 :
	  *s < 0xF8 ? 4 : 0;

    if (curlen < len || len == 0) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    if (*s < 0x80) {
	uv = (UV)*s;
    }
    else if (*s < 0xE0) {
	uv = (UV)(((s[0] & 0x1f) << 6) | (s[1] & 0x3f));
    }
    else if (*s < 0xF0) {
	uv = (UV)(((s[0] & 0x0f) << 12) |
		  ((s[1] & 0x3f) <<  6) | (s[2] & 0x3f));
    }
    else if (*s < 0xF8) {
	uv = (UV)(((s[0] & 0x07) << 18) | ((s[1] & 0x3f) << 12) |
		  ((s[2] & 0x3f) <<  6) |  (s[3] & 0x3f));
    }

    for (i = 1; i < len; i++) {
	if (!UTF8A_TRAIL(s[i])) {
	    len = 0;
	    break;
	}
    }

    if (len != (STRLEN) UTF8A_SKIP(uv))
	len = 0;

    if (retlen)
	*retlen = len;
    return uv;
}


static U8*
app_in_utf16le(U8* s, UV uv)
{
    if (uv <= 0xFFFF) {
	*s++ = (U8)(uv & 0xff);
	*s++ = (U8)(uv >> 8);
    }
    else if (Is_VALID_UTF(uv)) {
	int hi, lo;
	uv -= 0x10000;
	hi = (0xD800 | (uv >> 10));
	lo = (0xDC00 | (uv & 0x3FF));
	*s++ = (U8)(hi & 0xff);
	*s++ = (U8)(hi >> 8);
	*s++ = (U8)(lo & 0xff);
	*s++ = (U8)(lo >> 8);
    }
    return s;
}


static U8*
app_in_utf16be(U8* s, UV uv)
{
    if (uv <= 0xFFFF) {
	*s++ = (U8)(uv >> 8);
	*s++ = (U8)(uv & 0xff);
    }
    else if (Is_VALID_UTF(uv)) {
	int hi, lo;
	uv -= 0x10000;
	hi = (0xD800 | (uv >> 10));
	lo = (0xDC00 | (uv & 0x3FF));
	*s++ = (U8)(hi >> 8);
	*s++ = (U8)(hi & 0xff);
	*s++ = (U8)(lo >> 8);
	*s++ = (U8)(lo & 0xff);
    }
    return s;
}


static U8*
app_in_utf32le(U8* s, UV uv)
{
    if (Is_VALID_UTF(uv)) {
	*s++ = (U8)((uv      ) & 0xff);
	*s++ = (U8)((uv >>  8) & 0xff);
	*s++ = (U8)((uv >> 16) & 0xff);
	*s++ = (U8)((uv >> 24) & 0xff);
    }
    return s;
}


static U8*
app_in_utf32be(U8* s, UV uv)
{
    if (Is_VALID_UTF(uv)) {
	*s++ = (U8)((uv >> 24) & 0xff);
	*s++ = (U8)((uv >> 16) & 0xff);
	*s++ = (U8)((uv >>  8) & 0xff);
	*s++ = (U8)((uv      ) & 0xff);
    }
    return s;
}


static U8*
app_in_utf8(U8* s, UV uv)
{
    if (uv < 0x80) {
	*s++ = (U8)(uv & 0xff);
    }
    else if (uv < 0x800) {
	*s++ = (U8)(( uv >>  6)         | 0xc0);
	*s++ = (U8)(( uv        & 0x3f) | 0x80);
    }
    else if (uv < 0x10000) {
	*s++ = (U8)(( uv >> 12)         | 0xe0);
	*s++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*s++ = (U8)(( uv        & 0x3f) | 0x80);
    }
    else if (Is_VALID_UTF(uv)) {
	*s++ = (U8)(( uv >> 18)         | 0xf0);
	*s++ = (U8)(((uv >> 12) & 0x3f) | 0x80);
	*s++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*s++ = (U8)(( uv        & 0x3f) | 0x80);
    }
    return s;
}

#endif
