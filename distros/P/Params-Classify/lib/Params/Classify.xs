#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef PERL_UNUSED_VAR
# define PERL_UNUSED_VAR(x) ((void)x)
#endif /* !PERL_UNUSED_VAR */

#ifndef PERL_UNUSED_ARG
# define PERL_UNUSED_ARG(x) PERL_UNUSED_VAR(x)
#endif /* !PERL_UNUSED_ARG */

#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif /* !Newx */

#ifndef HvNAME_get
# define HvNAME_get(hv) HvNAME(hv)
#endif

#ifndef newSVpvs_share
# define newSVpvs_share(s) newSVpvn_share(""s"", (sizeof(""s"")-1), 0)
#endif /* !newSVpvs_share */

#ifndef newSVpvn_share
# define newSVpvn_share(s, l, h) newSVpvn(s, l)
#endif /* !newSVpvn_share */

#ifndef DPTR2FPTR
# define DPTR2FPTR(t,x) ((t)(UV)(x))
#endif /* !DPTR2FPTR */

#ifndef FPTR2DPTR
# define FPTR2DPTR(t,x) ((t)(UV)(x))
#endif /* !FPTR2DPTR */

#ifndef ptr_table_new

struct q_ptr_tbl_ent {
	struct q_ptr_tbl_ent *next;
	void *from, *to;
};

# undef PTR_TBL_t
# define PTR_TBL_t struct q_ptr_tbl_ent *

# define ptr_table_new() THX_ptr_table_new(aTHX)
static PTR_TBL_t *THX_ptr_table_new(pTHX)
{
	PTR_TBL_t *tbl;
	Newx(tbl, 1, PTR_TBL_t);
	*tbl = NULL;
	return tbl;
}

# if 0
#  define ptr_table_free(tbl) THX_ptr_table_free(aTHX_ tbl)
static void THX_ptr_table_free(pTHX_ PTR_TBL_t *tbl)
{
	struct q_ptr_tbl_ent *ent = *tbl;
	Safefree(tbl);
	while(ent) {
		struct q_ptr_tbl_ent *nent = ent->next;
		Safefree(ent);
		ent = nent;
	}
}
# endif /* 0 */

# define ptr_table_store(tbl, from, to) THX_ptr_table_store(aTHX_ tbl, from, to)
static void THX_ptr_table_store(pTHX_ PTR_TBL_t *tbl, void *from, void *to)
{
	struct q_ptr_tbl_ent *ent;
	Newx(ent, 1, struct q_ptr_tbl_ent);
	ent->next = *tbl;
	ent->from = from;
	ent->to = to;
	*tbl = ent;
}

# define ptr_table_fetch(tbl, from) THX_ptr_table_fetch(aTHX_ tbl, from)
static void *THX_ptr_table_fetch(pTHX_ PTR_TBL_t *tbl, void *from)
{
	struct q_ptr_tbl_ent *ent;
	for(ent = *tbl; ent; ent = ent->next) {
		if(ent->from == from) return ent->to;
	}
	return NULL;
}

#endif /* !ptr_table_new */

#if PERL_VERSION_GE(5,11,0)
# define case_SVt_RV_
#else /* <5.11.0 */
# define case_SVt_RV_ case SVt_RV:
#endif /* <5.11.0 */

#if PERL_VERSION_GE(5,9,5)
# define case_SVt_PVBM_
#else /* <5.11.0 */
# define case_SVt_PVBM_ case SVt_PVBM:
#endif /* <5.11.0 */

#if PERL_VERSION_GE(5,11,0)
# define case_SVt_REGEXP_ case SVt_REGEXP:
#else /* <5.11.0 */
# define case_SVt_REGEXP_
#endif /* <5.11.0 */

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

#define sv_is_untyped_ref(sv) (SvROK(sv) && !SvOBJECT(SvRV(sv)))
#define sv_is_untyped_blessed(sv) (SvROK(sv) && SvOBJECT(SvRV(sv)))

#define bool_sv(b) ((b) ? &PL_sv_yes : &PL_sv_no)

static bool THX_sv_is_undef(pTHX_ SV *sv) { return !!sv_is_undef(sv); }

static bool THX_sv_is_string(pTHX_ SV *sv) { return !!sv_is_string(sv); }

static bool THX_sv_is_glob(pTHX_ SV *sv) { return !!sv_is_glob(sv); }

