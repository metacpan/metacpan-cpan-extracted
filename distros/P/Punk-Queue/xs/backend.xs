MODULE = Punk::Queue        PACKAGE = Punk::Queue::Backend

# The shared backend surface. Both shipped backends inherit these; the
# per-driver divergences live in xs/backend_sqlite.xs (and, from phase 2,
# xs/backend_pg.xs).
#
# A hand-written backend is not required to inherit from this class - the
# contract is the method list, not the parentage. What it gets by
# inheriting is every method here for free.

SV *
dbh(self)
    SV *self
    CODE:
        RETVAL = newSVsv(pq_dbh(aTHX_ self));
    OUTPUT:
        RETVAL

IV
migrate(self, to = 0)
    SV *self
    IV to
    CODE:
        RETVAL = pq_migrate(aTHX_ self, to);
    OUTPUT:
        RETVAL

IV
schema_version(self)
    SV *self
    CODE:
        RETVAL = pq_schema_version(aTHX_ self);
    OUTPUT:
        RETVAL

# The latest schema version this build knows how to apply, as opposed to
# the one the database is at. `punk-queue migrate --check` (phase 3) is the
# difference between the two.
IV
latest_version(self)
    SV *self
    CODE:
        RETVAL = pq_migration_count(aTHX_ self);
    OUTPUT:
        RETVAL

# now(), in the database's frame of reference: this host's clock plus the
# delta probed at connect. Every timestamp the dist binds comes from here.
NV
now(self)
    SV *self
    CODE:
        RETVAL = pq_now(aTHX_ self);
    OUTPUT:
        RETVAL

NV
clock_delta(self)
    SV *self
    PREINIT:
        SV *d;
    CODE:
        (void)pq_dbh(aTHX_ self);
        d = pq_get(aTHX_ pq_hv(aTHX_ self, "Punk::Queue::Backend"),
                   PQ_DELTA_KEY);
        RETVAL = d ? SvNV(d) : 0.0;
    OUTPUT:
        RETVAL

IV
has_returning(self)
    SV *self
    CODE:
        RETVAL = pq_has_returning(aTHX_ self);
    OUTPUT:
        RETVAL

IV
enqueue(self, task, args = NULL, opts = NULL)
    SV *self
    SV *task
    SV *args
    SV *opts
    PREINIT:
        HV *o = NULL;
    CODE:
        if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
            o = (HV *)SvRV(opts);
        RETVAL = pq_enqueue(aTHX_ self, task, args, o);
    OUTPUT:
        RETVAL

SV *
job_info(self, id)
    SV *self
    IV id
    PREINIT:
        SV *info;
    CODE:
        info = pq_job_info(aTHX_ self, id);
        if (!info) XSRETURN_UNDEF;
        RETVAL = info;
    OUTPUT:
        RETVAL

IV
finish_job(self, id, retries, result = NULL)
    SV *self
    IV id
    IV retries
    SV *result
    CODE:
        RETVAL = pq_finish_job(aTHX_ self, id, retries, result);
    OUTPUT:
        RETVAL

IV
fail_job(self, id, retries, err = NULL)
    SV *self
    IV id
    IV retries
    SV *err
    CODE:
        RETVAL = pq_fail_job(aTHX_ self, id, retries, err);
    OUTPUT:
        RETVAL

IV
retry_job(self, id, retries, opts = NULL)
    SV *self
    IV id
    IV retries
    SV *opts
    PREINIT:
        HV *o = NULL;
    CODE:
        if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
            o = (HV *)SvRV(opts);
        RETVAL = pq_retry_job(aTHX_ self, id, retries, o);
    OUTPUT:
        RETVAL

IV
remove_job(self, id)
    SV *self
    IV id
    CODE:
        RETVAL = pq_remove_job(aTHX_ self, id);
    OUTPUT:
        RETVAL

IV
register_worker(self, id = 0, opts = NULL)
    SV *self
    IV id
    SV *opts
    PREINIT:
        HV *o = NULL;
    CODE:
        if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
            o = (HV *)SvRV(opts);
        RETVAL = pq_register_worker(aTHX_ self, id, o);
    OUTPUT:
        RETVAL

IV
unregister_worker(self, id)
    SV *self
    IV id
    CODE:
        RETVAL = pq_unregister_worker(aTHX_ self, id);
    OUTPUT:
        RETVAL

