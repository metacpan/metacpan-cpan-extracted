#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#if PERL_VERSION_GE(5, 38, 0)
#include "XSParseInfix.h"
#endif

#ifndef cop_hints_fetch_pvn
#   define cop_hints_fetch_pvn(cop, key, len, hash, flags) Perl_refcounted_he_fetch(aTHX_ cop->cop_hints_hash, NULL, key, len, flags, hash)
#   define cop_hints_fetch_pvs(cop, key, flags) Perl_refcounted_he_fetch(aTHX_ cop->cop_hints_hash, NULL, STR_WITH_LEN(key), flags, 0)
#endif

#ifndef cop_hints_exists_pvn
#   if PERL_VERSION_GE(5, 16, 0)
#	   define cop_hints_exists_pvn(cop, key, len, hash, flags) cop_hints_fetch_pvn(cop, key, len, hash, flags | 0x02)
#   else
#	   define cop_hints_exists_pvn(cop, key, len, hash, flags) (cop_hints_fetch_pvn(cop, key, len, hash, flags) != &PL_sv_placeholder)
#   endif
#endif

#ifndef newSV_type_mortal
SV* S_newSV_type_mortal(pTHX_ svtype type) {
	SV* result = newSV(0);
	SvUPGRADE(result, type);
	return sv_2mortal(result);
}
#define newSV_type_mortal(type) S_newSV_type_mortal(aTHX_ type)
#endif

#ifndef OP_CHECK_MUTEX_LOCK
#define OP_CHECK_MUTEX_LOCK   NOOP
#define OP_CHECK_MUTEX_UNLOCK NOOP
#endif

#ifndef PERLSI_SMARTMATCH
#define PERLSI_SMARTMATCH PERLSI_UNDEF
#endif

#define pragma_base "Syntax::Infix::Smartmatch/"
#define pragma_name pragma_base "enabled"
#define pragma_name_length (sizeof(pragma_name) - 1)
static U32 pragma_hash;

#define smartermatch_enabled() cop_hints_exists_pvn(PL_curcop, pragma_name, pragma_name_length, pragma_hash, 0)

static Perl_ppaddr_t orig_smartmatch;

/* This version of do_smartmatch() implements an
   alternative table of matches.
 */
