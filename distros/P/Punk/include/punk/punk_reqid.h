#ifndef PUNK_REQID_H
#define PUNK_REQID_H

/* Punk::Plugin::RequestId - an id for every request, in C.
 *
 * Backs the plugin `Punk.pm`'s SYNOPSIS has always opened with. The whole
 * path is here because an id is minted on EVERY request, including the ones
 * that 404, so it sits on the floor of the framework's cost.
 *
 * ---- why the shape is what it is (phase 0's measurements) ----------------
 *
 * A bare Punk request - one route, in-process dispatch, no socket - is
 * 1058 ns. Against that:
 *
 *   getentropy(16) per id ............. 693 ns   65.5% of a request
 *   entropy sliced 16 ids per call ..... 42 ns    4.0%
 *   clock_gettime(CLOCK_REALTIME) ...... 12 ns
 *   getpid() ........................... 1.5 ns
 *   this generator, complete ........... 64 ns    6.0%
 *
 * `getentropy` costs per CALL, not per byte: a flat ~640-730 ns whether it is
 * asked for 16 bytes or 256. So it is asked for 256 - its documented maximum -
 * and sixteen ids are handed out of the result. That one constant is worth
 * 17x, and it is why pk_random_bytes (which draws per call, correctly, for a
 * per-session CSRF token) is not used here.
 *
 * A LARGER buffer buys nothing: CAP bytes still needs CAP/256 calls, so ids
 * per syscall is pinned at 16 however much is held. 256 B measured the same
 * as 256 KB, so 256 B it is - least memory, least unused entropy resident.
 */

#define PR_ID_HEX   32                  /* 16 bytes as hex                   */

/* The entropy comes from punk_entropy.h, which is shared with the CSP nonce:
 * one 256-byte pid-guarded buffer for the dist rather than one per feature.
 * The reasoning for both the slicing and the pid guard lives there. */

static const char PR_HEX[] = "0123456789abcdef";

/* A UUIDv7 (RFC 9562) as 32 lowercase hex characters: 48 bits of millisecond
 * timestamp, then randomness.
 *
 * The timestamp is what a plain random id does not have, and it costs one
 * vDSO clock read - 12 ns, about 1% of a bare request. It buys ids that sort
 * chronologically across every worker and every log file, which is the thing
 * people actually do with them.
 *
 * A per-worker counter would be 2.7 ns, and was rejected on disclosure rather
 * than cost: the id goes back to the client in a response header, so a caller
 * making two requests would learn how many requests that worker served in
 * between, and every other id would be guessable.
 */
static SV *pr_mint(pTHX) {
    unsigned char raw[16];
    char hex[PR_ID_HEX];
    int i;
    UV ms;

    pk_ent_take(aTHX_ raw, 16);

    {   /* milliseconds since the epoch */
        struct timeval tv;
        gettimeofday(&tv, NULL);
        ms = (UV)tv.tv_sec * 1000 + (UV)(tv.tv_usec / 1000);
    }
    raw[0] = (unsigned char)((ms >> 40) & 0xff);
    raw[1] = (unsigned char)((ms >> 32) & 0xff);
    raw[2] = (unsigned char)((ms >> 24) & 0xff);
    raw[3] = (unsigned char)((ms >> 16) & 0xff);
    raw[4] = (unsigned char)((ms >>  8) & 0xff);
    raw[5] = (unsigned char)( ms        & 0xff);
    raw[6] = (unsigned char)(0x70 | (raw[6] & 0x0f));   /* version 7 */
    raw[8] = (unsigned char)(0x80 | (raw[8] & 0x3f));   /* variant   */

    for (i = 0; i < 16; i++) {
        hex[i * 2]     = PR_HEX[raw[i] >> 4];
        hex[i * 2 + 1] = PR_HEX[raw[i] & 0x0f];
    }
    return newSVpvn(hex, PR_ID_HEX);
}

/* ---- adopting an id handed in by a proxy --------------------------------- */

