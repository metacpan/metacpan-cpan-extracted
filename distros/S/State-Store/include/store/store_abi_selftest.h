#ifndef STORE_ABI_SELFTEST_H
#define STORE_ABI_SELFTEST_H

/* Walks the table. Every entry is called THROUGH the table, with its answer
 * checked, so an entry that points at the wrong function, or sits in the
 * wrong place, fails here by number and not in some consumer's hands.
 * 0 when every check passed, or the number of the first that failed. */

#define STORE_ST(n, cond) do { if (!(cond)) { step = (n); goto done; } } while (0)

typedef struct store_st_log { int calls; IV last_was, last_now; } store_st_log;

static void store_st_watch(pTHX_ void *ud, SV *was, SV *now, SV *st) {
    store_st_log *l = (store_st_log *)ud;
    PERL_UNUSED_ARG(st);
    l->calls++;
    l->last_was = SvOK(was) ? SvIV(was) : -1;
    l->last_now = SvOK(now) ? SvIV(now) : -1;
}
static int store_st_below_100(pTHX_ void *ud, SV *proposed, SV *held, SV *st) {
    PERL_UNUSED_ARG(held); PERL_UNUSED_ARG(st);
    (*(int *)ud)++;
    return SvIV(proposed) < 100;
}
static SV *store_st_double(pTHX_ void *ud, SV *current) {
    PERL_UNUSED_ARG(ud);
    return sv_2mortal(newSViv(SvIV(current) * 2));
}
static SV *store_st_nothing(pTHX_ void *ud, SV *current) {
    PERL_UNUSED_CONTEXT; PERL_UNUSED_ARG(ud); PERL_UNUSED_ARG(current);
    return NULL;
}
static int store_st_count_names(pTHX_ void *ud, const char *name, STRLEN len, int utf8, SV *value) {
    PERL_UNUSED_CONTEXT; PERL_UNUSED_ARG(name); PERL_UNUSED_ARG(len); PERL_UNUSED_ARG(utf8);
    if (value) (*(int *)ud)++;
    return 0;
}

/* `out`, when the test passes, gets the store it built: for the Perl side
 * to read back. */
