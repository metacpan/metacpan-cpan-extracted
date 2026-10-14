#ifndef STORE_ABI_IMPL_H
#define STORE_ABI_IMPL_H

/* The table behind state_store_abi.h. Each entry is the Perl method's own
 * code with the checks that would croak made first and answered with a
 * code instead: not a store, not allowed now, refused, not found. What is
 * left to croak is what the header says may: no memory, and a Perl watcher
 * or validator that dies. */

/* The struct behind a store, or NULL: never a croak. A clone in another
 * thread, whose struct is gone, is not a store here. */
static store *store_try(pTHX_ SV *sv) {
    if (sv && SvROK(sv) && SvTYPE(SvRV(sv)) >= SVt_PVMG) {
        MAGIC *mg;
        for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic)
            if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &store_vtbl)
                return (store *)mg->mg_ptr;
    }
    return NULL;
}

/* A name as a scalar, for the code that takes one from Perl. */
static SV *store_abi_name(pTHX_ const char *name, STRLEN len, int utf8) {
    SV *sv = sv_2mortal(newSVpvn(name ? name : "", name ? len : 0));
    if (utf8) SvUTF8_on(sv);
    return sv;
}

static SV *store_abi_new(pTHX_ SV *initial) {
    store *s;
    SV *rv = store_new(aTHX_ gv_stashpvs("State::Store", GV_ADD),
                       initial ? initial : &PL_sv_undef, &s);
    return SvREFCNT_inc_simple_NN(rv);
}

static int store_abi_is_store(pTHX_ SV *sv) {
    return store_try(aTHX_ sv) != NULL;
}

static SV *store_abi_current(pTHX_ SV *st) {
    store *s = store_try(aTHX_ st);
    return s ? s->value : NULL;
}

/* A change through store_put, then the watchers told. The store is held for
 * the length of the call, as the methods hold it. */
static int store_abi_put(pTHX_ store *s, SV *st, SV *value, int validate, const char *what) {
    SV *hold = sv_2mortal(newSVsv(st));
    int rc = store_put(aTHX_ s, value ? value : &PL_sv_undef, hold, validate, what);
    store_deliver(aTHX_ s, hold);
    return rc < 0 ? STATE_STORE_REFUSED : rc;
}

static int store_abi_set(pTHX_ SV *st, SV *value) {
    store *s = store_try(aTHX_ st);
    if (!s) return STATE_STORE_NOTSTORE;
    if (s->validating) return STATE_STORE_BUSY;
    return store_abi_put(aTHX_ s, st, value, 1, "State::Store set");
}

static int store_abi_swap(pTHX_ SV *st, state_store_swap_fn fn, void *ud) {
    store *s = store_try(aTHX_ st);
    SV *current, *result;
    int rc;

    if (!s) return STATE_STORE_NOTSTORE;
    if (s->validating) return STATE_STORE_BUSY;
    ENTER;
    SAVETMPS;
    current = sv_2mortal(SvREFCNT_inc_simple_NN(s->value));
    result  = fn(aTHX_ ud, current);
    rc = result ? store_abi_put(aTHX_ s, st, result, 1, "State::Store swap")
                : STATE_STORE_STOPPED;
    FREETMPS;
    LEAVE;
    return rc;
}

static int store_abi_move(pTHX_ SV *st, int undo, size_t n, size_t *taken) {
    store *s = store_try(aTHX_ st);
    SV *hold;
    size_t got;

    if (taken) *taken = 0;
    if (!s) return STATE_STORE_NOTSTORE;
    if (s->validating || s->txn_depth) return STATE_STORE_BUSY;
    hold = sv_2mortal(newSVsv(st));
    got = store_move(aTHX_ s, undo, n, undo ? "State::Store undo" : "State::Store redo");
    if (taken) *taken = got;
    store_deliver(aTHX_ s, hold);
    return STATE_STORE_OK;
}
static int store_abi_undo(pTHX_ SV *st, size_t n, size_t *taken) {
    return store_abi_move(aTHX_ st, 1, n, taken);
}
static int store_abi_redo(pTHX_ SV *st, size_t n, size_t *taken) {
    return store_abi_move(aTHX_ st, 0, n, taken);
}

static size_t store_abi_undo_count(pTHX_ SV *st) {
    store *s = store_try(aTHX_ st);
    return s ? store_past_len(aTHX_ s) : 0;
}
static size_t store_abi_redo_count(pTHX_ SV *st) {
    store *s = store_try(aTHX_ st);
    return s ? (STORE_HAMT->vec_count)(aTHX_ s->future) : 0;
}

