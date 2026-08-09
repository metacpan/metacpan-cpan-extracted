MODULE = Punk::Queue        PACKAGE = Punk::Queue

# The front object. Every method here resolves the backend and delegates;
# nothing about a particular database appears in this file.

SV *
new(class, ...)
    SV *class
    PREINIT:
        HV *opts, *self;
        SV *bclass, *backend, *rv;
        int i;
    CODE:
    {
        if ((items - 1) % 2)
            croak("Punk::Queue->new: odd number of options");

        opts = newHV();
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);

        /* An externally supplied handle is a legitimate way in - a test
         * fixture, or an app that already manages its own connection. It
         * still needs a backend class, so infer one from the driver. */
        if (!pq_get(aTHX_ opts, "dsn") && !pq_get(aTHX_ opts, "backend")) {
            SV *dbh = pq_get(aTHX_ opts, "dbh");
            if (dbh && SvROK(dbh)) {
                if (pq_driver_is(aTHX_ dbh, "SQLite"))
                    (void)hv_stores(opts, "backend", newSVpvs("SQLite"));
                else if (pq_driver_is(aTHX_ dbh, "Pg"))
                    (void)hv_stores(opts, "backend", newSVpvs("Pg"));
            }
        }

        bclass  = pq_backend_class(aTHX_ opts);
        backend = pq_backend_construct(aTHX_ bclass, opts);

        self = newHV();
        (void)hv_stores(self, "backend", backend);
        (void)hv_stores(self, "tasks",   newRV_noinc((SV *)newHV()));
        (void)hv_stores(self, "opts",    newRV_noinc((SV *)opts));

        rv = newRV_noinc((SV *)self);
        sv_bless(rv, gv_stashsv(SvROK(class) ? SvRV(class) : class, GV_ADD));
        RETVAL = rv;
    }
    OUTPUT:
        RETVAL

SV *
backend(self)
    SV *self
    CODE:
        RETVAL = newSVsv(pq_backend_of(aTHX_ self));
    OUTPUT:
        RETVAL

SV *
dbh(self)
    SV *self
    CODE:
        RETVAL = newSVsv(pq_dbh(aTHX_ pq_backend_of(aTHX_ self)));
    OUTPUT:
        RETVAL

IV
migrate(self, to = 0)
    SV *self
    IV to
    CODE:
        RETVAL = pq_migrate(aTHX_ pq_backend_of(aTHX_ self), to);
    OUTPUT:
        RETVAL

IV
schema_version(self)
    SV *self
    CODE:
        RETVAL = pq_schema_version(aTHX_ pq_backend_of(aTHX_ self));
    OUTPUT:
        RETVAL

# task NAME => sub {...}  - register a body. With one argument, look one up.
SV *
task(self, name, body = NULL)
    SV *self
    SV *name
    SV *body
    PREINIT:
        HV *tasks;
    CODE:
    {
        pq_name_check(aTHX_ name, "task");
        tasks = pq_tasks(aTHX_ self);
        if (body) {
            if (!(SvROK(body) && SvTYPE(SvRV(body)) == SVt_PVCV))
                croak("Punk::Queue: task '%s' needs a code reference",
                      SvPV_nolen(name));
            (void)hv_store_ent(tasks, name, newSVsv(body), 0);
            RETVAL = newSVsv(self);            /* chainable */
        }
        else {
            SV *found = pq_task_body(aTHX_ self, name);
            RETVAL = found ? newSVsv(found) : &PL_sv_undef;
            if (!found) XSRETURN_UNDEF;
        }
    }
    OUTPUT:
        RETVAL

void
tasks(self)
    SV *self
    PPCODE:
    {
        HV *t = pq_tasks(aTHX_ self);
        HE *he;
        hv_iterinit(t);
        while ((he = hv_iternext(t)))
            XPUSHs(sv_2mortal(newSVsv(HeSVKEY_force(he))));
    }

