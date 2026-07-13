#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "strigram.h"
#include "strigram_compat.h"

#define STRIGRAM_FROM_SV(sv) INT2PTR(strigram_t *, SvIV(SvRV(sv)))

/* ======================================================
   Custom op descriptors
   ====================================================== */

static XOP xop_strigram_add;
static XOP xop_strigram_search;
static XOP xop_strigram_remove;
static XOP xop_strigram_clear;
static XOP xop_strigram_optimize;
static XOP xop_strigram_doc_count;
static XOP xop_strigram_trigram_count;

/* ======================================================
   pp_ implementations
   ====================================================== */

/* BINOP: self (TOPs), text (POPs) -> UV doc_id replaces self */
static OP *
pp_strigram_add(pTHX) {
    dSP;
    SV        *text_sv = POPs;
    SV        *self    = TOPs;
    STRLEN     len;
    const char *str    = SvPVutf8(text_sv, len);
    SETs(sv_2mortal(newSVuv(
        (UV)strigram_add(STRIGRAM_FROM_SV(self), str, (uint32_t)len))));
    RETURN;
}

/* BINOP: self (TOPs), query (POPs) -> AV ref replaces self.
   limit from op_targ (0 = use default 10; non-zero = that value). */
static OP *
pp_strigram_search(pTHX) {
    dSP;
    SV                *query_sv = POPs;
    SV                *self     = TOPs;
    uint32_t           limit    = PL_op->op_targ ? (uint32_t)PL_op->op_targ : 10;
    STRLEN             qlen;
    const char        *qstr;
    uint32_t           rcount   = 0;
    strigram_result_t *results;
    AV                *av;
    uint32_t           i;

    qstr    = SvPVutf8(query_sv, qlen);
    results = strigram_search(STRIGRAM_FROM_SV(self), qstr, (uint32_t)qlen,
                              limit, &rcount);
    av = newAV();
    if (results) {
        for (i = 0; i < rcount; i++) {
            HV *hv = newHV();
            hv_stores(hv, "doc_id", newSVuv(results[i].doc_id));
            hv_stores(hv, "score",  newSVnv(results[i].score));
            hv_stores(hv, "text",
                newSVpvn_flags(results[i].text, results[i].text_len, SVf_UTF8));
            av_push(av, newRV_noinc((SV *)hv));
        }
        strigram_results_free(results);
    }
    SETs(sv_2mortal(newRV_noinc((SV *)av)));
    RETURN;
}

/* BINOP: self (POPs), doc_id (POPs) -> void */
static OP *
pp_strigram_remove(pTHX) {
    dSP;
    SV *id_sv = POPs;
    SV *self  = POPs;
    strigram_remove(STRIGRAM_FROM_SV(self), (uint32_t)SvUV(id_sv));
    RETURN;
}

/* UNOP: self (POPs) -> void */
static OP *
pp_strigram_clear(pTHX) {
    dSP;
    SV *self = POPs;
    strigram_clear(STRIGRAM_FROM_SV(self));
    RETURN;
}

/* UNOP: self (POPs) -> void */
static OP *
pp_strigram_optimize(pTHX) {
    dSP;
    SV *self = POPs;
    strigram_optimize(STRIGRAM_FROM_SV(self));
    RETURN;
}

/* UNOP: self (TOPs) -> UV replaces self */
static OP *
pp_strigram_doc_count(pTHX) {
    dSP;
    SV *self = TOPs;
    SETs(sv_2mortal(newSVuv(
        (UV)strigram_doc_count(STRIGRAM_FROM_SV(self)))));
    RETURN;
}

/* UNOP: self (TOPs) -> UV replaces self */
static OP *
pp_strigram_trigram_count(pTHX) {
    dSP;
    SV *self = TOPs;
    SETs(sv_2mortal(newSVuv(
        (UV)strigram_trigram_count(STRIGRAM_FROM_SV(self)))));
    RETURN;
}

/* ======================================================
   Call checkers
   ====================================================== */

