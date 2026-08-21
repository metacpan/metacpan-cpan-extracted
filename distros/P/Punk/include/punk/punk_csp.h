#ifndef PUNK_CSP_H
#define PUNK_CSP_H

/* Punk::Plugin::CSP - Content-Security-Policy with a per-request nonce.
 *
 * `headers` already sets a static CSP, and that is worth having. The policy
 * that actually stops cross-site scripting is `script-src 'nonce-...'`, and a
 * nonce is per request by definition: minted fresh, put in the header, and
 * threaded into every <script> tag the templates emit.
 *
 * That thread is the whole plugin. A nonce in the header that no template
 * carries blocks every script on the page - obvious, and someone fixes it. A
 * nonce in the template that the header does not carry blocks nothing, looks
 * perfectly fine, and nobody finds out. The second is why the two halves are
 * tested against each other rather than separately.
 *
 * ---- the nonce ------------------------------------------------------------
 *
 * 16 bytes - 128 bits - as base64url without padding: 22 characters. The CSP
 * grammar's base64-value accepts `-` and `_`, so base64url needs no
 * translation, and it is a third shorter than hex for the same entropy on a
 * header that goes out on every response.
 *
 * The requirement is UNPREDICTABILITY, not merely uniqueness, and that is a
 * stricter thing: a unique but guessable nonce is one an attacker can put in
 * their own injected <script nonce="...">, which is the entire attack the
 * policy exists to stop. So a counter is disqualified here in a way it merely
 * lost on taste for a request id, and so is anything derived from a clock, a
 * pid or a request count.
 *
 * The bytes come from punk_entropy.h - `getentropy` where the build probe
 * found it, a cached /dev/urandom descriptor otherwise, the same source
 * punk_csrf.h already treats as cryptographic for a CSRF token. A nonce is a
 * weaker requirement than that token, not a stronger one.
 */

#define PCSP_NONCE_BYTES 16
#define PCSP_ENV_KEY     "punk.csp_nonce"

/* This request's nonce, minted on first ask and kept in the env.
 *
 * The env rather than a C static, and not as a style choice: Punk dispatches
 * asynchronously through Punk::Future, so a worker can have several requests
 * in flight at once and a "current nonce" in a static would hand one
 * request's nonce to another - invisibly, and only under load. For a nonce
 * that is not an untidy log line, it is one user's page authorised by another
 * user's value.
 *
 * The env rather than a context slot, because the header is written by
 * phd_decorate, which sees the env and not the context.
 */
static SV *pcsp_nonce(pTHX_ HV *env) {
    SV **e = hv_fetchs(env, PCSP_ENV_KEY, 0);
    unsigned char raw[PCSP_NONCE_BYTES];
    SV *n;
    if (e && *e && SvOK(*e)) return *e;
    pk_ent_take(aTHX_ raw, sizeof raw);
    n = pk_b64url(aTHX_ raw, sizeof raw);
    (void)hv_stores(env, PCSP_ENV_KEY, n);
    return n;
}

/* Is CSP configured for the app this context belongs to?
 *
 * Read from the app hash rather than the compiled state because the view path
 * has a context and not a state - and it has to be a per-app answer, since
 * two Punk apps can share a process under Plack::Builder and only one of them
 * may have asked for a policy. */
static HV *pcsp_cfg_of(pTHX_ SV *c) {
    AV *av;
    SV *app, **e;
    if (!c || !SvROK(c)) return NULL;
    av = pcx_av(aTHX_ c);
    if (!av) return NULL;
    app = pcx_get(aTHX_ av, PCX_APP);
    if (!(app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV)) return NULL;
    e = hv_fetchs((HV *)SvRV(app), K_CSP, 0);
    return (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)
        ? (HV *)SvRV(*e) : NULL;
}

/* Put this request's nonce into the variables a template is about to be
 * rendered with, so `{% csp_nonce %}` works with nothing passed by the
 * application.
 *
 * SET, not set-if-absent, and that is the whole reason this is safe: a
 * handler that renders with a hashref it keeps between requests would
 * otherwise carry the first request's nonce for ever, and a template nonce
 * that does not match the header is the failure mode nobody notices - the
 * page works, the policy is decorative.
 */
