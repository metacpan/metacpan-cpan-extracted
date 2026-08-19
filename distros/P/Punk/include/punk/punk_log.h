/* punk_log.h - a level-based logger, in C.
 *
 * $c->log and $app->log return a Punk::Logger (a blessed hash { level, format,
 * to, ctx }); its debug/info/warn/error/fatal methods format a line and emit it
 * to the server's psgix.logger when there is one, else STDERR (a `to` coderef
 * or filehandle overrides). A request logger (ctx set) adds the method/path.
 * Below-threshold calls return before any formatting.
 *
 * A lone unblessed hashref is a record rather than a message: its `message`
 * key is the message and the rest are fields, merged into the object under
 * `format => 'json'` and rendered as sorted logfmt pairs otherwise. The six
 * names the house owns (pl_reserved) cannot be taken by a field.
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

/* The logger's configured level. Read before anything is formatted: a call
 * below it must cost nothing, which is what Punk::Logger has always promised
 * and, until this was hoisted out of pl_emit, did not do for the sprintf
 * form. */
static int pl_threshold(pTHX_ SV *self) {
    SV **lev = hv_fetchs(pl_hv(aTHX_ self), "level", 0);
    return (lev && *lev) ? (int)SvIV(*lev) : PL_INFO;
}

/* The keys the house owns. A field carrying one of these names is dropped
 * rather than merged, in every format - a field called `level` must not be
 * able to forge a line's severity, and a reader must be able to trust that
 * they mean what the logger says they mean.
 *
 * `trace_id` and `span_id` are here for the same reason as the rest: a
 * telemetry layer writes them from the active span, and an application field
 * of the same name would forge a correlation, pointing a reader at somebody
 * else's trace. */
static int pl_reserved(const char *k, STRLEN l) {
    switch (l) {
        case 4:  return memEQ(k, "time", 4) || memEQ(k, "path", 4);
        case 5:  return memEQ(k, "level", 5);
        case 6:  return memEQ(k, "method", 6);
        case 7:  return memEQ(k, "message", 7)
                     || memEQ(k, "span_id", 7);
        case 8:  return memEQ(k, "trace_id", 8);
        case 10: return memEQ(k, "request_id", 10);
        default: return 0;
    }
}


/* Exactly what File::Raw::JSON refuses to encode: it croaks on a CODE, GLOB
 * or Regexp reference, and takes everything else - hashes and arrays, blessed
 * or not, and a scalar reference as a boolean. SvRXOK is frj's own regexp
 * test, so the two agree by construction. */
static int pl_reject(pTHX_ SV *v, SV *rv) {
#ifdef SvRXOK
    if (SvRXOK(v) || SvRXOK(rv)) return 1;
#endif
    return SvTYPE(rv) == SVt_PVCV || SvTYPE(rv) == SVt_PVGV;
}

#define PL_SCRUB_MAX 32   /* deeper than any log record; also the cycle stop */

/* Does v hold something frj would croak on, anywhere inside it? Allocates
 * nothing, and is the only walk the ordinary all-scalars record pays for. */
static int pl_unsafe(pTHX_ SV *v, int depth) {
    SV *rv;
    if (!v || !SvROK(v) || depth > PL_SCRUB_MAX) return 0;
    rv = SvRV(v);
    if (pl_reject(aTHX_ v, rv)) return 1;
    if (SvTYPE(rv) == SVt_PVHV) {
        HV *h = (HV *)rv;
        HE *he;
        hv_iterinit(h);
        while ((he = hv_iternext(h))) {
            if (pl_unsafe(aTHX_ HeVAL(he), depth + 1)) {
                hv_iterinit(h);      /* do not leave the shared iterator
                                      * parked half way through the hash */
                return 1;
            }
        }
        return 0;
    }
    if (SvTYPE(rv) == SVt_PVAV) {
        AV *a = (AV *)rv;
        SSize_t i, n = av_len(a) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(a, i, 0);
            if (e && *e && pl_unsafe(aTHX_ *e, depth + 1)) return 1;
        }
    }
    return 0;
}

/* A copy of v with every value frj rejects replaced by its stringification.
 * Only ever called when pl_unsafe said so, so the cost lands on the record
 * that earned it. The copy is plain - a blessed hash loses its class - which
 * changes no output, because frj encodes a blessed hash as a plain object
 * anyway. Mortal. */
