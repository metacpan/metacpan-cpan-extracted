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
 * IT WAS NOT THE WHOLE WIN, AND THE ABLATION SAID SO. `cache->get` measured
 * 60.2ns unhooked, 55.1ns with the method op alone, and 48.8ns with both. The
 * two swaps are not additive - each alone is worth about 5ns and together they
 * are worth 12 - because when both belong to the same hook the method op
 * pushes a CV that the entersub immediately consumes, and neither has to go
 * through a generic dispatch to hand it over.
 *
 * Overwriting the other hook's ppaddr would take the same saving off THEIR
 * door, which is no better for being invisible from here. So at a shared site
 * the method op makes the whole call itself and returns the op AFTER the
 * entersub, which then never runs: sa_pp_methdoor_cache_get, below. That is
 * the two-op saving from one op, with no change to the other dist and no side
 * table keyed by op address. Measured on one machine: 52.5ns before, 42.4
 * after.
 *
 * The guards compose because each one checks the invocant's class and the
 * CV's identity. For a Cache the method op answers and Frozen's entersub is
 * never reached. For a Frozen container this declines at the method op and
 * Frozen's own fast path runs untouched.
 *
 * ---- what it costs everybody else ------------------------------------------
 *
 * The hook sees every `->get`, `->set`, `->add`, `->check`, `->record`,
 * `->store`, `->fetch`, `->exists`, `->incr`, `->counter`, `->publish`,
 * `->allow`, `->remaining`, `->retry_after` and `->estimate` in the whole
 * program, not only this dist's, at each width a door exists for. A call on
 * another class runs the guard, declines and delegates: measured at 2.5ns per
 * non-matching call, 39.6 to 42.1. A program that makes millions of those and
 * few of ours is paying for something it does not use, and sets
 * SHARED_ARENA_NO_XOP=1.
 *
 * `delete` and `remove` are deliberately not hooked at all. They are common
 * names on other classes, the tax would fall on every one of them, and neither
 * is on a request path often enough to pay for that.
 *
 * ---- what is NOT hooked ----------------------------------------------------
 *
 * op_type is left alone, so B::Deparse, B::Concise and every other dumper see
 * an ordinary entersub and keep working. A guard that fails delegates rather
 * than croaking. A door with optional arguments is a separate door per width,
 * each compiled only where the call site has exactly that many; a width nobody
 * wrote a door for - `drain` with a max - takes the ordinary path, because a
 * guard that has to cope with any stack shape is a guard that has stopped
 * being cheap.
 */

#include "sa/sa_cache.h"
#include "sa/sa_hash.h"
#include "sa/sa_bloom.h"
#include "sa/sa_hist.h"
#include "sa/sa_ring.h"
#include "sa/sa_rate.h"
#include "sa/sa_cms.h"
#include "sa/sa_cuckoo.h"
#include "xop_compat.h"

static Perl_check_t sa_prev_ck_entersub = NULL;

static HV *sa_stash_cache = NULL;
static HV *sa_stash_map   = NULL;
static HV *sa_stash_bloom = NULL;
static HV *sa_stash_hist  = NULL;
static HV *sa_stash_ring  = NULL;
static HV *sa_stash_rate  = NULL;
static HV *sa_stash_cms   = NULL;
static HV *sa_stash_cuckoo = NULL;

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
    _(cms_estimate, "Shared::Arena::CountMin::estimate")                    \
    _(cuckoo_add,   "Shared::Arena::Cuckoo::add")                           \
    _(cuckoo_check, "Shared::Arena::Cuckoo::check")                         \
    _(rate_remaining,   "Shared::Arena::Rate::remaining")                   \
    _(rate_retry_after, "Shared::Arena::Rate::retry_after")                 \
    _(map_counter,  "Shared::Arena::Map::counter")

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

/* An integer answer goes in the entersub's pad target, which is where the XSUB
 * this replaces put it through dXSTARG. A fresh mortal per call is an
 * allocation and a free that the XSUB never paid. */
#define SA_XOP_TARG()                                          \
    ((PL_op->op_private & OPpENTERSUB_HASTARG)                 \
        ? PAD_SV(PL_op->op_targ) : sv_newmortal())

#define SA_XOP_RETURN_IV(nargs, iv)                            \
    do {                                                       \
        SV *targ_ = SA_XOP_TARG();                             \
        sv_setiv_mg(targ_, (IV)(iv));                          \
        SA_XOP_RETURN(nargs, targ_);                           \
    } while (0)

