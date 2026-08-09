MODULE = Punk::Queue        PACKAGE = Punk::Queue::Worker

# The worker child. Constructed via $q->worker(%opts); run() claims and
# performs until stopped. One job in flight at a time - the concurrency
# knob is the supervisor's -j.

IV
run(self)
    SV *self
    CODE:
        RETVAL = pqw_run(aTHX_ self);
    OUTPUT:
        RETVAL

SV *
id(self)
    SV *self
    PREINIT:
        HV *h;
        SV *v;
    CODE:
        h = pq_hv(aTHX_ self, "Punk::Queue::Worker");
        v = pq_get(aTHX_ h, "worker_id");
        if (!v) XSRETURN_UNDEF;
        RETVAL = newSVsv(v);
    OUTPUT:
        RETVAL

SV *
queue(self)
    SV *self
    PREINIT:
        HV *h;
        SV *v;
    CODE:
        h = pq_hv(aTHX_ self, "Punk::Queue::Worker");
        v = pq_get(aTHX_ h, "queue");
        if (!(v && SvROK(v))) XSRETURN_UNDEF;
        RETVAL = newSVsv(v);
    OUTPUT:
        RETVAL

MODULE = Punk::Queue        PACKAGE = Punk::Queue::Supervisor

# The process pool: fork n children running $queue->worker(%opts)->run,
# respawn with backoff, shut down cleanly on TERM/INT, recycle on HUP,
# report on USR2. Returns the intended process exit code.

IV
run(class, queue, ...)
    SV *class
    SV *queue
    PREINIT:
        HV *opts, *wopts;
        SV *wopts_rv;
        int i, nworkers = 1, fail_fast = 0, scheduler = 1;
        double graceful = 60.0;
    CODE:
    {
        PERL_UNUSED_ARG(class);
        if ((items - 2) % 2)
            croak("Punk::Queue::Supervisor->run: odd number of options");
        opts = (HV *)sv_2mortal((SV *)newHV());
        for (i = 2; i < items; i += 2)
            (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);

        {
            SV *v;
            if ((v = pq_get(aTHX_ opts, "workers")) && SvOK(v))
                nworkers = (int)SvIV(v);
            if ((v = pq_get(aTHX_ opts, "graceful_timeout")) && SvOK(v))
                graceful = SvNV(v);
            if ((v = pq_get(aTHX_ opts, "fail_fast")) && SvOK(v))
                fail_fast = SvTRUE(v) ? 1 : 0;
        }
        {
            SV *v;
            if ((v = pq_get(aTHX_ opts, "scheduler")) && SvOK(v))
                scheduler = SvTRUE(v) ? 1 : 0;
        }

        /* everything else in opts is the children's worker options */
        wopts = newHV();
        {
            HE *he;
            hv_iterinit(opts);
            while ((he = hv_iternext(opts))) {
                SV *k = HeSVKEY_force(he);
                const char *ks = SvPV_nolen(k);
                if (strEQ(ks, "workers") || strEQ(ks, "graceful_timeout")
                    || strEQ(ks, "fail_fast") || strEQ(ks, "scheduler"))
                    continue;
                (void)hv_store_ent(wopts, k, newSVsv(HeVAL(he)), 0);
            }
        }
        wopts_rv = sv_2mortal(newRV_noinc((SV *)wopts));

        RETVAL = pqs_run(aTHX_ queue, wopts_rv, nworkers, graceful,
                         fail_fast, scheduler);
    }
    OUTPUT:
        RETVAL