static void pcsp_bind_vars(pTHX_ SV *c, SV *data) {
    HV *cfg = pcsp_cfg_of(aTHX_ c);
    AV *av;
    SV *e;
    if (!cfg) return;
    if (!(data && SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)) return;
    av = pcx_av(aTHX_ c);
    if (!av) return;
    e = pcx_get(aTHX_ av, PCX_ENV);
    if (!(e && SvROK(e) && SvTYPE(SvRV(e)) == SVt_PVHV)) return;
    (void)hv_stores((HV *)SvRV(data), "csp_nonce",
                    newSVsv(pcsp_nonce(aTHX_ (HV *)SvRV(e))));
}

/* ---- the policy ---------------------------------------------------------- */

/* The directives that are not negotiable, and why.
 *
 * `base-uri 'none'` is not optional and is the one people leave out: an
 * injected <base href> rewrites every relative script URL, so a nonce on a
 * relative <script src> would protect nothing at all.
 *
 * `object-src 'none'` closes the plugin-embedding bypasses a script-only
 * policy leaves open.
 *
 * Both are overridable, because a policy nobody can adjust is a policy that
 * gets removed rather than tuned - but they are present unless something is
 * said, which is the direction that fails safe.
 */
#define PCSP_DEF_DEFAULT  "'self'"
#define PCSP_DEF_SCRIPT   "'self'"
#define PCSP_DEF_OBJECT   "'none'"
#define PCSP_DEF_BASE     "'none'"

/* A directive value from configuration is on its way into a response header.
 *
 * A CR or an LF in one splits the response - the same class as the header
 * name check in Punk::Plugin::RequestId, and the same answer: croak at boot
 * naming the directive, rather than sanitising into a shape nobody asked for
 * and shipping a policy that is not the one that was written.
 */
static void pcsp_check_value(pTHX_ const char *name, SV *v) {
    STRLEN l, i;
    const char *p;
    if (!v || !SvOK(v)) return;
    p = SvPV_const(v, l);
    for (i = 0; i < l; i++) {
        unsigned char ch = (unsigned char)p[i];
        if (ch == '\r' || ch == '\n' || ch == '\0' || ch == ';')
            croak("Punk::Plugin::CSP: the %s directive contains a byte that "
                  "cannot appear in one (a newline, a NUL or a semicolon) - "
                  "give each directive its own option rather than joining "
                  "them", name);
    }
}

/* Append `name value` to the policy, with the separator when it is not the
 * first. */
static void pcsp_add(pTHX_ SV *out, const char *name, const char *val,
                     STRLEN vlen) {
    if (SvCUR(out)) sv_catpvs(out, "; ");
    sv_catpv(out, name);
    if (vlen) { sv_catpvs(out, " "); sv_catpvn(out, val, vlen); }
}

/* Build this request's policy.
 *
 * The nonce is spliced INTO script-src rather than appended to the finished
 * string, so an application that configured its own script-src gets its
 * sources and the nonce, in one directive, rather than a second script-src
 * that browsers would ignore.
 */
static SV *pcsp_policy(pTHX_ HV *cfg, HV *env) {
    SV *out = newSVpvs("");
    SV **v;
    SV *nonce = pcsp_nonce(aTHX_ env);
    STRLEN nl;
    const char *np = SvPV_const(nonce, nl);

    v = cfg ? hv_fetchs(cfg, "default_src", 0) : NULL;
    {   STRLEN l; const char *p = (v && *v && SvOK(*v))
            ? SvPV_const(*v, l) : (l = sizeof(PCSP_DEF_DEFAULT) - 1,
                                   PCSP_DEF_DEFAULT);
        if (l) pcsp_add(aTHX_ out, "default-src", p, l);
    }

    {   /* script-src: the configured sources, then this request's nonce */
        SV *ss = newSVpvs("");
        STRLEN l; const char *p;
        v = cfg ? hv_fetchs(cfg, "script_src", 0) : NULL;
        p = (v && *v && SvOK(*v)) ? SvPV_const(*v, l)
                                  : (l = sizeof(PCSP_DEF_SCRIPT) - 1,
                                     PCSP_DEF_SCRIPT);
        if (l) { sv_catpvn(ss, p, l); sv_catpvs(ss, " "); }
        sv_catpvs(ss, "'nonce-");
        sv_catpvn(ss, np, nl);
        sv_catpvs(ss, "'");
        pcsp_add(aTHX_ out, "script-src", SvPVX(ss), SvCUR(ss));
        SvREFCNT_dec(ss);
    }

    {   STRLEN l; const char *p;
        v = cfg ? hv_fetchs(cfg, "object_src", 0) : NULL;
        p = (v && *v && SvOK(*v)) ? SvPV_const(*v, l)
                                  : (l = sizeof(PCSP_DEF_OBJECT) - 1,
                                     PCSP_DEF_OBJECT);
        if (l) pcsp_add(aTHX_ out, "object-src", p, l);
    }
    {   STRLEN l; const char *p;
        v = cfg ? hv_fetchs(cfg, "base_uri", 0) : NULL;
        p = (v && *v && SvOK(*v)) ? SvPV_const(*v, l)
                                  : (l = sizeof(PCSP_DEF_BASE) - 1,
                                     PCSP_DEF_BASE);
        if (l) pcsp_add(aTHX_ out, "base-uri", p, l);
    }

    /* Anything else the application named, in the order it named them. */
    if (cfg) {
        static const char *extra[] = { "style_src", "img_src", "connect_src",
                                       "font_src", "frame_ancestors",
                                       "form_action", "report_uri", NULL };
        static const char *asname[] = { "style-src", "img-src", "connect-src",
                                        "font-src", "frame-ancestors",
                                        "form-action", "report-uri", NULL };
        int i;
        for (i = 0; extra[i]; i++) {
            SV **x = hv_fetch(cfg, extra[i], (I32)strlen(extra[i]), 0);
            if (x && *x && SvOK(*x)) {
                STRLEN l;
                const char *p = SvPV_const(*x, l);
                if (l) pcsp_add(aTHX_ out, asname[i], p, l);
            }
        }
    }

    return out;
}