#define SA_XOP_RETURN_UV(nargs, uv)                            \
    do {                                                       \
        SV *targ_ = SA_XOP_TARG();                             \
        sv_setuv_mg(targ_, (UV)(uv));                          \
        SA_XOP_RETURN(nargs, targ_);                           \
    } while (0)

#define SA_XOP_RETURN_NV(nargs, nv)                            \
    do {                                                       \
        SV *targ_ = SA_XOP_TARG();                             \
        sv_setnv_mg(targ_, (NV)(nv));                          \
        SA_XOP_RETURN(nargs, targ_);                           \
    } while (0)

/* Nothing to return, as from the void XSUB this replaces - which pp_entersub
 * turns into ONE undef in scalar context. The op has to do the same, or
 * `map { scalar $h->record($_) } 1 .. 3` comes back with no elements. */
#define SA_XOP_VOID(nargs)                                     \
    do {                                                       \
        (void)POPMARK;                                         \
        sp -= (nargs) + 2;                                     \
        if (GIMME_V == G_SCALAR) PUSHs(&PL_sv_undef);          \
        PUTBACK;                                               \
        sa_xop_hits++;                                         \
        return NORMAL;                                         \
    } while (0)

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
            char buf[1024];
            uint32_t vlen = 0;
            if (!c) goto delegate;
            k = SvPV(mark[2], klen);
            /* Stack first where an entry fits, as the XSUB does: a miss
             * allocates nothing and a hit only what the value needs. */
            if (c->pair_max < sizeof buf) {
                if (sa_cache_get(c, k, (uint32_t)klen, buf,
                                 (uint32_t)c->pair_max, &vlen) != SA_C_HIT)
                    SA_XOP_EMPTY(1);
                SA_XOP_RETURN(1, sv_2mortal(newSVpvn(buf, (STRLEN)vlen)));
            }
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
            SA_XOP_RETURN_IV(2, rc);
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
            char buf[1024];
            uint32_t vlen = 0;
            if (!m) goto delegate;
            k = SvPV(mark[2], klen);
            /* Stack first where a slot fits, as the XSUB does. */
            if (m->pair_max < sizeof buf) {
                if (sa_hash_fetch(m, k, (uint32_t)klen, buf,
                                  (uint32_t)m->pair_max, &vlen) != SA_H_HIT)
                    SA_XOP_EMPTY(1);
                SA_XOP_RETURN(1, sv_2mortal(newSVpvn(buf, (STRLEN)vlen)));
            }
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
            SA_XOP_RETURN_IV(2, rc);
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
            SA_XOP_RETURN_UV(1, (UV)now);
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
            SA_XOP_RETURN_IV(1, hit ? 1 : 0);
        }
    }
    SA_XOP_DELEGATE();
}

/* `check` is a name both filters answer to, so it is one door for two classes,
 * told apart the way `add` below tells its three apart: by the CV the method op
 * pushed, which is also the identity that keeps a monkeypatch working. */
static OP *sa_pp_meth_check(pTHX) {
    dSP;
    SV **mark = PL_stack_base + TOPMARK;
    SV *self;
    CV *cv = NULL;
    if (sp <= mark) return PL_ppaddr[OP_METHOD_NAMED](aTHX);
    self = mark[1];
    if      (SA_IS(self, sa_stash_bloom) && sa_gv_bloom_check)
        cv = GvCV(sa_gv_bloom_check);
    else if (SA_IS(self, sa_stash_cuckoo) && sa_gv_cuckoo_check)
        cv = GvCV(sa_gv_cuckoo_check);
    if (!cv) return PL_ppaddr[OP_METHOD_NAMED](aTHX);
    XPUSHs((SV *)cv);
    PUTBACK;
    return NORMAL;
}

