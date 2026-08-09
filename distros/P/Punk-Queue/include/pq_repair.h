#ifndef PQ_REPAIR_H
#define PQ_REPAIR_H

/* pq_repair.h - broadcast/receive, and the repair passes.
 *
 * Repair's contract has two halves and the second is the harder one:
 * every corruption a crash can leave gets fixed, AND a healthy queue is
 * left completely untouched. Every pass below is predicated - there is no
 * blanket rewrite anywhere - and the battery asserts the no-op with a
 * row-by-row comparison.
 *
 * Include after pq_lock.h. */

/* ---- broadcast / receive ---------------------------------------------------
 *
 * The inbox is a JSON array of [command, @args] tuples on the worker row.
 * broadcast appends (to every worker, or a named set); receive drains
 * atomically inside a transaction - a plain read-then-clear would drop a
 * command that arrived between the two, and "the operator's stop was
 * silently lost" is a miserable bug to chase. */

static IV pq_broadcast(pTHX_ SV *self, SV *cmd, AV *args, AV *ids) {
    AV *tuple = (AV *)sv_2mortal((SV *)newAV());
    SV *tuple_rv;
    IV hit = 0;

    if (!(cmd && SvOK(cmd)))
        croak("Punk::Queue: broadcast needs a command name");
    av_push(tuple, newSVsv(cmd));
    if (args) {
        SSize_t n = av_len(args) + 1, i;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(args, i, 0);
            av_push(tuple, newSVsv((e && *e) ? *e : &PL_sv_undef));
        }
    }
    tuple_rv = sv_2mortal(newRV_inc((SV *)tuple));

    pq_txn_begin(aTHX_ self);
    {
        /* which workers */
        SV *sql = pq_sql_new(aTHX_ "SELECT id, inbox FROM pq_workers");
        AV *bind = pq_binds(aTHX), *row;
        SV *sth;
        SSize_t nids = ids ? av_len(ids) + 1 : 0;
        AV *rows = (AV *)sv_2mortal((SV *)newAV());
        SSize_t k, nrows;

        if (nids > 0) {
            SSize_t i;
            pq_sql_cat(aTHX_ sql, " WHERE ");
            pq_sql_in(aTHX_ sql, "id", nids);
            for (i = 0; i < nids; i++)
                pq_bind_sv(aTHX_ bind, *av_fetch(ids, i, 0));
        }
        sth = pq_sth(aTHX_ self, sql);
        (void)pq_execute(aTHX_ sth, bind);
        while ((row = pq_fetchrow(aTHX_ sth)))
            av_push(rows, newRV_noinc((SV *)row));
        { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
          if (r) SvREFCNT_dec(r); }

        nrows = av_len(rows) + 1;
        for (k = 0; k < nrows; k++) {
            AV *r2 = (AV *)SvRV(*av_fetch(rows, k, 0));
            IV wid = pq_col_iv(aTHX_ r2, 0);
            SV *decoded = sv_2mortal(pq_json_decode(aTHX_
                              pq_col(aTHX_ r2, 1)));
            AV *inbox = (SvROK(decoded)
                         && SvTYPE(SvRV(decoded)) == SVt_PVAV)
                      ? (AV *)SvRV(decoded)
                      : (AV *)sv_2mortal((SV *)newAV());
            SV *json;
            AV *ub = pq_binds(aTHX);

            av_push(inbox, newSVsv(tuple_rv));
            json = sv_2mortal(pq_json_encode(aTHX_
                       sv_2mortal(newRV_inc((SV *)inbox)), "[]"));
            pq_bind_sv(aTHX_ ub, json);
            pq_bind_iv(aTHX_ ub, wid);
            (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                "UPDATE pq_workers SET inbox = ? WHERE id = ?")), ub);
            hit++;
        }
    }
    pq_txn_commit(aTHX_ self);
    return hit;
}

/* Drain and return this worker's inbox (+1 arrayref, possibly empty). */
static SV *pq_receive(pTHX_ SV *self, IV worker_id) {
    SV *out = NULL;

    pq_txn_begin(aTHX_ self);
    {
        AV *b = pq_binds(aTHX), *row;
        pq_bind_iv(aTHX_ b, worker_id);
        row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT inbox FROM pq_workers WHERE id = ?")), b);
        if (row) {
            out = pq_json_decode(aTHX_ pq_col(aTHX_ row, 0));
            SvREFCNT_dec((SV *)row);

            b = pq_binds(aTHX);
            pq_bind_iv(aTHX_ b, worker_id);
            (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                "UPDATE pq_workers SET inbox = '[]' WHERE id = ?")), b);
        }
    }
    pq_txn_commit(aTHX_ self);

    if (!(out && SvROK(out) && SvTYPE(SvRV(out)) == SVt_PVAV)) {
        if (out) SvREFCNT_dec(out);
        out = newRV_noinc((SV *)newAV());
    }
    return out;
}

