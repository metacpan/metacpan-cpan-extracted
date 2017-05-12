#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"
#include "ptr_table.h"

#ifndef SvPAD_TYPED
#define SvPAD_TYPED(sv) (SvFLAGS(sv) & SVpad_TYPED)
#endif

#ifndef SvPAD_OUR
#define SvPAD_OUR(sv) (SvFLAGS(sv) & SVpad_OUR)
#endif

#ifdef DEBUGGING
#define NO_OP_CUSTOM
#endif

#ifndef NO_OP_CUSTOM
#define OP_SCALAR_ALIAS  OP_CUSTOM
#define OP_LIST_ALIAS    OP_CUSTOM
#define OP_ALIASED_PADSV OP_CUSTOM
#else
#define OP_SCALAR_ALIAS  OP_PADSV
#define OP_LIST_ALIAS    OP_AASSIGN
#define OP_ALIASED_PADSV OP_PADSV
#endif

#define MyAliasDecl(padname) (SvPAD_TYPED(padname) && SvSTASH(padname) == MY_CXT.alias_stash)

#define PACKAGE "Scalar::Alias"

#define MY_CXT_VARS HV* alias_stash;
#include "peephook.h"


static OP*
sa_pp_scalar_alias(pTHX){
	dVAR; dSP;
	dTOPss;                              /* right-hand side value */
	PADOFFSET const po = PL_op->op_targ; /* left-hand side variable */

	if(SvTEMP(sv)){
		SAVEGENERICSV(PAD_SVl(po));

		SvREFCNT_inc_simple_void_NN(sv);
	}
	else{
		SAVESPTR(PAD_SVl(po));
	}

	PAD_SVl(po) = sv;

	SETs(sv);
	RETURN;
}

/* stolen from Perl_do_runcv() in pp_ctl.c */
static CV*
sa_find_runcv(pTHX){
	dVAR;
	PERL_SI *si;

	for(si = PL_curstackinfo; si; si = si->si_prev) {
		PERL_CONTEXT*       cxp = si->si_cxstack + si->si_cxix;
		PERL_CONTEXT* const end = si->si_cxstack - 1;

		while(cxp != end){
			switch(CxTYPE(cxp)){
			case CXt_SUB:
			case CXt_FORMAT:
				return cxp->blk_sub.cv;
			case CXt_EVAL:
				if(!CxTRYBLOCK(cxp)){
					return PL_compcv;
				}
			}

			cxp--;
		}
	}
	return PL_main_cv;
}

static OP*
sa_pp_aliased_padsv(pTHX){
	dVAR; dSP; dTARGET;

	if(!SvOK(TARG)){
		PADOFFSET const po = PL_op->op_targ;
		CV* const cv       = sa_find_runcv(aTHX);
		SV* const padname  = AvARRAY((AV*)AvARRAY(CvPADLIST(cv))[0])[po];

		/* replace TARG (PAD_SV(po)) with padname */

		PAD_SVl(po) = padname;
		SvREFCNT_inc_simple_void_NN(padname);

		SvREFCNT_dec(TARG);
		TARG = padname;

		/* use padname as an alias marker */
		SvUV_set(padname, po);
	}

	assert(PL_op->op_flags   & OPf_MOD);
	assert(PL_op->op_private & OPpLVAL_INTRO);
	assert(!(PL_op->op_private &OPpDEREF));

	XPUSHs(TARG);
	RETURN;
}

/* pp_assign() requires do_oddball() */
#define do_oddball(hv, svp1, svp2) S_do_oddball(aTHX_ hv, svp1, svp2)
STATIC void
S_do_oddball(pTHX_ HV *hash, SV **relem, SV **firstrelem)
{
    dVAR;
    if (*relem) {
	SV *tmpstr;
        const HE *didstore;

        if (ckWARN(WARN_MISC)) {
	    const char *err;
	    if (relem == firstrelem &&
		SvROK(*relem) &&
		(SvTYPE(SvRV(*relem)) == SVt_PVAV ||
		 SvTYPE(SvRV(*relem)) == SVt_PVHV))
	    {
		err = "Reference found where even-sized list expected";
	    }
	    else
		err = "Odd number of elements in hash assignment";
	    Perl_warner(aTHX_ packWARN(WARN_MISC), err);
	}

        tmpstr = newSV(0);
        didstore = hv_store_ent(hash,*relem,tmpstr,0);
        if (SvMAGICAL(hash)) {
            if (SvSMAGICAL(tmpstr))
                mg_set(tmpstr);
            if (!didstore)
                (void)sv_2mortal(tmpstr);
        }
        TAINT_NOT;
    }
}