/* An inbound id is REQUEST BYTES, which is the bug class this workspace has
 * been bitten by three times (CVE-2026-75628, the markdown 301, the
 * Reverse::Proxy smuggling fix). It reaches two dangerous places: a log line
 * and a response header. A CR in the first forges a log entry; a CR in the
 * second splits the response.
 *
 * So the charset is deliberately narrower than HTTP allows: printable ASCII
 * with no space and no DEL, which is 0x21 to 0x7e. That covers every real id
 * format - a UUID, hex, base64, base64url, a W3C traceparent - and excludes
 * CR, LF, NUL, tab, every other control byte and everything above ASCII.
 *
 * 128 bytes because the longest thing anyone legitimately sends is a
 * traceparent at 55. An id is not a place to put a kilobyte, and a log file
 * is not a place to let somebody else decide how many bytes to write.
 */
#define PR_MAX_INBOUND 128

static UV pr_n_adopted  = 0;
static UV pr_n_rejected = 0;
static UV pr_n_minted   = 0;

static int pr_id_ok(const char *p, STRLEN len) {
    STRLEN i;
    if (len == 0 || len > PR_MAX_INBOUND) return 0;
    for (i = 0; i < len; i++) {
        unsigned char ch = (unsigned char)p[i];
        if (ch < 0x21 || ch > 0x7e) return 0;
    }
    return 1;
}

/* ---- the plugin's state -------------------------------------------------- */
/*
 * The observers are process-global - they have to be, the same way Fetch's
 * are - but the CONFIGURATION is per application, frozen on the app hash
 * beside the `session` and `csrf` keywords' own.
 *
 * Holding the header name in a static instead was the first version, and it
 * was wrong in a way only a second app reveals: two Punk apps under one
 * Plack::Builder share the process, so whichever registered last named the
 * header for BOTH. App A emitted `X-B-Id`. Per-app options that quietly stop
 * being per-app are worse than options that were never offered.
 */

#define PR_APP_KEY "punk.request_id"

static int pr_on = 0;               /* observers registered in this process  */

/* This app's config: an AV of [ header-name-or-false, env-key-or-undef ].
 *
 * Two elements rather than two hash keys because it is read on every request
 * and an AV fetch is cheaper than a second hv_fetch. Element 1 is present
 * only when `trust_header` was asked for, so its mere existence is the
 * trust decision - there is no separate flag to fall out of step with it.
 */
static AV *pr_cfg(pTHX_ SV *c) {
    SV *app, **e;
    AV *av;
    if (!SvROK(c)) return NULL;
    av = pcx_av(aTHX_ c);
    if (!av) return NULL;
    app = pcx_get(aTHX_ av, PCX_APP);
    if (!(app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV)) return NULL;
    e = hv_fetchs((HV *)SvRV(app), PR_APP_KEY, 0);
    if (!e || !*e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVAV) return NULL;
    return (AV *)SvRV(*e);
}

/* The header to send, or NULL for none - which is `header => 0`. */
static SV *pr_cfg_header(pTHX_ AV *cfg) {
    SV **e = cfg ? av_fetch(cfg, 0, 0) : NULL;
    return (e && *e && SvOK(*e) && SvTRUE(*e)) ? *e : NULL;
}

/* Put the id where $c->request_id and the response observer can both find it.
 *
 * A CONTEXT SLOT, not the stash. The stash was the first version and cost an
 * HV allocation plus a hash store on every request, for one string - on a
 * route that never touches the stash otherwise, that HV existed only to hold
 * this. A slot on the context AV that is already allocated is one av_store.
 *
 * On the context at all, rather than a C static, and that is not a stylistic
 * choice: Punk dispatches asynchronously through Punk::Future, so a worker
 * can have several requests in flight at once. A "current request id" in a
 * static would hand one request's id to another - invisibly, and only under
 * load.
 */