IV
worker_heartbeat(self, id, status = NULL)
    SV *self
    IV id
    SV *status
    CODE:
        RETVAL = pq_worker_heartbeat(aTHX_ self, id, status);
    OUTPUT:
        RETVAL

SV *
list_jobs(self, offset = 0, limit = 0, filter = NULL, sort_col = NULL, sort_dir = NULL)
    SV *self
    IV offset
    IV limit
    SV *filter
    SV *sort_col
    SV *sort_dir
    PREINIT:
        HV *f = NULL;
    CODE:
        if (filter && SvROK(filter) && SvTYPE(SvRV(filter)) == SVt_PVHV)
            f = (HV *)SvRV(filter);
        RETVAL = pq_list_jobs(aTHX_ self, offset, limit, f, sort_col, sort_dir);
    OUTPUT:
        RETVAL

SV *
list_workers(self, offset = 0, limit = 0, filter = NULL)
    SV *self
    IV offset
    IV limit
    SV *filter
    PREINIT:
        HV *f = NULL;
    CODE:
        if (filter && SvROK(filter) && SvTYPE(SvRV(filter)) == SVt_PVHV)
            f = (HV *)SvRV(filter);
        RETVAL = pq_list_workers(aTHX_ self, offset, limit, f);
    OUTPUT:
        RETVAL

SV *
stats(self)
    SV *self
    CODE:
        RETVAL = pq_stats(aTHX_ self);
    OUTPUT:
        RETVAL

# Merge into a job's notes; a key whose value is undef is deleted. Works
# in any state - progress notes on an active job are the whole point.
IV
note(self, id, merge)
    SV *self
    IV id
    SV *merge
    PREINIT:
        HV *m = NULL;
    CODE:
        if (merge && SvROK(merge) && SvTYPE(SvRV(merge)) == SVt_PVHV)
            m = (HV *)SvRV(merge);
        if (!m)
            croak("Punk::Queue: note needs a hash reference to merge");
        RETVAL = pq_note(aTHX_ self, id, m);
    OUTPUT:
        RETVAL

# Append one log line to a job. Always writes - the `logging` option
# gates only the automatic lifecycle rows.

IV
log_job(self, id, message, level = NULL)
    SV *self
    IV id
    SV *message
    SV *level
    CODE:
        pq_log_add(aTHX_ self, id, level && SvOK(level)
                                    ? SvPV_nolen(level) : NULL, message);
        RETVAL = 1;
    OUTPUT:
        RETVAL

# The whole log for one job, oldest first:
# [ { created, level, message }, ... ]

SV *
job_log(self, id)
    SV *self
    IV id
    CODE:
        RETVAL = newRV_noinc((SV *)pq_job_log_rows(aTHX_ self, id));
    OUTPUT:
        RETVAL

void
reset(self)
    SV *self
    CODE:
        pq_reset(aTHX_ self);

# ---- locks ------------------------------------------------------------------

IV
lock(self, name, duration, opts = NULL)
    SV *self
    SV *name
    NV duration
    SV *opts
    PREINIT:
        HV *o = NULL;
        SV *v;
        IV limit = 1, owner = 0;
    CODE:
        if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
            o = (HV *)SvRV(opts);
        if (o && (v = pq_get(aTHX_ o, "limit")) && SvOK(v)) limit = SvIV(v);
        if (o && (v = pq_get(aTHX_ o, "owner")) && SvOK(v)) owner = SvIV(v);
        RETVAL = pq_lock(aTHX_ self, name, duration, limit, owner);
    OUTPUT:
        RETVAL

IV
renew_lock(self, name, owner, duration)
    SV *self
    SV *name
    IV owner
    NV duration
    CODE:
        RETVAL = pq_renew_lock(aTHX_ self, name, owner, duration);
    OUTPUT:
        RETVAL

IV
unlock(self, name, owner = NULL)
    SV *self
    SV *name
    SV *owner
    CODE:
        RETVAL = pq_unlock(aTHX_ self, name,
                           (owner && SvOK(owner)) ? SvIV(owner) : 0,
                           (owner && SvOK(owner)) ? 1 : 0);
    OUTPUT:
        RETVAL

SV *
list_locks(self, offset = 0, limit = 0, filter = NULL)
    SV *self
    IV offset
    IV limit
    SV *filter
    PREINIT:
        HV *f = NULL;
    CODE:
        if (filter && SvROK(filter) && SvTYPE(SvRV(filter)) == SVt_PVHV)
            f = (HV *)SvRV(filter);
        RETVAL = pq_list_locks(aTHX_ self, offset, limit, f);
    OUTPUT:
        RETVAL

