#include "stencil.h"

#include <stdarg.h>
#include <stdlib.h>

UV stencil_stat_scratch_allocs = 0;

/* ====================================================================
 * Render state
 * ==================================================================== */

#define STENCIL_VF_ESCAPED 0x1u  /* html filter ran; do not re-escape */

typedef struct stencil_val {
    SV     *sv;      /* NULL = undef */
    uint8_t owned;   /* consume must SvREFCNT_dec */
    uint8_t vflags;
} stencil_val;

typedef struct stencil_khent {
    const char *pv;
    STRLEN      len;
    int         utf8;
    SV         *val;
} stencil_khent;

/* Scope names are stored as (bytes, len, hash) rather than name ids:
 * name ids are per-program, and an include shares the caller's scope
 * across program boundaries. The pv points into the owning program's
 * arena, which outlives the render. */
typedef struct stencil_sname {
    const char *pv;
    uint32_t    len;
    uint32_t    hash;
} stencil_sname;

typedef struct stencil_rframe {
    int             is_hash;
    AV             *av;
    HV             *hv;
    stencil_khent  *kh;       /* sorted key/value vector (hash) */
    SV             *key_sv;   /* reused key SV (hash) */
    SSize_t         i, size;
    stencil_sname   name;     /* array var / hash key var */
    stencil_sname   val;      /* hash value var */
    uint32_t        serial;
    SV             *cur;      /* array element / key_sv */
    SV             *cur_val;  /* hash value */
    SV             *agg;      /* the iterated aggregate */
    int             agg_owned;
} stencil_rframe;

typedef struct stencil_rbind {
    stencil_sname name;
    SV           *sv;
    uint32_t      serial;
} stencil_rbind;

#define SNAME_EQ(a, b) \
    ((a).hash == (b).hash && (a).len == (b).len \
     && memcmp((a).pv, (b).pv, (a).len) == 0)

typedef struct stencil_rstate {
    /* current unit (swapped for includes / content) */
    stencil_program     *prog;
    const uint8_t       *code;
    const char          *pool;
    const stencil_cname *names;
    const stencil_cpath *paths;
    const stencil_seg   *segs;
    const stencil_cfilt *filts;      /* current unit's filter table */
    stencil_cache_ent  **incs;       /* current unit's include links */
    const char          *unit_name;
    /* content unit for {% content %} (page under a wrapper) */
    stencil_program     *content_prog;
    stencil_cache_ent  **content_incs;
    const char          *content_name;
    int                  content_done;
    /* filters */
    HV                  *filters;    /* engine's user coderef registry */
    SV                  *scratch[2]; /* filter output SVs, round-robin */
    int                  scr_i;
    /* shared render state */
    stencil_buf          buf;
    HV                  *data;
    stencil_val         *stack;
    int32_t              sp;
    stencil_rframe      *frames;
    int32_t              nf;
    stencil_rbind       *binds;
    int32_t              nb;
    uint32_t             serial;
    uint32_t             flags;
    uint32_t             last_path;
    /* error capture: message + the failing unit's name/line */
    char                 errbuf[192];
    int                  failed;
    int                  err_final;
    const char          *err_name;
    uint32_t             err_line;
} stencil_rstate;

static stencil_sname sname_of(const struct stencil_rstate *r, uint32_t id)
{
    const stencil_cname *nm = &r->names[id];
    stencil_sname s;
    s.pv   = r->pool + nm->off;
    s.len  = nm->len;
    s.hash = nm->hash;
    return s;
}

static void set_unit(stencil_rstate *r, stencil_program *prog,
                     stencil_cache_ent **incs, const char *name)
{
    r->prog      = prog;
    r->code      = stencil_prog_code(prog);
    r->pool      = stencil_prog_pool(prog);
    r->names     = stencil_prog_names(prog);
    r->paths     = stencil_prog_paths(prog);
    r->segs      = stencil_prog_segs(prog);
    r->filts     = stencil_prog_filts(prog);
    r->incs      = incs;
    r->unit_name = name;
}

