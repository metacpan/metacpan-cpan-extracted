#ifndef STORE_CORE_H
#define STORE_CORE_H

/* The cell: one value, and the one place it changes.
 *
 * ---- the handle --------------------------------------------------------
 *
 * A store is a blessed reference to a scalar that carries the C struct in
 * ext magic, marked by the address of a vtable in this file: HAMT's handle,
 * for HAMT's reasons. Magic cannot be forged from Perl or carried through a
 * serialiser, so an object without it is simply not a store and every method
 * says so; the struct is released when the scalar is freed, so there is no
 * DESTROY to call twice or to shadow in a subclass; and a new thread does
 * not get the handle, by CLONE_SKIP and, failing that, by a dup hook that
 * empties the clone's magic. */

/* Not during global destruction: by then perl is freeing every scalar in an
 * order of its own, and one this store still holds may already be gone. */
static void store_sv_release(pTHX_ SV *sv) {
    if (sv && !PL_dirty) SvREFCNT_dec(sv);
}

typedef struct store {
    SV       *value;      /* the current value: owned, read-only, never NULL */
    hamt_vec *past;       /* the values before it, oldest first: never NULL */
    hamt_vec *future;     /* the values undone, the next one to redo last */
    size_t    limit;      /* the most steps `past` keeps, when `limited` */
    size_t    past_skip;  /* its oldest steps, beyond the limit, not yet cut */
    int       limited;

    /* Phase 05: the watchers, in the order they were added, and the changes
     * waiting to be told to them. A watcher removed during a round is left
     * in place with no code and swept out when the round is over. */
    struct store_watcher *watchers;
    size_t    nwatchers, cwatchers, live_watchers;
    UV        next_id;
    struct store_change  *queue;
    size_t    qhead, qlen, qcap;
    int       delivering;

    /* Phase 06: the sub a new value must satisfy, or NULL; and whether it
     * is running, when nothing may change the store. */
    SV       *validator;
    state_store_validate_fn cvalidator;     /* or one from the C ABI */
    void     *cvalidator_ud;
    int       validating;

    /* Phase 07: how many transactions are open. Inside one, a change records
     * no step and is told to nobody: the transaction does both, once, when
     * the outermost one ends. */
    int       txn_depth;

    /* Phase 08: named values, or NULL until the first is named. */
    hamt_map *checkpoints;
} store;

/* A croak for what cannot be done inside a transaction. */
static void store_check_no_txn(pTHX_ const store *s, const char *what) {
    if (s->txn_depth) croak("%s: not inside a transaction", what);
}

/* A validator from Perl: a code reference, or undef for none. The CV, not
 * the reference to it. */
static SV *store_validator_arg(pTHX_ SV *sv, const char *what) {
    SvGETMAGIC(sv);
    if (!SvOK(sv)) return NULL;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVCV)
        croak("%s: the validator is not a code reference", what);
    return SvRV(sv);
}

/* A croak for anything that would change the store while its validator is
 * deciding whether a change may be made. */
static void store_check_mutable(pTHX_ const store *s, const char *what) {
    if (s->validating) croak("%s: the validator may not change the store", what);
}

/* Ask the validator - a Perl sub, or a C function and its data - whether
 * `candidate` may replace `old` in the store `storerv` refers to, or in no
 * store yet when it is undef. 1 yes, 0 no; a Perl validator that dies goes
 * on up as it is. `flag`, when given, is set for as long as the validator
 * runs and put back however it ends. */
static int store_validate(pTHX_ SV *validator, state_store_validate_fn cfn, void *cud,
                          SV *candidate, SV *old, SV *storerv, int *flag) {
    SV *args[3], *result, *err = NULL;
    int ok;

    args[0] = candidate;
    args[1] = old;
    args[2] = storerv;
    ENTER;
    SAVETMPS;
    if (flag) { SAVEINT(*flag); *flag = 1; }
    if (cfn) {
        ok = cfn(aTHX_ cud, candidate, old, storerv) ? 1 : 0;
    }
    else {
        err = store_call(aTHX_ validator, args, 3, G_SCALAR, &result, NULL);
        ok = !err && SvTRUE(result);
        if (err) SvREFCNT_inc_simple_void_NN(err);
    }
    FREETMPS;
    LEAVE;
    if (err) store_rethrow(aTHX_ sv_2mortal(err));
    return ok;
}

/* A watcher is a Perl sub or, from the C ABI, a function and its data.
 * One removed has neither. */
typedef struct store_watcher {
    UV id;
    SV *code;
    state_store_watch_fn cfn;
    void *ud;
} store_watcher;
typedef struct store_change  { SV *was; SV *now; } store_change;

/* A change to be told to the watchers once the store has settled: both
 * values held by the queue until it has been. Nothing is queued when nobody
 * is watching. */
static void store_enqueue(pTHX_ store *s, SV *was, SV *now) {
    if (!s->live_watchers || s->txn_depth) return;
    if (s->qhead + s->qlen == s->qcap) {
        if (s->qhead) {
            Move(s->queue + s->qhead, s->queue, s->qlen, store_change);
            s->qhead = 0;
        }
        else {
            s->qcap = s->qcap ? s->qcap * 2 : 4;
            Renew(s->queue, s->qcap, store_change);
        }
    }
    s->queue[s->qhead + s->qlen].was = SvREFCNT_inc_simple_NN(was);
    s->queue[s->qhead + s->qlen].now = SvREFCNT_inc_simple_NN(now);
    s->qlen++;
}

