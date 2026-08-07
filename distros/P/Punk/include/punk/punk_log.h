/* punk_log.h - a level-based logger, in C.
 *
 * $c->log and $app->log return a Punk::Logger (a blessed hash { level, format,
 * to, ctx }); its debug/info/warn/error/fatal methods format a line and emit it
 * to the server's psgix.logger when there is one, else STDERR (a `to` coderef
 * or filehandle overrides). A request logger (ctx set) adds the method/path.
 * Below-threshold calls return before any formatting.
 *
 * Must be included after punk_context.h (pcx_* / PCX_* / frj).
 */

#ifndef PUNK_LOG_H
#define PUNK_LOG_H

#include <time.h>

enum { PL_DEBUG = 0, PL_INFO = 1, PL_WARN = 2, PL_ERROR = 3, PL_FATAL = 4 };
static const char *const PL_NAMES[] = { "debug", "info", "warn", "error", "fatal" };

static int pl_level_num(pTHX_ SV *sv) {
    if (!SvOK(sv)) return PL_INFO;
    if (SvIOK(sv) && !SvPOK(sv)) {
        IV n = SvIV(sv);
        return n < 0 ? 0 : n > 4 ? 4 : (int)n;
    }
    {
        STRLEN l; const char *s = SvPV_const(sv, l);
        int i;
        for (i = 0; i < 5; i++) if (strEQ(s, PL_NAMES[i])) return i;
    }
    return PL_INFO;
}

static void pl_iso_time(char *out, size_t n) {
    struct tm tm;
    time_t t = time(NULL);
#ifdef HAS_GMTIME_R
    gmtime_r(&t, &tm);
#else
    tm = *gmtime(&t);
#endif
    my_snprintf(out, n, "%04d-%02d-%02dT%02d:%02d:%02dZ",
                tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday,
                tm.tm_hour, tm.tm_min, tm.tm_sec);
}

static HV *pl_hv(pTHX_ SV *self) {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Punk::Logger: not a logger");
    return (HV *)SvRV(self);
}

/* Punk::Logger::__fmt(fmt, @args) = sprintf - a named sub defined once (at
 * BOOT), so it is a symbol-table entry rather than an SV to keep alive; the
 * __ name reads as internal, keeping Punk::Logger.pm doc-only. */
static void pl_define_fmt(pTHX) {
    eval_pv("sub Punk::Logger::__fmt { sprintf(shift, @_) } 1", TRUE);
}

/* the output side of Perl's *STDERR (so `local *STDERR` and PerlIO layers
 * apply, matching warn), or the raw stderr if that is somehow unset */
static PerlIO *pl_stderr(pTHX) {
    IO *io = PL_stderrgv ? GvIO(PL_stderrgv) : NULL;
    return (io && IoOFP(io)) ? IoOFP(io) : PerlIO_stderr();
}

/* a Punk::Logger from an app's frozen `logging` config; ctx (a context, or
 * undef for the app logger) is held weakly so caching it in the context's
 * stash makes no cycle */
static SV *pl_make_logger(pTHX_ SV *app, SV *ctx) {
    HV *h = newHV();
    HV *cfg = NULL;
    int level = PL_INFO;
    SV *format = NULL, *to = NULL, *self;
    if (app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV) {
        SV **lc = hv_fetchs((HV *)SvRV(app), "logging", 0);
        if (lc && *lc && SvROK(*lc) && SvTYPE(SvRV(*lc)) == SVt_PVHV)
            cfg = (HV *)SvRV(*lc);
    }
    if (cfg) {
        SV **lv = hv_fetchs(cfg, "level", 0);
        SV **fm = hv_fetchs(cfg, "format", 0);
        SV **t  = hv_fetchs(cfg, "to", 0);
        if (lv && *lv && SvOK(*lv)) level = pl_level_num(aTHX_ *lv);
        if (fm && *fm && SvOK(*fm)) format = *fm;
        if (t  && *t  && SvOK(*t))  to = *t;
    }
    (void)hv_stores(h, "level", newSViv(level));
    (void)hv_stores(h, "format", format ? newSVsv(format) : newSVpvs("plain"));
    if (to) (void)hv_stores(h, "to", newSVsv(to));
    if (ctx && SvOK(ctx)) {
        SV *cref = newSVsv(ctx);
        (void)hv_stores(h, "ctx", cref);
        sv_rvweaken(cref);                 /* no context<->logger cycle */
    }
    self = sv_bless(newRV_noinc((SV *)h), gv_stashpvs("Punk::Logger", GV_ADD));
    return self;
}

/* run a coderef with one arg, swallowing a die (a broken sink must not take the
 * request down) */
static void pl_call1(pTHX_ SV *cb, SV *arg) {
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 1); PUSHs(arg); PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    SPAGAIN; PUTBACK; FREETMPS; LEAVE;
}