static int store_abi_selftest(pTHX_ SV **out) {
    const state_store_abi *T = &STORE_ABI;
    SV *st = NULL, *v;
    state_store_txn *outer = NULL, *inner = NULL;
    store_st_log log = { 0, 0, 0 };
    size_t taken = 9, limit = 9;
    int step = 0, asked = 0, names = 0, status = 99;
    UV id;

    *out = NULL;
    STORE_ST(1, T->abi_version == STATE_STORE_ABI_VERSION);

    v = sv_2mortal(newSViv(1));
    st = (T->store_new)(aTHX_ v);
    STORE_ST(2, st && (T->is_store)(aTHX_ st));
    STORE_ST(3, !(T->is_store)(aTHX_ v) && !(T->is_store)(aTHX_ &PL_sv_undef));
    STORE_ST(4, SvIV((T->current)(aTHX_ st)) == 1 && (T->current)(aTHX_ v) == NULL);

    STORE_ST(5, (T->set)(aTHX_ st, sv_2mortal(newSViv(2))) == 1);
    STORE_ST(6, (T->set)(aTHX_ st, sv_2mortal(newSVpvs("2"))) == 0);
    STORE_ST(7, (T->set)(aTHX_ v, v) == STATE_STORE_NOTSTORE);
    STORE_ST(8, (T->swap)(aTHX_ st, store_st_double, NULL) == 1 && SvIV((T->current)(aTHX_ st)) == 4);
    STORE_ST(9, (T->swap)(aTHX_ st, store_st_nothing, NULL) == STATE_STORE_STOPPED);

    STORE_ST(10, (T->undo_count)(aTHX_ st) == 2 && (T->redo_count)(aTHX_ st) == 0);
    STORE_ST(11, (T->undo)(aTHX_ st, 5, &taken) == STATE_STORE_OK && taken == 2);
    STORE_ST(12, SvIV((T->current)(aTHX_ st)) == 1 && (T->redo_count)(aTHX_ st) == 2);
    STORE_ST(13, (T->redo)(aTHX_ st, 1, &taken) == STATE_STORE_OK && taken == 1
                 && SvIV((T->current)(aTHX_ st)) == 2);
    STORE_ST(14, (T->clear_history)(aTHX_ st) == STATE_STORE_OK
                 && (T->undo_count)(aTHX_ st) == 0 && (T->redo_count)(aTHX_ st) == 0);

    STORE_ST(15, (T->history_limit)(aTHX_ st, &limit) == 0 && limit == 0);
    STORE_ST(16, (T->set_history_limit)(aTHX_ st, 1, 3) == STATE_STORE_OK);
    STORE_ST(17, (T->history_limit)(aTHX_ st, &limit) == 1 && limit == 3);

    id = (T->watch)(aTHX_ st, store_st_watch, &log);
    STORE_ST(18, id != 0 && (T->watchers)(aTHX_ st) == 1);
    (T->set)(aTHX_ st, sv_2mortal(newSViv(7)));
    STORE_ST(19, log.calls == 1 && log.last_was == 2 && log.last_now == 7);

    STORE_ST(20, (T->set_validator)(aTHX_ st, store_st_below_100, &asked) == STATE_STORE_OK);
    STORE_ST(21, (T->set)(aTHX_ st, sv_2mortal(newSViv(500))) == STATE_STORE_REFUSED
                 && SvIV((T->current)(aTHX_ st)) == 7 && asked == 1 && log.calls == 1);
    STORE_ST(22, (T->set)(aTHX_ st, sv_2mortal(newSViv(8))) == 1 && asked == 2);

    outer = (T->txn_begin)(aTHX_ st, &status);
    STORE_ST(23, outer && status == STATE_STORE_OK && (T->in_txn)(aTHX_ st) == 1);
    inner = (T->txn_begin)(aTHX_ st, NULL);
    STORE_ST(24, inner != NULL);
    STORE_ST(25, (T->txn_commit)(aTHX_ outer) == STATE_STORE_ORDER);
    STORE_ST(26, (T->undo)(aTHX_ st, 1, NULL) == STATE_STORE_BUSY);
    (T->set)(aTHX_ st, sv_2mortal(newSViv(30)));
    STORE_ST(27, (T->txn_abort)(aTHX_ inner) == STATE_STORE_OK && SvIV((T->current)(aTHX_ st)) == 8);
    inner = NULL;
    (T->set)(aTHX_ st, sv_2mortal(newSViv(40)));
    (T->set)(aTHX_ st, sv_2mortal(newSViv(41)));
    STORE_ST(28, log.calls == 2);
    STORE_ST(29, (T->txn_commit)(aTHX_ outer) == STATE_STORE_OK);
    outer = NULL;
    STORE_ST(30, log.calls == 3 && log.last_was == 8 && log.last_now == 41
                 && (T->in_txn)(aTHX_ st) == 0);

    STORE_ST(31, (T->checkpoint)(aTHX_ st, "here", 4, 0) == STATE_STORE_OK);
    STORE_ST(32, (T->has_checkpoint)(aTHX_ st, "here", 4, 0) == 1
                 && (T->has_checkpoint)(aTHX_ st, "there", 5, 0) == 0);
    STORE_ST(33, SvIV((T->checkpoint_value)(aTHX_ st, "here", 4, 0)) == 41);
    (T->set)(aTHX_ st, sv_2mortal(newSViv(50)));
    STORE_ST(34, (T->restore)(aTHX_ st, "here", 4, 0) == 1 && SvIV((T->current)(aTHX_ st)) == 41);
    STORE_ST(35, (T->restore)(aTHX_ st, "there", 5, 0) == STATE_STORE_NOTFOUND);
    STORE_ST(36, (T->checkpoint_count)(aTHX_ st) == 1);
    STORE_ST(37, (T->checkpoint_walk)(aTHX_ st, store_st_count_names, &names) == STATE_STORE_OK
                 && names == 1);
    STORE_ST(38, (T->drop_checkpoint)(aTHX_ st, "here", 4, 0) == STATE_STORE_OK
                 && (T->checkpoint_count)(aTHX_ st) == 0);
    STORE_ST(39, (T->drop_checkpoint)(aTHX_ st, "here", 4, 0) == STATE_STORE_NOTFOUND);

    STORE_ST(40, (T->unwatch)(aTHX_ st, id) == 1 && (T->watchers)(aTHX_ st) == 0
                 && (T->unwatch)(aTHX_ st, id) == 0);
    STORE_ST(41, (T->set_validator)(aTHX_ st, NULL, NULL) == STATE_STORE_OK
                 && (T->set)(aTHX_ st, sv_2mortal(newSViv(1000))) == 1);

  done:
    if (inner) (T->txn_abort)(aTHX_ inner);
    if (outer) (T->txn_abort)(aTHX_ outer);
    if (st) {
        if (step) SvREFCNT_dec(st);
        else *out = st;
    }
    return step;
}

#endif