static bool THX_sv_is_regexp(pTHX_ SV *sv) {
	PERL_UNUSED_ARG(sv);
	return !!sv_is_regexp(sv);
}

static bool THX_sv_is_untyped_ref(pTHX_ SV *sv) {
	return !!sv_is_untyped_ref(sv);
}

static bool THX_sv_is_untyped_blessed(pTHX_ SV *sv) {
	return !!sv_is_untyped_blessed(sv);
}

enum {
	SCLASS_UNDEF,
	SCLASS_STRING,
	SCLASS_GLOB,
	SCLASS_REGEXP,
	SCLASS_REF,
	SCLASS_BLESSED,
	SCLASS_COUNT
};

static struct sclass_metadata {
	char const *desc_adj_or_noun_phrase, *keyword_pv;
	SV *keyword_sv;
	bool (*THX_sv_is_sclass)(pTHX_ SV *);
} sclass_metadata[SCLASS_COUNT] = {
	{ "undefined",  "UNDEF",   NULL, THX_sv_is_undef },
	{ "a string",   "STRING",  NULL, THX_sv_is_string },
	{ "a typeglob", "GLOB",    NULL, THX_sv_is_glob },
	{ "a regexp",   "REGEXP",  NULL, THX_sv_is_regexp },
	{ "a reference to plain object",
			"REF",     NULL, THX_sv_is_untyped_ref },
	{ "a reference to blessed object",
			"BLESSED", NULL, THX_sv_is_untyped_blessed },
};

enum {
	RTYPE_SCALAR,
	RTYPE_ARRAY,
	RTYPE_HASH,
	RTYPE_CODE,
	RTYPE_FORMAT,
	RTYPE_IO,
	RTYPE_COUNT
};

static struct rtype_metadata {
	char const *desc_noun, *keyword_pv;
	SV *keyword_sv;
} rtype_metadata[RTYPE_COUNT] = {
	{ "scalar", "SCALAR", NULL },
	{ "array",  "ARRAY",  NULL },
	{ "hash",   "HASH",   NULL },
	{ "code",   "CODE",   NULL },
	{ "format", "FORMAT", NULL },
	{ "io",     "IO",     NULL },
};

#define PC_TYPE_MASK    0x00f
#define PC_CROAK        0x010
#define PC_STRICTBLESS  0x020
#define PC_ABLE         0x040
#define PC_ALLOW_UNARY  0x100
#define PC_ALLOW_BINARY 0x200

#define scalar_class(arg) THX_scalar_class(aTHX_ arg)
static I32 THX_scalar_class(pTHX_ SV *arg)
{
	if(sv_is_glob(arg)) {
		return SCLASS_GLOB;
	} else if(sv_is_regexp(arg)) {
		return SCLASS_REGEXP;
	} else if(!SvOK(arg)) {
		return SCLASS_UNDEF;
	} else if(SvROK(arg)) {
		return SvOBJECT(SvRV(arg)) ? SCLASS_BLESSED : SCLASS_REF;
	} else if(SvFLAGS(arg) &
			(SVf_IOK|SVf_NOK|SVf_POK|SVp_IOK|SVp_NOK|SVp_POK)) {
		return SCLASS_STRING;
	} else {
		croak("unknown scalar class, please update Params::Classify\n");
	}
}

#define read_reftype_or_neg(reftype) THX_read_reftype_or_neg(aTHX_ reftype)
static I32 THX_read_reftype_or_neg(pTHX_ SV *reftype)
{
	char *p;
	STRLEN l;
	if(!sv_is_string(reftype)) return -2;
	p = SvPV(reftype, l);
	if(strlen(p) != l) return -1;
	switch(p[0]) {
		case 'S':
			if(!strcmp(p, "SCALAR")) return RTYPE_SCALAR;
			return -1;
		case 'A':
			if(!strcmp(p, "ARRAY")) return RTYPE_ARRAY;
			return -1;
		case 'H':
			if(!strcmp(p, "HASH")) return RTYPE_HASH;
			return -1;
		case 'C':
			if(!strcmp(p, "CODE")) return RTYPE_CODE;
			return -1;
		case 'F':
			if(!strcmp(p, "FORMAT")) return RTYPE_FORMAT;
			return -1;
		case 'I':
			if(!strcmp(p, "IO")) return RTYPE_IO;
			return -1;
		default:
			return -1;
	}
}