/* ---- small helpers -------------------------------------------------- */

STENCIL_INLINE uint32_t vm_u32(const uint8_t *code, uint32_t *pc)
{
    uint32_t v;
    memcpy(&v, code + *pc, 4);
    *pc += 4;
    return v;
}

struct stencil_rstate;
static stencil_sname sname_of(const struct stencil_rstate *r, uint32_t id);

STENCIL_INLINE void val_release(pTHX_ stencil_val *v)
{
    if (v->owned)
        SvREFCNT_dec_NN(v->sv);
}

static uint32_t line_at(const stencil_program *prog, uint32_t off);

/* First error wins; the message is captured here, the unit name and
 * line are pinned by rfail_here at the failing op so nested-unit
 * errors report the right template. */
static int rerror(stencil_rstate *r, const char *fmt, ...)
{
    va_list ap;
    if (r->failed)
        return 0;
    r->failed = 1;
    va_start(ap, fmt);
    vsnprintf(r->errbuf, sizeof r->errbuf, fmt, ap);
    va_end(ap);
    return 0;
}

static int rfail_here(stencil_rstate *r, uint32_t at)
{
    if (!r->err_final) {
        r->err_final = 1;
        r->err_name  = r->unit_name;
        r->err_line  = line_at(r->prog, at);
    }
    return 0;
}

static int rfail(stencil_rstate *r, uint32_t at, const char *fmt, ...)
{
    va_list ap;
    if (!r->failed) {
        r->failed = 1;
        va_start(ap, fmt);
        vsnprintf(r->errbuf, sizeof r->errbuf, fmt, ap);
        va_end(ap);
    }
    return rfail_here(r, at);
}

static int rfail_path(stencil_rstate *r, uint32_t at, uint32_t pid)
{
    const stencil_cpath *p = &r->paths[pid];
    return rfail(r, at, "undef value for '%.*s'",
                 (int)p->full_len, r->pool + p->full_off);
}

