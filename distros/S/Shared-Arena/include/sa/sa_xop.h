#ifndef SA_XOP_H
#define SA_XOP_H

/* sa_xop.h - the hot doors as opcodes rather than calls.
 *
 * `$cache->get($k)` is two ops and an XSUB call frame, and the frame runs before
 * any of the work does. This removes it, so the method form becomes the fast
 * form and there is no separate "fast API" to migrate to.
 *
 * ---- BOTH ops, not just one -------------------------------------------------
 *
 * Swapping op_ppaddr on OP_ENTERSUB removes the call frame AND NOTHING ELSE.
 * `$obj->get($k)` still runs pp_method_named first, which walks the stash for
 * the name and validates the method cache before the hooked entersub is
 * reached. So the check hook swaps two ops on the same subtree: the
 * METHOD_NAMED that resolves the name, and the ENTERSUB that would call what it
 * resolved.
 *
 * How much each half is worth, measured on an M-series Mac at 500k iterations,
 * as XSUB / entersub only / both (bench/xop.pl, which runs the same binary
 * three ways):
 *
 *     cache->get   62.2   61.7   48.8 ns
 *     map->incr    38.9   31.2   26.6
 *     bloom->check 33.5   30.3   23.2
 *     hist->record 26.4   20.2   14.2
 *
 * Read the first row before deciding the second swap is a refinement: hooking
 * entersub alone bought `get` NOTHING. The whole of that door's saving is the
 * method resolution, and a version that swapped one op would have been all of
 * the risk for none of the gain.
 *
 * ---- how a monkeypatch still wins ------------------------------------------
 *
 * `*Shared::Arena::Cache::get = sub { ... }` puts a different CV in the same
 * glob, and a caller who does that has every reason to expect it to take
 * effect. Two things together make sure it does.
 *
 * The GLOB is read per call, never the CV. The method op pushes whatever the
 * glob holds NOW, which after a monkeypatch is the replacement.
 *
 * The ORIGINAL CV is captured at BOOT and used for identity, never called. The
 * entersub op runs its C door only when the thing on the stack is that exact
 * XSUB; a replacement is a different pointer, so the guard declines and the
 * ordinary path calls what the caller installed.
 *
 * Both halves are needed. Comparing against the glob's current CV instead
 * would make a replacement match ITSELF and the C door would run in its place -
 * a monkeypatch that silently does nothing, which is the worst outcome
 * available. And a reference is held on the original, so that a sub which is
 * deleted rather than replaced cannot free the CV and let a later allocation
 * land on the same address and pass an identity check it should fail.
 *
 * ---- one pp function per door ----------------------------------------------
 *
 * A single generic one would have to read the method name off the op to know
 * what to do, which means looking it up, which is the cost being removed.
 *
 * ---- when another dist got there first -------------------------------------
 *
 * Frozen hooks OP_ENTERSUB too, and it hooks `->get($k)` - one argument, same
 * name. Since Frozen is a prerequisite here it is ALWAYS loaded, so this is not
 * a corner case, it is the flagship door.
 *
 * Two hooks cannot both own one op_ppaddr. Overwriting the other dist's would
 * silently cost it its fast path; refusing the site outright costs this one its
 * own, which is what happened first and is why `cache->get` briefly went back
 * to being an ordinary call.
 *
 * So when the entersub is already somebody's, only the METHOD_NAMED op is
 * taken. The other dist keeps its entersub guard, which declines for an
 * invocant that is not its own and delegates, so both stay correct.
 *
 * IT IS NOT THE WHOLE WIN, AND THE ABLATION SAYS SO. `cache->get` measured
 * 60.2ns unhooked, 55.1ns with the method op alone, and 48.8ns with both. The
 * two swaps are not additive - each alone is worth about 5ns and together they
 * are worth 12 - because when both belong to the same hook the method op
 * pushes a CV that the entersub immediately consumes, and neither has to go
 * through a generic dispatch to hand it over.
 *
 * So a shared call site costs this dist about 6ns it would otherwise have. The
 * fix is not to grab the op back: overwriting the other hook's ppaddr would
 * take the same 13ns off THEIR door, which is no better for being invisible
 * from here. It is for both hooks to delegate to the ppaddr they displaced
 * rather than to PL_ppaddr, and that is a change to both dists.
 *
 * The two guards compose because each one checks the invocant's class and the
 * CV's identity. For a Cache, this pushes Cache::get and Frozen's entersub
 * guard sees a CV that is not its own and steps aside. For a Frozen container,
 * this declines at the method op and Frozen's own fast path runs untouched.
 *
 * ---- what it costs everybody else ------------------------------------------
 *
 * The hook sees every `->get`, `->set`, `->add`, `->check`, `->record`,
 * `->store`, `->fetch`, `->exists`, `->incr`, `->publish` and `->allow` in the
 * whole program, not only this dist's. A call on another class runs the guard,
 * declines and delegates: measured at 2.5ns per non-matching call, 39.6 to
 * 42.1. A program that makes millions of those and few of ours is paying for
 * something it does not use, and sets SHARED_ARENA_NO_XOP=1.
 *
 * ---- what is NOT hooked ----------------------------------------------------
 *
 * op_type is left alone, so B::Deparse, B::Concise and every other dumper see
 * an ordinary entersub and keep working. A guard that fails delegates rather
 * than croaking. And a door with a variable number of arguments - `set` with a
 * ttl, `drain` with a max - is hooked only in its commonest shape; the others
 * take the ordinary path, because a guard that has to cope with any stack shape
 * is a guard that has stopped being cheap.
 */