static SV *pl_scrubbed(pTHX_ SV *v, int depth) {
    SV *rv;
    if (!v) return &PL_sv_undef;
    if (!SvROK(v) || depth > PL_SCRUB_MAX) return v;
    rv = SvRV(v);
    if (pl_reject(aTHX_ v, rv)) {
        STRLEN l;
        const char *s = SvPV_const(v, l);
        return sv_2mortal(newSVpvn(s, l));
    }
    if (SvTYPE(rv) == SVt_PVHV) {
        HV *src = (HV *)rv, *dst = newHV();
        HE *he;
        hv_iterinit(src);
        while ((he = hv_iternext(src)))
            (void)hv_store_ent(dst, hv_iterkeysv(he),
                newSVsv(pl_scrubbed(aTHX_ HeVAL(he), depth + 1)), 0);
        return sv_2mortal(newRV_noinc((SV *)dst));
    }
    if (SvTYPE(rv) == SVt_PVAV) {
        AV *src = (AV *)rv, *dst = newAV();
        SSize_t i, n = av_len(src) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(src, i, 0);
            av_push(dst, newSVsv((e && *e) ? pl_scrubbed(aTHX_ *e, depth + 1)
                                           : &PL_sv_undef));
        }
        return sv_2mortal(newRV_noinc((SV *)dst));
    }
    return v;
}

/* A field value made safe to hand to frj: v itself when it already is. */
static SV *pl_safe(pTHX_ SV *v) {
    if (!v) return &PL_sv_undef;
    return pl_unsafe(aTHX_ v, 0) ? pl_scrubbed(aTHX_ v, 0) : v;
}

/* A logfmt key. Anything that would break the line apart - a space, an `=`, a
 * quote, a control character - becomes an underscore, because a field name is
 * not always a literal in the source: `{ %$from_the_client }` is an ordinary
 * thing to write, and a key holding a newline would otherwise forge a line. */
static void pl_logfmt_key(pTHX_ SV *out, SV *k) {
    STRLEN l, i;
    const char *s = SvPV_const(k, l);
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)s[i];
        if (c <= ' ' || c == '=' || c == '"' || c == '\\') sv_catpvs(out, "_");
        else sv_catpvn(out, s + i, 1);
    }
}

/* A logfmt value. An undef field renders as a bare `key=`; a reference is
 * encoded as compact JSON first. Quoted whenever it is empty or holds
 * anything that would break a space-split reader, and a newline inside a
 * value is escaped rather than passed through - a log line has to stay one
 * line whatever it was handed. */
static void pl_logfmt_val(pTHX_ SV *out, SV *v) {
    const char *s;
    STRLEN l, i;
    int quote = 0;
    if (!v || !SvOK(v)) return;
    v = pl_safe(aTHX_ v);          /* first: this may have turned a reference
                                    * frj cannot take into a plain string, and
                                    * that string wants rendering as a string
                                    * and not as a JSON-encoded one */
    if (SvROK(v)) {
        SV *enc = sv_2mortal(punk_frj(aTHX)->encode(aTHX_ v, NULL));
        s = SvPV_const(enc, l);
    }
    else s = SvPV_const(v, l);
    if (l == 0) quote = 1;
    for (i = 0; i < l && !quote; i++) {
        unsigned char c = (unsigned char)s[i];
        if (c <= ' ' || c == '"' || c == '=' || c == '\\') quote = 1;
    }
    if (!quote) { sv_catpvn(out, s, l); return; }
    sv_catpvs(out, "\"");
    for (i = 0; i < l; i++) {
        const char c = s[i];
        switch (c) {
            case '"':  sv_catpvs(out, "\\\""); break;
            case '\\': sv_catpvs(out, "\\\\"); break;
            case '\n': sv_catpvs(out, "\\n");  break;
            case '\r': sv_catpvs(out, "\\r");  break;
            case '\t': sv_catpvs(out, "\\t");  break;
            default:   sv_catpvn(out, &c, 1);  break;
        }
    }
    sv_catpvs(out, "\"");
}

/* A record's fields as logfmt pairs, for the plain line and for the message
 * handed to a psgix.logger. Sorted, because perl's hash order is randomised
 * per process and a line that reorders itself between runs is one nobody can
 * diff, grep or test. Mortal, and empty when the record says nothing the
 * house does not already carry. */