/* ---- repair ----------------------------------------------------------------
 *
 * The seven passes, in dependency order (stale workers first, because the
 * orphaned-jobs pass defines "orphaned" as "worker row gone"). Returns a
 * hashref of per-pass counts, so `punk-queue repair` can report what it
 * actually did and the battery can assert "exactly this and nothing else".
 *
 * Knobs (constructor options): missing_after (default 1800s) - a worker
 * silent this long is dead; remove_after (default 172800s) - terminal
 * jobs older than this are history, not queue. */

static SV *pq_repair(pTHX_ SV *self, int deep) {
    HV *out = newHV();
    double now = pq_now(aTHX_ self);
    double missing_after = pq_opt_num(aTHX_ self, "missing_after", 1800.0);
    double remove_after  = pq_opt_num(aTHX_ self, "remove_after", 172800.0);
    IV n;

    /* 1: workers that stopped heartbeating are unregistered. */
    {
        AV *b = pq_binds(aTHX);
        pq_bind_nv(aTHX_ b, now - missing_after);
        n = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "DELETE FROM pq_workers WHERE notified < ?")), b);
        (void)hv_stores(out, "stale_workers", newSViv(n));
    }

    /* 2: active jobs whose worker row is gone go back to inactive with
     * the retries bump - the bump is the point: it invalidates whatever
     * the vanished (or zombie) worker might still report through the
     * optimistic guard. This is the pass that picks up children killed
     * mid-job by the supervisor's hard timeout. */
    {
        AV *b = pq_binds(aTHX);
        pq_bind_nv(aTHX_ b, now);
        n = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "UPDATE pq_jobs SET state = 'inactive',"
            " retries = retries + 1, retried = ?, started = NULL,"
            " worker = NULL WHERE state = 'active' AND (worker IS NULL"
            " OR worker NOT IN (SELECT id FROM pq_workers))")), b);
        (void)hv_stores(out, "orphaned_jobs", newSViv(n));
    }

    /* 3: expired inactive jobs are deleted. The claim predicate already
     * refuses them (correctness is immediate); this keeps the table
     * small. Children adjust exactly as remove_job's inactive case. */
    {
        SV *sth;
        AV *b = pq_binds(aTHX), *row;
        AV *victims = (AV *)sv_2mortal((SV *)newAV());
        SSize_t i, nv;

        pq_bind_nv(aTHX_ b, now);
        sth = pq_sth(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT id FROM pq_jobs WHERE state = 'inactive'"
            " AND expires IS NOT NULL AND expires <= ?")));
        (void)pq_execute(aTHX_ sth, b);
        while ((row = pq_fetchrow(aTHX_ sth))) {
            av_push(victims, newSViv(pq_col_iv(aTHX_ row, 0)));
            SvREFCNT_dec((SV *)row);
        }
        { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
          if (r) SvREFCNT_dec(r); }

        nv = av_len(victims) + 1;
        for (i = 0; i < nv; i++)
            (void)pq_remove_job(aTHX_ self,
                                SvIV(*av_fetch(victims, i, 0)));
        (void)hv_stores(out, "expired_jobs", newSViv((IV)nv));
    }

    /* 4: ancient terminal jobs are history, not queue. Straight DELETE -
     * a finished parent's children got their decrements long ago, and
     * failed parents this old have failed children right next to them
     * (pass 5 already ran on them in an earlier repair). Dep rows
     * cascade. */
    {
        AV *b = pq_binds(aTHX);
        pq_bind_nv(aTHX_ b, now - remove_after);
        (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "DELETE FROM pq_job_logs WHERE job_id IN"
            " (SELECT id FROM pq_jobs"
            "   WHERE state IN ('finished', 'failed') AND finished < ?)")),
            b);
        b = pq_binds(aTHX);
        pq_bind_nv(aTHX_ b, now - remove_after);
        n = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "DELETE FROM pq_jobs"
            " WHERE state IN ('finished', 'failed') AND finished < ?")), b);
        (void)hv_stores(out, "ancient_jobs", newSViv(n));
    }

    /* 5: a non-lax child of a terminally failed parent will never run;
     * hanging silently is the one unforgivable outcome, so it fails with
     * a reason. (Terminally failed = state 'failed'; a backoff retry sits
     * in 'inactive' and does not strand anyone.) Each newly failed child
     * is itself a terminally failed parent - its lax children unblock via
     * the same pq_children_adjust every other transition uses - so the
     * pass iterates until a whole chain has settled. */
    {
        IV total = 0;
        for (;;) {
            SV *sth;
            AV *row, *victims = (AV *)sv_2mortal((SV *)newAV());
            SSize_t i, nv;

            sth = pq_sth(aTHX_ self, sv_2mortal(newSVpvs(
                "SELECT id FROM pq_jobs WHERE state = 'inactive'"
                " AND lax = 0 AND id IN (SELECT d.job_id"
                " FROM pq_job_deps d JOIN pq_jobs p ON p.id = d.parent_id"
                " WHERE p.state = 'failed')")));
            (void)pq_execute(aTHX_ sth, NULL);
            while ((row = pq_fetchrow(aTHX_ sth))) {
                av_push(victims, newSViv(pq_col_iv(aTHX_ row, 0)));
                SvREFCNT_dec((SV *)row);
            }
            { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
              if (r) SvREFCNT_dec(r); }

            nv = av_len(victims) + 1;
            if (nv == 0) break;

            for (i = 0; i < nv; i++) {
                IV cid = SvIV(*av_fetch(victims, i, 0));
                AV *b = pq_binds(aTHX);
                IV took;
                pq_txn_begin(aTHX_ self);
                pq_bind_nv(aTHX_ b, now);
                pq_bind_iv(aTHX_ b, cid);
                took = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                    "UPDATE pq_jobs SET state = 'failed', finished = ?,"
                    " result = '\"Punk::Queue: a parent this job depends"
                    " on has failed\"'"
                    " WHERE id = ? AND state = 'inactive'")), b);
                if (took > 0) {
                    pq_children_adjust(aTHX_ self, cid, -1, PQ_KIDS_LAX);
                    total++;
                }
                pq_txn_commit(aTHX_ self);
            }
        }
        (void)hv_stores(out, "stranded_children", newSViv(total));
    }

    /* 6: stale locks. Reads honour expiry everywhere already; this is
     * the table-size half. */
    {
        AV *b = pq_binds(aTHX);
        pq_bind_nv(aTHX_ b, now);
        n = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "DELETE FROM pq_locks WHERE expires <= ?")), b);
        (void)hv_stores(out, "stale_locks", newSViv(n));
    }

    /* 7: orphaned log lines. Every in-tree delete path cascades, so a
     * hit here means something ELSE deleted job rows (manual SQL, an
     * older binary) - which is exactly the drift repair exists to mop
     * up. */
    {
        n = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "DELETE FROM pq_job_logs WHERE job_id NOT IN"
            " (SELECT id FROM pq_jobs)")), NULL);
        (void)hv_stores(out, "orphaned_logs", newSViv(n));
    }

    /* 7 (--deep): recompute every parents_left from the deps table - the
     * correctness backstop for the whole counter design. Off by default
     * because it is a full scan. */
    if (deep) {
        n = pq_do_pv(aTHX_ self,
            "UPDATE pq_jobs SET parents_left ="
            " (SELECT count(*) FROM pq_job_deps d"
            "   JOIN pq_jobs p ON p.id = d.parent_id"
            "   WHERE d.job_id = pq_jobs.id AND CASE WHEN pq_jobs.lax = 1"
            "   THEN p.state NOT IN ('finished', 'failed')"
            "   ELSE p.state <> 'finished' END)"
            " WHERE state = 'inactive' AND parents_left <>"
            " (SELECT count(*) FROM pq_job_deps d"
            "   JOIN pq_jobs p ON p.id = d.parent_id"
            "   WHERE d.job_id = pq_jobs.id AND CASE WHEN pq_jobs.lax = 1"
            "   THEN p.state NOT IN ('finished', 'failed')"
            "   ELSE p.state <> 'finished' END)");
        (void)hv_stores(out, "recomputed_counters", newSViv(n));
    }

    return newRV_noinc((SV *)out);
}

#endif /* PQ_REPAIR_H */