#include "sa/sa_cache.h"
#include "sa/sa_hash.h"
#include "sa/sa_bloom.h"
#include "sa/sa_hist.h"
#include "sa/sa_ring.h"
#include "sa/sa_rate.h"
#include "sa/sa_cms.h"
#include "xop_compat.h"

static Perl_check_t sa_prev_ck_entersub = NULL;

static HV *sa_stash_cache = NULL;
static HV *sa_stash_map   = NULL;
static HV *sa_stash_bloom = NULL;
static HV *sa_stash_hist  = NULL;
static HV *sa_stash_ring  = NULL;
static HV *sa_stash_rate  = NULL;
static HV *sa_stash_cms   = NULL;

/* Per door: the glob, read every call, and the XSUB that was in it at BOOT,
 * compared but never called. */
#define SA_DOORS(_)                                                        \
    _(cache_get,    "Shared::Arena::Cache::get")                           \
    _(cache_set,    "Shared::Arena::Cache::set")                           \
    _(map_fetch,    "Shared::Arena::Map::fetch")                           \
    _(map_store,    "Shared::Arena::Map::store")                           \
    _(map_incr,     "Shared::Arena::Map::incr")                            \
    _(map_exists,   "Shared::Arena::Map::exists")                          \
    _(bloom_add,    "Shared::Arena::Bloom::add")                           \
    _(bloom_check,  "Shared::Arena::Bloom::check")                         \
    _(hist_record,  "Shared::Arena::Histogram::record")                    \
    _(ring_publish, "Shared::Arena::Ring::publish")                         \
    _(rate_allow,   "Shared::Arena::Rate::allow")                            \
    _(cms_add,      "Shared::Arena::CountMin::add")                         \
    _(cms_estimate, "Shared::Arena::CountMin::estimate")

#define SA_DOOR_DECL(door, path) \
    static GV *sa_gv_##door = NULL; static CV *sa_cv_##door = NULL;
SA_DOORS(SA_DOOR_DECL)
#undef SA_DOOR_DECL

static IV sa_xop_hook = 0;   /* call sites rewritten at compile time */
static IV sa_xop_hits = 0;   /* calls that took the op path          */
static IV sa_xop_miss = 0;   /* calls that declined and delegated    */
static IV sa_xop_meth = 0;   /* sites where only the method op was ours */

#define SA_IS(sv, stash) \
    ((stash) && SvROK(sv) && SvOBJECT(SvRV(sv)) && SvSTASH(SvRV(sv)) == (stash))

#ifdef G_LIST
#  define SA_G_LIST G_LIST
#else
#  define SA_G_LIST G_ARRAY
#endif