/* Everything the watchers held, given back: for a store being freed, and
 * for a round abandoned. */
static void store_queue_clear(pTHX_ store *s) {
    while (s->qlen) {
        store_change c = s->queue[s->qhead++];
        s->qlen--;
        store_sv_release(aTHX_ c.was);
        store_sv_release(aTHX_ c.now);
    }
    s->qhead = 0;
}

/* `v` with only its last `keep` values, as a new vector; or NULL when it
 * already has no more than that, or, with *nomem set, when there was no
 * memory to make one. The values dropped are the oldest. */
static hamt_vec *store_trimmed(pTHX_ const hamt_vec *v, size_t keep, int *nomem) {
    size_t have = (STORE_HAMT->vec_count)(aTHX_ v);
    hamt_vec *t;
    int status = HAMT_ABI_OK;

    *nomem = 0;
    if (have <= keep) return NULL;
    t = (STORE_HAMT->vec_slice)(aTHX_ v, have - keep, keep, &status);
    if (!t) *nomem = 1;
    return t;
}

/* Under a limit the past is not cut on every change: it is let grow to the
 * limit and this many steps more, then cut back to the limit in one go. A
 * cut is a slice of the vector, and one change in 32 paying for it costs a
 * small fraction of every change paying for it (bench/limit.pl). The steps
 * beyond the limit are never offered to undo, so what can be undone is
 * exact; they only stay alive a little longer. */
#define STORE_TRIM_SLACK 32

/* How many steps can be undone: the past, less its oldest steps beyond the
 * limit that have not been cut yet. */
static size_t store_past_len(pTHX_ const store *s) {
    return (STORE_HAMT->vec_count)(aTHX_ s->past) - s->past_skip;
}

/* How many of the oldest steps of `past` are beyond the limit, once steps
 * have been pushed onto it: those it already had, and any more the pushes
 * took it over by. */
static size_t store_skip_after(const store *s, size_t count, size_t skip) {
    if (s->limited && count - skip > s->limit) skip = count - s->limit;
    return skip;
}

/* A past about to have a step pushed onto it, cut back first if it has
 * outgrown the limit by the slack: a new vector of the newest `limit - 1`,
 * or NULL when no cut is due. *nomem as store_trimmed. */
static hamt_vec *store_room(pTHX_ const store *s, const hamt_vec *past, int *nomem) {
    *nomem = 0;
    if ((STORE_HAMT->vec_count)(aTHX_ past) < s->limit + STORE_TRIM_SLACK) return NULL;
    return store_trimmed(aTHX_ past, s->limit - 1, nomem);
}

static int store_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    store *s = (store *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (s) {
        SV *value = s->value;
        hamt_vec *past = s->past, *future = s->future;
        store_watcher *w = s->watchers;
        SV *s_validator = s->validator;
        hamt_map *s_checkpoints = s->checkpoints;
        store_change *q = s->queue;
        size_t nw = s->nwatchers, qhead = s->qhead, qlen = s->qlen, i;
        mg->mg_ptr = NULL;
        /* The struct goes before the values: releasing one can run its
         * DESTROY, and by then there must be nothing half-gone. */
        store_free(aTHX_ s);
        store_sv_release(aTHX_ value);
        for (i = 0; i < qlen; i++) {
            store_sv_release(aTHX_ q[qhead + i].was);
            store_sv_release(aTHX_ q[qhead + i].now);
        }
        for (i = 0; i < nw; i++) store_sv_release(aTHX_ w[i].code);
        Safefree(q);
        Safefree(w);
        store_sv_release(aTHX_ s_validator);
        if (s_checkpoints) (STORE_HAMT->map_release)(aTHX_ s_checkpoints);
        if (past)   (STORE_HAMT->vec_release)(aTHX_ past);
        if (future) (STORE_HAMT->vec_release)(aTHX_ future);
    }
    return 0;
}

static int store_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(param);
    mg->mg_ptr = NULL;
    return 0;
}

static MGVTBL store_vtbl = {
    NULL, NULL, NULL, NULL, store_magic_free, NULL, store_magic_dup, NULL
};

/* The struct behind an object, or a croak that names the method. */
static store *store_handle(pTHX_ SV *sv, const char *what) {
    if (SvROK(sv) && SvTYPE(SvRV(sv)) >= SVt_PVMG) {
        MAGIC *mg;
        for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type != PERL_MAGIC_ext || mg->mg_virtual != &store_vtbl) continue;
            if (!mg->mg_ptr) croak("%s: this store belongs to another thread", what);
            return (store *)mg->mg_ptr;
        }
    }
    croak("%s: not a store", what);
    return NULL;
}

/* The class to bless into: the one named, or the one an object is in. */
static HV *store_class_stash(pTHX_ SV *klass) {
    if (SvROK(klass) && SvOBJECT(SvRV(klass))) return SvSTASH(SvRV(klass));
    return gv_stashsv(klass, GV_ADD);
}

