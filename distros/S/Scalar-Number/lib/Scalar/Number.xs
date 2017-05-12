#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#define Q_IOK_MAYBE_SPURIOUS (!PERL_VERSION_GE(5,7,1))
#define Q_STRING_ZERO_FLOATS PERL_VERSION_GE(5,13,6)

/*
 * The way an SV is interpreted for its numerical value varies between Perl
 * versions.  The new way (perl 5.7.1+) is that the IOK and NOK flags
 * strictly indicate that the numerical value is acceptably represented by
 * the corresponding field.  The old way (up to perl 5.7.0) is that the IOK
 * and NOK flags indicate that the corresponding field is filled, but it
 * might be a conversion from the other form.  In the old form, most
 * arithmetic is floating point, so to handle an integer that can't be
 * represented in floating point it must be specially processed using
 * integer-only operations, and so won't have NOK set.  So the rules are:
 *
 * STYLE IOK  NOK
 * old   no   no   use string_2num() to numerify, then try again
 * old   no   yes  use NV
 * old   yes  no   use IV/UV
 * old   yes  yes  use NV
 * new   no   no   use string_2num() to numerify, then try again
 * new   no   yes  use NV
 * new   yes  no   use IV/UV
 * new   yes  yes  use IV/UV
 *
 * Which set of rules applies is controlled by the Q_IOK_MAYBE_SPURIOUS flag.
 */

/*
 * string_2num() resolves a string SV into one that has the same numeric
 * value and has that numeric value expressed directly in the SV structure
 * (as either an IV, UV, or NV).  A mortal reference to the resulting SV
 * is returned.  The resulting SV is not necessarily a pure number; it may
 * have an unrelated string value.  Warns for non-numeric strings.
 */

#define string_2num(s) THX_string_2num(aTHX_ s)
static SV *THX_string_2num(pTHX_ SV *s)
{
	if(SvIOK(s) || SvNOK(s)) return s;
	s = sv_mortalcopy(s);
	if(!Q_IOK_MAYBE_SPURIOUS && (SvIV(s), SvIOK(s))) {
		if(Q_HAVE_SIGNED_ZERO && SvIVX(s) == 0) {
			/* It's a zero, and asking for SvIV has squashed
			 * it to an integer zero, but it wouldn't
			 * necessarily be considered an integer zero
			 * by other operations.  We seek to match the
			 * behaviour of the printf("%.f")-based test,
			 * thus regarding the behaviour of the negate
			 * operation canonical.
			 */
			if(Q_STRING_ZERO_FLOATS) {
				/* String zeroes now always turn into
				 * floating-point zeroes.
				 */
				sv_setnv(s, SvNV(s));
			} else {
				/* Preserve sign iff the string value
				 * starts with a sign character.
				 */
				char c = *SvPV_nolen(s);
				if(c == '-') {
					sv_setnv(s, -0.0);
					SvIOK_off(s);
				} else if(c == '+') {
					sv_setnv(s, 0.0);
					SvIOK_off(s);
				} else {
					sv_setiv(s, 0);
					SvNOK_off(s);
				}
			}
		}
	} else {
		NV val = SvNV(s);
		if(!SvNOK(s)) sv_setnv(s, val);
	}
	return s;
}

/*
 * numscl_val_cmp() does a value comparison on two scalars that express
 * their numeric values directly.  It must not be called on general
 * scalars.
 */

/* These variables store the values min_natint and max_natint+1,
   respectively, in floating-point form.  They are initialised by
   the boot function. */
static NV neg_natint_limit, pos_natint_limit;

#define numscl_val_cmp(a, b) THX_numscl_val_cmp(aTHX_ a, b)
static SV *THX_numscl_val_cmp(pTHX_ SV *a, SV *b)
{
	bool aiok, biok;
	int result;
	aiok = Q_IOK_MAYBE_SPURIOUS ? !SvNOK(a) : !!SvIOK(a);
	biok = Q_IOK_MAYBE_SPURIOUS ? !SvNOK(b) : !!SvIOK(b);
	if(aiok && biok) {
		if(SvIOK_UV(a)) {
			if(SvIOK_UV(b)) {
				UV au = SvUVX(a), bu = SvUVX(b);
				result = au < bu ? -1 : au == bu ? 0 : +1;
			} else {
				UV au = SvUVX(a);
				IV bi = SvIVX(b);
				result = bi < 0 ? +1 :
					au < ((UV)bi) ? -1 :
					au == ((UV)bi) ? 0 : +1;
			}
		} else {
			if(SvIOK_UV(b)) {
				IV ai = SvIVX(a);
				UV bu = SvUVX(b);
				result = ai < 0 ? -1 :
					((UV)ai) < bu ? -1 :
					((UV)ai) == bu ? 0 : +1;
			} else {
				IV ai = SvIVX(a), bi = SvIVX(b);
				result = ai < bi ? -1 : ai == bi ? 0 : +1;
			}
		}
	} else if(SvNOK(a) && SvNOK(b)) {
		NV an = SvNVX(a);
		NV bn = SvNVX(b);
		if(an != an || bn != bn)
			return &PL_sv_undef;
		result = an < bn ? -1 : an == bn ? 0 : +1;
	} else {
		bool reversed = biok;
		SV *x = reversed ? b : a, *y = reversed ? a : b;
		NV yn = SvNVX(y);
		UV xu;
		if(yn != yn)
			return &PL_sv_undef;
		if(SvIOK_UV(x)) {
			xu = SvUVX(x);
		} else {
			IV xi = SvIVX(x);
			xu = (UV)xi;
			if(xi < 0) {
				xu = -xu;
				yn = -yn;
				reversed = !reversed;
			}
		}
		if(yn < 0.0) {
			result = +1;
		} else if(yn >= pos_natint_limit) {
			result = -1;
		} else {
			UV yu = yn;
			result = xu < yu ? -1 : xu > yu ? +1 :
				yn - ((NV)yu) == 0.0 ? 0 : -1;
		}
		if(reversed)
			result = -result;
	}
	return newSViv(result);
}