/* Almost the same as pp_aassign() */
static OP*
sa_pp_list_alias(pTHX){
    dVAR; dSP;
    dMY_CXT;
    SV ** const lastlelem  = SP;
    SV ** const lastrelem  = PL_stack_base + POPMARK;
    SV ** const firstrelem = PL_stack_base + POPMARK + 1;
    SV ** const firstlelem = lastrelem + 1;

    register SV **relem;
    register SV **lelem;

    register SV *sv;

    AV *ary  = NULL;
    HV *hash = NULL;

    I32 const gimme = GIMME_V;
    I32 i;
    int magic;
    int const common = PL_op->op_private & OPpASSIGN_COMMON;

    PL_delaymagic = DM_DELAY;		/* catch simultaneous items */

    /* If there's a common identifier on both sides we have to take
     * special care that assigning the identifier on the left doesn't
     * clobber a value on the right that's used later in the list.
     */
    if (common) {
		/* In special case (includes swapping): */
		relem = firstrelem;
		lelem = firstlelem;
		while (lelem <= lastlelem) {
			sv = *lelem++;
			if (relem <= lastrelem) {
				if(MyAliasDecl(sv)){
					PADOFFSET const po = SvUVX(sv);

					assert(po != 0);
					if(SvTEMP(*relem)){
						SAVEGENERICSV(PAD_SVl(po));

						SvREFCNT_inc_simple_void_NN(*relem);
					}
					else{
						SAVESPTR(PAD_SVl(po));
					}

					PAD_SVl(po) = *relem;
				}
				relem++;
			}
			else{
				break;
			}
		}


		EXTEND_MORTAL(lastrelem - firstrelem + 1);
		for (relem = firstrelem; relem <= lastrelem; relem++) {
			*relem = sv_mortalcopy(*relem);
		}
    }

    relem = firstrelem;
    lelem = firstlelem;

    while (lelem <= lastlelem) {
	TAINT_NOT;		/* Each item stands on its own, taintwise. */
	sv = *lelem++;
	switch (SvTYPE(sv)) {
	case SVt_PVAV:
	    ary = (AV*)sv;
	    magic = SvMAGICAL(ary);
	    av_clear(ary);
	    av_extend(ary, lastrelem - relem);
	    i = 0;
	    while (relem <= lastrelem) {	/* gobble up all the rest */
		SV **didstore;
		assert(*relem);
		sv = newSVsv(*relem);
		*(relem++) = sv;
		didstore = av_store(ary,i++,sv);
		if (magic) {
		    if (SvSMAGICAL(sv)) {
			/* More magic can happen in the mg_set callback, so we
			 * backup the delaymagic for now. */
			U16 const dmbak = PL_delaymagic;
			PL_delaymagic = 0;
			mg_set(sv);
			PL_delaymagic = dmbak;
		    }
		    if (!didstore)
			(void)sv_2mortal(sv);
		}
		TAINT_NOT;
	    }
#ifdef DM_ARRAY
	    if (PL_delaymagic & DM_ARRAY)
		SvSETMAGIC((SV*)ary);
#endif
	    break;
	case SVt_PVHV: {				/* normal hash */
		SV *tmpstr;

		hash = (HV*)sv;
		magic = SvMAGICAL(hash);
		hv_clear(hash);

		while (relem < lastrelem) {	/* gobble up all the rest */
		    HE *didstore;
		    sv = *relem ? *relem : &PL_sv_no;
		    relem++;
		    tmpstr = newSV(0);
		    sv_setsv(tmpstr,*relem);	/* value */
		    *(relem++) = tmpstr;
		    didstore = hv_store_ent(hash,sv,tmpstr,0);
		    if (magic) {
			if (SvSMAGICAL(tmpstr)) {
			    U16 const dmbak = PL_delaymagic;
			    PL_delaymagic = 0;
			    mg_set(tmpstr);
			    PL_delaymagic = dmbak;
			}
			if (!didstore)
			    (void)sv_2mortal(tmpstr);
		    }
		    TAINT_NOT;
		}
		if (relem == lastrelem) {
		    do_oddball(hash, relem, firstrelem);
		    relem++;
		}
	    }
	    break;
	default:
	    if(sv == &PL_sv_undef) {
		if (relem <= lastrelem)
		    relem++;
		break;
	    }
	    if (relem <= lastrelem) {
		if(MyAliasDecl(sv)){
			if(!common){
				PADOFFSET const po = SvUVX(sv);

				assert(po != 0);
				if(SvTEMP(*relem)){
					SAVEGENERICSV(PAD_SVl(po));

					SvREFCNT_inc_simple_void_NN(*relem);
				}
				else{
					SAVESPTR(PAD_SVl(po));
				}

				PAD_SVl(po) = *relem;
			}
		}
		else{
			sv_setsv(sv, *relem);
			*relem = sv;
		}
		relem++;
	    }
	    else
		sv_setsv(sv, &PL_sv_undef);

	    if (SvSMAGICAL(sv)) {
		U16 const dmbak = PL_delaymagic;
		PL_delaymagic = 0;
		mg_set(sv);
		PL_delaymagic = dmbak;
	    }
	    break;
	}
    }
    if (PL_delaymagic & ~DM_DELAY) {
	if (PL_delaymagic & DM_UID) {
#ifdef HAS_SETRESUID
	    (void)setresuid((PL_delaymagic & DM_RUID) ? PL_uid  : (Uid_t)-1,
			    (PL_delaymagic & DM_EUID) ? PL_euid : (Uid_t)-1,
			    (Uid_t)-1);
#else
#  ifdef HAS_SETREUID
	    (void)setreuid((PL_delaymagic & DM_RUID) ? PL_uid  : (Uid_t)-1,
			   (PL_delaymagic & DM_EUID) ? PL_euid : (Uid_t)-1);
#  else
#    ifdef HAS_SETRUID
	    if ((PL_delaymagic & DM_UID) == DM_RUID) {
		(void)setruid(PL_uid);
		PL_delaymagic &= ~DM_RUID;
	    }
#    endif /* HAS_SETRUID */
#    ifdef HAS_SETEUID
	    if ((PL_delaymagic & DM_UID) == DM_EUID) {
		(void)seteuid(PL_euid);
		PL_delaymagic &= ~DM_EUID;
	    }
#    endif /* HAS_SETEUID */
	    if (PL_delaymagic & DM_UID) {
		if (PL_uid != PL_euid)
		    DIE(aTHX_ "No setreuid available");
		(void)PerlProc_setuid(PL_uid);
	    }
#  endif /* HAS_SETREUID */
#endif /* HAS_SETRESUID */
	    PL_uid = PerlProc_getuid();
	    PL_euid = PerlProc_geteuid();
	}
	if (PL_delaymagic & DM_GID) {
#ifdef HAS_SETRESGID
	    (void)setresgid((PL_delaymagic & DM_RGID) ? PL_gid  : (Gid_t)-1,
			    (PL_delaymagic & DM_EGID) ? PL_egid : (Gid_t)-1,
			    (Gid_t)-1);
#else
#  ifdef HAS_SETREGID
	    (void)setregid((PL_delaymagic & DM_RGID) ? PL_gid  : (Gid_t)-1,
			   (PL_delaymagic & DM_EGID) ? PL_egid : (Gid_t)-1);
#  else
#    ifdef HAS_SETRGID
	    if ((PL_delaymagic & DM_GID) == DM_RGID) {
		(void)setrgid(PL_gid);
		PL_delaymagic &= ~DM_RGID;
	    }
#    endif /* HAS_SETRGID */
#    ifdef HAS_SETEGID
	    if ((PL_delaymagic & DM_GID) == DM_EGID) {
		(void)setegid(PL_egid);
		PL_delaymagic &= ~DM_EGID;
	    }
#    endif /* HAS_SETEGID */
	    if (PL_delaymagic & DM_GID) {
		if (PL_gid != PL_egid)
		    DIE(aTHX_ "No setregid available");
		(void)PerlProc_setgid(PL_gid);
	    }
#  endif /* HAS_SETREGID */
#endif /* HAS_SETRESGID */
	    PL_gid = PerlProc_getgid();
	    PL_egid = PerlProc_getegid();
	}
	PL_tainting |= (PL_uid && (PL_euid != PL_uid || PL_egid != PL_gid));
    }
    PL_delaymagic = 0;

    /* return values */
    if (gimme == G_VOID)
	SP = firstrelem - 1;
    else if (gimme == G_SCALAR) {
	dTARGET;
	SP = firstrelem;
	SETi(lastrelem - firstrelem + 1); /* the number of rvalues */
    }
    else {
	if (ary)
	    SP = lastrelem;
	else if (hash) {
	    SP = lastrelem;
	}
	else
	    SP = firstrelem + (lastlelem - firstlelem);

	lelem = firstlelem + (relem - firstrelem);
	while (relem <= SP)
	    *relem++ = (lelem <= lastlelem) ? *lelem++ : &PL_sv_undef;
    }

    RETURN;
}