/* A value as it is kept: a copy, read-only, so that every holder of it sees
 * what was stored and nothing written through an alias since. A reference
 * copied this way is a second reference to the same thing, which is what
 * makes a HAMT container in a store still that container. */
static SV *store_copy_in(pTHX_ SV *in) {
    SV *c = newSVsv(in);
    SvREADONLY_on(c);
    return c;
}

/* A new object of the class behind `stash`, mortal, holding `initial`. */
static SV *store_new(pTHX_ HV *stash, SV *initial, store **out) {
    store *s;
    hamt_vec *past, *future;
    SV *inner, *rv;
    MAGIC *mg;

    past   = (STORE_HAMT->vec_new)(aTHX);
    future = past ? (STORE_HAMT->vec_new)(aTHX) : NULL;
    if (!future) {
        if (past) (STORE_HAMT->vec_release)(aTHX_ past);
        croak("State::Store::new: out of memory");
    }
    s = (store *)store_alloc(aTHX_ sizeof(store));
    s->past   = past;
    s->future = future;
    s->value  = store_copy_in(aTHX_ initial);
    inner = newSV(0);
    mg = sv_magicext(inner, NULL, PERL_MAGIC_ext, &store_vtbl, (const char *)s, 0);
    mg->mg_flags |= MGf_DUP;
    rv = sv_2mortal(newRV_noinc(inner));
    sv_bless(rv, stash);
    *out = s;
    return rv;
}

/* The stored scalar itself, mortal, kept alive past the store by a
 * reference of its own. */
static SV *store_get(pTHX_ const store *s) {
    return sv_2mortal(SvREFCNT_inc_simple_NN(s->value));
}

/* The one place a new value arrives. 1 if it did, 0 if `in` is the value
 * already held, as HAMT's value_equal has it: the same scalar, two
 * references to one thing, or two non-references that are the same string.
 * A change that is no change records nothing and leaves the redo stack.
 * The validator is asked when `validate` is set: by set and swap, not by a
 * restore, whose value was accepted when it was stored. -1 if it refused,
 * with nothing changed.
 *
 * A tied or otherwise magical `in` is read once, here, and the rest works
 * on what was read.
 *
 * The value displaced goes onto the past, and the future is emptied. All
 * that can fail is allocated before anything changes, so running out of
 * memory croaks with the store as it was. What is let go is let go last,
 * when the store already holds the new value: releasing it can run a
 * DESTROY, and that may use this store. */
static int store_put(pTHX_ store *s, SV *in, SV *storerv, int validate, const char *what) {
    SV *old;
    hamt_vec *fresh = NULL, *dead = NULL, *room = NULL, *dead_past = NULL;
    int record = !s->txn_depth && (!s->limited || s->limit > 0), nomem = 0;

    SV *candidate;

    store_check_mutable(aTHX_ s, what);
    if (SvGMAGICAL(in)) in = store_read_once(aTHX_ in);
    if ((STORE_HAMT->value_equal)(aTHX_ s->value, in)) return 0;

    /* The validator is shown the very scalar that will be stored, and
     * decides before anything is allocated or changed. */
    candidate = sv_2mortal(store_copy_in(aTHX_ in));
    if (validate && (s->validator || s->cvalidator)
        && !store_validate(aTHX_ s->validator, s->cvalidator, s->cvalidator_ud,
                           candidate, s->value, storerv, &s->validating))
        return -1;

    if ((STORE_HAMT->vec_count)(aTHX_ s->future)) {
        fresh = (STORE_HAMT->vec_new)(aTHX);
        if (!fresh) croak("%s: out of memory", what);
    }
    /* When a cut is due, the past is cut to leave room for one more before
     * anything is pushed, so that a failure leaves it as it was. */
    if (record && s->limited) {
        room = store_room(aTHX_ s, s->past, &nomem);
        if (nomem) {
            if (fresh) (STORE_HAMT->vec_release)(aTHX_ fresh);
            croak("%s: out of memory", what);
        }
    }
    if (record && (STORE_HAMT->vec_push)(aTHX_ room ? room : s->past, s->value) != HAMT_ABI_OK) {
        if (room)  (STORE_HAMT->vec_release)(aTHX_ room);
        if (fresh) (STORE_HAMT->vec_release)(aTHX_ fresh);
        croak("%s: out of memory", what);
    }

    old = s->value;
    s->value = SvREFCNT_inc_simple_NN(candidate);
    if (fresh) { dead = s->future; s->future = fresh; }
    if (room)  { dead_past = s->past; s->past = room; s->past_skip = 0; }
    if (record) s->past_skip = store_skip_after(s, (STORE_HAMT->vec_count)(aTHX_ s->past), s->past_skip);

    store_enqueue(aTHX_ s, old, s->value);
    store_sv_release(aTHX_ old);
    if (dead)      (STORE_HAMT->vec_release)(aTHX_ dead);
    if (dead_past) (STORE_HAMT->vec_release)(aTHX_ dead_past);
    return 1;
}

#endif