/* format and emit one already-built message at level lvl */
static void pl_emit(pTHX_ SV *self, int lvl, SV *msg) {
    HV *lg = pl_hv(aTHX_ self);
    SV **lev = hv_fetchs(lg, "level", 0);
    int threshold = (lev && *lev) ? (int)SvIV(*lev) : PL_INFO;
    SV **ctxp, **fmtp, **top;
    SV *ctx;
    HV *env = NULL;
    const char *method = "", *path = "";
    STRLEN ml = 0, pl2 = 0;
    SV *reqid = NULL;
    const char *name = PL_NAMES[lvl < 0 ? 0 : lvl > 4 ? 4 : lvl];
    SV *detail;
    if (lvl < threshold) return;                       /* dropped, no work */

    ctxp = hv_fetchs(lg, "ctx", 0);
    ctx = (ctxp && *ctxp && SvOK(*ctxp)) ? *ctxp : NULL;
    if (ctx) {
        SV *e = pcx_get(aTHX_ pcx_av(aTHX_ ctx), PCX_ENV);
        if (e && SvROK(e) && SvTYPE(SvRV(e)) == SVt_PVHV) {
            SV **m, **p, **r;
            env = (HV *)SvRV(e);
            m = hv_fetchs(env, "REQUEST_METHOD", 0);
            p = hv_fetchs(env, "PATH_INFO", 0);
            if (m && *m && SvOK(*m)) method = SvPV_const(*m, ml);
            if (p && *p && SvOK(*p)) path = SvPV_const(*p, pl2);
            r = hv_fetchs(env, "psgix.request_id", 0);
            if (!(r && *r && SvOK(*r))) r = hv_fetchs(env, "HTTP_X_REQUEST_ID", 0);
            if (r && *r && SvOK(*r)) reqid = *r;
        }
    }

    detail = sv_2mortal(newSVpvs(""));
    if (ml || pl2) {
        sv_catpvn(detail, method, ml);
        sv_catpvs(detail, " ");
        sv_catpvn(detail, path, pl2);
        sv_catpvs(detail, " - ");
    }
    sv_catsv(detail, msg);

    if (env) {                                          /* prefer psgix.logger */
        SV **pgl = hv_fetchs(env, "psgix.logger", 0);
        if (pgl && *pgl && SvROK(*pgl) && SvTYPE(SvRV(*pgl)) == SVt_PVCV) {
            HV *arg = newHV();
            (void)hv_stores(arg, "level", newSVpv(name, 0));
            (void)hv_stores(arg, "message", newSVsv(detail));
            pl_call1(aTHX_ *pgl, sv_2mortal(newRV_noinc((SV *)arg)));
            return;
        }
    }

    fmtp = hv_fetchs(lg, "format", 0);
    top  = hv_fetchs(lg, "to", 0);
    {
        SV *line;
        int json = fmtp && *fmtp && SvOK(*fmtp)
                   && strEQ(SvPV_nolen(*fmtp), "json");
        char ts[24];
        pl_iso_time(ts, sizeof ts);
        if (json) {
            HV *o = newHV();
            (void)hv_stores(o, "time", newSVpv(ts, 0));
            (void)hv_stores(o, "level", newSVpv(name, 0));
            (void)hv_stores(o, "message", newSVsv(msg));
            if (ml)  (void)hv_stores(o, "method", newSVpvn(method, ml));
            if (pl2) (void)hv_stores(o, "path", newSVpvn(path, pl2));
            if (reqid) (void)hv_stores(o, "request_id", newSVsv(reqid));
            line = sv_2mortal(punk_frj(aTHX)->encode(aTHX_
                       sv_2mortal(newRV_noinc((SV *)o)), NULL));
            sv_catpvs(line, "\n");
        }
        else {
            line = sv_2mortal(newSVpvf("[%s] [%s] ", ts, name));
            sv_catsv(line, detail);
            sv_catpvs(line, "\n");
        }
        if (top && *top && SvOK(*top)) {
            SV *to = *top;
            if (SvROK(to) && SvTYPE(SvRV(to)) == SVt_PVCV)
                pl_call1(aTHX_ to, line);
            else {
                IO *io = sv_2io(to);
                if (io && IoOFP(io)) {
                    STRLEN ll; const char *lp = SvPV_const(line, ll);
                    (void)PerlIO_write(IoOFP(io), lp, ll);
                }
            }
        }
        else {
            STRLEN ll; const char *lp = SvPV_const(line, ll);
            (void)PerlIO_write(pl_stderr(aTHX), lp, ll);
        }
    }
}

/* the shared body of the level methods: build the message (one arg as-is,
 * several via sprintf) and emit */
static void pl_method(pTHX_ SV *self, int lvl, SV **argv, int argc) {
    SV *msg;
    if (argc <= 0) msg = sv_2mortal(newSVpvs(""));
    else if (argc == 1) msg = argv[0];
    else {
        dSP; int count, i;
        SV *result;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        for (i = 0; i < argc; i++) XPUSHs(sv_2mortal(newSVsv(argv[i])));
        PUTBACK;
        count = call_pv("Punk::Logger::__fmt", G_SCALAR);
        SPAGAIN;
        /* keep result off the temps stack so the FREETMPS below (paired with
         * our SAVETMPS) does not free it before pl_emit uses it */
        result = count > 0 ? newSVsv(POPs) : newSVpvs("");
        PUTBACK; FREETMPS; LEAVE;
        msg = sv_2mortal(result);
    }
    pl_emit(aTHX_ self, lvl, msg);
}

#endif /* PUNK_LOG_H */