# ---- broadcast / receive ----------------------------------------------------

IV
broadcast(self, cmd, args = NULL, ids = NULL)
    SV *self
    SV *cmd
    SV *args
    SV *ids
    PREINIT:
        AV *a = NULL, *w = NULL;
    CODE:
        if (args && SvROK(args) && SvTYPE(SvRV(args)) == SVt_PVAV)
            a = (AV *)SvRV(args);
        if (ids && SvROK(ids) && SvTYPE(SvRV(ids)) == SVt_PVAV)
            w = (AV *)SvRV(ids);
        RETVAL = pq_broadcast(aTHX_ self, cmd, a, w);
    OUTPUT:
        RETVAL

SV *
receive(self, worker_id)
    SV *self
    IV worker_id
    CODE:
        RETVAL = pq_receive(aTHX_ self, worker_id);
    OUTPUT:
        RETVAL

# ---- repair and history -----------------------------------------------------

SV *
repair(self, opts = NULL)
    SV *self
    SV *opts
    PREINIT:
        HV *o = NULL;
        SV *v;
        int deep = 0;
    CODE:
        if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
            o = (HV *)SvRV(opts);
        if (o && (v = pq_get(aTHX_ o, "deep")) && SvTRUE(v)) deep = 1;
        RETVAL = pq_repair(aTHX_ self, deep);
    OUTPUT:
        RETVAL

SV *
history(self)
    SV *self
    CODE:
        RETVAL = pq_history(aTHX_ self);
    OUTPUT:
        RETVAL

# Seconds until the next delayed job in these queues becomes claimable,
# or undef when none is waiting. The worker's sleep clamp; called with
# G_EVAL from C, hence a method.
SV *
_ready_horizon(self, queues)
    SV *self
    SV *queues
    PREINIT:
        AV *q;
        double h;
    CODE:
        q = pq_sql_list(aTHX_ queues);
        if (av_len(q) < 0) av_push(q, newSVpvs("default"));
        h = pq_ready_horizon(aTHX_ self, q);
        if (h < 0) XSRETURN_UNDEF;
        RETVAL = newSVnv(h);
    OUTPUT:
        RETVAL

# ---- cron storage -----------------------------------------------------------

IV
upsert_cron(self, def)
    SV *self
    SV *def
    PREINIT:
        HV *d = NULL;
    CODE:
        if (def && SvROK(def) && SvTYPE(SvRV(def)) == SVt_PVHV)
            d = (HV *)SvRV(def);
        if (!d) croak("Punk::Queue: upsert_cron needs a hash reference");
        RETVAL = pq_upsert_cron(aTHX_ self, d);
    OUTPUT:
        RETVAL

IV
disable_missing_crons(self, names = NULL)
    SV *self
    SV *names
    PREINIT:
        AV *n = NULL;
    CODE:
        if (names && SvROK(names) && SvTYPE(SvRV(names)) == SVt_PVAV)
            n = (AV *)SvRV(names);
        RETVAL = pq_disable_missing_crons(aTHX_ self, n);
    OUTPUT:
        RETVAL

IV
enable_cron(self, name, on = 1)
    SV *self
    SV *name
    IV on
    CODE:
        RETVAL = pq_enable_cron(aTHX_ self, name, on ? 1 : 0);
    OUTPUT:
        RETVAL

SV *
cron_info(self, name)
    SV *self
    SV *name
    PREINIT:
        SV *info;
    CODE:
        info = pq_cron_info(aTHX_ self, name);
        if (!info) XSRETURN_UNDEF;
        RETVAL = info;
    OUTPUT:
        RETVAL

SV *
list_crons(self, offset = 0, limit = 0)
    SV *self
    IV offset
    IV limit
    CODE:
        RETVAL = pq_list_crons(aTHX_ self, offset, limit);
    OUTPUT:
        RETVAL

# One leader tick: fire every due cron per its catch-up policy. The
# caller holds the pq.cron.leader lease; the optimistic guard and the
# occurrence dedupe make a stale caller harmless anyway.
IV
_cron_tick(self, limit = 100)
    SV *self
    IV limit
    CODE:
        RETVAL = pq_cron_tick(aTHX_ self, limit);
    OUTPUT:
        RETVAL