#define read_reftype(reftype) THX_read_reftype(aTHX_ reftype)
static I32 THX_read_reftype(pTHX_ SV *reftype)
{
	I32 rtype = read_reftype_or_neg(reftype);
	if(rtype < 0)
		croak(rtype == -2 ?
			"reference type argument is not a string\n" :
			"invalid reference type\n");
	return rtype;
}

#define ref_type(referent) THX_ref_type(aTHX_ referent)
static I32 THX_ref_type(pTHX_ SV *referent)
{
	switch(SvTYPE(referent)) {
		case SVt_NULL: case SVt_IV: case SVt_NV: case_SVt_RV_
		case SVt_PV: case SVt_PVIV: case SVt_PVNV:
		case SVt_PVMG: case SVt_PVLV: case SVt_PVGV:
		case_SVt_PVBM_ case_SVt_REGEXP_
			return RTYPE_SCALAR;
		case SVt_PVAV:
			return RTYPE_ARRAY;
		case SVt_PVHV:
			return RTYPE_HASH;
		case SVt_PVCV:
			return RTYPE_CODE;
		case SVt_PVFM:
			return RTYPE_FORMAT;
		case SVt_PVIO:
			return RTYPE_IO;
		default:
			croak("unknown SvTYPE, "
				"please update Params::Classify\n");
	}
}

#define blessed_class(referent) THX_blessed_class(aTHX_ referent)
static const char *THX_blessed_class(pTHX_ SV *referent)
{
	HV *stash = SvSTASH(referent);
	const char *name = HvNAME_get(stash);
	return name ? name : "__ANON__";
}

#define call_bool_method(objref, methodname, arg) \
	THX_call_bool_method(aTHX_ objref, methodname, arg)
static bool THX_call_bool_method(pTHX_ SV *objref, const char *methodname,
	SV *arg)
{
	dSP;
	int retcount;
	SV *ret;
	bool retval;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(objref);
	XPUSHs(arg);
	PUTBACK;
	retcount = call_method(methodname, G_SCALAR);
	SPAGAIN;
	if(retcount != 1) croak("call_method misbehaving\n");
	ret = POPs;
	retval = !!SvTRUE(ret);
	PUTBACK;
	FREETMPS;
	LEAVE;
	return retval;
}

#define pp1_scalar_class() THX_pp1_scalar_class(aTHX)
static void THX_pp1_scalar_class(pTHX)
{
	dSP;
	SV *arg = TOPs;
	TOPs = sclass_metadata[scalar_class(arg)].keyword_sv;
}

#define pp1_ref_type() THX_pp1_ref_type(aTHX)
static void THX_pp1_ref_type(pTHX)
{
	dSP;
	SV *arg, *referent;
	arg = TOPs;
	TOPs = !SvROK(arg) || (referent = SvRV(arg), SvOBJECT(referent)) ?
		&PL_sv_undef :
		rtype_metadata[ref_type(referent)].keyword_sv;
}

#define pp1_blessed_class() THX_pp1_blessed_class(aTHX)
static void THX_pp1_blessed_class(pTHX)
{
	dSP;
	SV *arg, *referent;
	arg = TOPs;
	TOPs = !SvROK(arg) || (referent = SvRV(arg), !SvOBJECT(referent)) ?
		&PL_sv_undef :
		sv_2mortal(newSVpv(blessed_class(referent), 0));
}

#define pp1_check_sclass(t) THX_pp1_check_sclass(aTHX_ t)
static void THX_pp1_check_sclass(pTHX_ I32 t)
{
	dSP;
	SV *arg = POPs;
	struct sclass_metadata const *sclassmeta =
		&sclass_metadata[t & PC_TYPE_MASK];
	bool matches;
	PUTBACK;
	matches = sclassmeta->THX_sv_is_sclass(aTHX_ arg);
	SPAGAIN;
	if(t & PC_CROAK) {
		if(!matches)
			croak("argument is not %s\n",
				sclassmeta->desc_adj_or_noun_phrase);
		if(GIMME_V == G_SCALAR) XPUSHs(&PL_sv_undef);
	} else {
		SV *result = bool_sv(matches);
		XPUSHs(result);
	}
	PUTBACK;
}

