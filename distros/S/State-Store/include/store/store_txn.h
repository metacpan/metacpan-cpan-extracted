#ifndef STORE_TXN_H
#define STORE_TXN_H

/* Transactions. Each one, nested or not, keeps what the store was when it
 * began: the value and copies of both stacks. A copy of a stack is a small
 * struct that shares every node, so keeping one costs that struct.
 *
 * A transaction that fails puts back what it kept, which undoes everything
 * done inside it and nothing done outside. One that succeeds lets go of what
 * it kept, unless it is the outermost: that one makes everything done
 * inside into one step, from the value it began with to the value it ends
 * with, and has the watchers told of it once. If the value it ends with is
 * the value it began with, there is no step: the stacks go back as they
 * were, and nobody is told. */

typedef struct store_saved {
    SV       *value;
    hamt_vec *past;
    hamt_vec *future;
    hamt_map *checkpoints;      /* NULL when the store had none */
    size_t    past_skip;
} store_saved;

static void store_txn_begin(pTHX_ store *s, store_saved *sv, const char *what) {
    sv->past   = (STORE_HAMT->vec_copy)(aTHX_ s->past);
    sv->future = sv->past ? (STORE_HAMT->vec_copy)(aTHX_ s->future) : NULL;
    if (!sv->future) {
        if (sv->past) (STORE_HAMT->vec_release)(aTHX_ sv->past);
        croak("%s: out of memory", what);
    }
    sv->checkpoints = NULL;
    if (s->checkpoints) {
        sv->checkpoints = (STORE_HAMT->map_copy)(aTHX_ s->checkpoints);
        if (!sv->checkpoints) {
            (STORE_HAMT->vec_release)(aTHX_ sv->past);
            (STORE_HAMT->vec_release)(aTHX_ sv->future);
            croak("%s: out of memory", what);
        }
    }
    sv->value = SvREFCNT_inc_simple_NN(s->value);
    sv->past_skip = s->past_skip;
    s->txn_depth++;
}

/* The store as it was when `sv` was kept. What it had become is let go
 * last, once the store holds the old state again. */
static void store_txn_restore(pTHX_ store *s, store_saved *sv) {
    SV *value = s->value;
    hamt_vec *past = s->past, *future = s->future;
    hamt_map *checkpoints = s->checkpoints;

    s->value       = sv->value;
    s->past        = sv->past;
    s->future      = sv->future;
    s->checkpoints = sv->checkpoints;
    s->past_skip   = sv->past_skip;
    s->txn_depth--;

    store_sv_release(aTHX_ value);
    (STORE_HAMT->vec_release)(aTHX_ past);
    (STORE_HAMT->vec_release)(aTHX_ future);
    if (checkpoints) (STORE_HAMT->map_release)(aTHX_ checkpoints);
}

/* What a transaction kept of the checkpoints, when it is not going back to
 * them. */
static void store_txn_drop_checkpoints(pTHX_ store_saved *sv) {
    if (sv->checkpoints) (STORE_HAMT->map_release)(aTHX_ sv->checkpoints);
    sv->checkpoints = NULL;
}

/* An inner transaction that worked: what it kept is not needed. */
static void store_txn_forget(pTHX_ store *s, store_saved *sv) {
    s->txn_depth--;
    store_txn_drop_checkpoints(aTHX_ sv);
    store_sv_release(aTHX_ sv->value);
    (STORE_HAMT->vec_release)(aTHX_ sv->past);
    (STORE_HAMT->vec_release)(aTHX_ sv->future);
}

/* The outermost transaction worked. One step, from the value it began with,
 * onto the stacks it began with; nothing to redo; one change queued. */
static void store_txn_commit(pTHX_ store *s, store_saved *sv, const char *what) {
    hamt_vec *past, *future, *room = NULL, *dead_past, *dead_future;
    int record = !s->limited || s->limit > 0, nomem = 0;

    /* No change of value: the stacks go back, but checkpoints named inside
     * stay, since the transaction worked. */
    if ((STORE_HAMT->value_equal)(aTHX_ sv->value, s->value)) {
        store_txn_drop_checkpoints(aTHX_ sv);
        sv->checkpoints = s->checkpoints;
        s->checkpoints  = NULL;
        store_txn_restore(aTHX_ s, sv);
        return;
    }

    future = (STORE_HAMT->vec_new)(aTHX);
    if (!future) { store_txn_restore(aTHX_ s, sv); croak("%s: out of memory", what); }
    past = sv->past;
    if (record && s->limited) {
        room = store_room(aTHX_ s, past, &nomem);
        if (nomem) {
            (STORE_HAMT->vec_release)(aTHX_ future);
            store_txn_restore(aTHX_ s, sv);
            croak("%s: out of memory", what);
        }
        if (room) { past = room; sv->past_skip = 0; }
    }
    if (record && (STORE_HAMT->vec_push)(aTHX_ past, sv->value) != HAMT_ABI_OK) {
        if (room) (STORE_HAMT->vec_release)(aTHX_ room);
        (STORE_HAMT->vec_release)(aTHX_ future);
        store_txn_restore(aTHX_ s, sv);
        croak("%s: out of memory", what);
    }

    dead_past   = s->past;
    dead_future = s->future;
    s->past   = past;
    s->future = future;
    s->past_skip = record ? store_skip_after(s, (STORE_HAMT->vec_count)(aTHX_ past), sv->past_skip)
                          : sv->past_skip;
    s->txn_depth--;

    store_enqueue(aTHX_ s, sv->value, s->value);
    store_txn_drop_checkpoints(aTHX_ sv);
    store_sv_release(aTHX_ sv->value);
    if (room) (STORE_HAMT->vec_release)(aTHX_ sv->past);
    (STORE_HAMT->vec_release)(aTHX_ sv->future);
    (STORE_HAMT->vec_release)(aTHX_ dead_past);
    (STORE_HAMT->vec_release)(aTHX_ dead_future);
}

#endif
