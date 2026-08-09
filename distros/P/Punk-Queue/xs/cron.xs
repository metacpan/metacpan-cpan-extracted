MODULE = Punk::Queue        PACKAGE = Punk::Queue::Cron

# The parser surface: validation for the boot croak, next-occurrence for
# the scheduler, the tests and `punk-queue cron next`.

# Validate an expression (+tz); croaks naming the offending token, or on
# a spec that can never fire. Returns 1.
IV
check(class, expr, tz = NULL)
    SV *class
    SV *expr
    SV *tz
    PREINIT:
        pq_cron c;
        pq_tz z;
        STRLEN el, tl = 0;
        const char *es, *ts = NULL;
    CODE:
        PERL_UNUSED_ARG(class);
        es = SvPV_const(expr, el);
        if (tz && SvOK(tz)) ts = SvPV_const(tz, tl);
        pq_cron_compile(aTHX_ es, el, ts, tl, &c, &z);
        RETVAL = 1;
    OUTPUT:
        RETVAL

# The next occurrence strictly after $from (default now), as epoch
# seconds; undef when none exists inside the five-year horizon.
SV *
next_after(class, expr, from = NULL, tz = NULL)
    SV *class
    SV *expr
    SV *from
    SV *tz
    PREINIT:
        pq_cron c;
        pq_tz z;
        STRLEN el, tl = 0;
        const char *es, *ts = NULL;
        double f, n;
    CODE:
        PERL_UNUSED_ARG(class);
        es = SvPV_const(expr, el);
        if (tz && SvOK(tz)) ts = SvPV_const(tz, tl);
        pq_cron_parse(aTHX_ es, el, &c);
        pq_tz_parse(aTHX_ ts, tl, &z);
        f = (from && SvOK(from)) ? SvNV(from) : (double)time(NULL);
        n = pq_cron_next(aTHX_ &c, f, &z);
        if (n < 0) XSRETURN_UNDEF;
        RETVAL = newSVnv(n);
    OUTPUT:
        RETVAL