#define pp1_check_rtype(t) THX_pp1_check_rtype(aTHX_ t)
static void THX_pp1_check_rtype(pTHX_ I32 t)
{
	dSP;
	SV *arg = POPs, *referent;
	I32 rtype = t & PC_TYPE_MASK;
	struct rtype_metadata const *rtypemeta = &rtype_metadata[rtype];
	bool matches = SvROK(arg) &&
		(referent = SvRV(arg), !SvOBJECT(referent)) &&
		ref_type(referent) == rtype;
	if(t & PC_CROAK) {
		if(!matches)
			croak("argument is not a reference to plain %s\n",
				rtypemeta->desc_noun);
		if(GIMME_V == G_SCALAR) XPUSHs(&PL_sv_undef);
	} else {
		SV *result = bool_sv(matches);
		XPUSHs(result);
	}
	PUTBACK;
}

#define pp1_check_dyn_rtype(t) THX_pp1_check_dyn_rtype(aTHX_ t)
static void THX_pp1_check_dyn_rtype(pTHX_ I32 t)
{
	dSP;
	SV *type_sv = POPs;
	PUTBACK;
	pp1_check_rtype(t | read_reftype(type_sv));
}

#define pp1_check_dyn_battr(t) THX_pp1_check_dyn_battr(aTHX_ t)
static void THX_pp1_check_dyn_battr(pTHX_ I32 t)
{
	dSP;
	SV *attr, *arg, *meth = NULL;
	bool matches;
	attr = POPs;
	if(t & PC_ABLE) {
		if(sv_is_string(attr)) {
			meth = attr;
		} else {
			AV *methods_av;
			I32 alen, pos;
			if(!SvROK(attr) || SvOBJECT(SvRV(attr)) ||
					SvTYPE(SvRV(attr)) != SVt_PVAV)
				croak("methods argument is not "
					"a string or array\n");
			methods_av = (AV*)SvRV(attr);
			alen = av_len(methods_av);
			for(pos = 0; pos <= alen; pos++) {
				SV **m_ptr = av_fetch(methods_av, pos, 0);
				if(!m_ptr || !sv_is_string(*m_ptr))
					croak("method name is not a string\n");
			}
			if(alen != -1) meth = *av_fetch(methods_av, 0, 0);
		}
	} else {
		if(!sv_is_string(attr))
			croak("class argument is not a string\n");
	}
	arg = POPs;
	if((matches = SvROK(arg) && SvOBJECT(SvRV(arg)))) {
		if(t & PC_ABLE) {
			PUTBACK;
			if(!SvROK(attr)) {
				meth = attr;
				matches = call_bool_method(arg, "can", attr);
			} else {
				AV *methods_av = (AV*)SvRV(attr);
				I32 alen = av_len(methods_av), pos;
				for(pos = 0; pos <= alen; pos++) {
					meth = *av_fetch(methods_av, pos, 0);
					if(!call_bool_method(arg, "can",
							meth)) {
						matches = 0;
						break;
					}
				}
			}
			SPAGAIN;
		} else if(t & PC_STRICTBLESS) {
			char const *actual_class = blessed_class(SvRV(arg));
			char const *check_class;
			STRLEN check_len;
			check_class = SvPV(attr, check_len);
			matches = check_len == strlen(actual_class) &&
					!strcmp(check_class, actual_class);
		} else {
			PUTBACK;
			matches = call_bool_method(arg, "isa", attr);
			SPAGAIN;
		}
	}
	if(t & PC_CROAK) {
		if(!matches) {
			if(t & PC_ABLE) {
				if(meth) {
					croak("argument is not able to "
						"perform method \"%s\"\n",
						SvPV_nolen(meth));
				} else {
					croak("argument is not able to "
						"perform at all\n");
				}
			} else {
				croak("argument is not a reference to "
					"%sblessed %s\n",
					t & PC_STRICTBLESS ? "strictly " : "",
					SvPV_nolen(attr));
			}
		}
		if(GIMME_V == G_SCALAR) XPUSHs(&PL_sv_undef);
	} else {
		SV *result = bool_sv(matches);
		XPUSHs(result);
	}
	PUTBACK;
}

static OP *THX_pp_scalar_class(pTHX)
{
	pp1_scalar_class();
	return NORMAL;
}

static OP *THX_pp_ref_type(pTHX)
{
	pp1_ref_type();
	return NORMAL;
}

static OP *THX_pp_blessed_class(pTHX)
{
	pp1_blessed_class();
	return NORMAL;
}

static OP *THX_pp_check_sclass(pTHX)
{
	pp1_check_sclass(PL_op->op_private);
	return NORMAL;
}

static OP *THX_pp_check_rtype(pTHX)
{
	pp1_check_rtype(PL_op->op_private);
	return NORMAL;
}