static OP *sa_pp_check(pTHX) {
    dSP;
    SV **mark = PL_stack_base + TOPMARK;
    SV *self;
    STRLEN klen;
    const char *k;

    if (sp - mark != 3) goto delegate;
    self = mark[1];

    if ((CV *)*sp == sa_cv_bloom_check && SA_IS(self, sa_stash_bloom)) {
        sa_bloom *b = SA_XOP_PTR(sa_bloom *);
        if (!b) goto delegate;
        k = SvPV(mark[2], klen);
        SA_XOP_RETURN_IV(1, sa_bloom_check(b, k, (uint32_t)klen));
    }
    if ((CV *)*sp == sa_cv_cuckoo_check && SA_IS(self, sa_stash_cuckoo)) {
        sa_cuckoo *ck = SA_XOP_PTR(sa_cuckoo *);
        if (!ck) goto delegate;
        k = SvPV(mark[2], klen);
        SA_XOP_RETURN_IV(1, sa_cuckoo_check(ck, k, (uint32_t)klen));
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
             * a void XSUB would - which is not quite empty: see SA_XOP_VOID. */
            SA_XOP_VOID(1);
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
            SA_XOP_RETURN_IV(2,
                rc == SA_PUB_OK ? (IV)seq : (IV)rc);
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
            SA_XOP_RETURN_IV(1, ok);
        }
    }
    SA_XOP_DELEGATE();
}

/* A sketch is added to once per event and asked once per report, so `add` is as
 * hot as anything in the dist. Both return the counter's new or current value,
 * which is the one estimate a caller wants without a second call. */
/* `add` is a name THREE of this dist's own classes answer to, so one door has
 * to cover them all. The method op resolves whichever class the invocant is, and the
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
    else if (SA_IS(self, sa_stash_cuckoo) && sa_gv_cuckoo_add)
        cv = GvCV(sa_gv_cuckoo_add);
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
        SA_XOP_RETURN_IV(1, sa_bloom_add(b, k, (uint32_t)klen));
    }
    if ((CV *)*sp == sa_cv_cms_add && SA_IS(self, sa_stash_cms)) {
        sa_cms *cm = SA_XOP_PTR(sa_cms *);
        if (!cm) goto delegate;
        k = SvPV(mark[2], klen);
        SA_XOP_RETURN_UV(1, (UV)sa_cms_add(cm, k, (uint32_t)klen, 1));
    }
    if ((CV *)*sp == sa_cv_cuckoo_add && SA_IS(self, sa_stash_cuckoo)) {
        sa_cuckoo *ck = SA_XOP_PTR(sa_cuckoo *);
        if (!ck) goto delegate;
        k = SvPV(mark[2], klen);
        SA_XOP_RETURN_IV(1, sa_cuckoo_add(ck, k, (uint32_t)klen));
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
            SA_XOP_RETURN_UV(1,
                (UV)sa_cms_estimate(cm, k, (uint32_t)klen));
        }
    }
    SA_XOP_DELEGATE();
}

/* ---- the other widths of the same doors ------------------------------------
 *
 * An optional argument used to send the call the ordinary way, on the
 * reasoning that a guard coping with any stack shape stops being cheap. It
 * would, so each width is its own door instead, compiled only at a call site
 * with exactly that many arguments and counted again at runtime. Measured
 * before, on an M-series Mac, the hooked width against the same door with its
 * optional argument:
 *
 *     map->incr($k)      / ($k, $by)             26.2 / 40.4 ns
 *     cache->set($k, $v) / (..., ttl => N)       31.2 / 42.8
 *     hist->record($v)   / ($v, $n)              13.5 / 30.3
 *     rate->allow($k)    / ($k, $cost)           28.6 / 37.5
 *     countmin->add($k)  / ($k, $n)              25.0 / 33.4
 *
 * Each shares the method op of the narrower width, which pushes the same CV
 * whatever the width. Arguments are read in the order the XSUB reads them, so
 * a tied one is fetched the same number of times either way. */

static OP *sa_pp_map_incr_by(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_map_incr, sa_stash_map, 2);
        {
            sa_hash *m = SA_XOP_PTR(sa_hash *);
            STRLEN klen;
            const char *k;
            IV by;
            uint64_t now = 0;
            if (!m) goto delegate;
            k  = SvPV(mark[2], klen);
            by = SvIV(mark[3]);
            if (sa_hash_incr(m, k, (uint32_t)klen, (int64_t)by, &now) != SA_H_OK)
                SA_XOP_RETURN(2, &PL_sv_undef);
            SA_XOP_RETURN_UV(2, (UV)now);
        }
    }
    SA_XOP_DELEGATE();
}

/* `set($k, $v, ttl => N)` and its `ttl_ms` spelling. Any other option name is
 * the XSUB's to handle, so the door looks at the name before touching anything
 * else and steps aside for one it does not know. */
