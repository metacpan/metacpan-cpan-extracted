#ifndef STORE_HISTORY_H
#define STORE_HISTORY_H

/* Undo and redo. The past is a vector of the values before the current one,
 * oldest first; the future is a vector of the values undone, with the next
 * one to redo at the end. Both are HAMT vectors, so keeping a step costs a
 * slot in a tree that shares everything else, and taking one back costs
 * the same.
 *
 * A move of `n` steps from one to the other is made on copies of both
 * structs, and the store takes the copies only once every part of the move
 * has worked: running out of memory part way croaks with the store as it
 * was. A copy shares every node with what it was copied from, so making one
 * costs a small struct; changing it copies only the nodes it changes. */

/* `from` is the stack a step is taken off and `to` the one the current value
 * goes onto: the past and the future for an undo, the other way about for a
 * redo. How many steps were taken: `n`, or fewer if `from` held fewer. */
static size_t store_move(pTHX_ store *s, int undo, size_t n, const char *what) {
    hamt_vec *from = undo ? s->past : s->future;
    hamt_vec *to   = undo ? s->future : s->past;
    hamt_vec *nfrom, *nto;
    size_t skip = s->past_skip;
    size_t phys = (STORE_HAMT->vec_count)(aTHX_ from), i;
    size_t have = undo ? store_past_len(aTHX_ s) : phys;
    SV *arrive, *old;
    int status = HAMT_ABI_OK;

    store_check_mutable(aTHX_ s, what);
    store_check_no_txn(aTHX_ s, what);
    if (n > have) n = have;
    if (n == 0) return 0;

    /* The current value goes onto `to`, then the values passed over on the
     * way, nearest first; the value arrived at is the n-th from the end of
     * `from`, and `from` keeps what is before it. */
    nto = (STORE_HAMT->vec_copy)(aTHX_ to);
    if (!nto) croak("%s: out of memory", what);
    for (i = 0; i < n; i++) {
        SV *v = i == 0 ? s->value : (STORE_HAMT->vec_fetch)(aTHX_ from, phys - i);
        if ((STORE_HAMT->vec_push)(aTHX_ nto, v) != HAMT_ABI_OK) {
            (STORE_HAMT->vec_release)(aTHX_ nto);
            croak("%s: out of memory", what);
        }
    }
    /* A redo adds to the past, which is cut as a change cuts it. */
    if (!undo && s->limited) {
        int nomem = 0;
        hamt_vec *cut = (STORE_HAMT->vec_count)(aTHX_ nto) >= s->limit + STORE_TRIM_SLACK
                      ? store_trimmed(aTHX_ nto, s->limit, &nomem) : NULL;
        if (nomem) {
            (STORE_HAMT->vec_release)(aTHX_ nto);
            croak("%s: out of memory", what);
        }
        if (cut) { (STORE_HAMT->vec_release)(aTHX_ nto); nto = cut; skip = 0; }
        skip = store_skip_after(s, (STORE_HAMT->vec_count)(aTHX_ nto), skip);
    }
    nfrom = (STORE_HAMT->vec_slice)(aTHX_ from, 0, phys - n, &status);
    if (!nfrom) {
        (STORE_HAMT->vec_release)(aTHX_ nto);
        croak("%s: out of memory", what);
    }

    arrive = SvREFCNT_inc_simple_NN((STORE_HAMT->vec_fetch)(aTHX_ from, phys - n));
    old = s->value;
    s->value = arrive;
    if (undo) { s->past = nfrom; s->future = nto; }
    else      { s->future = nfrom; s->past = nto; }
    s->past_skip = skip;

    store_enqueue(aTHX_ s, old, arrive);
    store_sv_release(aTHX_ old);
    (STORE_HAMT->vec_release)(aTHX_ from);
    (STORE_HAMT->vec_release)(aTHX_ to);
    return n;
}

/* Both stacks emptied; the value stays. */
static void store_clear_history(pTHX_ store *s, const char *what) {
    hamt_vec *past, *future, *dead_past = s->past, *dead_future = s->future;

    store_check_mutable(aTHX_ s, what);
    store_check_no_txn(aTHX_ s, what);
    past   = (STORE_HAMT->vec_new)(aTHX);
    future = past ? (STORE_HAMT->vec_new)(aTHX) : NULL;
    if (!future) {
        if (past) (STORE_HAMT->vec_release)(aTHX_ past);
        croak("%s: out of memory", what);
    }
    s->past   = past;
    s->future = future;
    s->past_skip = 0;
    (STORE_HAMT->vec_release)(aTHX_ dead_past);
    (STORE_HAMT->vec_release)(aTHX_ dead_future);
}

/* A history limit from Perl: undef is none, and anything else must be a
 * whole number that is not negative. */
static void store_limit_arg(pTHX_ SV *sv, size_t *limit, int *limited, const char *what) {
    NV nv;
    sv = store_read_once(aTHX_ sv);
    if (!SvOK(sv)) { *limited = 0; *limit = 0; return; }
    if (!looks_like_number(sv))
        croak("%s: the history limit is not a number", what);
    nv = SvNV(sv);
    if (nv < 0 || nv != (NV)(UV)nv)
        croak("%s: the history limit must be a whole number, not negative, or undef", what);
    *limited = 1;
    *limit = (size_t)(UV)nv;
}

/* A new limit, applied at once: the past is cut to it, oldest first. The
 * values ahead are left alone; a redo cuts the past again as it goes. */
static void store_set_limit(pTHX_ store *s, size_t limit, int limited, const char *what) {
    hamt_vec *cut = NULL, *dead = NULL;
    int nomem = 0;

    store_check_mutable(aTHX_ s, what);
    store_check_no_txn(aTHX_ s, what);
    /* Cut to what can be undone, or less, so that no step beyond the old
     * limit comes back under a new one. */
    {
        size_t keep = store_past_len(aTHX_ s);
        if (limited && limit < keep) keep = limit;
        cut = store_trimmed(aTHX_ s->past, keep, &nomem);
        if (nomem) croak("%s: out of memory", what);
    }
    s->limited = limited;
    s->limit   = limit;
    if (cut) { dead = s->past; s->past = cut; }
    s->past_skip = 0;
    if (dead) (STORE_HAMT->vec_release)(aTHX_ dead);
}

/* A count of steps from Perl: absent is one, and anything else must be a
 * whole number that is not negative. */
static size_t store_steps(pTHX_ SV *sv, const char *what) {
    NV nv;
    if (!sv) return 1;
    /* Read once, into a plain copy: SvNV_nomg is not in 5.10 or 5.12. */
    sv = store_read_once(aTHX_ sv);
    if (!SvOK(sv) || !looks_like_number(sv))
        croak("%s: the number of steps is not a number", what);
    nv = SvNV(sv);
    if (nv < 0 || nv != (NV)(UV)nv)
        croak("%s: the number of steps must be a whole number, not negative", what);
    return (size_t)(UV)nv;
}

#endif