static int
strigram_simple_op(OP *op) {
    if (!op) return 0;
    switch (op->op_type) {
        case OP_PADSV:
        case OP_CONST:
        case OP_GV:
        case OP_GVSV:
        case OP_AELEMFAST:
#if defined(OP_AELEMFAST_LEX) && OP_AELEMFAST_LEX != OP_AELEMFAST
        case OP_AELEMFAST_LEX:
#endif
        case OP_NULL:
            return 1;
        default:
            return 0;
    }
}

/* Walk entersub op tree into its components. */
static void
strigram_walk_args(OP *entersubop,
                   OP **pushop_out, OP **selfop_out,
                   OP **argop_out,  OP **cvop_out)
{
    OP *pushop, *selfop, *argop, *cvop;
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop))
        pushop = cUNOPx(pushop)->op_first;
    selfop = OpSIBLING(pushop);
    cvop = argop = selfop;
    while (OpHAS_SIBLING(cvop)) {
        argop = cvop;
        cvop  = OpSIBLING(cvop);
    }
    *pushop_out = pushop;
    *selfop_out = selfop;
    *argop_out  = argop;
    *cvop_out   = cvop;
}

/* Stamp out per-method call checkers with macros to avoid storing
   function pointers in ckobj (non-portable cast on some platforms). */

#define STRIGRAM_CK_UNOP(ck_name, pp_func)                              \
static OP *                                                               \
ck_name(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)                   \
{                                                                         \
    OP *pushop, *selfop, *argop, *cvop, *newop;                          \
    PERL_UNUSED_ARG(namegv);                                              \
    PERL_UNUSED_ARG(ckobj);                                               \
    strigram_walk_args(entersubop, &pushop, &selfop, &argop, &cvop);     \
    if (argop != selfop) return entersubop;                               \
    if (!strigram_simple_op(selfop)) return entersubop;                   \
    OpMORESIB_set(pushop, cvop);                                          \
    OpLASTSIB_set(selfop, NULL);                                          \
    newop = newUNOP(OP_NULL, 0, selfop);                                  \
    newop->op_type   = OP_CUSTOM;                                         \
    newop->op_ppaddr = pp_func;                                           \
    op_free(entersubop);                                                  \
    return newop;                                                          \
}

#define STRIGRAM_CK_BINOP(ck_name, pp_func)                              \
static OP *                                                               \
ck_name(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)                   \
{                                                                         \
    OP *pushop, *selfop, *argop, *cvop, *newop;                          \
    PERL_UNUSED_ARG(namegv);                                              \
    PERL_UNUSED_ARG(ckobj);                                               \
    strigram_walk_args(entersubop, &pushop, &selfop, &argop, &cvop);     \
    if (argop == selfop) return entersubop;                               \
    if (OpSIBLING(selfop) != argop) return entersubop;                   \
    if (!strigram_simple_op(selfop) || !strigram_simple_op(argop))       \
        return entersubop;                                                 \
    OpMORESIB_set(pushop, cvop);                                          \
    OpLASTSIB_set(argop, NULL);                                           \
    OpLASTSIB_set(selfop, NULL);                                          \
    newop = newBINOP(OP_NULL, 0, selfop, argop);                          \
    newop->op_type   = OP_CUSTOM;                                         \
    newop->op_ppaddr = pp_func;                                           \
    op_free(entersubop);                                                  \
    return newop;                                                          \
}

STRIGRAM_CK_UNOP(ck_strigram_clear,         pp_strigram_clear)
STRIGRAM_CK_UNOP(ck_strigram_optimize,      pp_strigram_optimize)
STRIGRAM_CK_UNOP(ck_strigram_doc_count,     pp_strigram_doc_count)
STRIGRAM_CK_UNOP(ck_strigram_trigram_count, pp_strigram_trigram_count)
STRIGRAM_CK_BINOP(ck_strigram_add,          pp_strigram_add)
STRIGRAM_CK_BINOP(ck_strigram_remove,       pp_strigram_remove)

