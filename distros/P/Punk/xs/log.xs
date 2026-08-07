MODULE = Punk        PACKAGE = Punk::Logger

PROTOTYPES: DISABLE

# Build the sprintf coderef once, at load, so it never runs eval_pv mid-log
# (which would disturb the argument stack of the call in progress).
BOOT:
    pl_define_fmt(aTHX);

# The level-based logger, in C (punk_log.h). debug/info/warn/error/fatal (and a
# generic log($level, ...)) format a message - one arg as-is, several via
# sprintf - and emit it. lib/Punk/Logger.pm is documentation.
SV *
debug(self, ...)
        SV *self
    ALIAS:
        info  = 1
        warn  = 2
        error = 3
        fatal = 4
    CODE:
    {
        int argc = items - 1, i;
        SV **argv;
        Newx(argv, argc > 0 ? argc : 1, SV *);
        for (i = 0; i < argc; i++) argv[i] = ST(i + 1);
        pl_method(aTHX_ self, (int)ix, argv, argc);
        Safefree(argv);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# log($level => $message, @args): the level-first form.
SV *
log(self, level, ...)
        SV *self
        SV *level
    CODE:
    {
        int lvl = pl_level_num(aTHX_ level);
        int argc = items - 2, i;
        SV **argv;
        Newx(argv, argc > 0 ? argc : 1, SV *);
        for (i = 0; i < argc; i++) argv[i] = ST(i + 2);
        pl_method(aTHX_ self, lvl, argv, argc);
        Safefree(argv);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::App

# $app->log: the application logger (no request context), cached on the app.
SV *
log(self)
        SV *self
    CODE:
    {
        HV *h = app_hv(aTHX_ self);
        SV **cached = hv_fetchs(h, "logger", 0);
        if (cached && *cached && SvROK(*cached)) RETVAL = newSVsv(*cached);
        else {
            SV *lg = pl_make_logger(aTHX_ self, NULL);
            (void)hv_stores(h, "logger", newSVsv(lg));
            RETVAL = lg;
        }
    }
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::Context

# $c->log: the request logger (adds method/path), cached in the stash.
SV *
log(self)
        SV *self
    CODE:
    {
        AV *av = pcx_av(aTHX_ self);
        SV *st = pcx_get(aTHX_ av, PCX_STASH);
        HV *stash;
        SV **cached;
        if (!st) { st = newRV_noinc((SV *)newHV()); (void)av_store(av, PCX_STASH, st); }
        stash = (HV *)SvRV(st);
        cached = hv_fetchs(stash, "punk.logger", 0);
        if (cached && *cached && SvROK(*cached)) RETVAL = newSVsv(*cached);
        else {
            SV *lg = pl_make_logger(aTHX_ pcx_get(aTHX_ av, PCX_APP), self);
            (void)hv_stores(stash, "punk.logger", newSVsv(lg));
            RETVAL = lg;
        }
    }
    OUTPUT:
        RETVAL