static OP *sa_pp_cache_set_ttl(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_cache_set, sa_stash_cache, 4);
        {
            sa_cache *c = SA_XOP_PTR(sa_cache *);
            SV *opt = mark[4];
            STRLEN klen, vlen;
            const char *k, *v;
            int ms, rc;
            UV ttl;
            if (!c) goto delegate;
            if (!SvPOK(opt) || SvGMAGICAL(opt)) goto delegate;
            if      (SvCUR(opt) == 3 && memEQ(SvPVX(opt), "ttl", 3))    ms = 0;
            else if (SvCUR(opt) == 6 && memEQ(SvPVX(opt), "ttl_ms", 6)) ms = 1;
            else goto delegate;
            k   = SvPV(mark[2], klen);
            v   = SvPV(mark[3], vlen);
            ttl = ms ? SvUV(mark[5]) : (UV)(SvNV(mark[5]) * 1000.0);
            rc  = sa_cache_set(c, k, (uint32_t)klen, v, (uint32_t)vlen,
                               (uint64_t)ttl);
            SA_XOP_RETURN_IV(4, rc);
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_hist_record_n(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_hist_record, sa_stash_hist, 2);
        {
            sa_hist *h = SA_XOP_PTR(sa_hist *);
            UV v, n;
            if (!h) goto delegate;
            v = SvUV(mark[2]);
            n = SvUV(mark[3]);
            sa_hist_record(h, (uint64_t)v, (uint64_t)n);
            SA_XOP_VOID(2);
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_rate_allow_cost(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_rate_allow, sa_stash_rate, 2);
        {
            sa_rate *rl = SA_XOP_PTR(sa_rate *);
            STRLEN klen;
            const char *k;
            UV cost;
            int ok;
            if (!rl) goto delegate;
            cost = SvUV(mark[3]);
            if (cost < 1) cost = 1;
            k = SvPV(mark[2], klen);
#if SA_HAVE_ATOMICS
            ok = sa_rate_take(rl, k, (uint32_t)klen,
                              (uint64_t)cost * SA_RATE_SCALE, 0, NULL, NULL);
#else
            PERL_UNUSED_VAR(k);
            ok = 1;
#endif
            SA_XOP_RETURN_IV(2, ok);
        }
    }
    SA_XOP_DELEGATE();
}

/* `add($k, $n)` is the sketch's alone: the filters take one argument, so a
 * filter at this width gets the ordinary call and its ordinary usage error. */
static OP *sa_pp_add_n(pTHX) {
    dSP;
    SV **mark = PL_stack_base + TOPMARK;
    SV *self;

    if (sp - mark != 4) goto delegate;
    self = mark[1];

    if ((CV *)*sp == sa_cv_cms_add && SA_IS(self, sa_stash_cms)) {
        sa_cms *cm = SA_XOP_PTR(sa_cms *);
        STRLEN klen;
        const char *k;
        UV n;
        if (!cm) goto delegate;
        n = SvUV(mark[3]);
        if (n < 1) n = 1;
        k = SvPV(mark[2], klen);
#if SA_HAVE_ATOMICS
        SA_XOP_RETURN_UV(2, (UV)sa_cms_add(cm, k, (uint32_t)klen, (uint64_t)n));
#else
        PERL_UNUSED_VAR(k);
        SA_XOP_RETURN_UV(2, 0);
#endif
    }

    SA_XOP_DELEGATE();
}

/* ---- the rest of a request's rate limiting, and a counter read ---------------
 *
 * A handler that sets X-RateLimit headers asks `remaining` on every request and
 * `retry_after` on every refusal, beside the `allow` that was already an op;
 * both were ordinary calls at 34ns. `counter` reads a Map counter without
 * changing it, at 38.5ns. None of the three is a common method name, so what
 * the hook costs other classes' call sites is close to nothing. */
SA_XOP_METH(rate_remaining,   sa_stash_rate)
SA_XOP_METH(rate_retry_after, sa_stash_rate)
SA_XOP_METH(map_counter,      sa_stash_map)