/* The invocant, if this call is one we may answer: the stack shape is what the
 * op was hooked for, the CV is still the one the glob holds, and the invocant
 * is of the class this door belongs to. Anything else and the caller gets the
 * ordinary path. */
#define SA_XOP_SELF(want_cv, stash, nargs)                        \
    SV **mark = PL_stack_base + TOPMARK;                          \
    SV *self;                                                     \
    do {                                                          \
        if (sp - mark != (nargs) + 2) goto delegate;              \
        if (!(want_cv) || (CV *)*sp != (want_cv)) goto delegate;  \
        self = mark[1];                                           \
        if (!SA_IS(self, stash)) goto delegate;                   \
    } while (0)

#define SA_XOP_PTR(type) INT2PTR(type, SvIV(SvRV(self)))

#define SA_XOP_RETURN(nargs, sv)   \
    do {                           \
        (void)POPMARK;             \
        sp -= (nargs) + 2;         \
        PUSHs(sv);                 \
        PUTBACK;                   \
        sa_xop_hits++;             \
        return NORMAL;             \
    } while (0)

/* An empty list in list context, undef in scalar - the shape every "absent"
 * door in this dist uses, so the op path and the XSUB path agree. */
#define SA_XOP_EMPTY(nargs)                            \
    do {                                               \
        (void)POPMARK;                                 \
        sp -= (nargs) + 2;                             \
        if (GIMME_V != SA_G_LIST) PUSHs(&PL_sv_undef); \
        PUTBACK;                                       \
        sa_xop_hits++;                                 \
        return NORMAL;                                 \
    } while (0)

#define SA_XOP_DELEGATE()                              \
    delegate:                                          \
        sa_xop_miss++;                                 \
        return PL_ppaddr[OP_ENTERSUB](aTHX)

/* ---- the method resolution ------------------------------------------------
 *
 * pp_method_named walks the stash and checks the method cache. When the
 * invocant is ours the answer is known without looking, so this pushes it and
 * returns. Everything else delegates, including a CV somebody has replaced. */
#define SA_XOP_METH(door, stash)                                       \
static OP *sa_pp_meth_##door(pTHX) {                                   \
    dSP;                                                               \
    SV **mark = PL_stack_base + TOPMARK;                               \
    SV *self;                                                          \
    CV *cv;                                                            \
    if (sp <= mark) return PL_ppaddr[OP_METHOD_NAMED](aTHX);           \
    self = mark[1];                                                    \
    if (!SA_IS(self, stash)) return PL_ppaddr[OP_METHOD_NAMED](aTHX);  \
    cv = sa_gv_##door ? GvCV(sa_gv_##door) : NULL;                     \
    if (!cv) return PL_ppaddr[OP_METHOD_NAMED](aTHX);                  \
    XPUSHs((SV *)cv);                                                  \
    PUTBACK;                                                           \
    return NORMAL;                                                     \
}

SA_XOP_METH(cache_get,    sa_stash_cache)
SA_XOP_METH(cache_set,    sa_stash_cache)
SA_XOP_METH(map_fetch,    sa_stash_map)
SA_XOP_METH(map_store,    sa_stash_map)
SA_XOP_METH(map_incr,     sa_stash_map)
SA_XOP_METH(map_exists,   sa_stash_map)
SA_XOP_METH(bloom_check,  sa_stash_bloom)
SA_XOP_METH(hist_record,  sa_stash_hist)
SA_XOP_METH(ring_publish, sa_stash_ring)
SA_XOP_METH(rate_allow,   sa_stash_rate)
SA_XOP_METH(cms_estimate, sa_stash_cms)

/* ---- the doors themselves -------------------------------------------------- */