static OP *THX_pp_check_dyn_rtype(pTHX)
{
	pp1_check_dyn_rtype(PL_op->op_private);
	return NORMAL;
}

static OP *THX_pp_check_dyn_battr(pTHX)
{
	pp1_check_dyn_battr(PL_op->op_private);
	return NORMAL;
}

#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE
static void S_croak_xs_usage(pTHX_ const CV *, const char *);
# define croak_xs_usage(cv, params) S_croak_xs_usage(aTHX_ cv, params)
#endif /* !PERL_ARGS_ASSERT_CROAK_XS_USAGE */

static void THX_xsfunc_scalar_class(pTHX_ CV *cv)
{
	dMARK; dSP;
	if(SP - MARK != 1) croak_xs_usage(cv, "arg");
	pp1_scalar_class();
}

static void THX_xsfunc_ref_type(pTHX_ CV *cv)
{
	dMARK; dSP;
	if(SP - MARK != 1) croak_xs_usage(cv, "arg");
	pp1_ref_type();
}

static void THX_xsfunc_blessed_class(pTHX_ CV *cv)
{
	dMARK; dSP;
	if(SP - MARK != 1) croak_xs_usage(cv, "arg");
	pp1_blessed_class();
}

static void THX_xsfunc_check_sclass(pTHX_ CV *cv)
{
	dMARK; dSP;
	if(SP - MARK != 1) croak_xs_usage(cv, "arg");
	pp1_check_sclass(CvXSUBANY(cv).any_i32);
}

static void THX_xsfunc_check_ref(pTHX_ CV *cv)
{
	I32 cvflags = CvXSUBANY(cv).any_i32;
	dMARK; dSP;
	switch(SP - MARK) {
		case 1: pp1_check_sclass(cvflags); break;
		case 2: pp1_check_dyn_rtype(cvflags & ~PC_TYPE_MASK); break;
		default: croak_xs_usage(cv, "arg, type");
	}
}

static void THX_xsfunc_check_blessed(pTHX_ CV *cv)
{
	I32 cvflags = CvXSUBANY(cv).any_i32;
	dMARK; dSP;
	switch(SP - MARK) {
		case 1: pp1_check_sclass(cvflags); break;
		case 2: pp1_check_dyn_battr(cvflags & ~PC_TYPE_MASK); break;
		default: croak_xs_usage(cv, "arg, class");
	}
}

#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE
# undef croak_xs_usage
#endif /* !PERL_ARGS_ASSERT_CROAK_XS_USAGE */

#define rvop_cv(rvop) THX_rvop_cv(aTHX_ rvop)
static CV *THX_rvop_cv(pTHX_ OP *rvop)
{
	switch(rvop->op_type) {
		case OP_CONST: {
			SV *rv = cSVOPx_sv(rvop);
			return SvROK(rv) ? (CV*)SvRV(rv) : NULL;
		} break;
		case OP_GV: return GvCV(cGVOPx_gv(rvop));
		default: return NULL;
	}
}

static PTR_TBL_t *ppmap;

static OP *(*nxck_entersub)(pTHX_ OP *o);
static OP *myck_entersub(pTHX_ OP *op)
{
	OP *pushop, *cvop, *aop, *bop;
	CV *cv;
	OP *(*ppfunc)(pTHX);
	I32 cvflags;
	pushop = cUNOPx(op)->op_first;
	if(!pushop->op_sibling) pushop = cUNOPx(pushop)->op_first;
	for(cvop = pushop; cvop->op_sibling; cvop = cvop->op_sibling) ;
	if(!(cvop->op_type == OP_RV2CV &&
			!(cvop->op_private & OPpENTERSUB_AMPER) &&
			(cv = rvop_cv(cUNOPx(cvop)->op_first)) &&
			(ppfunc = DPTR2FPTR(OP*(*)(pTHX),
					ptr_table_fetch(ppmap, cv)))))
		return nxck_entersub(aTHX_ op);
	cvflags = CvXSUBANY(cv).any_i32;
	op = nxck_entersub(aTHX_ op);   /* for prototype checking */
	aop = pushop->op_sibling;
	bop = aop->op_sibling;
	if(bop == cvop) {
		if(!(cvflags & PC_ALLOW_UNARY)) return op;
		unary:
		pushop->op_sibling = bop;
		aop->op_sibling = NULL;
		op_free(op);
		op = newUNOP(OP_NULL, 0, aop);
		op->op_type = OP_RAND;
		op->op_ppaddr = ppfunc;
		op->op_private = (U8)cvflags;
		return op;
	} else if(bop && bop->op_sibling == cvop) {
		if(!(cvflags & PC_ALLOW_BINARY)) return op;
		if(ppfunc == THX_pp_check_sclass &&
				(cvflags & PC_TYPE_MASK) == SCLASS_REF) {
			I32 rtype;
			cvflags &= ~PC_TYPE_MASK;
			if(bop->op_type == OP_CONST &&
				(rtype = read_reftype_or_neg(cSVOPx_sv(bop)))
					>= 0) {
				cvflags |= rtype;
				ppfunc = THX_pp_check_rtype;
				goto unary;
			}
			ppfunc = THX_pp_check_dyn_rtype;
		} else if(ppfunc == THX_pp_check_sclass &&
				(cvflags & PC_TYPE_MASK) == SCLASS_BLESSED) {
			cvflags &= ~PC_TYPE_MASK;
			ppfunc = THX_pp_check_dyn_battr;
		}
		pushop->op_sibling = cvop;
		aop->op_sibling = NULL;
		bop->op_sibling = NULL;
		op_free(op);
		op = newBINOP(OP_NULL, 0, aop, bop);
		op->op_type = OP_RAND;
		op->op_ppaddr = ppfunc;
		op->op_private = (U8)cvflags;
		return op;
	} else {
		return op;
	}
}