static void
sa_die(pTHX_ pMY_CXT_ COP* const cop, SV* const name, const char* const msg){
	dVAR;

	ptr_table_free(MY_CXT.seen);
	MY_CXT.seen = NULL;

	Perl_croak(aTHX_ "Cannot declare lexical alias %s %s at %s line %d.",
		SvPVX_const(name), msg,
		CopFILE(cop), (int)CopLINE(cop)
	);
}

static int
sa_check_alias_sassign(pTHX_ pMY_CXT_ const OP* const o){
	dVAR;
	OP* const kid = cBINOPo->op_last;

	assert(o->op_flags & OPf_KIDS);
	assert(kid != NULL);

	if(!(o->op_private & OPpASSIGN_BACKWARDS) /* not orassign, andassign nor dorassign */
		&& kid->op_type == OP_PADSV
		&& kid->op_private & OPpLVAL_INTRO
	){

		SV* const padname = AvARRAY(PL_comppad_name)[kid->op_targ];

		assert(AvFILLp(PL_comppad_name) >= (I32)kid->op_targ);

		if(MyAliasDecl(padname)){ /* my alias $foo = ... */

			return TRUE;
		}
	}

	return FALSE;
}

static void
my_peep(pTHX_ pMY_CXT_ COP* const cop, OP* const o){
	dVAR;

	switch(o->op_type){
	case OP_SASSIGN:
	if(sa_check_alias_sassign(aTHX_ aMY_CXT_ o)){
		OP* const rhs = cBINOPo->op_first;
		OP* const lhs = cBINOPo->op_last;

		/* change the left-hand side OP to pp_scalar_alias */
		lhs->op_type   = OP_SCALAR_ALIAS;
		lhs->op_ppaddr = sa_pp_scalar_alias;

		/* The right-hand side OP can be lvalue */
		rhs->op_flags |= OPf_MOD;

		if(rhs->op_type == OP_AELEM || rhs->op_type == OP_HELEM){
			rhs->op_private |= OPpLVAL_DEFER;
		}

		/* change the operator assign to null */
		op_null(o);
	}
		break;

	case OP_AASSIGN:{
		OP* kid         = cBINOPo->op_last; /* lhs */
		bool list_alias = FALSE;

		assert(kid != NULL);
		kid = kUNOP->op_first;
		assert(kid != NULL);
		assert(kid->op_type == OP_PUSHMARK);

		for(kid = kid->op_sibling; kid; kid = kid->op_sibling){
			if(kid->op_type == OP_PADSV
				&& kid->op_private & OPpLVAL_INTRO){

				SV* const padname = AvARRAY(PL_comppad_name)[kid->op_targ];

				assert(AvFILLp(PL_comppad_name) >= (I32)kid->op_targ);

				if(MyAliasDecl(padname)){
					kid->op_type   = OP_ALIASED_PADSV;
					kid->op_ppaddr = sa_pp_aliased_padsv;

					list_alias = TRUE;
				}
			}
		}

		if(list_alias){
			//warn("prepare list alias at %s line %d.\n", CopFILE(cop), (int)CopLINE(cop));
			o->op_type   = OP_LIST_ALIAS;
			o->op_ppaddr = sa_pp_list_alias;

			kid = cBINOPo->op_first; /* rhs */
			assert(kid != NULL);
			kid = kUNOP->op_first;
			assert(kid != NULL);
			assert(kid->op_type == OP_PUSHMARK);

			for(kid = kid->op_sibling; kid; kid = kid->op_sibling){
				/* The right-hand side OP can be lvalue */
				kid->op_flags |= OPf_MOD;

				if(kid->op_type == OP_AELEM || kid->op_type == OP_HELEM){
					kid->op_private |= OPpLVAL_DEFER;
				}
			}
		}
	}
		break;

	case OP_PADSV:{
		SV* const padname = AvARRAY(PL_comppad_name)[o->op_targ];

		if(MyAliasDecl(padname) /* my alias $foo */
			&& o->op_private & OPpLVAL_INTRO){

			if(o->op_private & OPpDEREF){
				sa_die(aTHX_ aMY_CXT_ cop, padname, "with dereference");
				return;
			}

			if(!(o->op_flags & OPf_REF)){
				sa_die(aTHX_ aMY_CXT_ cop, padname, "without assignment");
			}
		}
		break;
	}

	case OP_RV2SV:
	if(o->op_private & OPpOUR_INTRO){
		SV** svp         = AvARRAY(PL_comppad_name);
		SV** const end   = svp + AvFILLp(PL_comppad_name) + 1;
		GV* const gv     = cGVOPx_gv(cBINOPo->op_first);
		const char* name = GvNAME(gv);

		while(svp != end){
			if(SvPAD_OUR(*svp) && MyAliasDecl(*svp)
				&& strEQ(SvPVX_const(*svp)+1, name)){

				sa_die(aTHX_ aMY_CXT_ cop, *svp, "with our statement");
			}
			svp++;
		}
	}
		break;
	default:
		NOOP;
	}
}