/* ---- the inline-handler check, in development ---------------------------- */

/* Is this application in development?
 *
 * Scanning every response in production is a cost on the hot path to tell
 * somebody something they cannot act on at the time. The counter below makes
 * "it was not scanned" provable rather than merely unobserved. */
static int pcsp_dev(pTHX_ HV *cfg) {
    SV **e = cfg ? hv_fetchs(cfg, "dev", 0) : NULL;
    PERL_UNUSED_CONTEXT;
    return (e && *e && SvTRUE(*e));
}

static UV pcsp_n_scanned = 0;      /* bodies scanned; 0 in production        */
static UV pcsp_n_warned  = 0;

/* Templates already warned about, so the same page does not warn on every
 * request. Noise is ignored, and being ignored is how the original problem
 * happens. */
static HV *pcsp_seen = NULL;

/* Case-insensitive needle search over n bytes. */
static const char *pcsp_find(const char *h, STRLEN hl, const char *needle) {
    STRLEN nl = strlen(needle), i, j;
    if (nl == 0 || hl < nl) return NULL;
    for (i = 0; i + nl <= hl; i++) {
        for (j = 0; j < nl; j++)
            if (toLOWER((U8)h[i + j]) != (unsigned char)needle[j]) break;
        if (j == nl) return h + i;
    }
    return NULL;
}

/* An `on...=` attribute: `on`, at least one letter, then `=`. Matching the
 * shape rather than a list of names catches onclick, onerror, onload and
 * whatever was added to HTML last year. */
static int pcsp_find_handler(const char *b, STRLEN bl, char *out, size_t outn) {
    STRLEN i;
    for (i = 0; i + 3 < bl; i++) {
        STRLEN j;
        /* must follow whitespace, or it is the tail of another word */
        if (i && !isSPACE((U8)b[i - 1])) continue;
        if (toLOWER((U8)b[i]) != 'o' || toLOWER((U8)b[i + 1]) != 'n') continue;
        j = i + 2;
        while (j < bl && isALPHA((U8)b[j])) j++;
        if (j == i + 2 || j >= bl || b[j] != '=') continue;
        {   size_t n = (size_t)(j - i);
            if (n > outn - 1) n = outn - 1;
            Copy(b + i, out, n, char);
            out[n] = '\0';
        }
        return 1;
    }
    return 0;
}

static void pcsp_warn(pTHX_ SV *c, const char *fmt, SV *a, SV *b) {
    dSP;
    SV *msg = sv_2mortal(newSVpvf(fmt, SvPV_nolen(a), b ? SvPV_nolen(b) : ""));
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 1); PUSHs(c); PUTBACK;
    if (call_method("log", G_SCALAR | G_EVAL) > 0) {
        SV *lg = SvREFCNT_inc(POPs);
        PUTBACK;
        if (!SvTRUE(ERRSV) && SvOK(lg)) {
            PUSHMARK(SP); EXTEND(SP, 2);
            PUSHs(lg); PUSHs(msg);
            PUTBACK;
            (void)call_method("warn", G_DISCARD | G_EVAL);
            SPAGAIN;
        }
        SvREFCNT_dec(lg);
    }
    else PUTBACK;
    FREETMPS; LEAVE;
    pcsp_n_warned++;
}