MODULE = Params::Classify PACKAGE = Params::Classify

PROTOTYPES: DISABLE

BOOT:
{
	int i;
	SV *tsv = sv_2mortal(newSV(0));
	ppmap = ptr_table_new();
#define SETUP_SIMPLE_UNARY_XSUB(NAME) \
	do { \
		CV *cv = newXSproto_portable("Params::Classify::"#NAME, \
			THX_xsfunc_##NAME, __FILE__, "$"); \
		CvXSUBANY(cv).any_i32 = PC_ALLOW_UNARY; \
		ptr_table_store(ppmap, FPTR2DPTR(void*, cv), \
			FPTR2DPTR(void*, THX_pp_##NAME)); \
	} while(0)
	SETUP_SIMPLE_UNARY_XSUB(scalar_class);
	SETUP_SIMPLE_UNARY_XSUB(ref_type);
	SETUP_SIMPLE_UNARY_XSUB(blessed_class);
	for(i = SCLASS_COUNT; i--; ) {
		bool is_refish = i >= SCLASS_REF;
		struct sclass_metadata *sclassmeta = &sclass_metadata[i];
		char const *keyword_pv = sclassmeta->keyword_pv, *p;
		char lckeyword[8], *q;
		I32 cvflags = PC_ALLOW_UNARY |
			(is_refish ? PC_ALLOW_BINARY : 0) | i;
		I32 variant = (i == SCLASS_BLESSED ? PC_ABLE : 0) | PC_CROAK;
		void (*xsfunc)(pTHX_ CV*) =
			i == SCLASS_REF ? THX_xsfunc_check_ref :
			i == SCLASS_BLESSED ? THX_xsfunc_check_blessed :
			THX_xsfunc_check_sclass;
		for(p = keyword_pv, q = lckeyword; *p; p++, q++)
			*q = *p | 0x20;
		*q = 0;
		sclassmeta->keyword_sv =
			newSVpvn_share(keyword_pv, strlen(keyword_pv), 0);
		for(; variant >= 0; variant -= PC_CROAK) {
			CV *cv;
			sv_setpvf(tsv, "Params::Classify::%s_%s",
				variant & PC_CROAK ? "check" : "is",
				variant & PC_ABLE ? "able" :
				variant & PC_STRICTBLESS ? "strictly_blessed" :
				lckeyword);
			cv = newXSproto_portable(SvPVX(tsv),
				xsfunc, __FILE__, is_refish ? "$;$" : "$");
			CvXSUBANY(cv).any_i32 = cvflags | variant;
			ptr_table_store(ppmap, cv,
				FPTR2DPTR(void*, THX_pp_check_sclass));
		}
	}
	for(i = RTYPE_COUNT; i--; ) {
		struct rtype_metadata *rtypemeta = &rtype_metadata[i];
		rtypemeta->keyword_sv =
			newSVpvn_share(rtypemeta->keyword_pv,
					strlen(rtypemeta->keyword_pv), 0);
	}
	nxck_entersub = PL_check[OP_ENTERSUB];
	PL_check[OP_ENTERSUB] = myck_entersub;
}