#define do_smartmatch(d, e) S_do_smartmatch(aTHX_ d, e)
STATIC bool S_do_smartmatch(pTHX_ SV* d, SV* e) {
	/* Take care only to invoke mg_get() once for each argument.
	 * Currently we do this by copying the SV if it's magical. */
	if (d) {
		if (SvGMAGICAL(d))
			d = sv_mortalcopy(d);
	}
	else
		d = &PL_sv_undef;

	assert(e);
	if (SvGMAGICAL(e))
		e = sv_mortalcopy(e);

	/* ~~ undef */
	if (!SvOK(e)) {
		return !SvOK(d);
	}
	else if (SvROK(e)) {
		/* First of all, handle overload magic of the rightmost argument */
		if (SvAMAGIC(e)) {
			SV* sv = NULL;
#if PERL_VERSION_LT(5,41,3)
			sv = amagic_call(d, e, smart_amg, AMGf_noleft);
#else
			HV* stash = SvSTASH(SvRV(e));
			GV* gv = gv_fetchmeth_pvn(stash, "(~~", 3, -1, 0);

			if (gv) {
				UNOP myop = {
					.op_flags   = OPf_STACKED | OPf_WANT_SCALAR,
					.op_ppaddr  = PL_ppaddr[OP_ENTERSUB],
					.op_type    = OP_ENTERSUB,
					.op_private = PERLDB_SUB && PL_curstash != PL_debstash ? OPpENTERSUB_DB : 0,
				};

				const bool oldcatch = CATCH_GET;
				CATCH_SET(TRUE);

				dSP;
				PUSHSTACKi(PERLSI_OVERLOAD);
				ENTER;
				SAVEOP();
				PL_op = (OP *) &myop;

				PUSHMARK(SP);
				EXTEND(SP, 4);
				PUSHs(e);
				PUSHs(d);
				PUSHs(&PL_sv_yes);
				PUSHs(MUTABLE_SV(GvCV(gv)));
				PUTBACK;

				CALLRUNOPS(aTHX);
				SPAGAIN;
				LEAVE;

				sv = POPs;

				PUTBACK;
				POPSTACK;
				CATCH_SET(oldcatch);
			}
#endif
			if (sv)
				return SvTRUEx(sv);
		}

		/* ~~ qr// */
		if (SvTYPE(SvRV(e)) == SVt_REGEXP) {
			dSP;
			REGEXP* re = (REGEXP*)SvRV(e);
			PMOP* const matcher = cPMOPx(newPMOP(OP_MATCH, OPf_WANT_SCALAR | OPf_STACKED));
			PM_SETRE(matcher, ReREFCNT_inc(re));

			ENTER_with_name("matcher");
			SAVEFREEOP((OP *) matcher);
			SAVEOP();
			PL_op = (OP *) matcher;

			XPUSHs(d);
			PUTBACK;
			(void) PL_ppaddr[OP_MATCH](aTHX);
			SPAGAIN;
			bool result = SvTRUEx(POPs);
			PUTBACK;
			LEAVE_with_name("matcher");
			return result;
		}
		/* Non-overloaded object */
		else if (SvOBJECT(SvRV(e)))
			return d == e;
		/* ~~ sub */
		else if (SvTYPE(SvRV(e)) == SVt_PVCV) {
			dSP;
			PUSHSTACKi(PERLSI_SMARTMATCH);
			ENTER_with_name("smartmatch_array_elem_test");
			PUSHMARK(SP);
			PUSHs(d);
			PUTBACK;
			I32 c = call_sv(e, G_SCALAR);
			SPAGAIN;
			bool result = c == 0 ? FALSE : SvTRUEx(POPs);
			PUTBACK;
			LEAVE_with_name("smartmatch_array_elem_test");
			POPSTACK;
			return result;
		}
		/* ~~ @array */
		else if (SvTYPE(SvRV(e)) == SVt_PVAV) {
			Size_t i;
			const Size_t this_len = av_count(MUTABLE_AV(SvRV(e)));

			for (i = 0; i < this_len; ++i) {
				SV * const * const svp = av_fetch(MUTABLE_AV(SvRV(e)), i, FALSE);
				if (!svp)
					continue;

				if (do_smartmatch(d, *svp))
					return TRUE;
			}
			return FALSE;
		}
	}
	/* As a last resort, use string comparison */
	return SvOK(d) && sv_eq_flags(d, e, 0);
}

static OP* pp_smartermatch(pTHX) {
	dSP;
	SV *e = POPs; /* e is for 'expression' */
	SV *d = POPs; /* d is for 'default', as in PL_defgv */
	PUTBACK;
	bool result = do_smartmatch(d, e);
	SPAGAIN;
	PUSHs(result ? &PL_sv_yes : &PL_sv_no);
	RETURN;
}

static OP* pp_smartermatch_switch(pTHX) {
	if (smartermatch_enabled())
		return pp_smartermatch(aTHX);
	else
		return orig_smartmatch(aTHX);
}

#if PERL_VERSION_GE(5, 38, 0)
static const struct XSParseInfixHooks hooks_smarter = {
	.cls            = XPI_CLS_MATCH_MISC,
	.permit_hintkey = "Syntax::Infix::Smartmatch/enabled",
	.ppaddr         = &pp_smartermatch,
};
#endif

static unsigned initialized;

MODULE = Syntax::Infix::Smartmatch				PACKAGE = Syntax::Infix::Smartmatch

PROTOTYPES: DISABLED

BOOT:
#if PERL_VERSION_LT(5, 41, 3)
	OP_CHECK_MUTEX_LOCK;
	if (!initialized) {
		initialized = 1;
		orig_smartmatch = PL_ppaddr[OP_SMARTMATCH];
		PL_ppaddr[OP_SMARTMATCH] = pp_smartermatch_switch;
	}
	OP_CHECK_MUTEX_UNLOCK;
#endif
#	if PERL_VERSION_GE(5, 38, 0)
	boot_xs_parse_infix(0.26);
	register_xs_parse_infix("~~", &hooks_smarter, NULL);
#	endif