# Per-queue and per-task defaults, merged into enqueue options at a fixed
# precedence: explicit, task, queue, built-in. Set with a hashref, read
# without one. Application configuration - lives on this object, not in
# the database.
SV *
queue_defaults(self, name, defaults = NULL)
    SV *self
    SV *name
    SV *defaults
    ALIAS:
        task_defaults = 1
    PREINIT:
        HV *slot;
        HE *he;
    CODE:
    {
        pq_name_check(aTHX_ name, ix == 1 ? "task" : "queue");
        slot = pq_defaults_slot(aTHX_ self,
                                ix == 1 ? "task_defaults" : "queue_defaults");
        if (defaults) {
            if (!(SvROK(defaults) && SvTYPE(SvRV(defaults)) == SVt_PVHV))
                croak("Punk::Queue: defaults must be a hash reference");
            (void)hv_store_ent(slot, name, newSVsv(defaults), 0);
            RETVAL = newSVsv(self);          /* chainable */
        }
        else {
            he = hv_fetch_ent(slot, name, 0, 0);
            if (!he) XSRETURN_UNDEF;
            RETVAL = newSVsv(HeVAL(he));
        }
    }
    OUTPUT:
        RETVAL

IV
enqueue(self, task, args = NULL, ...)
    SV *self
    SV *task
    SV *args
    PREINIT:
        HV *opts;
        int i;
    CODE:
    {
        /* items is 2 when args was defaulted away, so guard the subtraction
         * before taking the modulus - C's % keeps the sign of a negative
         * left operand, and (2 - 3) % 2 is -1, not 1. */
        if (items > 3 && (items - 3) % 2)
            croak("Punk::Queue->enqueue: odd number of options");
        if (args && SvOK(args)
            && !(SvROK(args) && SvTYPE(SvRV(args)) == SVt_PVAV))
            croak("Punk::Queue->enqueue: args must be an array reference");

        opts = (HV *)sv_2mortal((SV *)newHV());
        for (i = 3; i < items; i += 2)
            (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);

        pq_merge_defaults(aTHX_ self, task, opts);
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_enqueue(aTHX_ pq_backend_of(aTHX_ self), task, args, opts);
    }
    OUTPUT:
        RETVAL

# Claim one job. Returns a Punk::Queue::Job, or undef when nothing is ready.
SV *
dequeue(self, ...)
    SV *self
    PREINIT:
        HV *opts;
        SV *backend, *row;
        AV *queues, *tasks;
        IV worker_id = 0;
        int i;
    CODE:
    {
        if ((items - 1) % 2)
            croak("Punk::Queue->dequeue: odd number of options");
        opts = (HV *)sv_2mortal((SV *)newHV());
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);

        {
            SV *w = pq_get(aTHX_ opts, "worker");
            if (w && SvOK(w)) worker_id = SvIV(w);
        }

        queues = pq_sql_list(aTHX_ pq_get(aTHX_ opts, "queues"));
        if (av_len(queues) < 0) av_push(queues, newSVpvs("default"));
        tasks  = pq_sql_list(aTHX_ pq_get(aTHX_ opts, "tasks"));

        pq_ensure_migrated(aTHX_ self);
        backend = pq_backend_of(aTHX_ self);
        row = pq_dequeue(aTHX_ backend, worker_id, queues, tasks);
        if (!row) XSRETURN_UNDEF;

        RETVAL = pq_job_new(aTHX_ self, (HV *)SvRV(row));
        SvREFCNT_dec(row);
    }
    OUTPUT:
        RETVAL

SV *
job_info(self, id)
    SV *self
    IV id
    PREINIT:
        SV *info;
    CODE:
        pq_ensure_migrated(aTHX_ self);
        info = pq_job_info(aTHX_ pq_backend_of(aTHX_ self), id);
        if (!info) XSRETURN_UNDEF;
        RETVAL = info;
    OUTPUT:
        RETVAL

SV *
job_log(self, id)
    SV *self
    IV id
    CODE:
        pq_ensure_migrated(aTHX_ self);
        RETVAL = newRV_noinc((SV *)pq_job_log_rows(aTHX_
                     pq_backend_of(aTHX_ self), id));
    OUTPUT:
        RETVAL