/* Scan one rendered body. Development only, and it never touches the
 * response: it has no authority over what is sent, because a checker that
 * breaks the page is a checker that gets removed. */
static void pcsp_scan(pTHX_ SV *c, SV *template, SV *bytes) {
    HV *cfg = pcsp_cfg_of(aTHX_ c);
    SV **opt;
    const char *b;
    STRLEN bl;
    char found[64];

    if (!cfg || !bytes || !SvOK(bytes)) return;
    opt = hv_fetchs(cfg, "inline_check", 0);
    if (opt && *opt && SvOK(*opt) && !SvTRUE(*opt)) return;   /* turned off */
    if (!pcsp_dev(aTHX_ cfg)) return;

    b = SvPV_const(bytes, bl);
    if (!bl) return;
    pcsp_n_scanned++;

    /* The escape hatch. A template that knowingly needs an inline handler
     * says so in itself, which keeps the exemption next to the thing being
     * exempted rather than in a config file that outlives the reason. A
     * checker with no way out gets disabled wholesale instead. */
    if (pcsp_find(b, bl, "csp-allow-inline")) return;

    {   /* once per template */
        STRLEN tl;
        const char *tp = template && SvOK(template) ? SvPV_const(template, tl)
                                                    : (tl = 7, "unknown");
        if (!pcsp_seen) pcsp_seen = newHV();
        if (hv_exists(pcsp_seen, tp, (I32)tl)) return;

        if (pcsp_find_handler(b, bl, found, sizeof found)) {
            (void)hv_store(pcsp_seen, tp, (I32)tl, &PL_sv_yes, 0);
            pcsp_warn(aTHX_ c,
                "Punk::Plugin::CSP: %s has an inline `%s=` handler, which a "
                "script nonce does NOT cover - it needs 'unsafe-inline', and "
                "adding that back defeats the policy for every page. Move the "
                "handler into a nonced <script>, or put csp-allow-inline in "
                "the template if it is deliberate.",
                sv_2mortal(newSVpvn(tp, tl)),
                sv_2mortal(newSVpvn(found, strlen(found))));
            return;
        }

        {   /* Phase 2 deferred this here, and it costs nothing extra now the
             * body is in hand: a nonce in the markup that is not THIS
             * request's is a page that came out of a cache. Every script on
             * it is blocked, and the fault appears long after the change that
             * caused it. */
            const char *at = pcsp_find(b, bl, "nonce=\"");
            if (at) {
                AV *av = pcx_av(aTHX_ c);
                SV *e  = av ? pcx_get(aTHX_ av, PCX_ENV) : NULL;
                if (e && SvROK(e) && SvTYPE(SvRV(e)) == SVt_PVHV) {
                    SV *mine = pcsp_nonce(aTHX_ (HV *)SvRV(e));
                    STRLEN ml;
                    const char *mp = SvPV_const(mine, ml);
                    const char *v  = at + 7;
                    STRLEN room = bl - (STRLEN)(v - b);
                    if (!(room >= ml && memEQ(v, mp, ml))) {
                        (void)hv_store(pcsp_seen, tp, (I32)tl, &PL_sv_yes, 0);
                        pcsp_warn(aTHX_ c,
                            "Punk::Plugin::CSP: %s rendered a nonce that is "
                            "not this request's%s - a cached page carries the "
                            "nonce it was rendered with, and every script on "
                            "it is blocked against a header carrying a "
                            "different one. A response that rendered a nonce "
                            "must not be cached.",
                            sv_2mortal(newSVpvn(tp, tl)), NULL);
                    }
                }
            }
        }
    }
}

/* ---- the report endpoint ------------------------------------------------- */

/* How many violations this process has been told about. A number nobody can
 * see is a number nobody acts on, and a rising one during a report-only
 * rollout is the whole signal you are rolling out for. */
static UV pcsp_n_reports = 0;
static UV pcsp_n_malformed = 0;