static SV *pl_logfmt(pTHX_ HV *fields) {
    SV *out = sv_2mortal(newSVpvs(""));
    AV *keys;
    HE *he;
    SSize_t i, n = 0;
    if (!fields || !HvUSEDKEYS(fields)) return out;
    keys = (AV *)sv_2mortal((SV *)newAV());
    hv_iterinit(fields);
    while ((he = hv_iternext(fields))) {
        SV *k = hv_iterkeysv(he);
        STRLEN kl;
        const char *ks = SvPV_const(k, kl);
        if (pl_reserved(ks, kl)) continue;
        av_push(keys, newSVsv(k));
        n++;
    }
    if (n > 1) sortsv(AvARRAY(keys), (STRLEN)n, Perl_sv_cmp);
    for (i = 0; i < n; i++) {
        SV **kp = av_fetch(keys, i, 0);
        HE *e;
        if (!kp || !*kp) continue;
        if (SvCUR(out)) sv_catpvs(out, " ");
        pl_logfmt_key(aTHX_ out, *kp);
        sv_catpvs(out, "=");
        e = hv_fetch_ent(fields, *kp, 0, 0);
        pl_logfmt_val(aTHX_ out, e ? HeVAL(e) : NULL);
    }
    return out;
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

/* format and emit one already-built message at level lvl, with the record's
 * fields (NULL for none) */
static void pl_emit(pTHX_ SV *self, int lvl, SV *msg, HV *fields) {
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

    /* The observers, before any rendering. They want the record - the level,
     * the message and the fields - not a formatted line, and a line that was
     * dropped for being below the threshold was never a record at all. */
    if (PL_OBS_N) {
        int oi;
        for (oi = 0; oi < PL_OBS_N; oi++)
            PL_OBS[oi].cb(aTHX_ name, strlen(name), msg, fields,
                          PL_OBS[oi].ud);
    }

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

    /* the fields, as logfmt, after the message. The json branch below merges
     * them into the object instead and reads `msg`, not this. */
    if (fields) {
        SV *pairs = pl_logfmt(aTHX_ fields);
        if (SvCUR(pairs)) {
            /* not when the message was empty: the method/path separator has
             * already left a space, and "GET /x -  books=3" is a typo, not a
             * log line */
            if (SvCUR(detail) && SvEND(detail)[-1] != ' ')
                sv_catpvs(detail, " ");
            sv_catsv(detail, pairs);
        }
    }

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
            if (fields) {         /* the record first, the house keys after:
                                   * a colliding field is dropped by
                                   * pl_reserved, and the six below are the
                                   * only things that can occupy those names */
                HE *he;
                hv_iterinit(fields);
                while ((he = hv_iternext(fields))) {
                    SV *k = hv_iterkeysv(he);
                    STRLEN kl;
                    const char *ks = SvPV_const(k, kl);
                    if (pl_reserved(ks, kl)) continue;
                    (void)hv_store_ent(o, k,
                        newSVsv(pl_safe(aTHX_ HeVAL(he))), 0);
                }
            }
            (void)hv_stores(o, "time", newSVpv(ts, 0));
            (void)hv_stores(o, "level", newSVpv(name, 0));
            (void)hv_stores(o, "message", newSVsv(pl_safe(aTHX_ msg)));
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

/* the shared body of the level methods: build the message (a lone unblessed
 * hashref is a record, one arg as-is, several via sprintf) and emit.
 *
 * The threshold is read here rather than in pl_emit, so a dropped call really
 * does no work: it used to sprintf first and ask afterwards, which made every
 * below-threshold ->debug('%s', $expensive) pay for a line nobody would see.
 *
 * A record is an UNBLESSED hashref only. An object is a message, however it
 * is built: one with an overloaded "" is an ordinary thing to log, and
 * dumping its guts as fields instead would be a silent change of meaning. */
static void pl_method(pTHX_ SV *self, int lvl, SV **argv, int argc) {
    SV *msg;
    HV *fields = NULL;
    if (lvl < pl_threshold(aTHX_ self)) return;        /* dropped, no work */
    if (argc == 1 && SvROK(argv[0]) && !SvOBJECT(SvRV(argv[0]))
        && SvTYPE(SvRV(argv[0])) == SVt_PVHV) {
        SV **m;
        fields = (HV *)SvRV(argv[0]);
        m = hv_fetchs(fields, "message", 0);
        msg = (m && *m && SvOK(*m)) ? *m : sv_2mortal(newSVpvs(""));
    }
    else if (argc <= 0) msg = sv_2mortal(newSVpvs(""));
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
    pl_emit(aTHX_ self, lvl, msg, fields);
}

#endif /* PUNK_LOG_H */