static int
my_peep_enabled(pTHX_ pMY_CXT_ OP* o){
	dVAR;
	SV**       svp = AvARRAY(PL_comppad_name);
	SV** const end = svp + AvFILLp(PL_comppad_name) + 1;

	PERL_UNUSED_ARG(o);

	while(svp != end){
		if(MyAliasDecl(*svp)){
			return TRUE;
		}

		svp++;
	}

	return FALSE;
}

static void
sa_setup_opnames(pTHX){
	dVAR;
	SV* const keysv = newSV(0);
	sv_upgrade(keysv, SVt_PVIV);

	if(!PL_custom_op_names){
		PL_custom_op_names = newHV();
	}
	if(!PL_custom_op_descs){
		PL_custom_op_descs = newHV();
	}

	sv_setiv(keysv, PTR2IV(sa_pp_scalar_alias));
	hv_store_ent(PL_custom_op_names, keysv, newSVpvs("scalar_alias"), 0U);
	hv_store_ent(PL_custom_op_descs, keysv, newSVpvs("scalar alias"), 0U);

	sv_setiv(keysv, PTR2IV(sa_pp_aliased_padsv));
	hv_store_ent(PL_custom_op_names, keysv, newSVpvs("aliased_padsv"),    0U);
	hv_store_ent(PL_custom_op_descs, keysv, newSVpvs("aliased variable"), 0U);

	sv_setiv(keysv, PTR2IV(sa_pp_list_alias));
	hv_store_ent(PL_custom_op_names, keysv, newSVpvs("list_alias"),  0U);
	hv_store_ent(PL_custom_op_descs, keysv, newSVpvs("list alias"),  0U);

	SvREFCNT_dec(keysv);
}


MODULE = Scalar::Alias	PACKAGE = Scalar::Alias

PROTOTYPES: DISABLE

BOOT:
{
	MY_CXT_INIT;
	MY_CXT.alias_stash   = gv_stashpvs("alias", GV_ADD);
	sa_setup_opnames(aTHX);

	PEEPHOOK_REGISTER();
}


#ifdef USE_ITHREADS

void
CLONE(...)
CODE:
{
	MY_CXT_CLONE;
	MY_CXT.alias_stash = gv_stashpvs("alias", GV_ADD);
	PERL_UNUSED_VAR(items);
}

#endif
