#ifndef PQ_SCHED_H
#define PQ_SCHED_H

/* pq_sched.h - cron storage and the scheduler tick.
 *
 * Declarations reconcile into pq_crons keyed on `name`: upsert updates
 * the definition and recomputes next_run when the schedule itself (expr
 * or tz) changed, and NEVER touches `enabled` - an operator's disable
 * must survive every deploy, or pausing a misbehaving cron lasts exactly
 * until the next boot. disable_missing_crons retires declarations that
 * disappeared; nothing is ever deleted, so history and identity survive.
 *
 * The tick is leader-only (the phase-6 lease arbitrates) and per due
 * cron ADVANCES FIRST, THEN ENQUEUES: a crash between the two loses one
 * occurrence, which is strictly better than duplicating one. The
 * optimistic `WHERE next_run = ?` guard makes a double-elected leader
 * harmless, and the occurrence dedupe key is the belt to those braces.
 * The guarantee, exactly: at-most-once per occurrence, at-least-once per
 * enqueued job.
 *
 * Include after pq_cron.h, pq_lock.h and pq_backend.h. */

#define PQ_CRON_COLS \
    "id, name, expr, task, args, queue, priority, attempts, tz, catchup," \
    " enabled, last_run, next_run, last_job"

enum {
    PQ_CR_ID = 0, PQ_CR_NAME, PQ_CR_EXPR, PQ_CR_TASK, PQ_CR_ARGS,
    PQ_CR_QUEUE, PQ_CR_PRIORITY, PQ_CR_ATTEMPTS, PQ_CR_TZ, PQ_CR_CATCHUP,
    PQ_CR_ENABLED, PQ_CR_LAST_RUN, PQ_CR_NEXT_RUN, PQ_CR_LAST_JOB
};

static HV *pq_cron_row_hv(pTHX_ AV *row) {
    HV *h = newHV();
    if (!row) return h;
    pq_hv_set_iv(aTHX_ h, "id",       pq_col_iv(aTHX_ row, PQ_CR_ID));
    pq_hv_set_sv(aTHX_ h, "name",     pq_col(aTHX_ row, PQ_CR_NAME));
    pq_hv_set_sv(aTHX_ h, "expr",     pq_col(aTHX_ row, PQ_CR_EXPR));
    pq_hv_set_sv(aTHX_ h, "task",     pq_col(aTHX_ row, PQ_CR_TASK));
    (void)hv_stores(h, "args",
                    pq_json_decode(aTHX_ pq_col(aTHX_ row, PQ_CR_ARGS)));
    pq_hv_set_sv(aTHX_ h, "queue",    pq_col(aTHX_ row, PQ_CR_QUEUE));
    pq_hv_set_iv(aTHX_ h, "priority", pq_col_iv(aTHX_ row, PQ_CR_PRIORITY));
    pq_hv_set_iv(aTHX_ h, "attempts", pq_col_iv(aTHX_ row, PQ_CR_ATTEMPTS));
    pq_hv_set_sv(aTHX_ h, "tz",       pq_col(aTHX_ row, PQ_CR_TZ));
    pq_hv_set_sv(aTHX_ h, "catchup",  pq_col(aTHX_ row, PQ_CR_CATCHUP));
    pq_hv_set_iv(aTHX_ h, "enabled",  pq_col_iv(aTHX_ row, PQ_CR_ENABLED));
    pq_hv_set_nv_or_undef(aTHX_ h, "last_run",
                          pq_col(aTHX_ row, PQ_CR_LAST_RUN));
    pq_hv_set_nv_or_undef(aTHX_ h, "next_run",
                          pq_col(aTHX_ row, PQ_CR_NEXT_RUN));
    {
        SV *j = pq_col(aTHX_ row, PQ_CR_LAST_JOB);
        (void)hv_stores(h, "last_job",
                        SvOK(j) ? newSViv(SvIV(j)) : newSV(0));
    }
    return h;
}

