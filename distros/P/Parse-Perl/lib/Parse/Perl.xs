#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "callchecker0.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#define QHAVE_UNITCHECK PERL_VERSION_GE(5,9,5)

#define QHAVE_WARNINGS_AS_SV (!PERL_VERSION_GE(5,9,4))
#if QHAVE_WARNINGS_AS_SV
# define WARNINGS_t SV
#else /* !QHAVE_WARNINGS_AS_SV */
# define WARNINGS_t STRLEN
#endif /* !QHAVE_WARNINGS_AS_SV */

#define QLEX_START_LINE_IS_SAFE PERL_VERSION_GE(5,13,7)
#define QHAVE_PARSE_STMTSEQ PERL_VERSION_GE(5,13,6)
#define QHAVE_COP_LABEL (!PERL_VERSION_GE(5,11,0))
#define QHAVE_COP_HINTS PERL_VERSION_GE(5,9,4)
#define QHAVE_COP_HINTS_HASH PERL_VERSION_GE(5,9,4)
#define QHAVE_COP_ARYBASE (!PERL_VERSION_GE(5,9,4))
#define QHAVE_COP_IO (!PERL_VERSION_GE(5,9,4) && PERL_VERSION_GE(5,8,0))

#ifndef COP_SEQ_RANGE_LOW
# if PERL_VERSION_GE(5,9,5)
#  define COP_SEQ_RANGE_LOW(sv) ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow
#  define COP_SEQ_RANGE_HIGH(sv) ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh
# else /* <5.9.5 */
#  define COP_SEQ_RANGE_LOW(sv) ((U32)SvNVX(sv))
#  define COP_SEQ_RANGE_HIGH(sv) ((U32)SvIVX(sv))
# endif /* <5.9.5 */
#endif /* !COP_SEQ_RANGE_LOW */

#if PERL_VERSION_GE(5,8,9) && !PERL_VERSION_GE(5,9,0)
/* there is a bogus definition, not actually used */
# undef PARENT_PAD_INDEX
#endif

