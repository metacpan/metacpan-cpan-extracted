#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef CvISXSUB
# define CvISXSUB(cv) !!CvXSUB(cv)
#endif /* !CvISXSUB */

#ifndef CvCONST
# define CvCONST(cv) (!!cv_const_sv(cv))
#endif /* !CvCONST */

#ifndef CvSTASH_set
# define CvSTASH_set(cv, st) (CvSTASH(cv) = (st))
#endif /* !CvSTASH_set */

#ifndef HvNAMEUTF8
# define HvNAMEUTF8(st) (((void)(st)), 0)
#endif /* !HvNAMEUTF8 */

#ifndef CvPROTO
# define CvPROTO(cv) SvPVX((SV*)(cv))
# define CvPROTOLEN(cv) SvCUR((SV*)(cv))
#endif /* !CvPROTO */

#ifndef newSVpvs
# define newSVpvs(string) newSVpvn(""string"", sizeof(string)-1)
#endif /* !newSVpvs */

#define sv_is_glob(sv) (SvTYPE(sv) == SVt_PVGV)

#if PERL_VERSION_GE(5,11,0)
# define sv_is_regexp(sv) (SvTYPE(sv) == SVt_REGEXP)
#else /* <5.11.0 */
# define sv_is_regexp(sv) 0
#endif /* <5.11.0 */

#define sv_is_undef(sv) (!sv_is_glob(sv) && !sv_is_regexp(sv) && !SvOK(sv))

#define sv_is_string(sv) \
	(!sv_is_glob(sv) && !sv_is_regexp(sv) && \
	 (SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK|SVp_IOK|SVp_NOK|SVp_POK)))

MODULE = Sub::Metadata PACKAGE = Sub::Metadata

PROTOTYPES: DISABLE

const char *
sub_body_type(CV *sub)
PROTOTYPE: $
CODE:
	if(!CvROOT(sub) && !CvXSUB(sub)) {
		RETVAL = "UNDEF";
	} else {
		RETVAL = CvISXSUB(sub) ? "XSUB" : "PERL";
	}
OUTPUT:
	RETVAL

const char *
sub_closure_role(CV *sub)
PROTOTYPE: $
CODE:
	RETVAL = CvCLONED(sub) ? "CLOSURE" :
		CvCLONE(sub) ? "PROTOTYPE" :
		"STANDALONE";
OUTPUT:
	RETVAL

bool
sub_is_lvalue(CV *sub)
PROTOTYPE: $
CODE:
	RETVAL = !!CvLVALUE(sub);
OUTPUT:
	RETVAL

bool
sub_is_constant(CV *sub)
PROTOTYPE: $
CODE:
	RETVAL = !!CvCONST(sub);
OUTPUT:
	RETVAL

bool
sub_is_method(CV *sub)
PROTOTYPE: $
CODE:
	RETVAL = !!CvMETHOD(sub);
OUTPUT:
	RETVAL

void
mutate_sub_is_method(CV *sub, bool new_methodness)
PROTOTYPE: $$
CODE:
	if(new_methodness) {
		CvMETHOD_on(sub);
	} else {
		CvMETHOD_off(sub);
	}

bool
sub_is_debuggable(CV *sub)
PROTOTYPE: $
CODE:
	RETVAL = !CvNODEBUG(sub);
OUTPUT:
	RETVAL

void
mutate_sub_is_debuggable(CV *sub, bool new_debuggability)
PROTOTYPE: $$
CODE:
	if(new_debuggability) {
		CvNODEBUG_off(sub);
	} else {
		CvNODEBUG_on(sub);
	}

SV *
sub_prototype(CV *sub)
PROTOTYPE: $
CODE:
	if(!SvPOK(sub)) {
		RETVAL = &PL_sv_undef;
	} else {
		RETVAL = newSVpvn(CvPROTO(sub), CvPROTOLEN(sub));
#if PERL_VERSION_GE(5,15,4)
		if(SvUTF8((SV*)sub)) SvUTF8_on(RETVAL);
#endif /* >=5.15.4 */
	}
OUTPUT:
	RETVAL