/* next occurrence for a stored expr/tz pair, strictly after `from` */
static double pq_sched_next(pTHX_ SV *expr, SV *tz, double from) {
    pq_cron c;
    pq_tz z;
    STRLEN el, tl = 0;
    const char *es = SvPV_const(expr, el);
    const char *ts = (tz && SvOK(tz)) ? SvPV_const(tz, tl) : NULL;
    pq_cron_parse(aTHX_ es, el, &c);
    pq_tz_parse(aTHX_ ts, tl, &z);
    return pq_cron_next(aTHX_ &c, from, &z);
}

/* ---- upsert / reconcile ---------------------------------------------------- */

static IV pq_upsert_cron(pTHX_ SV *self, HV *def) {
    SV *name  = pq_get(aTHX_ def, "name");
    SV *expr  = pq_get(aTHX_ def, "expr");
    SV *task  = pq_get(aTHX_ def, "task");
    SV *queue = pq_get(aTHX_ def, "queue");
    SV *tz    = pq_get(aTHX_ def, "tz");
    SV *catchup = pq_get(aTHX_ def, "catchup");
    SV *args_json;
    double now = pq_now(aTHX_ self);
    IV id = 0;

    pq_name_check(aTHX_ name, "cron");
    pq_name_check(aTHX_ task, "task");
    if (queue && SvOK(queue)) pq_name_check(aTHX_ queue, "queue");
    else                      queue = sv_2mortal(newSVpvs("default"));
    if (!(expr && SvOK(expr)))
        croak("Punk::Queue: a cron needs an expression");
    if (!(tz && SvOK(tz))) tz = sv_2mortal(newSVpvs("UTC"));
    if (catchup && SvOK(catchup)) {
        const char *cp = SvPV_nolen(catchup);
        if (strNE(cp, "once") && strNE(cp, "all") && strNE(cp, "skip"))
            croak("Punk::Queue: cron catchup must be once, all or skip, "
                  "not '%s'", cp);
    }
    else catchup = sv_2mortal(newSVpvs("once"));

    /* the boot croak: syntax AND can-it-ever-fire */
    {
        pq_cron c;
        pq_tz z;
        STRLEN el, tl;
        const char *es = SvPV_const(expr, el);
        const char *ts = SvPV_const(tz, tl);
        pq_cron_compile(aTHX_ es, el, ts, tl, &c, &z);
    }

    args_json = sv_2mortal(pq_json_encode(aTHX_
                    pq_get(aTHX_ def, "args"), "[]"));

    pq_txn_begin(aTHX_ self);
    {
        AV *b = pq_binds(aTHX), *row;
        pq_bind_sv(aTHX_ b, name);
        row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT id, expr, tz FROM pq_crons WHERE name = ?")), b);

        if (row) {
            SV *oexpr = pq_col(aTHX_ row, 1);
            SV *otz   = pq_col(aTHX_ row, 2);
            int sched_changed =
                   !(SvOK(oexpr) && sv_eq(oexpr, expr))
                || !(SvOK(otz)   && sv_eq(otz, tz));
            id = pq_col_iv(aTHX_ row, 0);
            SvREFCNT_dec((SV *)row);

            b = pq_binds(aTHX);
            {
                SV *sql = pq_sql_new(aTHX_
                    "UPDATE pq_crons SET expr = ?, task = ?, args = ?,"
                    " queue = ?, priority = ?, attempts = ?, tz = ?,"
                    " catchup = ?, updated = ?");
                pq_bind_sv(aTHX_ b, expr);
                pq_bind_sv(aTHX_ b, task);
                pq_bind_sv(aTHX_ b, args_json);
                pq_bind_sv(aTHX_ b, queue);
                {
                    SV *prio = pq_get(aTHX_ def, "priority");
                    pq_bind_iv(aTHX_ b, (prio && SvOK(prio)) ? SvIV(prio) : 0);
                }
                {
                    SV *at = pq_get(aTHX_ def, "attempts");
                    pq_bind_iv(aTHX_ b, (at && SvOK(at)) ? SvIV(at) : 1);
                }
                pq_bind_sv(aTHX_ b, tz);
                pq_bind_sv(aTHX_ b, catchup);
                pq_bind_nv(aTHX_ b, now);
                if (sched_changed) {
                    /* a new schedule starts from now - and deliberately
                     * NOT a new enabled state */
                    pq_sql_cat(aTHX_ sql, ", next_run = ?");
                    pq_bind_nv(aTHX_ b,
                               pq_sched_next(aTHX_ expr, tz, now));
                }
                pq_sql_cat(aTHX_ sql, " WHERE id = ?");
                pq_bind_iv(aTHX_ b, id);
                (void)pq_do(aTHX_ self, sql, b);
            }
        }
        else {
            SV *prio = pq_get(aTHX_ def, "priority");
            SV *at   = pq_get(aTHX_ def, "attempts");
            b = pq_binds(aTHX);
            pq_bind_sv(aTHX_ b, name);
            pq_bind_sv(aTHX_ b, expr);
            pq_bind_sv(aTHX_ b, task);
            pq_bind_sv(aTHX_ b, args_json);
            pq_bind_sv(aTHX_ b, queue);
            pq_bind_iv(aTHX_ b, (prio && SvOK(prio)) ? SvIV(prio) : 0);
            pq_bind_iv(aTHX_ b, (at && SvOK(at)) ? SvIV(at) : 1);
            pq_bind_sv(aTHX_ b, tz);
            pq_bind_sv(aTHX_ b, catchup);
            pq_bind_nv(aTHX_ b, pq_sched_next(aTHX_ expr, tz, now));
            pq_bind_nv(aTHX_ b, now);
            pq_bind_nv(aTHX_ b, now);
            {
                SV *sql = pq_sql_new(aTHX_
                    "INSERT INTO pq_crons (name, expr, task, args, queue,"
                    " priority, attempts, tz, catchup, enabled, next_run,"
                    " created, updated)"
                    " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?)");
                if (pq_has_returning(aTHX_ self)) {
                    AV *r2;
                    pq_sql_cat(aTHX_ sql, " RETURNING id");
                    r2 = pq_selectrow(aTHX_ self, sql, b);
                    if (r2) { id = pq_col_iv(aTHX_ r2, 0);
                              SvREFCNT_dec((SV *)r2); }
                }
                else {
                    (void)pq_do(aTHX_ self, sql, b);
                    id = pq_last_insert_id(aTHX_ self);
                }
            }
        }
    }
    pq_txn_commit(aTHX_ self);
    return id;
}

