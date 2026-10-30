#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef XS_VERSION
#undef XS_VERSION
#endif
#define XS_VERSION "2.600"

#define BASE 36
#define TMIN 1
#define TMAX 26
#define SKEW 38
#define DAMP 700
#define INITIAL_BIAS 72
#define INITIAL_N 128
#define UNICODE_MAX 0x10FFFF
#define PUNYCODE_MAXINT 0xFFFFFFFFUL

#define SURROGATE_MIN 0xD800
#define SURROGATE_MAX 0xDFFF
#define isSURROGATE(c) ((c) >= SURROGATE_MIN && (c) <= SURROGATE_MAX)

#define isBASE(x) UTF8_IS_INVARIANT((unsigned char)x)
#define DELIM '-'

#define TMIN_MAX(t)  (((t) < TMIN) ? (TMIN) : ((t) > TMAX) ? (TMAX) : (t))

#ifndef uvchr_to_utf8_flags
#define uvchr_to_utf8_flags(d, uv, flags) uvuni_to_utf8_flags(d, uv, flags);
#endif

#ifndef MEM_SIZE_MAX			/* perl 5.8.5 to 5.8.8 */
#define MEM_SIZE_MAX ((MEM_SIZE)-1)
#endif

#ifndef UTF8_ALLOW_FE_FF		/* perl 5.14 to 5.26 */
#define UTF8_ALLOW_FE_FF 0
#endif

static char enc_digit[BASE] = {
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
};

static IV dec_digit[0x80] = {
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 00..0F */
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 10..1F */
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 20..2F */
  26, 27, 28, 29, 30, 31, 32, 33, 34, 35, -1, -1, -1, -1, -1, -1, /* 30..3F */
  -1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, /* 40..4F */
  15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, /* 50..5F */
  -1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, /* 60..6F */
  15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, /* 70..7F */
};

static int adapt(UV delta, UV numpoints, int first) {
  int k;

  delta /= first ? DAMP : 2;
  delta += delta/numpoints;

  for(k=0; delta > ((BASE-TMIN) * TMAX)/2; k += BASE)
    delta /= BASE-TMIN;

  return k + (int)(((BASE-TMIN+1) * delta) / (delta+SKEW));
};

static void
grow_string(SV *const sv, char **start, char **current, char **end, STRLEN add)
{
  STRLEN len;

  if(*current + add <= *end)
    return;

  len = (*current - *start);
  *start = SvGROW(sv, (len + add + 15) & ~15);
  *current = *start + len;
  *end = *start + SvLEN(sv);
}

MODULE = Net::IDN::Punycode PACKAGE = Net::IDN::Punycode