IV
finish_job(self, id, retries, result = NULL)
    SV *self
    IV id
    IV retries
    SV *result
    CODE:
        RETVAL = pq_finish_job(aTHX_ pq_backend_of(aTHX_ self), id, retries,
                               result);
    OUTPUT:
        RETVAL

IV
fail_job(self, id, retries, err = NULL)
    SV *self
    IV id
    IV retries
    SV *err
    CODE:
        RETVAL = pq_fail_job(aTHX_ pq_backend_of(aTHX_ self), id, retries, err);
    OUTPUT:
        RETVAL

# Run one claimed job to completion: look up the body, call it, settle the
# row. Returns true when the job finished, false when it failed.
IV
perform(self, job)
    SV *self
    SV *job
    CODE:
        RETVAL = pq_perform(aTHX_ self, job);
    OUTPUT:
        RETVAL

# The worker's claim entry: positional, no option parsing, G_EVAL-called
# from C so a raised claim never unwinds the loop. Takes what the worker
# already holds (id, queues arrayref, tasks arrayref) and returns a Job,
# or nothing. Not documented API; the keyword form above is.
SV *
dequeue_ref(self, worker_id, queues, tasks)
    SV *self
    IV worker_id
    SV *queues
    SV *tasks
    PREINIT:
        AV *q, *t;
        SV *row;
    CODE:
    {
        q = pq_sql_list(aTHX_ queues);
        if (av_len(q) < 0) av_push(q, newSVpvs("default"));
        t = pq_sql_list(aTHX_ tasks);
        pq_ensure_migrated(aTHX_ self);
        row = pq_dequeue(aTHX_ pq_backend_of(aTHX_ self), worker_id, q, t);
        if (!row) XSRETURN_UNDEF;
        RETVAL = pq_job_new(aTHX_ self, (HV *)SvRV(row));
        SvREFCNT_dec(row);
    }
    OUTPUT:
        RETVAL

# Front delegators for the management surface, so the CLI and the phase-8
# plugin never reach around the queue object to its backend.

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
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_retry_job(aTHX_ pq_backend_of(aTHX_ self), id, retries, o);
    OUTPUT:
        RETVAL

IV
remove_job(self, id)
    SV *self
    IV id
    CODE:
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_remove_job(aTHX_ pq_backend_of(aTHX_ self), id);
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
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_list_jobs(aTHX_ pq_backend_of(aTHX_ self), offset, limit, f, sort_col, sort_dir);
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
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_list_workers(aTHX_ pq_backend_of(aTHX_ self), offset,
                                 limit, f);
    OUTPUT:
        RETVAL

SV *
stats(self)
    SV *self
    CODE:
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_stats(aTHX_ pq_backend_of(aTHX_ self));
    OUTPUT:
        RETVAL

void
reset(self)
    SV *self
    CODE:
        pq_ensure_migrated(aTHX_ self);
        pq_reset(aTHX_ pq_backend_of(aTHX_ self));

SV *
repair(self, ...)
    SV *self
    PREINIT:
        HV *opts;
        SV *v;
        int i, deep = 0;
    CODE:
    {
        if ((items - 1) % 2)
            croak("Punk::Queue->repair: odd number of options");
        opts = (HV *)sv_2mortal((SV *)newHV());
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);
        if ((v = pq_get(aTHX_ opts, "deep")) && SvTRUE(v)) deep = 1;
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_repair(aTHX_ pq_backend_of(aTHX_ self), deep);
    }
    OUTPUT:
        RETVAL

SV *
history(self)
    SV *self
    CODE:
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_history(aTHX_ pq_backend_of(aTHX_ self));
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
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_list_locks(aTHX_ pq_backend_of(aTHX_ self), offset,
                               limit, f);
    OUTPUT:
        RETVAL

