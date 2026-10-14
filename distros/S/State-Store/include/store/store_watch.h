#ifndef STORE_WATCH_H
#define STORE_WATCH_H

/* Watchers: subs told of every change, after the store has settled.
 *
 * A change is queued where it is made and told once the operation that made
 * it is over. A watcher that changes the store queues another change behind
 * the one being told, so every watcher sees every change, in order, and
 * none is told a `now` older than its `was`. A store that keeps changing
 * itself from its watchers is a loop, and is stopped after a fixed number
 * of changes told in one round.
 *
 * A watcher that dies does not stop the others, and does not undo the
 * change: the change has happened. The first error is thrown again once
 * every watcher has been told every change. */

#define STORE_WATCH_LOOP 10000

/* Removed watchers out of the list. Only between rounds: during one, a
 * removed watcher keeps its place so that the indices being walked hold. */
static void store_watch_sweep(store *s) {
    size_t i, j = 0;
    for (i = 0; i < s->nwatchers; i++)
        if (s->watchers[i].code || s->watchers[i].cfn) s->watchers[j++] = s->watchers[i];
    s->nwatchers = j;
}

/* A Perl sub, or a C function and its data. */
static UV store_watch_add(pTHX_ store *s, SV *code, state_store_watch_fn cfn, void *ud) {
    if (s->nwatchers == s->cwatchers) {
        s->cwatchers = s->cwatchers ? s->cwatchers * 2 : 4;
        Renew(s->watchers, s->cwatchers, store_watcher);
    }
    s->watchers[s->nwatchers].id   = ++s->next_id;
    s->watchers[s->nwatchers].code = code ? SvREFCNT_inc_simple_NN(code) : NULL;
    s->watchers[s->nwatchers].cfn  = code ? NULL : cfn;
    s->watchers[s->nwatchers].ud   = ud;
    s->nwatchers++;
    s->live_watchers++;
    return s->next_id;
}

/* 1 if there was a watcher with that id. Its code is let go now; a round
 * that is calling it holds a reference of its own. */
static int store_watch_remove(pTHX_ store *s, UV id) {
    size_t i;
    for (i = 0; i < s->nwatchers; i++) {
        SV *code = s->watchers[i].code;
        if (s->watchers[i].id != id || (!code && !s->watchers[i].cfn)) continue;
        s->watchers[i].code = NULL;
        s->watchers[i].cfn  = NULL;
        s->live_watchers--;
        if (!s->delivering) store_watch_sweep(s);
        if (code) SvREFCNT_dec(code);
        return 1;
    }
    return 0;
}

/* Tell the watchers every change queued. `storerv` is a reference to the
 * store, held by the caller for as long as this runs, and handed to each
 * watcher. Nothing happens if a round is already running further up: that
 * round will tell what was queued here. */
static void store_deliver(pTHX_ store *s, SV *storerv) {
    SV *first_err = NULL;
    size_t told = 0;

    if (s->delivering || !s->qlen) return;
    if (PL_dirty) { store_queue_clear(aTHX_ s); return; }
    s->delivering = 1;

    while (s->qlen) {
        store_change c = s->queue[s->qhead++];
        size_t n = s->nwatchers, i;
        s->qlen--;
        if (!s->qlen) s->qhead = 0;

        if (++told > STORE_WATCH_LOOP) {
            SvREFCNT_dec(c.was);
            SvREFCNT_dec(c.now);
            store_queue_clear(aTHX_ s);
            s->delivering = 0;
            store_watch_sweep(s);
            if (first_err) SvREFCNT_dec(first_err);
            croak("State::Store: the watchers changed the store %d times in one round;"
                  " one of them changes it every time it is called", STORE_WATCH_LOOP);
        }

        /* Those there when this change is told, and still there when their
         * turn comes. One added now is told the next change. */
        for (i = 0; i < n && i < s->nwatchers; i++) {
            SV *code = s->watchers[i].code, *args[3], *err;
            if (!code) {
                state_store_watch_fn cfn = s->watchers[i].cfn;
                if (cfn) {
                    ENTER;
                    SAVETMPS;
                    cfn(aTHX_ s->watchers[i].ud, c.was, c.now, storerv);
                    FREETMPS;
                    LEAVE;
                }
                continue;
            }
            args[0] = c.was;
            args[1] = c.now;
            args[2] = storerv;
            SvREFCNT_inc_simple_void_NN(code);
            ENTER;
            SAVETMPS;
            err = store_call(aTHX_ code, args, 3, G_VOID, NULL, NULL);
            if (err && !first_err) first_err = newSVsv(err);
            FREETMPS;
            LEAVE;
            SvREFCNT_dec(code);
        }
        SvREFCNT_dec(c.was);
        SvREFCNT_dec(c.now);
    }

    s->delivering = 0;
    store_watch_sweep(s);
    if (first_err) store_rethrow(aTHX_ sv_2mortal(first_err));
}

#endif