/* The fields of a violation report worth keeping.
 *
 * EVERY ONE OF THESE IS REQUEST BYTES. `document-uri`, `blocked-uri`,
 * `script-sample` and `referrer` all come from a client that can send
 * anything, and they are on their way into a log line - the class this
 * workspace has been bitten by three times.
 *
 * They are handed to the logger as a RECORD rather than pasted into a
 * message, which is what makes that safe: punk_log.h renders a record's
 * values through pl_logfmt_val, which quotes and escapes a newline rather
 * than passing it through, "because a log line has to stay one line whatever
 * it was handed". Reusing that is the point - a second escaper here would be
 * a second thing to get wrong. */
static const char *PCSP_FIELDS[] = {
    "document-uri", "referrer", "violated-directive", "effective-directive",
    "blocked-uri", "source-file", "line-number", "script-sample",
    "disposition", "status-code", NULL
};

/* POST <report_uri>: take a violation report, log it, answer 204.
 *
 * cap = [ $app ]. Always 204, including for a body that made no sense:
 * nothing reads the response, and an error status invites a retry from a
 * browser that cannot fix what it sent.
 */
XS_INTERNAL(pcsp_report_cb);
XS_INTERNAL(pcsp_report_cb) {
    dXSARGS;
    SV *c = items > 0 ? ST(0) : &PL_sv_undef;
    HV *rec = newHV();
    SV *json = NULL;
    int i;
    PERL_UNUSED_VAR(items);

    pcsp_n_reports++;

    /* $c->req->json - the body through File::Raw::JSON's ABI. A malformed
     * body decodes to undef and is counted rather than argued with. */
    {
        dSP; int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(c); PUTBACK;
        count = call_method("req", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (count > 0) {
            SV *req = SvREFCNT_inc(POPs);
            PUTBACK;
            if (!SvTRUE(ERRSV) && SvOK(req)) {
                PUSHMARK(SP); EXTEND(SP, 1); PUSHs(req); PUTBACK;
                count = call_method("json", G_SCALAR | G_EVAL);
                SPAGAIN;
                if (count > 0 && !SvTRUE(ERRSV)) json = SvREFCNT_inc(POPs);
                PUTBACK;
            }
            SvREFCNT_dec(req);
        }
        else PUTBACK;
        FREETMPS; LEAVE;
    }

    /* A report arrives as { "csp-report": { ... } }. Newer browsers send the
     * Reporting API shape instead; taking the inner object when it is there
     * and the outer one otherwise handles both without pretending to
     * understand either. */
    {
        HV *body = NULL;
        if (json && SvROK(json) && SvTYPE(SvRV(json)) == SVt_PVHV) {
            HV *top = (HV *)SvRV(json);
            SV **inner = hv_fetchs(top, "csp-report", 0);
            body = (inner && *inner && SvROK(*inner)
                    && SvTYPE(SvRV(*inner)) == SVt_PVHV)
                 ? (HV *)SvRV(*inner) : top;
        }
        if (!body) pcsp_n_malformed++;
        for (i = 0; body && PCSP_FIELDS[i]; i++) {
            I32 kl = (I32)strlen(PCSP_FIELDS[i]);
            SV **v = hv_fetch(body, PCSP_FIELDS[i], kl, 0);
            if (v && *v && SvOK(*v))
                (void)hv_store(rec, PCSP_FIELDS[i], kl, newSVsv(*v), 0);
        }
    }
    if (json) SvREFCNT_dec(json);

    (void)hv_stores(rec, "message", newSVpvs("csp violation"));

    {   /* $c->log->warn(\%rec) */
        dSP; int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(c); PUTBACK;
        count = call_method("log", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (count > 0) {
            SV *lg = SvREFCNT_inc(POPs);
            PUTBACK;
            if (!SvTRUE(ERRSV) && SvOK(lg)) {
                PUSHMARK(SP); EXTEND(SP, 2);
                PUSHs(lg);
                PUSHs(sv_2mortal(newRV_inc((SV *)rec)));
                PUTBACK;
                (void)call_method("warn", G_DISCARD | G_EVAL);
                SPAGAIN;
            }
            SvREFCNT_dec(lg);
        }
        else PUTBACK;
        FREETMPS; LEAVE;
    }
    SvREFCNT_dec((SV *)rec);

    {   /* 204: no body, and no Content-Type for one */
        AV *resp = newAV();
        av_push(resp, newSViv(204));
        av_push(resp, newRV_noinc((SV *)newAV()));
        av_push(resp, newRV_noinc((SV *)newAV()));
        ST(0) = sv_2mortal(newRV_noinc((SV *)resp));
    }
    XSRETURN(1);
}

#endif /* PUNK_CSP_H */