/* search: BINOP(self, query) with optional compile-time constant limit
   embedded in op_targ.  Falls back to XS when limit is a runtime variable. */
static OP *
ck_strigram_search(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    OP *pushop, *selfop, *argop, *cvop;
    OP *queryop, *limitop, *newop;
    PADOFFSET limit_val;
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);

    strigram_walk_args(entersubop, &pushop, &selfop, &argop, &cvop);

    if (argop == selfop) return entersubop; /* no query arg */

    queryop   = OpSIBLING(selfop);
    limit_val = 0; /* 0 means pp_ uses default 10 */

    if (queryop == argop) {
        /* $idx->search($query) — no limit supplied */
        if (!strigram_simple_op(selfop) || !strigram_simple_op(queryop))
            return entersubop;
        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(queryop, NULL);
        OpLASTSIB_set(selfop, NULL);
    } else {
        /* $idx->search($query, $limit) */
        limitop = OpSIBLING(queryop);
        if (limitop != argop) return entersubop; /* > 2 extra args */
        /* Only inline when limit is a compile-time constant */
        if (limitop->op_type != OP_CONST) return entersubop;
        if (!strigram_simple_op(selfop) || !strigram_simple_op(queryop))
            return entersubop;
        limit_val = (PADOFFSET)SvUV(cSVOPx(limitop)->op_sv);
        if (limit_val == 0) limit_val = 10;
        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(queryop, NULL);
        OpLASTSIB_set(selfop, NULL);
        OpLASTSIB_set(limitop, NULL); /* clear before freeing */
        op_free(limitop);
    }

    newop = newBINOP(OP_NULL, 0, selfop, queryop);
    newop->op_type   = OP_CUSTOM;
    newop->op_ppaddr = pp_strigram_search;
    newop->op_targ   = limit_val;

    op_free(entersubop);
    return newop;
}

/* ======================================================
   XS module (fallbacks for non-optimisable call sites)
   ====================================================== */

MODULE = Search::Trigram  PACKAGE = Search::Trigram

SV *
new(class)
    const char *class
    CODE:
        strigram_t *idx = strigram_new();
        SV *obj = newSV(0);
        sv_setref_pv(obj, class, (void *)idx);
        RETVAL = obj;
    OUTPUT:
        RETVAL

UV
add(self, text)
    SV *self
    SV *text
    CODE:
        strigram_t *idx = STRIGRAM_FROM_SV(self);
        STRLEN len;
        const char *str = SvPVutf8(text, len);
        RETVAL = (UV)strigram_add(idx, str, (uint32_t)len);
    OUTPUT:
        RETVAL

SV *
search(self, query, ...)
    SV *self
    SV *query
    CODE:
        strigram_t *idx = STRIGRAM_FROM_SV(self);
        uint32_t limit = (items > 2) ? (uint32_t)SvUV(ST(2)) : 10;
        STRLEN qlen;
        const char *qstr = SvPVutf8(query, qlen);
        uint32_t rcount = 0;
        strigram_result_t *results =
            strigram_search(idx, qstr, (uint32_t)qlen, limit, &rcount);
        AV *av = newAV();
        if (results) {
            uint32_t i;
            for (i = 0; i < rcount; i++) {
                HV *hv = newHV();
                hv_stores(hv, "doc_id", newSVuv(results[i].doc_id));
                hv_stores(hv, "score",  newSVnv(results[i].score));
                hv_stores(hv, "text",
                    newSVpvn_flags(results[i].text, results[i].text_len,
                                   SVf_UTF8));
                av_push(av, newRV_noinc((SV *)hv));
            }
            strigram_results_free(results);
        }
        RETVAL = newRV_noinc((SV *)av);
    OUTPUT:
        RETVAL

void
remove(self, doc_id)
    SV     *self
    UV      doc_id
    CODE:
        strigram_remove(STRIGRAM_FROM_SV(self), (uint32_t)doc_id);