SV*
encode_punycode(input)
		SV * input
	PREINIT:
		UV c, m, n = INITIAL_N;
		UV q, delta = 0, skip_delta;
		int k, t;
		int bias = INITIAL_BIAS;

		const char *in_s, *in_p, *in_e;
 		char *re_s, *re_p, *re_e;
		int first = 1;
		STRLEN length_guess, len, h, u8, count, i, skip;
		U32 cp_stack[256];
		U32 *cp_s;
		SV *cp_sv;

	CODE:
		/* SvPVutf8 would upgrade the caller's scalar */
		if(!SvUTF8(input))
		  input = sv_mortalcopy(input);
		in_s = in_p = SvPVutf8(input, len);
		in_e = in_s + len;

		if(!is_utf8_string((U8*)in_s, len))
		  croak("malformed UTF-8 in input for encode_punycode");

		/* every code point takes at least one byte */
		if(len < 256) {
		  cp_s = cp_stack;
		} else {
		  if(len > (MEM_SIZE_MAX - 1) / sizeof(U32))
		    croak("input too long for encode_punycode");
		  cp_sv = sv_2mortal(newSV(len * sizeof(U32)));
		  cp_s = (U32*)SvPVX(cp_sv);
		}

		count = 0;
		for(in_p = in_s; in_p < in_e; in_p += u8) {
		  c = utf8n_to_uvchr((U8*)in_p, in_e - in_p, &u8,
		    UTF8_CHECK_ONLY|UTF8_ALLOW_SURROGATE|UTF8_ALLOW_FFFF|
		    UTF8_ALLOW_FE_FF);
		  if(u8 == (STRLEN)-1)
		    croak("malformed UTF-8 in input for encode_punycode");
		  c = NATIVE_TO_UNI(c);
		  if(c > UNICODE_MAX || isSURROGATE(c))
		    croak("invalid code point");
		  cp_s[count++] = (U32)c;
		}

		length_guess = len;
		if(length_guess < 64) length_guess = 64;	/* optimise for maximum length of domain names */
		length_guess += 2;				/* plus DELIM + '\0' */

		RETVAL = NEWSV('P',length_guess);
		sv_2mortal(RETVAL);		/* freed on croak */
		SvPOK_only(RETVAL);
		re_s = re_p = SvPV_nolen(RETVAL);
		re_e = re_s + SvLEN(RETVAL);
		h = 0;

		/* copy basic code points */
		for(i = 0; i < count; i++) {
		  if(cp_s[i] < INITIAL_N) {
		    grow_string(RETVAL, &re_s, &re_p, &re_e, sizeof(char));
		    *re_p++ = (char)UNI_TO_NATIVE(cp_s[i]);
		    h++;
		  }
		}

		/* add DELIM if needed */
		if(h) {
                  grow_string(RETVAL, &re_s, &re_p, &re_e, sizeof(char));
		  *re_p++ = DELIM;
		}

		for(;;) {
		  /* find smallest code point not yet handled */
		  m = UNICODE_MAX + 1;
		  q = skip_delta = 0;
		  skip = 0;

		  for(i = 0; i < count; i++) {
		    c = cp_s[i];
		    if(c >= n && c < m) {
		      m = c;
		      skip = i;
		      skip_delta = q;
		    }
		    if(c < n)
		      ++q;
		  }
		  if(m > UNICODE_MAX)
		    break;

		  /* increase delta to the state corresponding to
		     the m code point at the beginning of the string */
		  if(m - n > (PUNYCODE_MAXINT - delta) / (h+1))
		    croak("input exceeds punycode limit");
		  delta += (m-n) * (h+1);
		  n = m;

		  /* now find the chars to be encoded in this round */

		  if(skip_delta > PUNYCODE_MAXINT - delta)
		    croak("input exceeds punycode limit");
		  delta += skip_delta;
		  for(i = skip; i < count; i++) {
		    c = cp_s[i];

		    if(c < n) {
		      /* delta resets at c == n, so reaching this
		         takes PUNYCODE_MAXINT characters */
		      if(delta == PUNYCODE_MAXINT)
		        croak("input exceeds punycode limit");
		      ++delta;
                    } else if( c == n ) {
		      q = delta;

		      for(k = BASE;; k += BASE) {
			t = TMIN_MAX(k - bias);
			if(q < t) break;
		        grow_string(RETVAL, &re_s, &re_p, &re_e, sizeof(char));
			*re_p++ = enc_digit[t + ((q-t) % (BASE-t))];
		        q = (q-t) / (BASE-t);
  		      }
		      /* q < t <= TMAX < BASE, but guard enc_digit[q] anyway */
		      if(q >= BASE) croak("input exceeds punycode limit");
		      grow_string(RETVAL, &re_s, &re_p, &re_e, sizeof(char));
	              *re_p++ = enc_digit[q];
		      bias = adapt(delta, h+1, first);
                      delta = first = 0;
		      ++h;
                    }
		  }
		  /* delta resets at c == n, so reaching this takes
		     PUNYCODE_MAXINT characters */
		  if(delta == PUNYCODE_MAXINT)
		    croak("input exceeds punycode limit");
		  ++delta;
		  ++n;
		}
		grow_string(RETVAL, &re_s, &re_p, &re_e, sizeof(char));
		*re_p = 0;
		SvCUR_set(RETVAL, re_p - re_s);
		SvREFCNT_inc(RETVAL);		/* the typemap mortalises it */

	OUTPUT:
		RETVAL