static void pr_obs_req(pTHX_ SV *c, void *ud) {
    AV *av, *cfg;
    SV **envp, *id = NULL;
    PERL_UNUSED_ARG(ud);

    if (!SvROK(c)) return;
    cfg = pr_cfg(aTHX_ c);
    if (!cfg) return;                   /* another app in this process */
    av = pcx_av(aTHX_ c);
    if (!av) return;

    /* Adopt an inbound id only when this app asked to, and only when what
     * arrived survives validation. A value that fails is REPLACED, never
     * trimmed into shape: a mangled id correlates with nothing at either end,
     * and silently editing what a client sent produces a third value that
     * matches neither. */
    envp = av_fetch(cfg, 1, 0);
    if (envp && *envp && SvOK(*envp)) {
        SV *envsv = pcx_get(aTHX_ av, PCX_ENV);
        if (envsv && SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV) {
            STRLEN kl;
            const char *k = SvPV_const(*envp, kl);
            SV **hv = hv_fetch((HV *)SvRV(envsv), k, (I32)kl, 0);
            if (hv && *hv && SvOK(*hv)) {
                STRLEN vl;
                const char *v = SvPV_const(*hv, vl);
                if (pr_id_ok(v, vl)) { id = newSVpvn(v, vl); pr_n_adopted++; }
                else                 { pr_n_rejected++; }
            }
        }
    }

    if (!id) { id = pr_mint(aTHX); pr_n_minted++; }
    (void)av_store(av, PCX_REQID, id);

    /* And into the env under the PSGI extension key, which is how everything
     * else in the stack finds it: Punk's own logger reads psgix.request_id,
     * and so do other people's middlewares. Publishing it here rather than
     * teaching the logger about a context slot means one convention instead
     * of two, and anything mounted inside this app sees it as well. */
    {
        SV *envsv = pcx_get(aTHX_ av, PCX_ENV);
        if (envsv && SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV)
            (void)hv_stores((HV *)SvRV(envsv), "psgix.request_id",
                            newSVsv(id));
    }
}

/* Echo it on the way out.
 *
 * This runs on the RESPONSE OBSERVER rather than an after_dispatch hook, and
 * the difference is the whole point: the dispatcher has exits that never
 * reach punk_finish_c - the house 404 and 405 among them - so an
 * after_dispatch hook cannot see them. An id present on a 200 and missing on
 * a 404 is missing exactly when somebody is trying to trace a 404.
 */
static void pr_obs_res(pTHX_ SV *c, SV *response, void *ud) {
    AV *ra, *hdrs, *cav;
    SV **hp, *id, *name;
    PERL_UNUSED_ARG(ud);

    name = pr_cfg_header(aTHX_ pr_cfg(aTHX_ c));
    if (!name) return;
    if (!SvROK(response) || SvTYPE(SvRV(response)) != SVt_PVAV) return;
    ra = (AV *)SvRV(response);
    if (av_len(ra) < 1) return;                 /* not a triplet: leave it   */

    hp = av_fetch(ra, 1, 0);
    if (!hp || !*hp || !SvROK(*hp) || SvTYPE(SvRV(*hp)) != SVt_PVAV) return;
    hdrs = (AV *)SvRV(*hp);

    cav = pcx_av(aTHX_ c);
    if (!cav) return;
    id = pcx_get(aTHX_ cav, PCX_REQID);
    if (!id || !SvOK(id)) return;

    av_push(hdrs, newSVsv(name));
    av_push(hdrs, newSVsv(id));
}

/* Registered once per process, at plugin registration - which is boot, in the
 * parent, before any fork. The observers are process-global by design (the
 * same reason Fetch's are), so registering twice would echo the header twice. */
static int pr_enable(pTHX) {
    if (pr_on) return 1;                 /* once per process, not per app    */
    if (!pk_obs_add_req(aTHX_ pr_obs_req, NULL)) return 0;
    if (!pk_obs_add_res(aTHX_ pr_obs_res, NULL)) return 0;
    pr_on = 1;
    return 1;
}

#endif /* PUNK_REQID_H */