/* Retire declarations the app no longer makes: enabled = 0, never
 * delete, so an accidentally dropped declaration keeps its identity and
 * history when it comes back. */
static IV pq_disable_missing_crons(pTHX_ SV *self, AV *names) {
    SSize_t n = names ? av_len(names) + 1 : 0, i;
    AV *bind = pq_binds(aTHX);
    SV *sql = pq_sql_new(aTHX_
        "UPDATE pq_crons SET enabled = 0, updated = ?");
    pq_bind_nv(aTHX_ bind, pq_now(aTHX_ self));
    if (n > 0) {
        pq_sql_cat(aTHX_ sql, " WHERE enabled = 1 AND name NOT IN (");
        pq_sql_placeholders(aTHX_ sql, n);
        pq_sql_cat(aTHX_ sql, ")");
        for (i = 0; i < n; i++)
            pq_bind_sv(aTHX_ bind, *av_fetch(names, i, 0));
    }
    else pq_sql_cat(aTHX_ sql, " WHERE enabled = 1");
    return pq_do(aTHX_ self, sql, bind);
}

/* Enable / disable, the operational pause. Re-enabling recomputes
 * next_run from NOW regardless of the cron's own catchup policy - the
 * disabled window behaves as `skip`, so flipping a cron back on cannot
 * fire a catch-up storm for the time it was off. */