static uint32_t line_at(const stencil_program *prog, uint32_t off)
{
    const stencil_cline *lines = stencil_prog_lines(prog);
    uint32_t lo = 0, hi = prog->n_lines, line = 1;
    while (lo < hi) {
        uint32_t mid = (lo + hi) / 2;
        if (lines[mid].off <= off) {
            line = lines[mid].line;
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    return line;
}

/* Perl truth, extended: an unblessed empty array/hash ref is false, so
 * `{% if items %}` guards a loop naturally. */
static int sv_truthy(pTHX_ SV *sv)
{
    if (!sv || !SvOK(sv))
        return 0;
    if (SvROK(sv) && !SvOBJECT(SvRV(sv))) {
        SV *rv = SvRV(sv);
        if (SvTYPE(rv) == SVt_PVAV)
            return av_top_index((AV *)rv) >= 0;
        if (SvTYPE(rv) == SVt_PVHV)
            return HvKEYS((HV *)rv) > 0;
    }
    return SvTRUE(sv);
}

/* ---- hash iteration key vector -------------------------------------- */

static int kh_cmp(const void *pa, const void *pb)
{
    const stencil_khent *a = (const stencil_khent *)pa;
    const stencil_khent *b = (const stencil_khent *)pb;
    STRLEN min = a->len < b->len ? a->len : b->len;
    int    c   = memcmp(a->pv, b->pv, min);
    if (c)
        return c;
    return a->len < b->len ? -1 : a->len > b->len ? 1 : 0;
}

static stencil_khent *kh_collect(pTHX_ HV *hv, SSize_t size, int sorted)
{
    stencil_khent *kh;
    HE            *he;
    SSize_t        n = 0;
    Newx(kh, (size_t)size, stencil_khent);
    stencil_stat_scratch_allocs++;
    hv_iterinit(hv);
    while ((he = hv_iternext(hv)) && n < size) {
        STRLEN len;
        kh[n].pv   = HePV(he, len);
        kh[n].len  = len;
        kh[n].utf8 = HeUTF8(he) ? 1 : 0;
        kh[n].val  = HeVAL(he);
        n++;
    }
    if (sorted)
        qsort(kh, (size_t)n, sizeof *kh, kh_cmp);
    return kh;
}

static void kh_bind(pTHX_ stencil_rframe *f, SSize_t i)
{
    sv_setpvn(f->key_sv, f->kh[i].pv, f->kh[i].len);
    if (f->kh[i].utf8)
        SvUTF8_on(f->key_sv);
    else
        SvUTF8_off(f->key_sv);
    f->cur     = f->key_sv;
    f->cur_val = f->kh[i].val;
}

static void frame_release(pTHX_ stencil_rframe *f)
{
    if (f->kh) {
        Safefree(f->kh);
        f->kh = NULL;
    }
    if (f->key_sv) {
        SvREFCNT_dec_NN(f->key_sv);
        f->key_sv = NULL;
    }
    if (f->agg_owned)
        SvREFCNT_dec(f->agg);
}

/* ---- loop metadata (pure C, no HV) ----------------------------------- */

static SV *loop_meta(pTHX_ const stencil_rframe *f, const char *n,
                     uint32_t len, int *owned)
{
    switch (len) {
    case 3:
        if (memcmp(n, "key", 3) == 0)
            return f->is_hash ? f->cur : NULL;
        if (memcmp(n, "odd", 3) == 0)
            return ((f->i + 1) & 1) ? &PL_sv_yes : &PL_sv_no;
        break;
    case 4:
        if (memcmp(n, "size", 4) == 0) {
            *owned = 1;
            return newSViv((IV)f->size);
        }
        if (memcmp(n, "last", 4) == 0)
            return f->i == f->size - 1 ? &PL_sv_yes : &PL_sv_no;
        if (memcmp(n, "even", 4) == 0)
            return ((f->i + 1) & 1) ? &PL_sv_no : &PL_sv_yes;
        break;
    case 5:
        if (memcmp(n, "index", 5) == 0) {
            *owned = 1;
            return newSViv((IV)f->i);
        }
        if (memcmp(n, "first", 5) == 0)
            return f->i == 0 ? &PL_sv_yes : &PL_sv_no;
        break;
    case 6:
        if (memcmp(n, "index1", 6) == 0) {
            *owned = 1;
            return newSViv((IV)(f->i + 1));
        }
        break;
    }
    return NULL;
}

/* Materialise the frame as a real HV - the only place a loop HV is
 * ever built (capture via `set x = loop`). */
static SV *loop_snapshot(pTHX_ const stencil_rframe *f)
{
    HV *hv = newHV();
    (void)hv_stores(hv, "index",  newSViv((IV)f->i));
    (void)hv_stores(hv, "index1", newSViv((IV)(f->i + 1)));
    (void)hv_stores(hv, "size",   newSViv((IV)f->size));
    (void)hv_stores(hv, "first",  newSVsv(boolSV(f->i == 0)));
    (void)hv_stores(hv, "last",   newSVsv(boolSV(f->i == f->size - 1)));
    (void)hv_stores(hv, "even",   newSVsv(boolSV(((f->i + 1) & 1) == 0)));
    (void)hv_stores(hv, "odd",    newSVsv(boolSV(((f->i + 1) & 1) == 1)));
    if (f->is_hash)
        (void)hv_stores(hv, "key", newSVsv(f->cur));
    return newRV_noinc((SV *)hv);
}

/* ---- path resolution -------------------------------------------------- */

static SV *resolve_path(pTHX_ stencil_rstate *r, uint32_t pid, int *owned)
{
    const stencil_cpath *path = &r->paths[pid];
    const stencil_seg   *segs = r->segs + path->seg_idx;
    uint32_t             i;
    SV                  *cur = NULL;
    int                  kflags =
        (r->prog->flags & STENCIL_PROG_SRC_UTF8) ? HVhek_UTF8 : 0;

    *owned = 0;

    if (path->loop_rooted && r->nf > 0) {
        const stencil_rframe *f = &r->frames[r->nf - 1];
        if (path->n_segs == 1) {
            *owned = 1;
            return loop_snapshot(aTHX_ f);
        }
        if (segs[1].is_index)
            return NULL;
        {
            const stencil_cname *nm = &r->names[segs[1].name_id];
            cur = loop_meta(aTHX_ f, r->pool + nm->off, nm->len, owned);
        }
        if (!cur)
            return NULL;
        i = 2;
    } else {
        /* first segment: innermost scope wins (serial-stamped binds
         * and loop frames, matched by name bytes so includes share the
         * caller's scope), then the root data hash */
        const stencil_cname *nm = &r->names[segs[0].name_id];
        stencil_sname seg0;
        SV      *best = NULL;
        uint32_t best_serial = 0;
        int      found = 0;
        int32_t  k;
        seg0.pv   = r->pool + nm->off;
        seg0.len  = nm->len;
        seg0.hash = nm->hash;
        for (k = r->nb - 1; k >= 0; k--) {
            if (SNAME_EQ(r->binds[k].name, seg0)) {
                best        = r->binds[k].sv;
                best_serial = r->binds[k].serial;
                found       = 1;
                break;
            }
        }
        for (k = r->nf - 1; k >= 0; k--) {
            const stencil_rframe *f  = &r->frames[k];
            SV                   *hit = NULL;
            int                   match = 0;
            if (SNAME_EQ(f->name, seg0)) {
                hit   = f->cur;
                match = 1;
            } else if (f->is_hash && SNAME_EQ(f->val, seg0)) {
                hit   = f->cur_val;
                match = 1;
            }
            if (match) {
                if (!found || f->serial > best_serial)
                    best = hit;
                found = 1;
                break;
            }
        }
        if (found) {
            cur = best;
        } else {
            SV **svp = (SV **)hv_common(r->data, NULL, seg0.pv,
                                        seg0.len, kflags,
                                        HV_FETCH_JUST_SV, NULL,
                                        seg0.hash);
            cur = svp ? *svp : NULL;
        }
        if (!cur)
            return NULL;
        i = 1;
    }

    for (; i < path->n_segs; i++) {
        SV *rv;
        if (!SvROK(cur))
            return NULL;
        rv = SvRV(cur);
        if (SvOBJECT(rv)) {
            rerror(r, "cannot traverse blessed reference in '%.*s'",
                   (int)path->full_len, r->pool + path->full_off);
            return NULL;
        }
        if (*owned) {
            /* intermediate owned value (loop meta deref) - hand its
             * lifetime to the temp stack */
            sv_2mortal(cur);
            *owned = 0;
        }
        if (segs[i].is_index) {
            SV **svp;
            if (SvTYPE(rv) != SVt_PVAV)
                return NULL;
            svp = av_fetch((AV *)rv, segs[i].index, 0);
            cur = svp ? *svp : NULL;
        } else {
            const stencil_cname *nm = &r->names[segs[i].name_id];
            SV **svp;
            if (SvTYPE(rv) != SVt_PVHV)
                return NULL;
            svp = (SV **)hv_common((HV *)rv, NULL, r->pool + nm->off,
                                   nm->len, kflags, HV_FETCH_JUST_SV,
                                   NULL, nm->hash);
            cur = svp ? *svp : NULL;
        }
        if (!cur)
            return NULL;
    }
    return cur;
}

/* ---- output encoding --------------------------------------------------- */

/* The buffer always holds valid UTF-8 bytes: UTF8-flagged values pass
 * through, and unflagged values containing high bytes (perl's latin-1
 * internal form) are upgraded at print time. The engine owns encoding;
 * callers never utf8::encode. */

static int has_high_byte(const char *p, STRLEN n)
{
    const char *end = p + n;
    while ((size_t)(end - p) >= 8) {
        uint64_t v;
        memcpy(&v, p, 8);
        if (v & 0x8080808080808080ULL)
            return 1;
        p += 8;
    }
    while (p < end)
        if ((unsigned char)*p++ & 0x80)
            return 1;
    return 0;
}

static SV *scratch_next(pTHX_ stencil_rstate *r);

static const char *latin1_upgrade(pTHX_ stencil_rstate *r,
                                  const char *p, STRLEN *np)
{
    SV         *sc = scratch_next(aTHX_ r);
    const char *end = p + *np;
    char       *w;
    SvUPGRADE(sc, SVt_PV);
    SvGROW(sc, *np * 2 + 1);
    SvPOK_only(sc);
    w = SvPVX(sc);
    while (p < end) {
        unsigned char c = (unsigned char)*p++;
        if (c < 0x80) {
            *w++ = (char)c;
        } else {
            *w++ = (char)(0xC0 | (c >> 6));
            *w++ = (char)(0x80 | (c & 0x3F));
        }
    }
    *np = (STRLEN)(w - SvPVX(sc));
    SvCUR_set(sc, *np);
    return SvPVX(sc);
}

/* ---- filter pipeline --------------------------------------------------- */

static SV *scratch_next(pTHX_ stencil_rstate *r)
{
    SV **slot = &r->scratch[r->scr_i ^= 1];
    if (!*slot)
        *slot = newSV(64);
    return *slot;
}

/* Apply filter table entry `idx` (current unit) to the stack top in
 * place. Returns 0 with the error message set (caller pins location). */
static int filter_apply(pTHX_ stencil_rstate *r, uint32_t idx)
{
    const stencil_cfilt *f = &r->filts[idx];
    stencil_val         *v = &r->stack[r->sp - 1];
    SV                  *in = v->sv;
    SV                  *out;

    if (f->builtin_id >= 0) {
        if (f->builtin_id == STENCIL_FILT_DEFAULT) {
            STRLEN n = 0;
            if (in && SvOK(in)) {
                (void)SvPV(in, n);
                if (n)
                    return 1;   /* passthrough, flags untouched */
            }
            out = scratch_next(aTHX_ r);
            if (f->arg_is_num) {
                sv_setnv(out, (NV)f->num_arg);
            } else {
                sv_setpvn(out, r->pool + f->str_off, f->str_len);
                if (r->prog->flags & STENCIL_PROG_SRC_UTF8)
                    SvUTF8_on(out);
                else
                    SvUTF8_off(out);
            }
        } else {
            if (!in || !SvOK(in))
                return 1;       /* undef passes through the others */
            out = scratch_next(aTHX_ r);
            switch (f->builtin_id) {
            case STENCIL_FILT_UPPER:
                stencil_filt_case(aTHX_ in, out, 1);
                break;
            case STENCIL_FILT_LOWER:
                stencil_filt_case(aTHX_ in, out, 0);
                break;
            case STENCIL_FILT_TRIM:
                stencil_filt_trim(aTHX_ in, out);
                break;
            case STENCIL_FILT_HTML:
                stencil_filt_html(aTHX_ in, out);
                break;
            case STENCIL_FILT_URI:
                stencil_filt_uri(aTHX_ in, out);
                break;
            default:
                return rerror(r, "corrupt filter table");
            }
        }
        val_release(aTHX_ v);
        v->sv     = out;
        v->owned  = 0;
        v->vflags = f->builtin_id == STENCIL_FILT_HTML
            ? STENCIL_VF_ESCAPED : 0;
        return 1;
    }

    /* engine-registered Perl coderef */
    {
        SV **cvp = r->filters
            ? hv_fetch(r->filters, r->pool + f->name_off,
                       (I32)f->name_len, 0)
            : NULL;
        SV  *copy = NULL;
        int  died;
        if (!cvp || !SvROK(*cvp) || SvTYPE(SvRV(*cvp)) != SVt_PVCV)
            return rerror(r, "unknown filter '%.*s'",
                          (int)f->name_len, r->pool + f->name_off);
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(in ? in : &PL_sv_undef);
            if (f->has_arg) {
                SV *arg = f->arg_is_num
                    ? newSVnv((NV)f->num_arg)
                    : newSVpvn(r->pool + f->str_off, f->str_len);
                if (!f->arg_is_num
                    && (r->prog->flags & STENCIL_PROG_SRC_UTF8))
                    SvUTF8_on(arg);
                PUSHs(sv_2mortal(arg));
            }
            PUTBACK;
            (void)call_sv(*cvp, G_SCALAR | G_EVAL);
            SPAGAIN;
            died = SvTRUE(ERRSV);
            if (died)
                (void)POPs;
            else
                copy = newSVsv(POPs);
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
        if (died)
            return rerror(r, "filter '%.*s' died: %s",
                          (int)f->name_len, r->pool + f->name_off,
                          SvPV_nolen(ERRSV));
        val_release(aTHX_ v);
        v->sv     = copy;
        v->owned  = 1;
        v->vflags = 0;
        return 1;
    }
}

/* ---- comparison macros for the VM body -------------------------------- */

#define VM_CMP_NUM(OPR)                                                  \
    {                                                                    \
        stencil_val vb = r->stack[--r->sp];                              \
        stencil_val va = r->stack[--r->sp];                              \
        NV na = (va.sv && SvOK(va.sv)) ? SvNV(va.sv) : 0.0;              \
        NV nb = (vb.sv && SvOK(vb.sv)) ? SvNV(vb.sv) : 0.0;              \
        int res = na OPR nb;                                             \
        val_release(aTHX_ &va);                                                \
        val_release(aTHX_ &vb);                                                \
        r->stack[r->sp].sv    = res ? &PL_sv_yes : &PL_sv_no;            \
        r->stack[r->sp].owned = 0;                                       \
        r->stack[r->sp].vflags = 0;                                      \
        r->sp++;                                                         \
    }                                                                    \
    VM_NEXT;

#define VM_CMP_STR(EXPR)                                                 \
    {                                                                    \
        stencil_val vb = r->stack[--r->sp];                              \
        stencil_val va = r->stack[--r->sp];                              \
        SV *a = (va.sv && SvOK(va.sv)) ? va.sv : &PL_sv_no;              \
        SV *b = (vb.sv && SvOK(vb.sv)) ? vb.sv : &PL_sv_no;              \
        int res = (EXPR) ? 1 : 0;                                        \
        val_release(aTHX_ &va);                                                \
        val_release(aTHX_ &vb);                                                \
        r->stack[r->sp].sv    = res ? &PL_sv_yes : &PL_sv_no;            \
        r->stack[r->sp].owned = 0;                                       \
        r->stack[r->sp].vflags = 0;                                      \
        r->sp++;                                                         \
    }                                                                    \
    VM_NEXT;

/* ---- VM instantiations ------------------------------------------------ */

#ifdef STENCIL_HAVE_COMPUTED_GOTO
#define STENCIL_VM_GOTO 1
#define STENCIL_VM_NAME stencil_vm_goto
#include "stencil_vm.inc"
#undef STENCIL_VM_GOTO
#undef STENCIL_VM_NAME
#endif

#define STENCIL_VM_GOTO 0
#define STENCIL_VM_NAME stencil_vm_switch
#include "stencil_vm.inc"
#undef STENCIL_VM_GOTO
#undef STENCIL_VM_NAME

/* ---- public entries ---------------------------------------------------- */

SV *stencil_render_core(pTHX_
    stencil_program *page_prog, stencil_cache_ent **page_incs,
    const char *page_name,
    stencil_program *wrap_prog, stencil_cache_ent **wrap_incs,
    const char *wrap_name,
    uint32_t eff_stack, uint32_t eff_frames, uint32_t eff_binds,
    HV *data, HV *filters, uint32_t flags, SV **err)
{
    stencil_rstate  r;
    stencil_val     fix_stack[16];
    stencil_rframe  fix_frames[8];
    stencil_rbind   fix_binds[16];
    int             heap_stack = 0, heap_frames = 0, heap_binds = 0;
    int             ok;
    stencil_program *entry_prog = wrap_prog ? wrap_prog : page_prog;

    memset(&r, 0, sizeof r);
    if (wrap_prog) {
        set_unit(&r, wrap_prog, wrap_incs,
                 wrap_name ? wrap_name : "<wrapper>");
        r.content_prog = page_prog;
        r.content_incs = page_incs;
        r.content_name = page_name ? page_name : "<string>";
    } else {
        set_unit(&r, page_prog, page_incs,
                 page_name ? page_name : "<string>");
    }
    r.data    = data;
    r.filters = filters;
    r.flags   = flags;

    if (eff_stack <= 16) {
        r.stack = fix_stack;
    } else {
        Newx(r.stack, eff_stack, stencil_val);
        heap_stack = 1;
    }
    if (eff_frames <= 8) {
        r.frames = fix_frames;
    } else {
        Newx(r.frames, eff_frames, stencil_rframe);
        heap_frames = 1;
    }
    if (eff_binds <= 16) {
        r.binds = fix_binds;
    } else {
        Newx(r.binds, eff_binds, stencil_rbind);
        heap_binds = 1;
    }

    /* profiled_size is a capacity high-water (SvLEN), so it is used
     * as-is: adding headroom here would compound with the stored
     * capacity into geometric growth */
    stencil_buf_init(aTHX_ &r.buf,
                     entry_prog->profiled_size
                         ? entry_prog->profiled_size : 64);
    if ((page_prog->flags | (wrap_prog ? wrap_prog->flags : 0))
        & STENCIL_PROG_SRC_UTF8)
        r.buf.utf8 = 1;

#ifdef STENCIL_HAVE_COMPUTED_GOTO
    ok = stencil_dispatch.force_switch
        ? stencil_vm_switch(aTHX_ &r)
        : stencil_vm_goto(aTHX_ &r);
#else
    ok = stencil_vm_switch(aTHX_ &r);
#endif

    /* unwind whatever an error path left live */
    while (r.sp > 0) {
        r.sp--;
        val_release(aTHX_ &r.stack[r.sp]);
    }
    while (r.nf > 0)
        frame_release(aTHX_ &r.frames[--r.nf]);
    while (r.nb > 0)
        SvREFCNT_dec(r.binds[--r.nb].sv);
    SvREFCNT_dec(r.scratch[0]);
    SvREFCNT_dec(r.scratch[1]);
    if (heap_stack)
        Safefree(r.stack);
    if (heap_frames)
        Safefree(r.frames);
    if (heap_binds)
        Safefree(r.binds);

    if (!ok) {
        SvREFCNT_dec(r.buf.sv);
        if (err)
            *err = sv_2mortal(newSVpvf(
                "Template::Stencil: %s:%u: %s",
                r.err_final ? r.err_name : r.unit_name,
                (unsigned)r.err_line, r.errbuf));
        return NULL;
    }
    {
        SV *out = stencil_buf_done(&r.buf);
        if (!(flags & STENCIL_RF_CHARS))
            SvUTF8_off(out);   /* default: wire-ready UTF-8 bytes */
        /* profile the capacity high-water (SvLEN, not SvCUR): the
         * escaper reserves worst-case space, and pre-growing to only
         * the final length would re-grow on every render of small
         * templates with escaped values */
        if (SvLEN(out) > entry_prog->profiled_size)
            entry_prog->profiled_size = SvLEN(out);
        return out;
    }
}

SV *stencil_render_run(pTHX_ stencil_program *prog, HV *data,
                       uint32_t flags, const char *tname, SV **err)
{
    return stencil_render_core(aTHX_ prog, NULL, tname,
                               NULL, NULL, NULL,
                               prog->max_stack, prog->max_frames,
                               prog->max_binds, data, NULL, flags, err);
}
