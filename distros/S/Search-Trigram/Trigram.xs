#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "strigram.h"
#include "strigram_compat.h"

#define STRIGRAM_FROM_SV(sv) INT2PTR(strigram_t *, SvIV(SvRV(sv)))

/* The shared C ABI. Must come after strigram.h and STRIGRAM_FROM_SV. */
#include "sg_abi_impl.h"

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

# ---- shared C ABI ---------------------------------------------------------

# Address of Search::Trigram's own C ABI table (sg_abi.h). A consumer XS
# module fetches this once at boot, INT2PTRs it to a `const sg_abi *`, and
# checks ->abi_version before using it. Not part of the public Perl API.
#
# Unsigned, not IV: where the loader maps this object decides the sign bit.
# A 32-bit perl above 0x7fffffff, or illumos putting shared objects up at
# 0xfffffd7f..., would hand back a negative number from PTR2IV.
UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&SG_ABI);
    OUTPUT:
        RETVAL

# The ABI version this build compiled against, for a consumer's diagnostics.
IV
_abi_version()
    CODE:
        RETVAL = SG_ABI_VERSION;
    OUTPUT:
        RETVAL

# Exercise the whole sg_abi table the way a C consumer would: resolve it from
# the UV _abi_ptr hands back, gate on abi_version, then drive index_of ->
# search through the function pointers rather than calling the C directly.
# This is how the ABI gets tested without a second distribution.
#
# Returns a list of { doc_id, score, text } hashrefs; an empty list when the
# gate rejects the table or the invocant is not an index, which is where a
# consumer would fall back to the search method.
void
_abi_selftest(self, query, limit = 10)
    SV  *self
    SV  *query
    UV   limit
    PPCODE:
    {
        const sg_abi *abi = NULL;
        void         *idx;
        sg_abi_hit    hits[64];
        uint32_t      n, i;
        STRLEN        qlen;
        const char   *q;
        {
            dSP;
            UV  ptr = 0;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            count = call_pv("Search::Trigram::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (count > 0) {
                /* Pop into a local first: before 5.30 SvUV was a macro that
                 * evaluated its argument twice, so SvUV(POPs) popped twice
                 * and read the value off whatever sat one slot lower.
                 *
                 * SvUV, not SvIV, to match the UV _abi_ptr returns: an
                 * address with the top bit set is above IV_MAX, and SvIV
                 * would clamp it rather than hand back the address. */
                SV *rv = POPs;
                if (!SvTRUE(ERRSV)) ptr = SvUV(rv);
            }
            PUTBACK; FREETMPS; LEAVE;
            if (ptr) abi = INT2PTR(const sg_abi *, ptr);
        }
        if (!abi || abi->abi_version < SG_ABI_VERSION) XSRETURN_EMPTY;

        idx = abi->index_of(aTHX_ self);
        if (!idx) XSRETURN_EMPTY;

        q = SvPVutf8(query, qlen);
        n = abi->search(idx, q, (uint32_t)qlen, (uint32_t)limit,
                        hits, (uint32_t)(sizeof hits / sizeof hits[0]));

        EXTEND(SP, (SSize_t)n);
        for (i = 0; i < n; i++) {
            HV *h = newHV();
            (void)hv_stores(h, "doc_id", newSVuv(hits[i].doc_id));
            (void)hv_stores(h, "score",  newSVnv(hits[i].score));
            (void)hv_stores(h, "text",
                newSVpvn_flags(hits[i].text, hits[i].text_len, SVf_UTF8));
            mPUSHs(newRV_noinc((SV *)h));
        }
        XSRETURN((I32)n);
    }

# add / optimize / doc_count driven through the table, so a mis-ordered entry
# shows up as a wrong answer rather than passing unnoticed.
UV
_abi_selftest_add(self, text)
    SV *self
    SV *text
    CODE:
    {
        const sg_abi *abi = INT2PTR(const sg_abi *, PTR2IV(&SG_ABI));
        void *idx = abi->index_of(aTHX_ self);
        STRLEN len;
        const char *s = SvPVutf8(text, len);
        RETVAL = idx ? (UV)abi->add(idx, s, (uint32_t)len) : 0;
        if (idx) abi->optimize(idx);
    }
    OUTPUT:
        RETVAL

UV
_abi_selftest_doc_count(self)
    SV *self
    CODE:
    {
        const sg_abi *abi = INT2PTR(const sg_abi *, PTR2IV(&SG_ABI));
        void *idx = abi->index_of(aTHX_ self);
        RETVAL = idx ? (UV)abi->doc_count(idx) : 0;
    }
    OUTPUT:
        RETVAL

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