static OP *sa_pp_cache_get(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_cache_get, sa_stash_cache, 1);
        {
            sa_cache *c = SA_XOP_PTR(sa_cache *);
            STRLEN klen;
            const char *k;
            SV *out;
            uint32_t vlen = 0;
            if (!c) goto delegate;
            k = SvPV(mark[2], klen);
            out = sv_2mortal(newSV((STRLEN)c->pair_max + 1));
            SvPOK_on(out);
            if (sa_cache_get(c, k, (uint32_t)klen, SvPVX(out),
                             (uint32_t)c->pair_max, &vlen) != SA_C_HIT)
                SA_XOP_EMPTY(1);
            SvCUR_set(out, (STRLEN)vlen);
            SvPVX(out)[vlen] = '\0';
            SA_XOP_RETURN(1, out);
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_cache_set(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_cache_set, sa_stash_cache, 2);
        {
            sa_cache *c = SA_XOP_PTR(sa_cache *);
            STRLEN klen, vlen;
            const char *k, *v;
            int rc;
            if (!c) goto delegate;
            k = SvPV(mark[2], klen);
            v = SvPV(mark[3], vlen);
            rc = sa_cache_set(c, k, (uint32_t)klen, v, (uint32_t)vlen, 0);
            SA_XOP_RETURN(2, sv_2mortal(newSViv(rc)));
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_map_fetch(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_map_fetch, sa_stash_map, 1);
        {
            sa_hash *m = SA_XOP_PTR(sa_hash *);
            STRLEN klen;
            const char *k;
            SV *out;
            uint32_t vlen = 0;
            if (!m) goto delegate;
            k = SvPV(mark[2], klen);
            out = sv_2mortal(newSV((STRLEN)m->pair_max + 1));
            SvPOK_on(out);
            if (sa_hash_fetch(m, k, (uint32_t)klen, SvPVX(out),
                              (uint32_t)m->pair_max, &vlen) != SA_H_HIT)
                SA_XOP_EMPTY(1);
            SvCUR_set(out, (STRLEN)vlen);
            SvPVX(out)[vlen] = '\0';
            SA_XOP_RETURN(1, out);
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_map_store(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_map_store, sa_stash_map, 2);
        {
            sa_hash *m = SA_XOP_PTR(sa_hash *);
            STRLEN klen, vlen;
            const char *k, *v;
            int rc;
            if (!m) goto delegate;
            k = SvPV(mark[2], klen);
            v = SvPV(mark[3], vlen);
            rc = sa_hash_store(m, k, (uint32_t)klen, v, (uint32_t)vlen);
            SA_XOP_RETURN(2, sv_2mortal(newSViv(rc)));
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_map_incr(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_map_incr, sa_stash_map, 1);
        {
            sa_hash *m = SA_XOP_PTR(sa_hash *);
            STRLEN klen;
            const char *k;
            uint64_t now = 0;
            if (!m) goto delegate;
            k = SvPV(mark[2], klen);
            if (sa_hash_incr(m, k, (uint32_t)klen, 1, &now) != SA_H_OK)
                SA_XOP_RETURN(1, &PL_sv_undef);
            SA_XOP_RETURN(1, sv_2mortal(newSVuv((UV)now)));
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_map_exists(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_map_exists, sa_stash_map, 1);
        {
            sa_hash *m = SA_XOP_PTR(sa_hash *);
            STRLEN klen;
            const char *k;
            char scratch[8];
            uint32_t vlen = 0;
            int hit;
            if (!m) goto delegate;
            k = SvPV(mark[2], klen);
            hit = sa_hash_fetch(m, k, (uint32_t)klen, scratch, 0, &vlen)
                  != SA_H_MISS;
            SA_XOP_RETURN(1, sv_2mortal(newSViv(hit ? 1 : 0)));
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_bloom_check(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_bloom_check, sa_stash_bloom, 1);
        {
            sa_bloom *b = SA_XOP_PTR(sa_bloom *);
            STRLEN klen;
            const char *k;
            if (!b) goto delegate;
            k = SvPV(mark[2], klen);
            SA_XOP_RETURN(1,
                sv_2mortal(newSViv(sa_bloom_check(b, k, (uint32_t)klen))));
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_hist_record(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_hist_record, sa_stash_hist, 1);
        {
            sa_hist *h = SA_XOP_PTR(sa_hist *);
            if (!h) goto delegate;
            sa_hist_record(h, (uint64_t)SvUV(mark[2]), 1);
            /* record returns nothing, so the op must leave the stack the way
             * a void XSUB would: empty. */
            (void)POPMARK;
            sp -= 1 + 2;
            PUTBACK;
            sa_xop_hits++;
            return NORMAL;
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_ring_publish(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_ring_publish, sa_stash_ring, 2);
        {
            sa_ring *r = SA_XOP_PTR(sa_ring *);
            STRLEN tlen, plen;
            const char *t, *p;
            uint64_t seq = 0;
            int rc;
            if (!r) goto delegate;
            t = SvPV(mark[2], tlen);
            p = SvPV(mark[3], plen);
            rc = sa_ring_publish(r, t, (uint32_t)tlen, p, (uint32_t)plen, &seq);
            SA_XOP_RETURN(2, sv_2mortal(newSViv(
                rc == SA_PUB_OK ? (IV)seq : (IV)rc)));
        }
    }
    SA_XOP_DELEGATE();
}

/* A limiter is asked once per request, so the guard runs on a door whose own
 * work is a couple of atomics. Without atomics the XSUB allows everything
 * rather than refusing good requests, and this says the same thing. */
static OP *sa_pp_rate_allow(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_rate_allow, sa_stash_rate, 1);
        {
            sa_rate *rl = SA_XOP_PTR(sa_rate *);
            STRLEN klen;
            const char *k;
            int ok;
            if (!rl) goto delegate;
            k = SvPV(mark[2], klen);
#if SA_HAVE_ATOMICS
            ok = sa_rate_take(rl, k, (uint32_t)klen,
                              (uint64_t)SA_RATE_SCALE, 0, NULL, NULL);
#else
            ok = 1;
#endif
            SA_XOP_RETURN(1, sv_2mortal(newSViv(ok)));
        }
    }
    SA_XOP_DELEGATE();
}

/* A sketch is added to once per event and asked once per report, so `add` is as
 * hot as anything in the dist. Both return the counter's new or current value,
 * which is the one estimate a caller wants without a second call. */
/* `add` is a name TWO of this dist's own classes answer to, so one door has to
 * cover both. The method op resolves whichever class the invocant is, and the
 * entersub door below tells them apart by the CV the method op pushed - which
 * is the same identity check that keeps a monkeypatch working, doing a second
 * job here for free.
 *
 * Without this the first entry in the hook table would win the name outright
 * and the other class would silently lose its fast path, which is exactly the
 * failure two SEPARATE dists hit and is no more acceptable for being internal. */
static OP *sa_pp_meth_add(pTHX) {
    dSP;
    SV **mark = PL_stack_base + TOPMARK;
    SV *self;
    CV *cv = NULL;
    if (sp <= mark) return PL_ppaddr[OP_METHOD_NAMED](aTHX);
    self = mark[1];
    if      (SA_IS(self, sa_stash_bloom) && sa_gv_bloom_add)
        cv = GvCV(sa_gv_bloom_add);
    else if (SA_IS(self, sa_stash_cms) && sa_gv_cms_add)
        cv = GvCV(sa_gv_cms_add);
    if (!cv) return PL_ppaddr[OP_METHOD_NAMED](aTHX);
    XPUSHs((SV *)cv);
    PUTBACK;
    return NORMAL;
}

static OP *sa_pp_add(pTHX) {
    dSP;
    SV **mark = PL_stack_base + TOPMARK;
    SV *self;
    STRLEN klen;
    const char *k;

    if (sp - mark != 3) goto delegate;
    self = mark[1];

    if ((CV *)*sp == sa_cv_bloom_add && SA_IS(self, sa_stash_bloom)) {
        sa_bloom *b = SA_XOP_PTR(sa_bloom *);
        if (!b) goto delegate;
        k = SvPV(mark[2], klen);
        SA_XOP_RETURN(1, sv_2mortal(newSViv(sa_bloom_add(b, k, (uint32_t)klen))));
    }
    if ((CV *)*sp == sa_cv_cms_add && SA_IS(self, sa_stash_cms)) {
        sa_cms *cm = SA_XOP_PTR(sa_cms *);
        if (!cm) goto delegate;
        k = SvPV(mark[2], klen);
        SA_XOP_RETURN(1,
            sv_2mortal(newSVuv((UV)sa_cms_add(cm, k, (uint32_t)klen, 1))));
    }

    SA_XOP_DELEGATE();
}

static OP *sa_pp_cms_estimate(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_cms_estimate, sa_stash_cms, 1);
        {
            sa_cms *cm = SA_XOP_PTR(sa_cms *);
            STRLEN klen;
            const char *k;
            if (!cm) goto delegate;
            k = SvPV(mark[2], klen);
            SA_XOP_RETURN(1, sv_2mortal(newSVuv(
                (UV)sa_cms_estimate(cm, k, (uint32_t)klen))));
        }
    }
    SA_XOP_DELEGATE();
}

/* ---- the check hook -------------------------------------------------------- */

static int sa_xop_is_ours(Perl_ppaddr_t p) {
    return p == sa_pp_cache_get   || p == sa_pp_cache_set
        || p == sa_pp_map_fetch   || p == sa_pp_map_store
        || p == sa_pp_map_incr    || p == sa_pp_map_exists
        || p == sa_pp_bloom_check
        || p == sa_pp_hist_record || p == sa_pp_ring_publish
        || p == sa_pp_rate_allow  || p == sa_pp_add
        || p == sa_pp_meth_add
        || p == sa_pp_cms_estimate;
}

static void sa_try_hook(pTHX_ OP *o) {
    OP *pushop, *selfop, *last, *cur;
    int nargs = 0;
    const char *name;

    if (!o || o->op_type != OP_ENTERSUB) return;
    if (sa_xop_is_ours(o->op_ppaddr)) return;

    pushop = cUNOPx(o)->op_first;
    if (!pushop) return;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
    if (!pushop) return;

    selfop = OpSIBLING(pushop);
    if (!selfop) return;

    last = selfop;
    while (OpHAS_SIBLING(last)) { cur = OpSIBLING(last); if (!cur) break; last = cur; }
    if (!last || last->op_type != OP_METHOD_NAMED) return;

    for (cur = OpSIBLING(selfop); cur && cur != last; cur = OpSIBLING(cur))
        nargs++;

    {
        SV *namesv;
#if defined(OPpMETH_NO_BAREWORD_IO) || PERL_VERSION_GE(5,22,0)
        namesv = cMETHOPx_meth(last);
#else
        namesv = cSVOPx_sv(last);
#endif
        if (!namesv || !SvPOK(namesv)) return;
        name = SvPVX(namesv);
    }

    /* BOTH ops where both are free: the entersub loses the call frame, and the
     * method_named loses the stash walk that would otherwise happen first.
     * Where another dist already owns one of them, take the other and leave
     * theirs alone - see the note above on why that is nearly all of it. */
#define SA_HOOK(n, meth, door)                                        \
    if (nargs == (n) && strEQ(name, meth)) {                          \
        int got = 0;                                                  \
        if (o->op_ppaddr == PL_ppaddr[OP_ENTERSUB]) {                 \
            o->op_ppaddr = sa_pp_##door;                              \
            got = 1;                                                  \
        }                                                             \
        if (last->op_ppaddr == PL_ppaddr[OP_METHOD_NAMED]) {          \
            last->op_ppaddr = sa_pp_meth_##door;                      \
            if (!got) sa_xop_meth++;                                  \
            got = 1;                                                  \
        }                                                             \
        if (got) sa_xop_hook++;                                       \
        return;                                                       \
    }

    SA_HOOK(1, "get",     cache_get)
    SA_HOOK(2, "set",     cache_set)
    SA_HOOK(1, "fetch",   map_fetch)
    SA_HOOK(2, "store",   map_store)
    SA_HOOK(1, "incr",    map_incr)
    SA_HOOK(1, "exists",  map_exists)
    SA_HOOK(1, "check",   bloom_check)
    SA_HOOK(1, "record",  hist_record)
    SA_HOOK(2, "publish", ring_publish)
    SA_HOOK(1, "allow",    rate_allow)
    SA_HOOK(1, "estimate", cms_estimate)
    SA_HOOK(1, "add",      add)
#undef SA_HOOK
}

static OP *sa_ck_entersub(pTHX_ OP *o) {
    if (sa_prev_ck_entersub) o = sa_prev_ck_entersub(aTHX_ o);
    sa_try_hook(aTHX_ o);
    return o;
}

#endif /* SA_XOP_H */