static OP *sa_pp_rate_remaining(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_rate_remaining, sa_stash_rate, 1);
        {
            sa_rate *rl = SA_XOP_PTR(sa_rate *);
            STRLEN klen;
            const char *k;
            uint64_t left = 0;
            if (!rl) goto delegate;
            k = SvPV(mark[2], klen);
#if SA_HAVE_ATOMICS
            (void)sa_rate_take(rl, k, (uint32_t)klen,
                               (uint64_t)SA_RATE_SCALE, 1, &left, NULL);
#else
            PERL_UNUSED_VAR(k);
#endif
            SA_XOP_RETURN_NV(1, (NV)left / (NV)SA_RATE_SCALE);
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_rate_retry_after(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_rate_retry_after, sa_stash_rate, 1);
        {
            sa_rate *rl = SA_XOP_PTR(sa_rate *);
            STRLEN klen;
            const char *k;
            uint64_t retry = 0;
            if (!rl) goto delegate;
            k = SvPV(mark[2], klen);
#if SA_HAVE_ATOMICS
            (void)sa_rate_take(rl, k, (uint32_t)klen,
                               (uint64_t)SA_RATE_SCALE, 1, NULL, &retry);
#else
            PERL_UNUSED_VAR(k);
#endif
            SA_XOP_RETURN_NV(1, (NV)retry / (NV)1000.0);
        }
    }
    SA_XOP_DELEGATE();
}

static OP *sa_pp_map_counter(pTHX) {
    dSP;
    {
        SA_XOP_SELF(sa_cv_map_counter, sa_stash_map, 1);
        {
            sa_hash *m = SA_XOP_PTR(sa_hash *);
            STRLEN klen;
            const char *k;
            char buf[8];
            uint32_t vlen = 0;
            uint64_t v;
            if (!m) goto delegate;
            k = SvPV(mark[2], klen);
            if (sa_hash_fetch(m, k, (uint32_t)klen, buf, 8, &vlen) != SA_H_HIT
                || vlen != 8)
                SA_XOP_RETURN(1, &PL_sv_undef);
            memcpy(&v, buf, 8);
            SA_XOP_RETURN_UV(1, (UV)v);
        }
    }
    SA_XOP_DELEGATE();
}

/* ---- the whole door in the method op, where the entersub is not ours -------
 *
 * Frozen owns the entersub at every one-argument `->get` site, and Frozen is
 * always loaded, so the cache's main door was only ever half hooked: the
 * method op pushed our CV, Frozen's entersub stepped aside for it, and
 * pp_entersub then made an ordinary XSUB call. 55.1ns against 48.8 with both
 * ops ours.
 *
 * A pp function returns the op to run next. So a method op that has already
 * made the call can return the op AFTER the entersub and skip it entirely,
 * whoever owns it - which needs no change to the other dist and no side table
 * keyed by op address. The method op then does the entersub's checking itself:
 *
 *   - the width, one fewer here because no CV has been pushed yet;
 *   - the identity: the glob's CV against the one captured at BOOT, so a
 *     monkeypatch falls through to the ordinary path and the replacement runs;
 *   - the context, which is the ENTERSUB's. This op's own flags say scalar
 *     whatever the call, so GIMME_V is read with PL_op pointed at the call.
 *
 * Anything else falls through to the plain method-op door, which pushes the
 * CV and lets the entersub, and its owner, carry on as before. Installed only
 * where the entersub is another dist's; where both ops are ours the two-op door
 * already has the whole saving. */
static OP *sa_pp_methdoor_cache_get(pTHX) {
    dSP;
    SV **mark = PL_stack_base + TOPMARK;
    OP *call = PL_op->op_next;
    SV *self, *out = NULL;
    sa_cache *c;
    STRLEN klen;
    const char *k;
    char buf[1024];
    uint32_t vlen = 0;
    int hit;
    U8 gimme;

    if (sp - mark != 2 || !call || call->op_type != OP_ENTERSUB)
        return sa_pp_meth_cache_get(aTHX);
    self = mark[1];
    if (!SA_IS(self, sa_stash_cache) || !sa_gv_cache_get || !sa_cv_cache_get
        || GvCV(sa_gv_cache_get) != sa_cv_cache_get)
        return sa_pp_meth_cache_get(aTHX);
    c = SA_XOP_PTR(sa_cache *);
    if (!c) return sa_pp_meth_cache_get(aTHX);

    k = SvPV(mark[2], klen);
    if (c->pair_max < sizeof buf) {
        hit = sa_cache_get(c, k, (uint32_t)klen, buf, (uint32_t)c->pair_max,
                           &vlen) == SA_C_HIT;
        if (hit) out = sv_2mortal(newSVpvn(buf, (STRLEN)vlen));
    }
    else {
        out = sv_2mortal(newSV((STRLEN)c->pair_max + 1));
        SvPOK_on(out);
        hit = sa_cache_get(c, k, (uint32_t)klen, SvPVX(out),
                           (uint32_t)c->pair_max, &vlen) == SA_C_HIT;
        if (hit) { SvCUR_set(out, (STRLEN)vlen); SvPVX(out)[vlen] = '\0'; }
    }

    {
        OP *was = PL_op;
        PL_op = call;
        gimme = GIMME_V;
        PL_op = was;
    }
    (void)POPMARK;
    sp = mark;
    if (hit)                     PUSHs(out);
    else if (gimme != SA_G_LIST) PUSHs(&PL_sv_undef);
    PUTBACK;
    sa_xop_hits++;
    return call->op_next;
}

