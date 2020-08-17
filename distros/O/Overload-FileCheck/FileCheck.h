/*
 * FileCheck.h
 */

#ifndef XS_FILE_CHECK_H
#  define XS_FILE_CHECK_H 1

#define NEED_sv_2pv_flags
#include "ppport.h"
#include <perl.h>

#define OP_MAX	MAXO

/* informations for a single overload mock */
typedef struct {
	int is_mocked; /* int for now.. could use function later */
	OP *(*real_pp)(pTHX);
} OPMocked;

/* this could be an array but for now let's keep it as a struct */
typedef struct {
	OPMocked op[OP_MAX]; /* int for now.. could use function later */
	int offset;
} OverloadFTOps;

/* function prototypes */

/* TODO maybe move somewhere else... */

/******************************************************************************/
/*** helpers stolen from pp_sys.c ****/
/******************************************************************************/

/* If the next filetest is stacked up with this one
   (PL_op->op_private & OPpFT_STACKING), we leave
   the original argument on the stack for success,
   and skip the stacked operators on failure.
   The next few macros/functions take care of this.
*/

/* yes.... this is c code in a .h file... */

#if PERL_VERSION_GE(5,15,0)
/******************************************************************************/
/************* Perl > 5.14 ***************************************************/
/******************************************************************************/

static OP *
S_ft_return_false(pTHX_ SV *ret) {
    OP *next = NORMAL;
    dSP;

    if (PL_op->op_flags & OPf_REF) XPUSHs(ret);
    else         SETs(ret);
    PUTBACK;

    if (PL_op->op_private & OPpFT_STACKING) {
        while (next && OP_IS_FILETEST(next->op_type)
               && next->op_private & OPpFT_STACKED)
            next = next->op_next;
    }
    return next;
}

PERL_STATIC_INLINE OP *
S_ft_return_true(pTHX_ SV *ret) {
    dSP;
    if (PL_op->op_flags & OPf_REF)
        XPUSHs(PL_op->op_private & OPpFT_STACKING ? (SV *)cGVOP_gv : (ret));
    else if (!(PL_op->op_private & OPpFT_STACKING))
        SETs(ret);
    PUTBACK;
    return NORMAL;
}

#define FT_RETURNYES    return S_ft_return_true(aTHX_ &PL_sv_yes)
#define FT_RETURNNO     return S_ft_return_false(aTHX_ &PL_sv_no)
#define FT_RETURNUNDEF  return S_ft_return_false(aTHX_ &PL_sv_undef)
#define FT_RETURN_TARG  return S_ft_return_true(aTHX_ TARG)

#define FT_SETUP_dSP_IF_NEEDED

#else
/******************************************************************************/
/************* Perl <= 5.14 ***************************************************/
/******************************************************************************/

#if PERL_VERSION_GE(5,14,0)
PERL_STATIC_INLINE OP *
#else
OP *
#endif
S_ft_return_bool(pTHX_ SV *ret) {
    dSP;
    if (PL_op->op_flags & OPf_REF)
        XPUSHs(ret);
    else
        SETs(ret);
    PUTBACK;
    return NORMAL;
}

#define FT_SETUP_dSP_IF_NEEDED    dSP

#define FT_RETURNYES    RETURNX( S_ft_return_bool(aTHX_ &PL_sv_yes) )
#define FT_RETURNNO     RETURNX( S_ft_return_bool(aTHX_ &PL_sv_no) )
#define FT_RETURNUNDEF  RETURNX( S_ft_return_bool(aTHX_ &PL_sv_undef) )
#define FT_RETURN_TARG  RETURNX(PUSHs(TARG))

#endif
/******************************************************************************/
/* end check Perl version */
/******************************************************************************/

/*** end of helpers from pp_sys.c ****/

/******************************************************************************/
/*** helpers stolen from pp.h ****/
/******************************************************************************/

#  define MAYBE_DEREF_GV_flags(sv,phlags)                          \
    (                                                               \
        (void)(phlags & SV_GMAGIC && (SvGETMAGIC(sv),0)),            \
        isGV_with_GP(sv)                                              \
          ? (GV *)(sv)                                                \
          : SvROK(sv) && SvTYPE(SvRV(sv)) <= SVt_PVLV &&               \
            (SvGETMAGIC(SvRV(sv)), isGV_with_GP(SvRV(sv)))              \
             ? (GV *)SvRV(sv)                                            \
             : NULL                                                       \
    )
#  define MAYBE_DEREF_GV(sv)      MAYBE_DEREF_GV_flags(sv,SV_GMAGIC)

/*** end of helpers from pp.h ****/

/******************************************************************************/
/*** helpers stolen from handy.h ***/
/******************************************************************************/

#  if Uid_t_size > IVSIZE
#    define sv_setuid(sv, uid)       sv_setnv((sv), (NV)(uid))
#    define SvUID(sv)                SvNV(sv)
#  elif Uid_t_sign <= 0
#    define sv_setuid(sv, uid)       sv_setiv((sv), (IV)(uid))
#    define SvUID(sv)                SvIV(sv)
#  else
#    define sv_setuid(sv, uid)       sv_setuv((sv), (UV)(uid))
#    define SvUID(sv)                SvUV(sv)
#  endif /* Uid_t_size */

#  if Gid_t_size > IVSIZE
#    define sv_setgid(sv, gid)       sv_setnv((sv), (NV)(gid))
#    define SvGID(sv)                SvNV(sv)
#  elif Gid_t_sign <= 0
#    define sv_setgid(sv, gid)       sv_setiv((sv), (IV)(gid))
#    define SvGID(sv)                SvIV(sv)
#  else
#    define sv_setgid(sv, gid)       sv_setuv((sv), (UV)(gid))
#    define SvGID(sv)                SvUV(sv)
#  endif /* Gid_t_size */

/*** end of helpers from handy.h ****/

#endif /* XS_FILE_CHECK_H */