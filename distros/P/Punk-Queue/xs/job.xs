MODULE = Punk::Queue        PACKAGE = Punk::Queue::Job

# The handle a task body receives as its first argument. Read-only
# accessors over the claimed row, plus the two settle methods so a task can
# finish itself early or fail deliberately.

SV *
id(self)
    SV *self
    PREINIT:
        SV *v;
    CODE:
        v = pq_job_field(aTHX_ self, "id");
        RETVAL = newSViv(v ? SvIV(v) : 0);
    OUTPUT:
        RETVAL

SV *
task(self)
    SV *self
    ALIAS:
        queue = 1
        state = 2
    PREINIT:
        SV *v;
        const char *k;
    CODE:
        k = (ix == 1) ? "queue" : (ix == 2) ? "state" : "task";
        v = pq_job_field(aTHX_ self, k);
        RETVAL = newSVsv(v ? v : &PL_sv_undef);
    OUTPUT:
        RETVAL

IV
retries(self)
    SV *self
    ALIAS:
        attempts = 1
        priority = 2
    PREINIT:
        SV *v;
        const char *k;
    CODE:
        k = (ix == 1) ? "attempts" : (ix == 2) ? "priority" : "retries";
        v = pq_job_field(aTHX_ self, k);
        RETVAL = v ? SvIV(v) : 0;
    OUTPUT:
        RETVAL

SV *
args(self)
    SV *self
    ALIAS:
        notes = 1
    PREINIT:
        SV *v;
    CODE:
        v = pq_job_field(aTHX_ self, ix == 1 ? "notes" : "args");
        RETVAL = newSVsv(v ? v : &PL_sv_undef);
    OUTPUT:
        RETVAL

# The whole row as a plain hashref - what job_info would return, without
# the round trip.
SV *
info(self)
    SV *self
    PREINIT:
        HV *h, *row;
    CODE:
        h = pq_hv(aTHX_ self, "Punk::Queue::Job");
        row = pq_get_hv(aTHX_ h, "row");
        if (!row) XSRETURN_UNDEF;
        RETVAL = newRV_inc((SV *)row);
    OUTPUT:
        RETVAL

# The queue this job was claimed from.
SV *
queue_object(self)
    SV *self
    PREINIT:
        HV *h;
        SV *q;
    CODE:
        h = pq_hv(aTHX_ self, "Punk::Queue::Job");
        q = pq_get(aTHX_ h, "queue");
        if (!(q && SvROK(q))) XSRETURN_UNDEF;
        RETVAL = newSVsv(q);
    OUTPUT:
        RETVAL

# Merge into this job's notes: $job->note(pct => 50, stale_key => undef).
# The in-memory row is updated too, so $job->notes reflects the write
# without a re-read.
IV
note(self, ...)
    SV *self
    PREINIT:
        HV *h, *row, *merge, *notes;
        SV *q, *backend, *nv;
        IV id;
        int i;
    CODE:
    {
        if ((items - 1) % 2)
            croak("Punk::Queue::Job->note: odd number of key/value pairs");
        h   = pq_hv(aTHX_ self, "Punk::Queue::Job");
        row = pq_get_hv(aTHX_ h, "row");
        q   = pq_get(aTHX_ h, "queue");
        if (!(row && q && SvROK(q)))
            croak("Punk::Queue::Job: detached job object");
        backend = pq_backend_of(aTHX_ q);
        id = pq_get(aTHX_ row, "id") ? SvIV(pq_get(aTHX_ row, "id")) : 0;

        merge = (HV *)sv_2mortal((SV *)newHV());
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(merge, ST(i), newSVsv(ST(i + 1)), 0);

        RETVAL = pq_note(aTHX_ backend, id, merge);

        /* mirror the merge onto the in-memory row */
        nv = pq_get(aTHX_ row, "notes");
        notes = (nv && SvROK(nv) && SvTYPE(SvRV(nv)) == SVt_PVHV)
              ? (HV *)SvRV(nv) : NULL;
        if (RETVAL && notes) {
            HE *he;
            hv_iterinit(merge);
            while ((he = hv_iternext(merge))) {
                SV *val = HeVAL(he);
                if (val && SvOK(val))
                    (void)hv_store_ent(notes, HeSVKEY_force(he),
                                       newSVsv(val), 0);
                else
                    (void)hv_delete_ent(notes, HeSVKEY_force(he),
                                        G_DISCARD, 0);
            }
        }
    }
    OUTPUT:
        RETVAL

# Append to this job's log: $job->log('resizing image 3 of 10') or
# $job->log(warn => 'thumbnail source missing, using placeholder').
# Always writes, whatever the `logging` option says - a call the task
# author typed is not lifecycle noise.

IV
log(self, first, second = NULL)
    SV *self
    SV *first
    SV *second
    PREINIT:
        HV *h, *row;
        SV *q, *backend, *msg;
        const char *level = NULL;
        IV id;
    CODE:
    {
        h   = pq_hv(aTHX_ self, "Punk::Queue::Job");
        row = pq_get_hv(aTHX_ h, "row");
        q   = pq_get(aTHX_ h, "queue");
        if (!(row && q && SvROK(q)))
            croak("Punk::Queue::Job: detached job object");
        backend = pq_backend_of(aTHX_ q);
        id = pq_get(aTHX_ row, "id") ? SvIV(pq_get(aTHX_ row, "id")) : 0;

        if (second && SvOK(second)) {
            level = SvPV_nolen(first);
            msg   = second;
        }
        else msg = first;
        pq_log_add(aTHX_ backend, id, level, msg);
        RETVAL = 1;
    }
    OUTPUT:
        RETVAL

IV
finish(self, result = NULL)
    SV *self
    SV *result
    ALIAS:
        fail = 1
    PREINIT:
        HV *h, *row;
        SV *q, *backend;
        IV id, retries;
    CODE:
    {
        h   = pq_hv(aTHX_ self, "Punk::Queue::Job");
        row = pq_get_hv(aTHX_ h, "row");
        q   = pq_get(aTHX_ h, "queue");
        if (!(row && q && SvROK(q)))
            croak("Punk::Queue::Job: detached job object");
        backend = pq_backend_of(aTHX_ q);
        id      = pq_get(aTHX_ row, "id")      ? SvIV(pq_get(aTHX_ row, "id"))      : 0;
        retries = pq_get(aTHX_ row, "retries") ? SvIV(pq_get(aTHX_ row, "retries")) : 0;
        RETVAL = ix == 1 ? pq_fail_job(aTHX_ backend, id, retries, result)
                         : pq_finish_job(aTHX_ backend, id, retries, result);
    }
    OUTPUT:
        RETVAL