/* ---- the check hook -------------------------------------------------------- */

static int sa_xop_is_ours(Perl_ppaddr_t p) {
    return p == sa_pp_cache_get   || p == sa_pp_cache_set
        || p == sa_pp_map_fetch   || p == sa_pp_map_store
        || p == sa_pp_map_incr    || p == sa_pp_map_exists
        || p == sa_pp_check       || p == sa_pp_meth_check
        || p == sa_pp_hist_record || p == sa_pp_ring_publish
        || p == sa_pp_rate_allow  || p == sa_pp_add
        || p == sa_pp_meth_add
        || p == sa_pp_cms_estimate
        || p == sa_pp_map_incr_by      || p == sa_pp_cache_set_ttl
        || p == sa_pp_hist_record_n    || p == sa_pp_rate_allow_cost
        || p == sa_pp_add_n            || p == sa_pp_rate_remaining
        || p == sa_pp_rate_retry_after || p == sa_pp_map_counter;
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
     * Where another dist already owns the entersub, the method op gets
     * `shared` instead: for `get` that is the door which makes the whole call
     * from the method op and skips the entersub, elsewhere the plain push.
     * `mdoor` names the method op, which a wider form shares with the
     * narrower one because it pushes the same CV. */
#define SA_HOOK_AS(n, meth, door, mdoor, shared)                      \
    if (nargs == (n) && strEQ(name, meth)) {                          \
        int got = 0;                                                  \
        if (o->op_ppaddr == PL_ppaddr[OP_ENTERSUB]) {                 \
            o->op_ppaddr = sa_pp_##door;                              \
            got = 1;                                                  \
        }                                                             \
        if (last->op_ppaddr == PL_ppaddr[OP_METHOD_NAMED]) {          \
            last->op_ppaddr = got ? sa_pp_meth_##mdoor : (shared);    \
            if (!got) sa_xop_meth++;                                  \
            got = 1;                                                  \
        }                                                             \
        if (got) sa_xop_hook++;                                       \
        return;                                                       \
    }
#define SA_HOOK(n, meth, door) \
    SA_HOOK_AS(n, meth, door, door, sa_pp_meth_##door)

    SA_HOOK_AS(1, "get",  cache_get, cache_get, sa_pp_methdoor_cache_get)
    SA_HOOK(2, "set",     cache_set)
    SA_HOOK_AS(4, "set",  cache_set_ttl, cache_set, sa_pp_meth_cache_set)
    SA_HOOK(1, "fetch",   map_fetch)
    SA_HOOK(2, "store",   map_store)
    SA_HOOK(1, "incr",    map_incr)
    SA_HOOK_AS(2, "incr", map_incr_by, map_incr, sa_pp_meth_map_incr)
    SA_HOOK(1, "exists",  map_exists)
    SA_HOOK(1, "counter", map_counter)
    SA_HOOK(1, "check",   check)
    SA_HOOK(1, "record",  hist_record)
    SA_HOOK_AS(2, "record", hist_record_n, hist_record, sa_pp_meth_hist_record)
    SA_HOOK(2, "publish", ring_publish)
    SA_HOOK(1, "allow",    rate_allow)
    SA_HOOK_AS(2, "allow", rate_allow_cost, rate_allow, sa_pp_meth_rate_allow)
    SA_HOOK(1, "remaining",   rate_remaining)
    SA_HOOK(1, "retry_after", rate_retry_after)
    SA_HOOK(1, "estimate", cms_estimate)
    SA_HOOK(1, "add",      add)
    SA_HOOK_AS(2, "add",   add_n, add, sa_pp_meth_add)
#undef SA_HOOK_AS
#undef SA_HOOK
}

static OP *sa_ck_entersub(pTHX_ OP *o) {
    if (sa_prev_ck_entersub) o = sa_prev_ck_entersub(aTHX_ o);
    sa_try_hook(aTHX_ o);
    return o;
}

#endif /* SA_XOP_H */