SV*
decode_punycode(input)
		SV * input
	PREINIT:
		UV c, n = INITIAL_N;
		IV dc;
		UV i = 0, oldi, j, w;
		int k, t;

		int bias = INITIAL_BIAS;

		const char *in_s, *in_p, *in_e, *skip_p;
		char *re_s, *re_p;
		int first = 1;
		STRLEN len, h, total, cp_max;
		U32 cp_stack[256];
		U32 *cp_s;
		SV *cp_sv;

	CODE:
		in_s = in_p = SvPV(input, len);
		in_e = in_s + len;

		skip_p = NULL;
		for(in_p = in_s; in_p < in_e; in_p++) {
		  c = *in_p;					/* we don't care whether it's UTF-8 */
		  if(!isBASE(c))
		    croak("non-base character in input for decode_punycode");
		  if(c == DELIM) skip_p = in_p;
		}

		if(skip_p) {
		  h = skip_p - in_s;				/* base chars handled */
		  skip_p++;					/* skip over DELIM */
                } else {
		  h = 0;					/* no base chars */
		  skip_p = in_s;				/* read everything */
		}

		/* every insertion consumes at least one digit byte */
		cp_max = h + (in_e - skip_p) + 1;
		if(cp_max <= 256) {
		  cp_s = cp_stack;
		} else {
		  if(cp_max > (MEM_SIZE_MAX - 1) / sizeof(U32))
		    croak("input too long for decode_punycode");
		  cp_sv = sv_2mortal(newSV(cp_max * sizeof(U32)));
		  cp_s = (U32*)SvPVX(cp_sv);
		}
		for(j = 0; j < h; j++)
		  cp_s[j] = (unsigned char)in_s[j];	/* copy base chars */

		for(in_p = skip_p; in_p < in_e; i++) {
		  oldi = i;
		  w = 1;

	          for(k = BASE;; k+= BASE) {
		    if(!(in_p < in_e))
		      croak("incomplete encoded code point in decode_punycode");
		    dc = dec_digit[*in_p++];			/* we already know it's in 0..127 */
		    if(dc < 0)
		      croak("invalid digit in input for decode_punycode");
		    c = (UV)dc;
		    if(c > (PUNYCODE_MAXINT - i) / w)
		      croak("input exceeds punycode limit");
		    i += c * w;
		    t = TMIN_MAX(k - bias);
		    if(c < t) break;
		    /* the overflow check of RFC 3492 section 6.2 */
		    if(w > PUNYCODE_MAXINT / (BASE-t))
		      croak("input exceeds punycode limit");
		    w *= BASE-t;
		  }
		  h++;
		  bias = adapt(i-oldi, h, first);
		  first = 0;
		  /* adding first wraps a 32-bit UV */
		  if(i / h > UNICODE_MAX - n)
		    croak("invalid code point");
		  n += i / h;					/* code point n to insert */
		  if(isSURROGATE(n))		/* not a Unicode scalar value */
		    croak("invalid code point");
	          i = i % h;					/* at position i */

		  if(i < h-1)			/* move succeeding chars */
		    Move(cp_s + i, cp_s + i + 1, (h-1) - i, U32);
		  cp_s[i] = (U32)n;
		}

		total = 0;
		for(j = 0; j < h; j++)
		  total += UNISKIP(cp_s[j]);

		RETVAL = newSV(total + 1);
		sv_2mortal(RETVAL);		/* freed on croak */
		SvPOK_only(RETVAL);
		re_s = re_p = SvPV_nolen(RETVAL);
		for(j = 0; j < h; j++) {
		  if(UNI_IS_INVARIANT(cp_s[j]))
		    *re_p++ = (char)cp_s[j];
		  else
		    re_p = (char*)uvchr_to_utf8_flags((U8*)re_p, cp_s[j],
		      UNICODE_ALLOW_ANY);
		}

		if(!first) SvUTF8_on(RETVAL);			/* UTF-8 chars have been inserted */
		*re_p = 0;
		SvCUR_set(RETVAL, re_p - re_s);
		SvREFCNT_inc(RETVAL);		/* the typemap mortalises it */
	OUTPUT:
		RETVAL