static int store_abi_clear_history(pTHX_ SV *st) {
    store *s = store_try(aTHX_ st);
    if (!s) return STATE_STORE_NOTSTORE;
    if (s->validating || s->txn_depth) return STATE_STORE_BUSY;
    sv_2mortal(newSVsv(st));
    store_clear_history(aTHX_ s, "State::Store clear_history");
    return STATE_STORE_OK;
}

static int store_abi_history_limit(pTHX_ SV *st, size_t *limit) {
    store *s = store_try(aTHX_ st);
    if (!s) return STATE_STORE_NOTSTORE;
    if (limit) *limit = s->limited ? s->limit : 0;
    return s->limited ? 1 : 0;
}

static int store_abi_set_history_limit(pTHX_ SV *st, int limited, size_t limit) {
    store *s = store_try(aTHX_ st);
    if (!s) return STATE_STORE_NOTSTORE;
    if (s->validating || s->txn_depth) return STATE_STORE_BUSY;
    sv_2mortal(newSVsv(st));
    store_set_limit(aTHX_ s, limited ? limit : 0, limited ? 1 : 0, "State::Store set_history_limit");
    return STATE_STORE_OK;
}

static UV store_abi_watch(pTHX_ SV *st, state_store_watch_fn fn, void *ud) {
    store *s = store_try(aTHX_ st);
    if (!s || !fn) return 0;
    return store_watch_add(aTHX_ s, NULL, fn, ud);
}

static int store_abi_unwatch(pTHX_ SV *st, UV id) {
    store *s = store_try(aTHX_ st);
    if (!s) return STATE_STORE_NOTSTORE;
    return id ? store_watch_remove(aTHX_ s, id) : 0;
}

static size_t store_abi_watchers(pTHX_ SV *st) {
    store *s = store_try(aTHX_ st);
    return s ? s->live_watchers : 0;
}

static int store_abi_set_validator(pTHX_ SV *st, state_store_validate_fn fn, void *ud) {
    store *s = store_try(aTHX_ st);
    SV *dead;
    if (!s) return STATE_STORE_NOTSTORE;
    if (s->validating) return STATE_STORE_BUSY;
    dead = s->validator;
    s->validator     = NULL;
    s->cvalidator    = fn;
    s->cvalidator_ud = fn ? ud : NULL;
    if (dead) SvREFCNT_dec(dead);
    return STATE_STORE_OK;
}

/* ---- transactions ------------------------------------------------------ */

struct state_store_txn {
    SV         *st;         /* a reference of its own to the store */
    store_saved saved;
    int         depth;      /* the depth it opened at: which one it is */
};

static state_store_txn *store_abi_txn_begin(pTHX_ SV *st, int *status) {
    store *s = store_try(aTHX_ st);
    state_store_txn *t;
    store_saved saved;

    if (status) *status = STATE_STORE_OK;
    if (!s || s->validating) {
        if (status) *status = s ? STATE_STORE_BUSY : STATE_STORE_NOTSTORE;
        return NULL;
    }
    store_txn_begin(aTHX_ s, &saved, "State::Store txn_begin");
    t = (state_store_txn *)store_alloc(aTHX_ sizeof(state_store_txn));
    t->saved = saved;
    t->st    = newSVsv(st);
    t->depth = s->txn_depth;
    return t;
}

/* The transaction's store, or NULL with *rc set when it cannot be closed:
 * gone, or not the innermost one open. */
static store *store_abi_txn_store(pTHX_ state_store_txn *t, int *rc) {
    store *s = t ? store_try(aTHX_ t->st) : NULL;
    if (!s) { *rc = STATE_STORE_NOTSTORE; return NULL; }
    if (s->txn_depth != t->depth || s->validating) { *rc = STATE_STORE_ORDER; return NULL; }
    *rc = STATE_STORE_OK;
    return s;
}

static void store_abi_txn_free(pTHX_ state_store_txn *t) {
    SV *st = t->st;
    store_free(aTHX_ t);
    SvREFCNT_dec(st);
}

static int store_abi_txn_commit(pTHX_ state_store_txn *t) {
    int rc;
    store *s = store_abi_txn_store(aTHX_ t, &rc);
    SV *hold;

    if (!s) return rc;
    hold = sv_2mortal(newSVsv(t->st));
    if (t->depth > 1) store_txn_forget(aTHX_ s, &t->saved);
    else              store_txn_commit(aTHX_ s, &t->saved, "State::Store txn_commit");
    store_abi_txn_free(aTHX_ t);
    store_deliver(aTHX_ s, hold);
    return STATE_STORE_OK;
}

static int store_abi_txn_abort(pTHX_ state_store_txn *t) {
    int rc;
    store *s = store_abi_txn_store(aTHX_ t, &rc);

    if (!s) return rc;
    sv_2mortal(newSVsv(t->st));
    store_txn_restore(aTHX_ s, &t->saved);
    store_abi_txn_free(aTHX_ t);
    return STATE_STORE_OK;
}