MODULE = Scalar::Number PACKAGE = Scalar::Number

PROTOTYPES: DISABLE

BOOT:
{
	int i;
	neg_natint_limit = -1.0;
	pos_natint_limit = +2.0;
	for(i = Q_NATINT_BITS; --i; ) {
		neg_natint_limit += neg_natint_limit;
		pos_natint_limit += pos_natint_limit;
	}
}

SV *
_warnable_scalar_num_part(SV *scalar)
PROTOTYPE: $
CODE:
	while(!SvIOK(scalar) && !SvNOK(scalar) && SvROK(scalar)) {
		if(SvAMAGIC(scalar)) {
			SV *t = AMG_CALLun(scalar, numer);
			if(t && (!SvROK(t) || SvRV(t) != SvRV(scalar))) {
				scalar = t;
				continue;
			}
		}
		scalar = sv_2mortal(newSVuv(PTR2UV(SvRV(scalar))));
	}
	scalar = string_2num(scalar);
	if(Q_IOK_MAYBE_SPURIOUS && SvNOK(scalar)) {
		RETVAL = newSVnv(SvNVX(scalar));
	} else if(SvIOK_notUV(scalar)) {
		RETVAL = newSViv(SvIVX(scalar));
	} else if(SvIOK_UV(scalar)) {
		RETVAL = newSVuv(SvUVX(scalar));
	} else {
		RETVAL = newSVnv(SvNVX(scalar));
	}
OUTPUT:
	RETVAL

bool
sclnum_is_natint(SV *scalar)
PROTOTYPE: $
CODE:
	scalar = string_2num(scalar);
	if(Q_IOK_MAYBE_SPURIOUS ? !SvNOK(scalar) : SvIOK(scalar)) {
		RETVAL = 1;
	} else {
		NV val = SvNVX(scalar);
		if(Q_HAVE_SIGNED_ZERO && val == 0.0) {
			RETVAL = 0;
		} else if(val < 0.0) {
			RETVAL = val >= neg_natint_limit &&
					((NV)(IV)val) == val;
		} else {
			RETVAL = val < pos_natint_limit &&
					((NV)(UV)val) == val;
		}
	}
OUTPUT:
	RETVAL

bool
sclnum_is_float(SV *scalar)
PROTOTYPE: $
CODE:
	scalar = string_2num(scalar);
	if(SvNOK(scalar)) {
		RETVAL = !(Q_HAVE_SIGNED_ZERO && !Q_IOK_MAYBE_SPURIOUS &&
				SvIOK(scalar) && SvIVX(scalar) == 0);
	} else {
		UV mag = SvIOK_UV(scalar) ? SvUVX(scalar) :
			SvIVX(scalar) < 0 ? -(UV)SvIVX(scalar) : SvIVX(scalar);
		if(Q_HAVE_SIGNED_ZERO && mag == 0) {
			RETVAL = 0;
		} else {
#if Q_SIGNIFICAND_BITS+1 >= Q_NATINT_BITS
			/* all native integers are representable as floats
			 * (except possibly zero, handled above)
			 */
			RETVAL = 1;
#else /* Q_SIGNIFICAND_BITS+1 < Q_NATINT_BITS */
			/* check length of integer */
			RETVAL = 1;
			while(mag >= (((UV)1) << (Q_SIGNIFICAND_BITS+1))) {
				if(mag & 1) {
					RETVAL = 0;
					break;
				}
				mag >>= 1;
			}
#endif /* Q_SIGNIFICAND_BITS+1 < Q_NATINT_BITS */
		}
	}
OUTPUT:
	RETVAL

SV *
sclnum_val_cmp(SV *a, SV *b)
PROTOTYPE: $$
CODE:
	RETVAL = numscl_val_cmp(string_2num(a), string_2num(b));
OUTPUT:
	RETVAL

SV *
sclnum_id_cmp(SV *a, SV *b)
PROTOTYPE: $$
PREINIT:
	bool aiok, biok;
	bool anan, bnan;
CODE:
	a = string_2num(a);
	b = string_2num(b);
	aiok = Q_IOK_MAYBE_SPURIOUS ? !SvNOK(a) : !!SvIOK(a);
	biok = Q_IOK_MAYBE_SPURIOUS ? !SvNOK(b) : !!SvIOK(b);
	anan = !aiok && SvNVX(a) != SvNVX(a);
	bnan = !biok && SvNVX(b) != SvNVX(b);
	if(anan || bnan) {
		RETVAL = newSViv(bnan - anan);
	} else if(Q_HAVE_SIGNED_ZERO &&
			(aiok ? SvUVX(a) == 0 : SvNVX(a) == 0.0) &&
			(biok ? SvUVX(b) == 0 : SvNVX(b) == 0.0)) {
		int atype, btype;
		char tbuf[3];
		if(aiok) {
			atype = 0;
		} else {
			sprintf(tbuf, "%+.f", (double)SvNVX(a));
			atype = tbuf[0] == '-' ? -1 : +1;
		}
		if(biok) {
			btype = 0;
		} else {
			sprintf(tbuf, "%+.f", (double)SvNVX(b));
			btype = tbuf[0] == '-' ? -1 : +1;
		}
		RETVAL = newSViv(atype < btype ? -1 : atype == btype ? 0 : +1);
	} else {
		RETVAL = numscl_val_cmp(a, b);
	}
OUTPUT:
	RETVAL