static IV pq_enable_cron(pTHX_ SV *self, SV *name, int on) {
    IV took = 0;
    pq_name_check(aTHX_ name, "cron");
    pq_txn_begin(aTHX_ self);
    if (on) {
        AV *b = pq_binds(aTHX), *row;
        pq_bind_sv(aTHX_ b, name);
        row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT id, expr, tz FROM pq_crons WHERE name = ?"
            " AND enabled = 0")), b);
        if (row) {
            IV id = pq_col_iv(aTHX_ row, 0);
            double nx = pq_sched_next(aTHX_ pq_col(aTHX_ row, 1),
                                      pq_col(aTHX_ row, 2),
                                      pq_now(aTHX_ self));
            SvREFCNT_dec((SV *)row);
            b = pq_binds(aTHX);
            pq_bind_nv(aTHX_ b, nx);
            pq_bind_nv(aTHX_ b, pq_now(aTHX_ self));
            pq_bind_iv(aTHX_ b, id);
            took = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                "UPDATE pq_crons SET enabled = 1, next_run = ?,"
                " updated = ? WHERE id = ?")), b);
        }
    }
    else {
        AV *b = pq_binds(aTHX);
        pq_bind_nv(aTHX_ b, pq_now(aTHX_ self));
        pq_bind_sv(aTHX_ b, name);
        took = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "UPDATE pq_crons SET enabled = 0, updated = ?"
            " WHERE name = ? AND enabled = 1")), b);
    }
    pq_txn_commit(aTHX_ self);
    return took > 0 ? 1 : 0;
}

static SV *pq_cron_info(pTHX_ SV *self, SV *name) {
    AV *b = pq_binds(aTHX), *row;
    HV *h;
    pq_bind_sv(aTHX_ b, name);
    row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
        "SELECT " PQ_CRON_COLS " FROM pq_crons WHERE name = ?")), b);
    if (!row) return NULL;
    h = pq_cron_row_hv(aTHX_ row);
    SvREFCNT_dec((SV *)row);
    return newRV_noinc((SV *)h);
}

static SV *pq_list_crons(pTHX_ SV *self, IV offset, IV limit) {
    HV *out = newHV();
    AV *crons = newAV();
    {
        AV *row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT count(*) FROM pq_crons")), NULL);
        (void)hv_stores(out, "total",
                        newSViv(row ? pq_col_iv(aTHX_ row, 0) : 0));
        if (row) SvREFCNT_dec((SV *)row);
    }
    {
        SV *sth;
        AV *bind = pq_binds(aTHX), *row;
        pq_bind_iv(aTHX_ bind, limit  > 0 ? limit  : 50);
        pq_bind_iv(aTHX_ bind, offset > 0 ? offset : 0);
        sth = pq_sth(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT " PQ_CRON_COLS " FROM pq_crons ORDER BY name"
            " LIMIT ? OFFSET ?")));
        (void)pq_execute(aTHX_ sth, bind);
        while ((row = pq_fetchrow(aTHX_ sth))) {
            av_push(crons, newRV_noinc((SV *)pq_cron_row_hv(aTHX_ row)));
            SvREFCNT_dec((SV *)row);
        }
        { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
          if (r) SvREFCNT_dec(r); }
    }
    (void)hv_stores(out, "crons", newRV_noinc((SV *)crons));
    return newRV_noinc((SV *)out);
}

/* ---- the tick --------------------------------------------------------------
 *
 * Leader-only; the caller holds the lease. Per due cron:
 *
 *   advance next_run under the optimistic `WHERE next_run = ?` guard -
 *   a second leader loses cleanly - THEN enqueue the occurrence with the
 *   dedupe key cron:<name-hash>:<occurrence>, which makes even a race
 *   that beats the guard at-most-once per occurrence.
 *
 * An occurrence is "missed" when it is more than a minute stale (one
 * minute is cron's own resolution). `once` fires the oldest missed
 * occurrence then jumps to the future; `all` fires each missed one up
 * to catchup_max then jumps; `skip` fires only fresh occurrences.
 * Returns the number of jobs enqueued. */