IV
lock(self, name, duration, ...)
    SV *self
    SV *name
    NV duration
    PREINIT:
        HV *opts;
        SV *v;
        int i;
        IV limit = 1, owner = 0;
    CODE:
    {
        if ((items - 3) % 2 && items > 3)
            croak("Punk::Queue->lock: odd number of options");
        opts = (HV *)sv_2mortal((SV *)newHV());
        for (i = 3; i < items; i += 2)
            (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);
        if ((v = pq_get(aTHX_ opts, "limit")) && SvOK(v)) limit = SvIV(v);
        if ((v = pq_get(aTHX_ opts, "owner")) && SvOK(v)) owner = SvIV(v);
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_lock(aTHX_ pq_backend_of(aTHX_ self), name, duration,
                         limit, owner);
    }
    OUTPUT:
        RETVAL

IV
unlock(self, name, owner = NULL)
    SV *self
    SV *name
    SV *owner
    CODE:
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_unlock(aTHX_ pq_backend_of(aTHX_ self), name,
                           (owner && SvOK(owner)) ? SvIV(owner) : 0,
                           (owner && SvOK(owner)) ? 1 : 0);
    OUTPUT:
        RETVAL

IV
renew_lock(self, name, owner, duration)
    SV *self
    SV *name
    IV owner
    NV duration
    CODE:
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_renew_lock(aTHX_ pq_backend_of(aTHX_ self), name,
                               owner, duration);
    OUTPUT:
        RETVAL

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
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_broadcast(aTHX_ pq_backend_of(aTHX_ self), cmd, a, w);
    OUTPUT:
        RETVAL

# A worker bound to this queue: $q->worker(%opts)->run. Options are the
# worker's (queues, tasks, interval, heartbeat_interval, max_jobs).
SV *
worker(self, ...)
    SV *self
    PREINIT:
        HV *opts, *w;
        SV *rv;
        int i;
    CODE:
    {
        if ((items - 1) % 2)
            croak("Punk::Queue->worker: odd number of options");
        opts = newHV();
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);

        w = newHV();
        (void)hv_stores(w, "queue", newSVsv(self));
        (void)hv_stores(w, "opts",  newRV_noinc((SV *)opts));
        rv = newRV_noinc((SV *)w);
        sv_bless(rv, gv_stashpvs("Punk::Queue::Worker", GV_ADD));
        RETVAL = rv;
    }
    OUTPUT:
        RETVAL

# The in-server attach seam: called once per web-worker process from the
# plugin's lazy before_dispatch hook. Returns true when armed, false when
# there is no live Hyperman loop - in-server is an enhancement, never a
# requirement. (This internal XSUB is what replaced the deferred ABI's
# worker_new for the same-dist consumer.)
IV
_inserver_attach(queue, opts = NULL)
    SV *queue
    SV *opts
    PREINIT:
        HV *o = NULL;
    CODE:
        if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
            o = (HV *)SvRV(opts);
        RETVAL = pq_inserver_attach(aTHX_ queue, o);
    OUTPUT:
        RETVAL

# Front delegators for the cron surface.

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
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_upsert_cron(aTHX_ pq_backend_of(aTHX_ self), d);
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
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_disable_missing_crons(aTHX_ pq_backend_of(aTHX_ self), n);
    OUTPUT:
        RETVAL

IV
enable_cron(self, name, on = 1)
    SV *self
    SV *name
    IV on
    CODE:
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_enable_cron(aTHX_ pq_backend_of(aTHX_ self), name,
                                on ? 1 : 0);
    OUTPUT:
        RETVAL

SV *
cron_info(self, name)
    SV *self
    SV *name
    PREINIT:
        SV *info;
    CODE:
        pq_ensure_migrated(aTHX_ self);
        info = pq_cron_info(aTHX_ pq_backend_of(aTHX_ self), name);
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
        pq_ensure_migrated(aTHX_ self);
        RETVAL = pq_list_crons(aTHX_ pq_backend_of(aTHX_ self), offset,
                               limit);
    OUTPUT:
        RETVAL
