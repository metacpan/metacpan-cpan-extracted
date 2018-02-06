#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_SvRX
#include "ppport.h"

#if defined(cv_set_call_checker) && defined(XopENTRY_set)
# define USE_CUSTOM_OPS 1
#else
# define USE_CUSTOM_OPS 0
#endif

/* Boolean expression that considers an SV* named "ref" */
#define COND(expr) (SvROK(ref) && expr)

#define PLAIN         (!sv_isobject(ref))
#define REFTYPE(tail) (SvTYPE(SvRV(ref)) tail)
#define REFREF        (SvROK( SvRV(ref) ))

#define JUSTSCALAR (                            \
        REFTYPE(< SVt_PVAV)                     \
        && REFTYPE(!= SVt_PVGV)                 \
        && (SvTYPE(SvRV(ref)) != SVt_PVGV)      \
        && !REFREF                              \
        && !SvRXOK(ref)                         \
        )

#if PERL_VERSION >= 7
#define FORMATREF REFTYPE(== SVt_PVFM)
#else
#define FORMATREF (croak("is_formatref() isn't available on Perl 5.6.x and under"), 0)
#endif

#define FUNC_BODY(cond)                                 \
  {                                                     \
    SV *ref = TOPs;                                     \
    SvGETMAGIC(ref);                                    \
    SETs( COND(cond) ? &PL_sv_yes : &PL_sv_no );        \
  }