static IV pq_cron_tick(pTHX_ SV *self, IV limit) {
    double now = pq_now(aTHX_ self);
    IV catchup_max = (IV)pq_opt_num(aTHX_ self, "catchup_max", 10.0);
    IV fired_total = 0;
    SV *sth;
    AV *bind = pq_binds(aTHX), *row;
    AV *due = (AV *)sv_2mortal((SV *)newAV());
    SSize_t i, ndue;

    pq_bind_nv(aTHX_ bind, now);
    pq_bind_iv(aTHX_ bind, limit > 0 ? limit : 100);
    sth = pq_sth(aTHX_ self, sv_2mortal(newSVpvs(
        "SELECT " PQ_CRON_COLS " FROM pq_crons"
        " WHERE enabled = 1 AND next_run <= ?"
        " ORDER BY next_run LIMIT ?")));
    (void)pq_execute(aTHX_ sth, bind);
    while ((row = pq_fetchrow(aTHX_ sth)))
        av_push(due, newRV_noinc((SV *)row));
    { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
      if (r) SvREFCNT_dec(r); }

    ndue = av_len(due) + 1;
    for (i = 0; i < ndue; i++) {
        AV *r2 = (AV *)SvRV(*av_fetch(due, i, 0));
        IV  id      = pq_col_iv(aTHX_ r2, PQ_CR_ID);
        SV *name    = pq_col(aTHX_ r2, PQ_CR_NAME);
        SV *expr    = pq_col(aTHX_ r2, PQ_CR_EXPR);
        SV *task    = pq_col(aTHX_ r2, PQ_CR_TASK);
        SV *tz      = pq_col(aTHX_ r2, PQ_CR_TZ);
        const char *policy = SvOK(pq_col(aTHX_ r2, PQ_CR_CATCHUP))
                           ? SvPV_nolen(pq_col(aTHX_ r2, PQ_CR_CATCHUP))
                           : "once";
        SV *occ_sv = pq_col(aTHX_ r2, PQ_CR_NEXT_RUN);
        double occ = SvOK(occ_sv) ? SvNV(occ_sv) : 0.0;
        IV count = 0;
        int died = 0;

        for (;;) {
            double nx;
            int missed = (now - occ) > 60.0;
            int fire = !(strEQ(policy, "skip") && missed);
            IV took;
            nx = -1;
            {
                SV *r3 = NULL;
                int d2 = 0;
                SV *argv[3];
                argv[0] = expr;
                argv[1] = sv_2mortal(newSVnv(occ));
                argv[2] = tz;
                r3 = pq_call_meth_ev(aTHX_
                        sv_2mortal(newSVpvs("Punk::Queue::Cron")),
                        "next_after", argv, 3, 1, &d2);
                if (!d2 && r3 && SvOK(r3)) nx = SvNV(r3);
                if (r3) SvREFCNT_dec(r3);
                if (d2 || nx < 0) {
                    warn("Punk::Queue: cron '%s' failed to compute its "
                         "next occurrence - disabling it",
                         SvOK(name) ? SvPV_nolen(name) : "?");
                    (void)pq_enable_cron(aTHX_ self, name, 0);
                    break;
                }
            }

            /* a stale occurrence under `skip` never fires - jump straight
             * to the future instead of walking the gap a minute at a
             * time. last_run stays put: nothing ran. */
            if (missed && !fire) {
                double jump = nx > now ? nx
                            : pq_sched_next(aTHX_ expr, tz, now);
                AV *b = pq_binds(aTHX);
                pq_bind_nv(aTHX_ b, jump);
                pq_bind_nv(aTHX_ b, now);
                pq_bind_iv(aTHX_ b, id);
                pq_bind_nv(aTHX_ b, occ);
                (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                    "UPDATE pq_crons SET next_run = ?, updated = ?"
                    " WHERE id = ? AND next_run = ?")), b);
                break;
            }

            /* advance FIRST (the optimistic guard) ... */
            {
                AV *b = pq_binds(aTHX);
                pq_bind_nv(aTHX_ b, occ);
                pq_bind_nv(aTHX_ b, nx);
                pq_bind_nv(aTHX_ b, now);
                pq_bind_iv(aTHX_ b, id);
                pq_bind_nv(aTHX_ b, occ);
                took = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                    "UPDATE pq_crons SET last_run = ?, next_run = ?,"
                    " updated = ? WHERE id = ? AND next_run = ?")), b);
            }
            if (took <= 0) break;      /* another leader owns this cron */

            /* ... THEN enqueue, deduped per occurrence */
            if (fire) {
                HV *opts = (HV *)sv_2mortal((SV *)newHV());
                SV *ukey = sv_2mortal(Perl_newSVpvf(aTHX_
                    "cron:%lx:%ld",
                    (unsigned long)pq_lock_hash(
                        SvOK(name) ? SvPV_nolen(name) : "?",
                        SvOK(name) ? SvCUR(name) : 1),
                    (long)occ));
                SV *jid;
                (void)hv_stores(opts, "queue",
                                newSVsv(pq_col(aTHX_ r2, PQ_CR_QUEUE)));
                (void)hv_stores(opts, "priority",
                    newSViv(pq_col_iv(aTHX_ r2, PQ_CR_PRIORITY)));
                (void)hv_stores(opts, "attempts",
                    newSViv(pq_col_iv(aTHX_ r2, PQ_CR_ATTEMPTS)));
                (void)hv_stores(opts, "unique", newSVsv(ukey));

                {
                    SV *argv[4];
                    argv[0] = task;
                    argv[1] = pq_col(aTHX_ r2, PQ_CR_ARGS);
                    /* args column is JSON text; decode for enqueue */
                    argv[1] = sv_2mortal(pq_json_decode(aTHX_ argv[1]));
                    argv[2] = sv_2mortal(newRV_inc((SV *)opts));
                    jid = pq_call_meth_ev(aTHX_ self, "enqueue",
                                          argv, 3, 1, &died);
                }
                if (!died && jid && SvOK(jid)) {
                    AV *b = pq_binds(aTHX);
                    pq_bind_sv(aTHX_ b, jid);
                    pq_bind_iv(aTHX_ b, id);
                    (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                        "UPDATE pq_crons SET last_job = ? WHERE id = ?")),
                        b);
                    fired_total++;
                    count++;
                }
                if (jid) SvREFCNT_dec(jid);
            }

            occ = nx;
            if (occ > now) break;

            /* still behind: policy decides how far the catch-up goes */
            if (strEQ(policy, "once") && count >= 1) {
                double jump = pq_sched_next(aTHX_ expr, tz, now);
                AV *b = pq_binds(aTHX);
                pq_bind_nv(aTHX_ b, jump);
                pq_bind_iv(aTHX_ b, id);
                pq_bind_nv(aTHX_ b, occ);
                (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                    "UPDATE pq_crons SET next_run = ? WHERE id = ?"
                    " AND next_run = ?")), b);
                break;
            }
            if (strEQ(policy, "all") && count >= catchup_max) {
                double jump = pq_sched_next(aTHX_ expr, tz, now);
                AV *b = pq_binds(aTHX);
                pq_bind_nv(aTHX_ b, jump);
                pq_bind_iv(aTHX_ b, id);
                pq_bind_nv(aTHX_ b, occ);
                (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                    "UPDATE pq_crons SET next_run = ? WHERE id = ?"
                    " AND next_run = ?")), b);
                break;
            }
        }
    }
    return fired_total;
}

#endif /* PQ_SCHED_H */