static int store_abi_in_txn(pTHX_ SV *st) {
    store *s = store_try(aTHX_ st);
    if (!s) return STATE_STORE_NOTSTORE;
    return s->txn_depth > 0;
}

/* ---- checkpoints ------------------------------------------------------- */

static int store_abi_checkpoint(pTHX_ SV *st, const char *name, STRLEN len, int utf8) {
    store *s = store_try(aTHX_ st);
    if (!s) return STATE_STORE_NOTSTORE;
    if (s->validating) return STATE_STORE_BUSY;
    store_checkpoint(aTHX_ s, store_abi_name(aTHX_ name, len, utf8), "State::Store checkpoint");
    return STATE_STORE_OK;
}

static SV *store_abi_checkpoint_value(pTHX_ SV *st, const char *name, STRLEN len, int utf8) {
    store *s = store_try(aTHX_ st);
    if (!s || !s->checkpoints || !name) return NULL;
    return (STORE_HAMT->map_fetch)(aTHX_ s->checkpoints, name, len, utf8);
}

static int store_abi_has_checkpoint(pTHX_ SV *st, const char *name, STRLEN len, int utf8) {
    store *s = store_try(aTHX_ st);
    if (!s) return STATE_STORE_NOTSTORE;
    return s->checkpoints && name
        && (STORE_HAMT->map_has)(aTHX_ s->checkpoints, name, len, utf8);
}

static int store_abi_restore(pTHX_ SV *st, const char *name, STRLEN len, int utf8) {
    store *s = store_try(aTHX_ st);
    SV *value;
    if (!s) return STATE_STORE_NOTSTORE;
    if (s->validating || s->txn_depth) return STATE_STORE_BUSY;
    value = store_abi_checkpoint_value(aTHX_ st, name, len, utf8);
    if (!value) return STATE_STORE_NOTFOUND;
    value = sv_2mortal(SvREFCNT_inc_simple_NN(value));
    return store_abi_put(aTHX_ s, st, value, 0, "State::Store restore");
}

static int store_abi_drop_checkpoint(pTHX_ SV *st, const char *name, STRLEN len, int utf8) {
    store *s = store_try(aTHX_ st);
    if (!s) return STATE_STORE_NOTSTORE;
    if (s->validating) return STATE_STORE_BUSY;
    if (!store_abi_checkpoint_value(aTHX_ st, name, len, utf8)) return STATE_STORE_NOTFOUND;
    store_drop_checkpoint(aTHX_ s, store_abi_name(aTHX_ name, len, utf8), "State::Store drop_checkpoint");
    return STATE_STORE_OK;
}

static size_t store_abi_checkpoint_count(pTHX_ SV *st) {
    store *s = store_try(aTHX_ st);
    return s && s->checkpoints ? (STORE_HAMT->map_count)(aTHX_ s->checkpoints) : 0;
}

typedef struct store_abi_walk { state_store_name_fn fn; void *ud; } store_abi_walk;

static int store_abi_walk_one(pTHX_ void *ud, const char *key, STRLEN klen, int utf8, SV *value) {
    store_abi_walk *w = (store_abi_walk *)ud;
    return w->fn(aTHX_ w->ud, key, klen, utf8, value);
}

static int store_abi_checkpoint_walk(pTHX_ SV *st, state_store_name_fn fn, void *ud) {
    store *s = store_try(aTHX_ st);
    store_abi_walk w;
    if (!s) return STATE_STORE_NOTSTORE;
    if (!s->checkpoints) return STATE_STORE_OK;
    w.fn = fn;
    w.ud = ud;
    return (STORE_HAMT->map_walk)(aTHX_ s->checkpoints, store_abi_walk_one, &w) == HAMT_ABI_OK
         ? STATE_STORE_OK : STATE_STORE_STOPPED;
}

/* ---- the table --------------------------------------------------------- */

static const state_store_abi STORE_ABI = {
    STATE_STORE_ABI_VERSION,

    store_abi_new,
    store_abi_is_store,

    store_abi_current,
    store_abi_set,
    store_abi_swap,

    store_abi_undo,
    store_abi_redo,
    store_abi_undo_count,
    store_abi_redo_count,
    store_abi_clear_history,
    store_abi_history_limit,
    store_abi_set_history_limit,

    store_abi_watch,
    store_abi_unwatch,
    store_abi_watchers,
    store_abi_set_validator,

    store_abi_txn_begin,
    store_abi_txn_commit,
    store_abi_txn_abort,
    store_abi_in_txn,

    store_abi_checkpoint,
    store_abi_restore,
    store_abi_has_checkpoint,
    store_abi_checkpoint_value,
    store_abi_drop_checkpoint,
    store_abi_checkpoint_count,
    store_abi_checkpoint_walk
};

#endif