#ifndef PARENT_PAD_INDEX
# if PERL_VERSION_GE(5,9,5)
#  define PARENT_PAD_INDEX(sv) ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow
#  define PARENT_FAKELEX_FLAGS(sv) \
	((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh
# elif PERL_VERSION_GE(5,9,0)
#  define PARENT_PAD_INDEX(sv) ((U32)SvNVX(sv))
#  define PARENT_FAKELEX_FLAGS(sv) ((U32)SvIVX(sv))
# endif /* >=5.9.0 */
#endif /* !PARENT_PAD_INDEX */

#ifndef pad_findmy_sv
# if PERL_VERSION_GE(5,11,2)
#  define pad_findmy_sv(sv, flags) pad_findmy(SvPVX(sv), SvCUR(sv), flags)
# else /* <5.11.2 */
#  define pad_findmy_sv(sv, flags) pad_findmy(SvPVX(sv))
# endif /* <5.11.2 */
#endif /* !pad_findmy_sv */

#ifndef newSV_type
# define newSV_type(type) THX_newSV_type(aTHX_ type)
static SV *THX_newSV_type(pTHX_ svtype type)
{
	SV *sv = newSV(0);
	(void) SvUPGRADE(sv, type);
	return sv;
}
#endif /* !newSV_type */

#ifndef gv_stashpvs
# define gv_stashpvs(name, flags) gv_stashpvn(""name"", sizeof(name)-1, flags)
#endif /* !gv_stashpvs */

#ifndef gv_fetchpvs
# ifdef gv_fetchpvn_flags
#  define gv_fetchpvs(name, flags, type) \
		gv_fetchpvn_flags(""name"", sizeof(name)-1, flags, type)
# else /* !gv_fetchpvn_flags */
#  define gv_fetchpvs(name, flags, type) gv_fetchpv(""name"", flags, type)
# endif /* !gv_fetchpvn_flags */
#endif /* !gv_fetchpvs */

#ifndef sv_setpvs
# define sv_setpvs(sv, string) sv_setpvn(sv, ""string"", sizeof(string)-1)
#endif /* !sv_setpvs */

#ifndef newSVpvs
# define newSVpvs(string) newSVpvn(""string"", sizeof(string)-1)
#endif /* !newSVpvs */

#ifndef SvPVX_const
# define SvPVX_const(sv) SvPVX(sv)
#endif /* !SvPVX_const */

#ifndef SvPADSTALE
# define SvPADSTALE(sv) 0
#endif /* !SvPADSTALE */

#ifndef SvPAD_STATE
# define SvPAD_STATE(sv) 0
#endif /* !SvPAD_STATE */

#ifndef HvNAME_get
# define HvNAME_get(hv) HvNAME(hv)
#endif /* !HvNAME_get */

#ifndef HvRITER_get
# define HvRITER_get(hv) HvRITER(hv)
#endif /* !HvRITER_get */

#ifndef HvEITER_get
# define HvEITER_get(hv) HvEITER(hv)
#endif /* !HvEITER_get */

#ifndef HvRITER_set
# define HvRITER_set(hv, val) (HvRITER(hv) = val)
#endif /* !HvRITER_set */

#ifndef HvEITER_set
# define HvEITER_set(hv, val) (HvEITER(hv) = val)
#endif /* !HvEITER_set */

#ifndef CvGV_set
# define CvGV_set(cv, val) (CvGV(cv) = val)
#endif /*!CvGV_set */

#ifndef lex_start
# define lex_start(l,r,f) Perl_lex_start(aTHX_ l,r,f)
#endif /* !lex_start */

#if PERL_VERSION_GE(5,13,7)
# define lex_end() 0
#else /* <5.13.7 */
# ifndef lex_end
#  define lex_end() Perl_lex_end(aTHX)
# endif /* !lex_end */
#endif /* <5.13.7 */

#ifndef op_append_elem
# define op_append_elem(t,f,l) append_elem(t,f,l)
# ifndef append_elem
#  define append_elem(t,f,l) Perl_append_elem(aTHX_ t,f,l)
# endif /* !append_elem */
#endif /* !op_append_elem */

#ifndef mess
# define mess Perl_mess_nocontext
#endif /* !mess */

#ifndef croak
# define croak Perl_croak_nocontext
#endif /* !croak */

#if PERL_VERSION_GE(5,15,5)
# define LOCALLY_SET_CURSTASH(newstash) \
	do { \
		SAVEGENERICSV(PL_curstash); \
		PL_curstash = (HV*)SvREFCNT_inc((SV*)(newstash)); \
	} while(0)
#else /* <5.15.5 */
# define LOCALLY_SET_CURSTASH(newstash) \
	do { \
		SAVESPTR(PL_curstash); \
		PL_curstash = (newstash); \
	} while(0)
#endif /* <5.15.5 */

#if QHAVE_COP_HINTS_HASH && !PERL_VERSION_GE(5,13,7)

# define refcounted_he_inc(rhe) THX_refcounted_he_inc(aTHX_ rhe)
static struct refcounted_he *THX_refcounted_he_inc(pTHX_
	struct refcounted_he *rhe)
{
	if(rhe) {
		HINTS_REFCNT_LOCK;
		rhe->refcounted_he_refcnt++;
		HINTS_REFCNT_UNLOCK;
	}
	return rhe;
}

# ifndef refcounted_he_free
#  define refcounted_he_free(rhe) Perl_refcounted_he_free(aTHX_ rhe)
# endif /* !refcounted_he_free */

typedef struct refcounted_he COPHH;
# define cophh_copy refcounted_he_inc
# define cophh_free refcounted_he_free

# define CopHINTHASH_get(c) ((COPHH*)((c)->cop_hints_hash))
# define CopHINTHASH_set(c,h) ((c)->cop_hints_hash = (h))

#endif /* QHAVE_COP_HINTS_HASH && <5.13.7 */

#ifdef PERL_MAGIC_hints
# ifndef hv_copy_hints_hv
#  define hv_copy_hints_hv(hv) Perl_hv_copy_hints_hv(aTHX_ hv)
# endif /* !hv_copy_hints_hv */
#endif /* PERL_MAGIC_hints */

#ifndef pad_new
# define pad_new(f) Perl_pad_new(aTHX_ f)
#endif /* !pad_new */

#ifndef pad_tidy
# define pad_tidy(t) Perl_pad_tidy(aTHX_ t)
#endif /* !pad_new */

#ifndef qerror
# define qerror(m) Perl_qerror(aTHX_ m)
#endif /* !qerror */

#if PERL_VERSION_GE(5,9,5)
# define PL_error_count (PL_parser->error_count)
#endif /* >=5.9.5 */

#if PERL_VERSION_GE(5,13,7)
# define lex_start_simple(line) lex_start(line, NULL, 0)
#elif PERL_VERSION_GE(5,9,5)
# define lex_start_simple(line) lex_start(line, NULL, 1)
#else /* <5.9.5 */
# define lex_start_simple(line) do { \
		lex_start(line); \
		SAVEI32(PL_error_count); \
		PL_error_count = 0; \
	} while(0)
#endif /* <5.9.5 */

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

enum {
	/* this enumeration must match gen_current_environment_op() */
	ENV_PACKAGE,
	ENV_WARNINGS,
#if QHAVE_COP_ARYBASE
	ENV_ARYBASE,
#endif /* QHAVE_COP_ARYBASE */
#if QHAVE_COP_IO
	ENV_IOHINT,
#endif /* QHAVE_COP_IO */
	ENV_HINTBITS,
#if QHAVE_COP_HINTS_HASH
	ENV_COPHINTHASH,
#endif /* QHAVE_COP_HINTS_HASH */
	ENV_HINTHASH,
	ENV_OUTSIDECV,
	ENV_OUTSIDESEQ,
	ENV_OUTSIDEPAD,
	ENV_SIZE
};

static SV *pkgname_env;
static HV *stash_env, *stash_cophh;

static SV *undef_sv;
static SV *warnsv_all, *warnsv_none;

#define safe_av_fetch(av, index) THX_safe_av_fetch(aTHX_ av, index)
static SV *THX_safe_av_fetch(pTHX_ AV *av, I32 index)
{
	SV **ptr = av_fetch(av, index, 0);
	return ptr ? *ptr : &PL_sv_undef;
}

#define package_to_sv(pkg) THX_package_to_sv(aTHX_ pkg)
static SV *THX_package_to_sv(pTHX_ HV *pkg)
{
	SV *sv;
	if(!pkg) return SvREFCNT_inc(undef_sv);
	sv = newSVpv(HvNAME_get(pkg), 0);
	SvREADONLY_on(sv);
	return sv;
}

#define package_from_sv(sv) THX_package_from_sv(aTHX_ sv)
static HV *THX_package_from_sv(pTHX_ SV *sv)
{
	if(sv_is_undef(sv)) return NULL;
	if(!sv_is_string(sv)) croak("malformed package name");
	return gv_stashsv(sv, GV_ADD);
}

#if QHAVE_COP_ARYBASE

# define iv_to_sv(iv) THX_iv_to_sv(aTHX_ iv)
static SV *THX_iv_to_sv(pTHX_ IV iv)
{
	SV *sv = newSViv(iv);
	SvREADONLY_on(sv);
	return sv;
}

# define iv_from_sv(sv) THX_iv_from_sv(aTHX_ sv)
static IV THX_iv_from_sv(pTHX_ SV *sv)
{
	if(!(sv_is_string(sv) && SvIOK(sv))) croak("malformed integer");
	return SvIV(sv);
}

#endif /* !QHAVE_COP_ARYBASE */

#define uv_to_sv(uv) THX_uv_to_sv(aTHX_ uv)
static SV *THX_uv_to_sv(pTHX_ UV uv)
{
	SV *sv = newSVuv(uv);
	SvREADONLY_on(sv);
	return sv;
}

#define uv_from_sv(sv) THX_uv_from_sv(aTHX_ sv)
static UV THX_uv_from_sv(pTHX_ SV *sv)
{
	if(!(sv_is_string(sv) && SvIOK(sv))) croak("malformed integer");
	return SvUV(sv);
}

#define warnings_to_sv(warnings) THX_warnings_to_sv(aTHX_ warnings)
static SV *THX_warnings_to_sv(pTHX_ WARNINGS_t *warnings)
{
	if(warnings == pWARN_ALL) {
		return SvREFCNT_inc(warnsv_all);
	} else if(warnings == pWARN_NONE) {
		return SvREFCNT_inc(warnsv_none);
	} else if(warnings == pWARN_STD) {
		return SvREFCNT_inc(undef_sv);
	} else {
#if QHAVE_WARNINGS_AS_SV
		SV *sv = newSVsv(warnings);
#else /* !QHAVE_WARNINGS_AS_SV */
		SV *sv = newSVpvn((char*)(warnings+1), warnings[0]);
#endif /* !QHAVE_WARNINGS_AS_SV */
		SvREADONLY_on(sv);
		return sv;
	}
}

#define warnings_from_sv(sv) THX_warnings_from_sv(aTHX_ sv)
static WARNINGS_t *THX_warnings_from_sv(pTHX_ SV *sv)
{
	if(sv == warnsv_all) {
		return pWARN_ALL;
	} else if(sv == warnsv_none) {
		return pWARN_NONE;
	} else if(sv_is_undef(sv)) {
		return pWARN_STD;
	} else {
#if QHAVE_WARNINGS_AS_SV
		return newSVsv(sv);
#else /* !QHAVE_WARNINGS_AS_SV */
		char *warn_octets;
		STRLEN len;
		STRLEN *warnings;
		if(!sv_is_string(sv)) croak("malformed warnings bitset");
		warn_octets = SvPV(sv, len);
		warnings = PerlMemShared_malloc(sizeof(*warnings) + len);
		warnings[0] = len;
		Copy(warn_octets, warnings+1, len, char);
		return warnings;
#endif /* !QHAVE_WARNINGS_AS_SV */
	}
}

#if QHAVE_COP_IO

#define iohint_to_sv(iohint) THX_iohint_to_sv(aTHX_ iohint)
static SV *THX_iohint_to_sv(pTHX_ SV *iohint)
{
	SV *sv;
	if(!iohint) return SvREFCNT_inc(undef_sv);
	sv = newSVsv(iohint);
	SvREADONLY_on(sv);
	return sv;
}

#define iohint_from_sv(sv) THX_iohint_from_sv(aTHX_ sv)
static SV *THX_iohint_from_sv(pTHX_ SV *sv)
{
	if(sv_is_undef(sv)) return NULL;
	return newSVsv(sv);
}

#endif /* QHAVE_COP_IO */

#if QHAVE_COP_HINTS_HASH

#define cophh_to_sv(cophh) THX_cophh_to_sv(aTHX_ cophh)
static SV *THX_cophh_to_sv(pTHX_ COPHH *cophh)
{
	SV *usv, *rsv;
	cophh = cophh_copy(cophh);
	if(!cophh) return SvREFCNT_inc(undef_sv);
	usv = newSVuv((UV)cophh);
	rsv = newRV_noinc(usv);
	sv_bless(rsv, stash_cophh);
	SvREADONLY_on(usv);
	SvREADONLY_on(rsv);
	return rsv;
}

#define cophh_from_sv(sv) THX_cophh_from_sv(aTHX_ sv)
static COPHH *THX_cophh_from_sv(pTHX_ SV *sv)
{
	SV *usv;
	COPHH *cophh;
	if(sv_is_undef(sv)) {
		cophh = NULL;
	} else if(SvROK(sv) && (usv = SvRV(sv), 1) &&
			SvOBJECT(usv) && SvSTASH(usv) == stash_cophh &&
			SvIOK(usv)) {
		cophh = (COPHH *)SvUV(usv);
	} else {
		croak("malformed cop_hints_hash");
	}
	return cophh_copy(cophh);
}

#endif /* QHAVE_COP_HINTS_HASH */

#define copy_hv(hin, readonly) THX_copy_hv(aTHX_ hin, readonly)
static HV *THX_copy_hv(pTHX_ HV *hin, int readonly)
{
	HV *hout = newHV();
	STRLEN hv_fill = HvFILL(hin);
	if(hv_fill) {
		HE *entry;
		I32 save_riter = HvRITER_get(hin);
		HE *save_eiter = HvEITER_get(hin);
		STRLEN hv_max = HvMAX(hin);
		while(hv_max && hv_max + 1 >= (hv_fill<<1))
			hv_max >>= 1;
		HvMAX(hout) = hv_max;
		hv_iterinit(hin);
		while((entry = hv_iternext_flags(hin, 0))) {
			SV *sv = newSVsv(HeVAL(entry));
			if(readonly) SvREADONLY_on(sv);
			(void) hv_store_flags(hout, HeKEY(entry), HeKLEN(entry),
				sv, HeHASH(entry), HeKFLAGS(entry));
		}
		HvRITER_set(hin, save_riter);
		HvEITER_set(hin, save_eiter);
	}
	if(readonly) SvREADONLY_on((SV*)hout);
	return hout;
}

#define hinthash_to_sv(hinthash) THX_hinthash_to_sv(aTHX_ hinthash)
static SV *THX_hinthash_to_sv(pTHX_ HV *hinthash)
{
	SV *sv;
	if(!hinthash) return SvREFCNT_inc(undef_sv);
	sv = newRV_noinc((SV*)copy_hv(hinthash, 1));
	SvREADONLY_on(sv);
	return sv;
}

#define hinthash_from_sv(sv) THX_hinthash_from_sv(aTHX_ sv)
static HV *THX_hinthash_from_sv(pTHX_ SV *sv)
{
	HV *hh_copy;
	if(sv_is_undef(sv)) return NULL;
	if(!(SvROK(sv) && (hh_copy = (HV*)SvRV(sv), 1) &&
			SvTYPE((SV*)hh_copy) == SVt_PVHV))
		croak("malformed hint hash");
#ifdef PERL_MAGIC_hints
	return hv_copy_hints_hv(hh_copy);
#else /* !PERL_MAGIC_hints */
	return copy_hv(hh_copy, 0);
#endif /* !PERL_MAGIC_hints */
}

#define function_to_sv(func) THX_function_to_sv(aTHX_ func)
static SV *THX_function_to_sv(pTHX_ CV *func)
{
	SV *sv = newRV_inc((SV*)func);
	SvREADONLY_on(sv);
	return sv;
}

#define function_from_sv(sv) THX_function_from_sv(aTHX_ sv)
static CV *THX_function_from_sv(pTHX_ SV *sv)
{
	SV *func;
	if(!(SvROK(sv) && (func = SvRV(sv), 1) && SvTYPE(func) == SVt_PVCV))
		croak("malformed function reference");
	return (CV*)SvREFCNT_inc(func);
}

#if 0
# define array_to_sv(array) THX_array_to_sv(aTHX_ array)
static SV *THX_array_to_sv(pTHX_ AV *array)
{
	SV *sv = newRV_inc((SV*)array);
	SvREADONLY_on(sv);
	return sv;
}
#endif /* 0 */

#define array_from_sv(sv) THX_array_from_sv(aTHX_ sv)
static AV *THX_array_from_sv(pTHX_ SV *sv)
{
	SV *array;
	if(!(SvROK(sv) && (array = SvRV(sv), 1) && SvTYPE(array) == SVt_PVAV))
		croak("malformed array reference");
	return (AV*)SvREFCNT_inc(array);
}

static OP *pp_current_pad(pTHX)
{
	CV *function = find_runcv(NULL);
	SV *functionsv = sv_2mortal(function_to_sv(function));
	U32 seq = PL_curcop->cop_seq;
	SV *seqsv = sv_2mortal(uv_to_sv(seq));
	AV *padlist = CvPADLIST(function);
	AV *padname = (AV*)*av_fetch(padlist, 0, 0);
	SV **pname = AvARRAY(padname);
	I32 fname = AvFILLp(padname);
	I32 fpad = AvFILLp(PL_comppad);
	I32 ix;
	AV *savedpad = newAV();
	SV *savedpadsv = sv_2mortal(newRV_noinc((SV*)savedpad));
	av_extend(savedpad, fpad);
	av_fill(savedpad, fpad);
	for(ix = (fpad<fname ? fpad : fname) + 1; ix--; ) {
		SV *namesv, *vsv, *vref;
		if((namesv = pname[ix]) &&
				SvPOKp(namesv) && SvCUR(namesv) > 1 &&
				(SvFAKE(namesv) ||
					(seq > COP_SEQ_RANGE_LOW(namesv) &&
					 seq <= COP_SEQ_RANGE_HIGH(namesv))) &&
				(vsv = PL_curpad[ix])) {
			vref = newRV_inc(vsv);
			SvREADONLY_on(vref);
			av_store(savedpad, ix, vref);
		}
	}
	SvREADONLY_on((SV*)savedpad);
	SvREADONLY_on(savedpadsv);
	{
		dSP;
		EXTEND(SP, 3);
		PUSHs(functionsv);
		PUSHs(seqsv);
		PUSHs(savedpadsv);
		PUTBACK;
	}
	return PL_op->op_next;
}

#define gen_current_pad_op() THX_gen_current_pad_op(aTHX)
static OP *THX_gen_current_pad_op(pTHX)
{
	OP *op = newSVOP(OP_CONST, 0, &PL_sv_undef);
	op->op_ppaddr = pp_current_pad;
	return op;
}

#define gen_current_environment_op() THX_gen_current_environment_op(aTHX)
static OP *THX_gen_current_environment_op(pTHX)
{
	CV *cv;
	OP *op;
	/*
	 * Prepare current function's pad for eval behaviour.  This
	 * consists of looking up all lexical variables that are currently
	 * in scope, thus getting them into the current function's pad,
	 * in order to make them available for code compiled later in this
	 * scope.  A variable doesn't get inherited into the current pad
	 * unless it is looked up at compile time.
	 */
	for(cv = CvOUTSIDE(PL_compcv); cv; cv = CvOUTSIDE(cv)) {
		AV *padlist, *padname;
		SV **pname;
		I32 fname, ix;
		padlist = CvPADLIST(cv);
		if(!padlist) continue;
		padname = (AV*)*av_fetch(padlist, 0, 0);
		pname = AvARRAY(padname);
		fname = AvFILLp(padname);
		for(ix = fname+1; ix--; ) {
			SV *namesv = pname[ix];
			if(namesv && SvPOKp(namesv) && SvCUR(namesv) > 1) {
				PADOFFSET po;
				/*
				 * On Perls prior to 5.15.8,
				 * Perl_pad_findmy_sv() or
				 * Perl_pad_findmy() is marked as having
				 * an unignorable return value.  In fact
				 * we're executing it for side effects
				 * here (the side effect of allocating
				 * a slot in the current pad for a
				 * lexically inherited variable), and it
				 * is correct to ignore the return value.
				 * The redundant assignment suppresses a
				 * compiler warning.
				 */
				po = pad_findmy_sv(namesv, 0);
			}
		}
	}
	/*
	 * Generate bless([...], "Parse::Perl::Environment") op tree, that
	 * will assemble an environment object at runtime.  The order of
	 * the op_append_elem clauses must match the ENV_ enumeration.
	 */
	op = NULL;
	op = op_append_elem(OP_LIST, op, /* ENV_PACKAGE */
		newSVOP(OP_CONST, 0,
			package_to_sv(PL_curstash)));
	op = op_append_elem(OP_LIST, op, /* ENV_WARNINGS */
		newSVOP(OP_CONST, 0,
			warnings_to_sv(PL_compiling.cop_warnings)));
#if QHAVE_COP_ARYBASE
	op = op_append_elem(OP_LIST, op, /* ENV_ARYBASE */
		newSVOP(OP_CONST, 0,
			iv_to_sv(PL_compiling.cop_arybase)));
#endif /* QHAVE_COP_ARYBASE */
#if QHAVE_COP_IO
	op = op_append_elem(OP_LIST, op, /* ENV_IOHINT */
		newSVOP(OP_CONST, 0,
			iohint_to_sv(PL_compiling.cop_io)));
#endif /* QHAVE_COP_IO */
	op = op_append_elem(OP_LIST, op, /* ENV_HINTBITS */
		newSVOP(OP_CONST, 0,
			uv_to_sv(PL_hints)));
#if QHAVE_COP_HINTS_HASH
	op = op_append_elem(OP_LIST, op, /* ENV_COPHINTHASH */
		newSVOP(OP_CONST, 0,
			cophh_to_sv(CopHINTHASH_get(&PL_compiling))));
#endif /* QHAVE_COP_HINTS_HASH */
	op = op_append_elem(OP_LIST, op, /* ENV_HINTHASH */
		newSVOP(OP_CONST, 0,
			hinthash_to_sv(GvHV(PL_hintgv))));
	op = op_append_elem(OP_LIST, op, /* ENV_OUTSIDE{CV,SEQ,PAD} */
		gen_current_pad_op());
	return newLISTOP(OP_BLESS, 0, newANONLIST(op),
		newSVOP(OP_CONST, 0, SvREFCNT_inc(pkgname_env)));
}

static OP *myck_entersub_curenv(pTHX_ OP *entersubop, GV *namegv, SV *protosv)
{
	entersubop = ck_entersub_args_proto(entersubop, namegv, protosv);
	op_free(entersubop);
	return gen_current_environment_op();
}

#define close_pad(func, outpad) THX_close_pad(aTHX_ func, outpad)
static void THX_close_pad(pTHX_ CV *func, AV *outpad)
{
#ifndef PARENT_PAD_INDEX
	CV *out = CvOUTSIDE(func);
	AV *out_padlist = out ? CvPADLIST(out) : NULL;
	AV *out_padname =
		out_padlist ? (AV*)*av_fetch(out_padlist, 0, 0) : NULL;
	SV **out_pname = out_padname ? AvARRAY(out_padname) : NULL;
	I32 out_fname = out_padname ? AvFILLp(out_padname) : 0;
	U32 out_seq = CvOUTSIDE_SEQ(func);
#endif /* !PARENT_PAD_INDEX */
	AV *padlist = CvPADLIST(func);
	AV *padname = (AV*)*av_fetch(padlist, 0, 0);
	AV *pad = (AV*)*av_fetch(padlist, 1, 0);
	SV **pname = AvARRAY(padname);
	SV **ppad = AvARRAY(pad);
	I32 fname = AvFILLp(padname);
	I32 fpad = AvFILLp(pad);
	I32 ix;
	for(ix = fname+1; ix--; ) {
		SV *namesv = pname[ix];
		I32 pix;
#ifndef PARENT_PAD_INDEX
		I32 fpix;
#endif /* !PARENT_PAD_INDEX */
		SV *vref, *vsv;
		if(!(namesv && SvFAKE(namesv))) continue;
#ifdef PARENT_PAD_INDEX
		pix = PARENT_PAD_INDEX(namesv);
#else /* !PARENT_PAD_INDEX */
		fpix = 0;
		for(pix = out_fname; pix != 0; pix--) {
			SV *out_namesv = out_pname[pix];
			if(!(out_namesv && SvPOKp(out_namesv) &&
				strEQ(SvPVX(out_namesv), SvPVX(namesv))))
					continue;
			if(SvFAKE(out_namesv)) {
					fpix = pix;
			} else if(out_seq > COP_SEQ_RANGE_LOW(out_namesv) &&
				  out_seq <= COP_SEQ_RANGE_HIGH(out_namesv)) {
					break;
			}
		}
		if(pix == 0) pix = fpix;
#endif /* !PARENT_PAD_INDEX */
		if(!(pix != 0 && ix <= fpad &&
				(vref = safe_av_fetch(outpad, pix), 1) &&
				SvROK(vref) && (vsv = SvRV(vref), 1) &&
				!(SvPADSTALE(vsv) && !SvPAD_STATE(namesv))))
			croak("Variable \"%s\" is not available",
				SvPVX_const(namesv));
		SvREFCNT_inc(vsv);
		if(ppad[ix]) SvREFCNT_dec(ppad[ix]);
		ppad[ix] = vsv;
	}
}

#if QHAVE_PARSE_STMTSEQ

# define parse_file_as_sub_body(outpad) \
	THX_parse_file_as_sub_body(aTHX_ outpad)
static void THX_parse_file_as_sub_body(pTHX_ AV *outpad)
{
	OP *stmtseq;
	ENTER;
	SAVEI8(PL_in_eval);
	PL_in_eval = EVAL_INEVAL;
	stmtseq = parse_stmtseq(0);
	if(lex_peek_unichar(0) == /*{*/'}') qerror(mess("Parse error"));
	LEAVE;
	if(PL_error_count) {
		if(stmtseq) op_free(stmtseq);
		return;
	}
	if(!stmtseq) stmtseq = newOP(OP_STUB, 0);
	if(CvCLONE(PL_compcv)) {
		close_pad(PL_compcv, outpad);
		CvCLONE_off(PL_compcv);
	}
	newATTRSUB(PL_savestack_ix, NULL, NULL, NULL, stmtseq);
}

#else /* !QHAVE_PARSE_STMTSEQ */

# if PERL_VERSION_GE(5,13,5)
#  ifndef yyparse
#   define yyparse(g) Perl_yyparse(aTHX_ g)
#  endif /* !yyparse */
#  define yyparse_prog() yyparse(GRAMPROG)
# else /* <5.13.5 */
#  ifndef yyparse
#   define yyparse() Perl_yyparse(aTHX)
#  endif /* !yyparse */
#  define yyparse_prog() yyparse()
# endif /* <5.13.5 */

# ifndef CvSTASH_set
#  if PERL_VERSION_GE(5,13,3)
#   ifndef sv_del_backref
#    define sv_del_backref(t,s) Perl_sv_del_backref(aTHX_ t,s)
#   endif /* !sv_del_backref */
#   ifndef sv_add_backref
#    define sv_add_backref(t,s) Perl_sv_add_backref(aTHX_ t,s)
PERL_CALLCONV void Perl_sv_add_backref(pTHX_ SV *t, SV *s);
#   endif /* !sv_add_backref */
#   define CvSTASH_set(cv, newst) THX_cvstash_set(aTHX_ cv, newst)
static void THX_cvstash_set(pTHX_ CV *cv, HV *newst)
{
	HV *oldst = CvSTASH(cv);
	if(oldst) sv_del_backref((SV*)oldst, (SV*)cv);
	CvSTASH(cv) = newst;
	if(newst) sv_add_backref((SV*)newst, (SV*)cv);
}
#  else /* <5.13.3 */
#   define CvSTASH_set(cv, newst) (CvSTASH(cv) = (newst))
#  endif /* <5.13.3 */
# endif /* !CvSTASH_set */

# ifdef PARENT_PAD_INDEX

#  define populate_pad() THX_populate_pad(aTHX)
static void THX_populate_pad(pTHX)
{
	/* pad is fully populated during normal compilation */
}

# else /* !PARENT_PAD_INDEX */

#  define var_from_outside_compcv(cv, namesv) \
	THX_var_from_outside_compcv(aTHX_ cv, namesv)
static int THX_var_from_outside_compcv(pTHX_ CV *cv, SV *namesv)
{
	while(1) {
		/*
		 * Loop invariant: the variable identified by namesv
		 * is inherited into cv from outside, and cv is not
		 * PL_compcv.
		 */
		U32 seq;
		AV *padname;
		I32 ix;
		seq = CvOUTSIDE_SEQ(cv);
		cv = CvOUTSIDE(cv);
		if(!cv) return 0;
		padname = (AV*)*av_fetch(CvPADLIST(cv), 0, 0);
		for(ix = AvFILLp(padname)+1; ix--; ) {
			SV **pnamesv_p, *pnamesv;
			if((pnamesv_p = av_fetch(padname, ix, 0)) &&
					(pnamesv = *pnamesv_p) &&
					SvPOKp(pnamesv) &&
					strEQ(SvPVX(pnamesv), SvPVX(namesv)) &&
					seq > COP_SEQ_RANGE_LOW(pnamesv) &&
					seq <= COP_SEQ_RANGE_HIGH(pnamesv))
				return 0;
		}
		if(cv == PL_compcv) return 1;
	}
}

#  define populate_pad_from_sub(func) THX_populate_pad_from_sub(aTHX_ func)
static void THX_populate_pad_from_sub(pTHX_ CV *func)
{
	AV *padname = (AV*)*av_fetch(CvPADLIST(func), 0, 0);
	I32 ix;
	for(ix = AvFILLp(padname)+1; ix--; ) {
		SV **namesv_p, *namesv;
		if((namesv_p = av_fetch(padname, ix, 0)) &&
				(namesv = *namesv_p) &&
				SvPOKp(namesv) && SvCUR(namesv) > 1 &&
				SvFAKE(namesv) &&
				var_from_outside_compcv(func, namesv)) {
			PADOFFSET po;
			/*
			 * As noted in THX_gen_current_environment_op(),
			 * this statement tries to suppress a compiler
			 * warning relating to Perl_pad_findmy_sv() or
			 * Perl_pad_findmy().
			 */
			po = pad_findmy_sv(namesv, 0);
		}
	}
}

#  define populate_pad_recursively(func) \
	THX_populate_pad_recursively(aTHX_ func)
static void THX_populate_pad_recursively(pTHX_ CV *func);
static void THX_populate_pad_recursively(pTHX_ CV *func)
{
	AV *padlist = CvPADLIST(func);
	AV *padname = (AV*)*av_fetch(padlist, 0, 0);
	AV *pad = (AV*)*av_fetch(padlist, 1, 0);
	I32 ix;
	for(ix = AvFILLp(padname)+1; ix--; ) {
		SV **namesv_p, *namesv;
		CV *sub;
		if((namesv_p = av_fetch(padname, ix, 0)) &&
				(namesv = *namesv_p) &&
				SvPOKp(namesv) && SvCUR(namesv) == 1 &&
				*SvPVX(namesv) == '&' &&
				(sub = (CV*)*av_fetch(pad, ix, 0)) &&
				CvCLONE(sub)) {
			populate_pad_from_sub(sub);
			populate_pad_recursively(sub);
		}
	}
}

#  define populate_pad() THX_populate_pad(aTHX)
static void THX_populate_pad(pTHX)
{
	populate_pad_recursively(PL_compcv);
}

# endif /* !PARENT_PAD_INDEX */

# define parse_file_as_sub_body(outpad) \
	THX_parse_file_as_sub_body(aTHX_ outpad)
static void THX_parse_file_as_sub_body(pTHX_ AV *outpad)
{
	OP *rootop, *startop;
	int parse_fail;
	CvSTASH_set(PL_compcv, PL_curstash);
	CvGV_set(PL_compcv, PL_curstash ?
		gv_fetchpvs("__ANON__", GV_ADDMULTI, SVt_PVCV) :
		gv_fetchpvs("__ANON__::__ANON__", GV_ADDMULTI, SVt_PVCV));
	ENTER;
	SAVEVPTR(PL_eval_root);
	SAVEVPTR(PL_eval_start);
	SAVEI8(PL_in_eval);
	PL_eval_root = NULL;
	PL_eval_start = NULL;
	PL_in_eval = EVAL_INEVAL;
	parse_fail = yyparse_prog();
	rootop = PL_eval_root;
	startop = PL_eval_start;
	if(parse_fail && !PL_error_count) qerror(mess("Parse error"));
	if(!rootop || rootop->op_type != OP_LEAVEEVAL) {
		if(!PL_error_count) qerror(mess("Compilation error"));
	}
	LEAVE;
	if(PL_error_count) {
		if(rootop) op_free(rootop);
		return;
	}
	rootop->op_type = OP_LEAVESUB;
	rootop->op_ppaddr = PL_ppaddr[OP_LEAVESUB];
	rootop->op_flags &= OPf_KIDS|OPf_PARENS;
	CvROOT(PL_compcv) = rootop;
	CvSTART(PL_compcv) = startop;
	if(CvCLONE(PL_compcv)) {
		populate_pad();
		close_pad(PL_compcv, outpad);
		CvCLONE_off(PL_compcv);
	}
	pad_tidy(padtidy_SUB);
}

#endif /* !QHAVE_PARSE_STMTSEQ */

MODULE = Parse::Perl PACKAGE = Parse::Perl

PROTOTYPES: DISABLE

BOOT:
{
	CV *curenv_cv;
	undef_sv = newSV(0);
	SvREADONLY_on(undef_sv);
	pkgname_env = newSVpvs("Parse::Perl::Environment");
	SvREADONLY_on(pkgname_env);
	stash_env = gv_stashpvs("Parse::Perl::Environment", 1);
	stash_cophh = gv_stashpvs("Parse::Perl::CopHintsHash", 1);
	warnsv_all = newSVpvn(WARN_ALLstring, WARNsize);
	SvREADONLY_on(warnsv_all);
	warnsv_none = newSVpvn(WARN_NONEstring, WARNsize);
	SvREADONLY_on(warnsv_none);
	curenv_cv = get_cv("Parse::Perl::current_environment", 0);
	cv_set_call_checker(curenv_cv, myck_entersub_curenv, (SV*)curenv_cv);
}

void
current_environment(...)
PROTOTYPE:
CODE:
	PERL_UNUSED_VAR(items);
	croak("current_environment called as a function");

CV *
parse_perl(SV *environment, SV *source)
PROTOTYPE: $$
PREINIT:
	AV *enva;
CODE:
	TAINT_IF(SvTAINTED(environment));
	TAINT_IF(SvTAINTED(source));
	TAINT_PROPER("parse_perl");
	if(!(SvROK(environment) && (enva = (AV*)SvRV(environment), 1) &&
			SvOBJECT((SV*)enva) &&
			SvSTASH((SV*)enva) == stash_env &&
			SvTYPE((SV*)enva) == SVt_PVAV))
		croak("environment is not an environment object");
	if(!sv_is_string(source)) croak("source is not a string");
	ENTER;
	SAVETMPS;
	/* populate PL_compiling and related state */
	SAVECOPFILE_FREE(&PL_compiling);
	{
		char filename[TYPE_DIGITS(long) + 10];
		sprintf(filename, "(eval %lu)", (unsigned long)++PL_evalseq);
		CopFILE_set(&PL_compiling, filename);
	}
	SAVECOPLINE(&PL_compiling);
	CopLINE_set(&PL_compiling, 1);
	SAVEI32(PL_subline);
	PL_subline = 1;
	LOCALLY_SET_CURSTASH(package_from_sv(safe_av_fetch(enva, ENV_PACKAGE)));
	save_item(PL_curstname);
	sv_setpv(PL_curstname,
			!PL_curstash ? "<none>" : HvNAME_get(PL_curstash));
	SAVECOPSTASH_FREE(&PL_compiling);
	CopSTASH_set(&PL_compiling, PL_curstash);
#if QHAVE_WARNINGS_AS_SV
	SAVESPTR(PL_compiling.cop_warnings);
#else /* !QHAVE_WARNINGS_AS_SV */
	SAVECOMPILEWARNINGS();
#endif /* !QHAVE_WARNINGS_AS_SV */
	PL_compiling.cop_warnings =
		warnings_from_sv(safe_av_fetch(enva, ENV_WARNINGS));
#if QHAVE_WARNINGS_AS_SV
	if(!specialWARN(PL_compiling.cop_warnings))
		SAVEFREESV(PL_compiling.cop_warnings);
#endif /* QHAVE_WARNINGS_AS_SV */
#if QHAVE_COP_ARYBASE
	SAVEI32(PL_compiling.cop_arybase);
	PL_compiling.cop_arybase =
		iv_from_sv(safe_av_fetch(enva, ENV_ARYBASE));
#endif /* QHAVE_COP_ARYBASE */
#if QHAVE_COP_IO
	SAVESPTR(PL_compiling.cop_io);
	PL_compiling.cop_io = iohint_from_sv(safe_av_fetch(enva, ENV_IOHINT));
	if(PL_compiling.cop_io) SAVEFREESV(PL_compiling.cop_io);
#endif /* QHAVE_COP_IO */
	PL_hints |= HINT_LOCALIZE_HH;
	SAVEHINTS();
	PL_hints = uv_from_sv(safe_av_fetch(enva, ENV_HINTBITS)) |
		HINT_BLOCK_SCOPE;
	{
		HV *old_hh = GvHV(PL_hintgv);
		GvHV(PL_hintgv) =
			hinthash_from_sv(safe_av_fetch(enva, ENV_HINTHASH));
		if(old_hh) SvREFCNT_dec(old_hh);
	}
#if QHAVE_COP_HINTS_HASH
	{
		COPHH *old_cophh = CopHINTHASH_get(&PL_compiling);
		CopHINTHASH_set(&PL_compiling,
			cophh_from_sv(safe_av_fetch(enva, ENV_COPHINTHASH)));
		cophh_free(old_cophh);
	}
#endif /* QHAVE_COP_HINTS_HASH */
#if QHAVE_COP_HINTS
	SAVEI32(PL_compiling.cop_hints);
	PL_compiling.cop_hints = PL_hints;
#endif /* QHAVE_COP_HINTS */
#if QHAVE_COP_LABEL
	SAVEPPTR(PL_compiling.cop_label);
	PL_compiling.cop_label = NULL;
#endif /* QHAVE_COP_LABEL */
	SAVEVPTR(PL_curcop);
	PL_curcop = &PL_compiling;
	/* initialise PL_compcv and related state */
	SAVEGENERICSV(PL_compcv);
	PL_compcv = (CV*)newSV_type(SVt_PVCV);
	CvANON_on(PL_compcv);
	CvOUTSIDE(PL_compcv) =
		function_from_sv(safe_av_fetch(enva, ENV_OUTSIDECV));
	CvOUTSIDE_SEQ(PL_compcv) =
		uv_from_sv(safe_av_fetch(enva, ENV_OUTSIDESEQ));
	CvPADLIST(PL_compcv) = pad_new(padnew_SAVE);
	/* initialise other parser state */
	SAVEOP();
	PL_op = NULL;
	SAVEGENERICSV(PL_beginav);
	PL_beginav = newAV();
#if QHAVE_UNITCHECK
	SAVEGENERICSV(PL_unitcheckav);
	PL_unitcheckav = newAV();
#endif /* QHAVE_UNITCHECK */
	/* parse */
#if !QLEX_START_LINE_IS_SAFE
	source = sv_mortalcopy(source);
#endif /* !QLEX_START_LINE_IS_SAFE */
	lex_start_simple(source);
	parse_file_as_sub_body(
		array_from_sv(safe_av_fetch(enva, ENV_OUTSIDEPAD)));
	lex_end();
	if(PL_error_count) {
		if(!(SvPOK(ERRSV) && SvCUR(ERRSV) != 0))
			sv_setpvs(ERRSV, "Compilation error");
		Perl_die(aTHX_ NULL);
	}
	/* finalise */
#if QHAVE_UNITCHECK
	if(PL_unitcheckav) call_list(PL_scopestack_ix, PL_unitcheckav);
#endif /* QHAVE_UNITCHECK */
	RETVAL = (CV*)SvREFCNT_inc((SV*)PL_compcv);
	FREETMPS;
	LEAVE;
OUTPUT:
	RETVAL

MODULE = Parse::Perl PACKAGE = Parse::Perl::CopHintsHash

void
DESTROY(SV *sv)
PREINIT:
#if QHAVE_COP_HINTS_HASH
	SV *usv;
	COPHH *cophh;
#endif /* QHAVE_COP_HINTS_HASH */
CODE:
#if QHAVE_COP_HINTS_HASH
	if(sv_is_undef(sv)) {
		cophh = NULL;
	} else if(SvROK(sv) && (usv = SvRV(sv), 1) &&
			SvOBJECT(usv) && SvSTASH(usv) == stash_cophh &&
			SvIOK(usv)) {
		cophh = (COPHH *)SvUV(usv);
	} else {
		croak("malformed cop_hints_hash");
	}
	cophh_free(cophh);
#else /* !QHAVE_COP_HINTS_HASH */
	PERL_UNUSED_VAR(sv);
#endif /* !QHAVE_COP_HINTS_HASH */
