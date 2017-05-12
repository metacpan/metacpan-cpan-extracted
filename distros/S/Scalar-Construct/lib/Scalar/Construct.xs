#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

static bool svt_scalar(svtype t)
{
	switch(t) {
		case SVt_NULL: case SVt_IV: case SVt_NV:
#if !PERL_VERSION_GE(5,11,0)
		case SVt_RV:
#endif /* <5.11.0 */
		case SVt_PV: case SVt_PVIV: case SVt_PVNV:
		case SVt_PVMG: case SVt_PVLV: case SVt_PVGV:
#if PERL_VERSION_GE(5,11,0)
		case SVt_REGEXP:
#endif /* >=5.11.0 */
			return 1;
		default:
			return 0;
	}
}

MODULE = Scalar::Construct PACKAGE = Scalar::Construct

PROTOTYPES: DISABLE

SV *
constant(SV *value)
PROTOTYPE: $
PREINIT:
	SV *obj;
CODE:
	obj = newSVsv(value);
	SvREADONLY_on(obj);
	RETVAL = newRV_noinc(obj);
OUTPUT:
	RETVAL

SV *
variable(SV *value)
PROTOTYPE: $
CODE:
	RETVAL = newRV_noinc(newSVsv(value));
OUTPUT:
	RETVAL

SV *
aliasref(SV *object_ref)
PROTOTYPE: $
PREINIT:
	SV *object;
CODE:
	if(!(SvROK(object_ref) && (object = SvRV(object_ref), 1) &&
			svt_scalar(SvTYPE(object))))
		croak("not a scalar reference");
	RETVAL = newRV_inc(object);
OUTPUT:
	RETVAL

SV *
aliasobj(SV *object)
PROTOTYPE: $
CODE:
	RETVAL = newRV_inc(object);
OUTPUT:
	RETVAL