void
mutate_sub_prototype(CV *sub, SV *new_prototype)
PROTOTYPE: $$
CODE:
	if(sv_is_undef(new_prototype)) {
		SvPOK_off((SV*)sub);
#if PERL_VERSION_GE(5,15,4)
		SvUTF8_off((SV*)sub);
#endif /* >= 5.15.4 */
	} else if(sv_is_string(new_prototype)) {
		STRLEN proto_len;
		char *proto_chars;
#if PERL_VERSION_GE(5,15,4)
		if(SvUTF8(new_prototype)) {
			new_prototype = sv_2mortal(newSVsv(new_prototype));
			sv_utf8_downgrade(new_prototype, 1);
		}
		if(CvAUTOLOAD(sub)) {
			STRLEN nam_len;
			char *oldbuf;
			SV *buf_sv = newSVpvn_flags(SvPVX((SV*)sub),
				SvCUR((SV*)sub), SvUTF8(sub) | SVs_TEMP);
			sv_utf8_downgrade(buf_sv, 1);
			if(SvUTF8(buf_sv) || SvUTF8(new_prototype)) {
				sv_utf8_upgrade(buf_sv);
				new_prototype =
					sv_2mortal(newSVsv(new_prototype));
				sv_utf8_upgrade(new_prototype);
			}
			proto_chars = SvPV((SV*)new_prototype, proto_len);
			nam_len = SvCUR(buf_sv);
			SvCUR(buf_sv)++;
			sv_catpvn(buf_sv, proto_chars, proto_len);
			oldbuf = SvPVX((SV*)sub);
			SvPVX((SV*)sub) = SvPVX(buf_sv);
			SvLEN((SV*)sub) = SvCUR(buf_sv) + 1;
			SvCUR((SV*)sub) = nam_len;
			SvFLAGS((SV*)sub) =
				(SvFLAGS((SV*)sub) & ~SVf_UTF8) |
				SVf_POK | SvUTF8(buf_sv);
			SvPVX(buf_sv) = oldbuf;
			SvPOK_off(buf_sv);
		} else {
			proto_chars = SvPV((SV*)new_prototype, proto_len);
			sv_setpvn((SV*)sub, proto_chars, proto_len);
			SvFLAGS((SV*)sub) =
				(SvFLAGS((SV*)sub) & ~SVf_UTF8) |
				SvUTF8(new_prototype);
		}
#else /* <5.15.4 */
		if(SvUTF8(new_prototype)) {
			new_prototype = sv_2mortal(newSVsv(new_prototype));
			sv_utf8_downgrade(new_prototype, 0);
		}
		proto_chars = SvPV((SV*)new_prototype, proto_len);
		sv_setpvn((SV*)sub, proto_chars, proto_len);
#endif /* <5.15.4 */
	} else {
		croak("new_prototype is not a string or undef");
	}

SV *
sub_package(CV *sub)
PROTOTYPE: $
PREINIT:
	HV *st;
	char const *nam;
CODE:
	if(!(st = CvSTASH(sub))) {
		RETVAL = &PL_sv_undef;
	} else if(!(nam = HvNAME(st))) {
		RETVAL = newSVpvs("__ANON__");
	} else {
#ifdef HvNAMELEN
		RETVAL = newSVpvn(nam, HvNAMELEN(st));
#else /* !HvNAMELEN */
		RETVAL = newSVpv(nam, 0);
#endif /* !HvNAMELEN */
		if(HvNAMEUTF8(st)) SvUTF8_on(RETVAL);
	}
OUTPUT:
	RETVAL

void
mutate_sub_package(CV *sub, SV *new_package)
PROTOTYPE: $$
PREINIT:
	HV *st;
CODE:
	if(sv_is_undef(new_package)) {
		st = NULL;
	} else if(sv_is_string(new_package)) {
		STRLEN pkg_len;
		char *pkg_chars;
#if PERL_VERSION_GE(5,15,4)
		pkg_chars = SvPV(new_package, pkg_len);
		st = gv_stashpvn(pkg_chars, pkg_len,
			GV_ADD | SvUTF8(new_package));
#else /* <5.15.4 */
		if(SvUTF8(new_package)) {
			new_package = sv_2mortal(newSVsv(new_package));
			sv_utf8_downgrade(new_package, 0);
		}
		pkg_chars = SvPV(new_package, pkg_len);
		st = gv_stashpvn(pkg_chars, pkg_len, GV_ADD);
#endif /* <5.15.4 */
	} else {
		croak("new_package is not a string or undef");
	}
	CvSTASH_set(sub, st);