void
optimize(self)
    SV *self
    CODE:
        strigram_optimize(STRIGRAM_FROM_SV(self));

void
clear(self)
    SV *self
    CODE:
        strigram_clear(STRIGRAM_FROM_SV(self));

UV
doc_count(self)
    SV *self
    CODE:
        RETVAL = (UV)strigram_doc_count(STRIGRAM_FROM_SV(self));
    OUTPUT:
        RETVAL

UV
trigram_count(self)
    SV *self
    CODE:
        RETVAL = (UV)strigram_trigram_count(STRIGRAM_FROM_SV(self));
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV *self
    CODE:
        strigram_free(STRIGRAM_FROM_SV(self));

BOOT:
{
    SV *empty = newSViv(0);
    CV *cv;

    XopENTRY_set(&xop_strigram_add, xop_name,  "strigram_add");
    XopENTRY_set(&xop_strigram_add, xop_desc,  "trigram index: add document");
    XopENTRY_set(&xop_strigram_add, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_strigram_add, &xop_strigram_add);

    XopENTRY_set(&xop_strigram_search, xop_name,  "strigram_search");
    XopENTRY_set(&xop_strigram_search, xop_desc,  "trigram index: search");
    XopENTRY_set(&xop_strigram_search, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_strigram_search, &xop_strigram_search);

    XopENTRY_set(&xop_strigram_remove, xop_name,  "strigram_remove");
    XopENTRY_set(&xop_strigram_remove, xop_desc,  "trigram index: remove document");
    XopENTRY_set(&xop_strigram_remove, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_strigram_remove, &xop_strigram_remove);

    XopENTRY_set(&xop_strigram_clear, xop_name,  "strigram_clear");
    XopENTRY_set(&xop_strigram_clear, xop_desc,  "trigram index: clear");
    XopENTRY_set(&xop_strigram_clear, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_strigram_clear, &xop_strigram_clear);

    XopENTRY_set(&xop_strigram_optimize, xop_name,  "strigram_optimize");
    XopENTRY_set(&xop_strigram_optimize, xop_desc,  "trigram index: optimize");
    XopENTRY_set(&xop_strigram_optimize, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_strigram_optimize, &xop_strigram_optimize);

    XopENTRY_set(&xop_strigram_doc_count, xop_name,  "strigram_doc_count");
    XopENTRY_set(&xop_strigram_doc_count, xop_desc,  "trigram index: doc_count");
    XopENTRY_set(&xop_strigram_doc_count, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_strigram_doc_count, &xop_strigram_doc_count);

    XopENTRY_set(&xop_strigram_trigram_count, xop_name,  "strigram_trigram_count");
    XopENTRY_set(&xop_strigram_trigram_count, xop_desc,  "trigram index: trigram_count");
    XopENTRY_set(&xop_strigram_trigram_count, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_strigram_trigram_count, &xop_strigram_trigram_count);

    cv = get_cv("Search::Trigram::add", 0);
    if (cv) cv_set_call_checker(cv, ck_strigram_add, empty);

    cv = get_cv("Search::Trigram::search", 0);
    if (cv) cv_set_call_checker(cv, ck_strigram_search, empty);

    cv = get_cv("Search::Trigram::remove", 0);
    if (cv) cv_set_call_checker(cv, ck_strigram_remove, empty);

    cv = get_cv("Search::Trigram::clear", 0);
    if (cv) cv_set_call_checker(cv, ck_strigram_clear, empty);

    cv = get_cv("Search::Trigram::optimize", 0);
    if (cv) cv_set_call_checker(cv, ck_strigram_optimize, empty);

    cv = get_cv("Search::Trigram::doc_count", 0);
    if (cv) cv_set_call_checker(cv, ck_strigram_doc_count, empty);

    cv = get_cv("Search::Trigram::trigram_count", 0);
    if (cv) cv_set_call_checker(cv, ck_strigram_trigram_count, empty);

    SvREFCNT_dec(empty);
}