#define DECL_RUNTIME_FUNC(x, cond)                              \
    static void                                                 \
    THX_xsfunc_ ## x (pTHX_ CV *cv)                             \
    {                                                           \
        dXSARGS;                                                \
        if (items != 1)                                         \
            Perl_croak(aTHX_ "Usage: Ref::Util::XS::" #x "(ref)");  \
        FUNC_BODY(cond);                                        \
    }

#define DECL_XOP(x) \
    static XOP x ## _xop;

#define DECL_MAIN_FUNC(x, cond)                 \
    static OP *                                 \
    x ## _op(pTHX)                              \
    {                                           \
        dSP;                                    \
        FUNC_BODY(cond);                        \
        return NORMAL;                          \
    }

#define DECL_CALL_CHK_FUNC(x)                                                  \
    static OP *                                                                \
    THX_ck_entersub_args_ ## x(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)    \
    {                                                                          \
        return call_checker_common(aTHX_ entersubop, namegv, ckobj, x ## _op); \
    }

#if !USE_CUSTOM_OPS

#define DECL(x, cond) DECL_RUNTIME_FUNC(x, cond)
#define INSTALL(x, ref) \
    newXSproto("Ref::Util::XS::" #x, THX_xsfunc_ ## x, __FILE__, "$");

#else

#define DECL(x, cond)                           \
    DECL_RUNTIME_FUNC(x, cond)                  \
    DECL_XOP(x)                                 \
    DECL_MAIN_FUNC(x, cond)                     \
    DECL_CALL_CHK_FUNC(x)

#define INSTALL(x, ref)                                               \
    {                                                                 \
        CV *cv;                                                       \
        XopENTRY_set(& x ##_xop, xop_name, #x);                       \
        XopENTRY_set(& x ##_xop, xop_desc, "'" ref "' ref check");    \
        XopENTRY_set(& x ##_xop, xop_class, OA_UNOP);                 \
        Perl_custom_op_register(aTHX_ x ##_op, & x ##_xop);           \
        cv = newXSproto_portable(                                     \
            "Ref::Util::XS::" #x, THX_xsfunc_ ## x, __FILE__, "$"         \
        );                                                            \
        cv_set_call_checker(cv, THX_ck_entersub_args_ ## x, (SV*)cv); \
    }

// This function extracts the args for the custom op, and deletes the remaining
// ops from memory, so they can then be replaced entirely by the custom op.
/*
    This is how the ops will look like:

    $ perl -MO=Concise -E'is_arrayref($foo)'
    7  <@> leave[1 ref] vKP/REFC ->(end)
    1     <0> enter ->2
    2     <;> nextstate(main 47 -e:1) v:%,{,469764096 ->3
    6     <1> entersub[t4] vKS/TARG ->7
    -        <1> ex-list K ->6
    3           <0> pushmark s ->4
    -           <1> ex-rv2sv sKM/1 ->5
    4              <#> gvsv[*foo] s ->5
    -           <1> ex-rv2cv sK ->-
    5              <#> gv[*is_arrayref] ->6
*/
static OP *
call_checker_common(pTHX_ OP *entersubop, GV *namegv, SV *ckobj, OP* (*op_ppaddr)(pTHX))
{
    OP *pushop = NULL;
    OP *arg = NULL;
    OP *newop = NULL;

    /* fix up argument structures */
    entersubop = ck_entersub_args_proto(entersubop, namegv, ckobj);

    /* extract the args for the custom op, and delete the remaining ops
       NOTE: this is the *single* arg version, multi-arg is more
       complicated, see Hash::SharedMem's THX_ck_entersub_args_hsm */

    /* These comments will visualize how the op tree look like after
       each operation. We usually start out with this: */
    /* --> entersub( list( push, arg1, cv ) ) */
    /* Though in rare cases it can also look like this: */
    /* --> entersub( push, arg1, cv ) */

    /* first, get the real pushop, after which comes the arg list */

    /* Cast the entersub op as an op with a single child */
    /* and get that child (the args list or pushop). */
    pushop = cUNOPx( entersubop )->op_first;

    /* At this point we're still not sure if it's the right op,
       (because it should normally be a list() with the push inside it)
       so we check whether it has siblings or not. The list() has no
       siblings */
    /* Go one layer deeper to get at the real pushop. */
    if( !OpHAS_SIBLING( pushop ) )
      /* Fetch the actual push op from inside the list() op */
      pushop = cUNOPx( pushop )->op_first;

    /* then extract the arg */
    /* Get a pointer to the first arg op */
    /* so we can attach it to the custom op later on. */
    /* Notice "ex-rv2sv" calls are optimized away. */
    arg = OpSIBLING( pushop );

    /* --> entersub( list( push, arg1, cv ) ) + ( arg1, cv ) */

    /* and prepare to delete the other ops */
    /* Replace the first op of the arg list with the last arg op
       (the cv op, i.e. pointer to original xs function),
       which allows recursive deletion of all unneeded ops
       while keeping the arg list. */
    OpMORESIB_set( pushop, OpSIBLING( arg ) );
    /* --> entersub( list( push, cv ) ) + ( arg1, cv ) */

    /* Remove the trailing cv op from the arg list,
       by declaring the arg to be the last sibling in the arg list. */
    OpLASTSIB_set( arg, NULL );
    /* --> entersub( list( push, cv ) ) */
    /* --> arg1                         */

    /* Recursively free entersubop + children,
       as it'll be replaced by the op we return. */
    op_free( entersubop );
    /* --> ( arg1 ) */

    /* create and return new op */
    newop = newUNOP( OP_NULL, 0, arg );
    /* can't do this in the new above, due to crashes pre-5.22 */
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = op_ppaddr;
    /* --> custom_op( arg1 ) */

    return newop;
}

#endif

DECL(is_ref,             1)
DECL(is_scalarref,       JUSTSCALAR)
DECL(is_arrayref,        REFTYPE(== SVt_PVAV))
DECL(is_hashref,         REFTYPE(== SVt_PVHV))
DECL(is_coderef,         REFTYPE(== SVt_PVCV))
DECL(is_globref,         REFTYPE(== SVt_PVGV))
DECL(is_formatref,       FORMATREF)
DECL(is_ioref,           REFTYPE(== SVt_PVIO))
DECL(is_regexpref,       SvRXOK(ref))
DECL(is_refref,          REFREF)

DECL(is_plain_ref,       PLAIN)
DECL(is_plain_scalarref, JUSTSCALAR && PLAIN)
DECL(is_plain_arrayref,  REFTYPE(== SVt_PVAV) && PLAIN)
DECL(is_plain_hashref,   REFTYPE(== SVt_PVHV) && PLAIN)
DECL(is_plain_coderef,   REFTYPE(== SVt_PVCV) && PLAIN)
DECL(is_plain_globref,   REFTYPE(== SVt_PVGV) && PLAIN)
DECL(is_plain_formatref, FORMATREF && PLAIN)
DECL(is_plain_ioref,     REFTYPE(== SVt_PVIO) && PLAIN)
DECL(is_plain_refref,    REFREF && PLAIN)

DECL(is_blessed_ref,       !PLAIN)
DECL(is_blessed_scalarref, JUSTSCALAR && !PLAIN)
DECL(is_blessed_arrayref,  REFTYPE(== SVt_PVAV) && !PLAIN)
DECL(is_blessed_hashref,   REFTYPE(== SVt_PVHV) && !PLAIN)
DECL(is_blessed_coderef,   REFTYPE(== SVt_PVCV) && !PLAIN)
DECL(is_blessed_globref,   REFTYPE(== SVt_PVGV) && !PLAIN)
DECL(is_blessed_formatref, FORMATREF && !PLAIN)
DECL(is_blessed_ioref,     REFTYPE(== SVt_PVIO) && !PLAIN)
DECL(is_blessed_refref,    REFREF && !PLAIN)

MODULE = Ref::Util::XS		PACKAGE = Ref::Util::XS

PROTOTYPES: DISABLE

BOOT:
    {
        INSTALL( is_ref, "" )
        INSTALL( is_scalarref, "SCALAR" )
        INSTALL( is_arrayref,  "ARRAY"  )
        INSTALL( is_hashref,   "HASH"   )
        INSTALL( is_coderef,   "CODE"   )
        INSTALL( is_regexpref, "REGEXP" )
        INSTALL( is_globref,   "GLOB"   )
        INSTALL( is_formatref, "FORMAT" )
        INSTALL( is_ioref,     "IO"     )
        INSTALL( is_refref,    "REF"    )
        INSTALL( is_plain_ref, "plain" )
        INSTALL( is_plain_scalarref, "plain SCALAR" )
        INSTALL( is_plain_arrayref,  "plain ARRAY"  )
        INSTALL( is_plain_hashref,   "plain HASH"   )
        INSTALL( is_plain_coderef,   "plain CODE"   )
        INSTALL( is_plain_globref,   "plain GLOB"   )
        INSTALL( is_plain_formatref,   "plain FORMAT"   )
        INSTALL( is_plain_refref,   "plain REF"   )
        INSTALL( is_blessed_ref, "blessed" )
        INSTALL( is_blessed_scalarref, "blessed SCALAR" )
        INSTALL( is_blessed_arrayref,  "blessed ARRAY"  )
        INSTALL( is_blessed_hashref,   "blessed HASH"   )
        INSTALL( is_blessed_coderef,   "blessed CODE"   )
        INSTALL( is_blessed_globref,   "blessed GLOB"   )
        INSTALL( is_blessed_formatref,   "blessed FORMAT"   )
        INSTALL( is_blessed_refref,   "blessed REF"   )
    }

SV *
_using_custom_ops()
    PPCODE:
        /* This is provided for the test suite; do not use it. */
        /* Use if-else below because ternary operator cannot build on Sun
           Studio 11 and 12. */
        if (USE_CUSTOM_OPS) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
