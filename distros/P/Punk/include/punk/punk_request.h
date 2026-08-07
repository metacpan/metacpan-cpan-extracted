/* punk_request.h - C request parsing (the Punk::Request hot methods).
 *
 * The object is a plain blessed AV whose slot layout is shared with
 * lib/Punk/Request.pm (the pure-Perl reference tier) - keep the enum
 * below in sync with the constants there. Parsing semantics mirror the
 * Perl exactly: pairs split on '&'/';', keys split on the first '=',
 * '+' and %XX percent-decoding, repeated keys promote to arrayrefs,
 * cookie values decode with first-value-wins. body() stays Perl (I/O);
 * form() calls it through the method interface once, then caches.
 */

#ifndef PUNK_REQUEST_H
#define PUNK_REQUEST_H

enum {
    PQ_ENV     = 0,
    PQ_QUERY   = 1,
    PQ_FORM    = 2,
    PQ_COOKIES = 3,
    PQ_BODY    = 4,
    PQ_READ    = 5,
    PQ_UPLOADS = 6
};

static AV *punk_req_av(pTHX_ SV *self) {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
        croak("Punk::Request: not a request object");
    return (AV *)SvRV(self);
}

static HV *punk_req_env(pTHX_ AV *req) {
    SV **e = av_fetch(req, PQ_ENV, 0);
    if (!e || !*e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVHV)
        croak("Punk::Request: no PSGI environment");
    return (HV *)SvRV(*e);
}

/* Every request header, as a hash keyed the way HTTP/2 and most Perl web
 * code spell them: HTTP_X_FORWARDED_FOR -> 'x-forwarded-for', lowercased
 * with dashes. CONTENT_TYPE is folded in because PSGI stores it (and
 * CONTENT_LENGTH) without the HTTP_ prefix, so a caller walking HTTP_*
 * alone would silently miss it.
 *
 * content-length is deliberately left to the caller: Punk::Request takes it
 * from the environment, while the OpenAPI validation path takes the length
 * it actually read off psgi.input, which is the one the body was framed by.
 *
 * Owned (+1). */
static HV *pq_headers(pTHX_ HV *env) {
    HV *out = newHV();
    HE *he;
    SV **e;
    if (!env) return out;

    hv_iterinit(env);
    while ((he = hv_iternext(env))) {
        I32 kl;
        const char *k = hv_iterkey(he, &kl);
        char stackbuf[64], *lname;
        STRLEN nl, i;
        if (!(kl > 5 && memEQ(k, "HTTP_", 5))) continue;
        nl = (STRLEN)(kl - 5);
        lname = nl < sizeof stackbuf ? stackbuf : (char *)safemalloc(nl);
        for (i = 0; i < nl; i++) {
            char c = k[5 + i];
            lname[i] = (c == '_') ? '-' : (char)toLOWER((U8)c);
        }
        (void)hv_store(out, lname, (I32)nl,
                       newSVsv(hv_iterval(env, he)), 0);
        if (lname != stackbuf) safefree(lname);
    }

    e = hv_fetchs(env, "CONTENT_TYPE", 0);
    if (e && *e && SvOK(*e)) {
        STRLEN vl;
        (void)SvPV_const(*e, vl);      /* not SvCUR: it may not be a PV yet */
        if (vl) (void)hv_stores(out, "content-type", newSVsv(*e));
    }
    return out;
}

/* %XX / '+' decode of [s, s+len) into a fresh SV (owned). */
static SV *pq_decode(pTHX_ const char *s, STRLEN len) {
    SV *out = newSV(len + 1);
    char *d;
    STRLEN i, o = 0;
    SvPOK_on(out);
    d = SvPVX(out);
    for (i = 0; i < len; i++) {
        char c = s[i];
        if (c == '+') d[o++] = ' ';
        else if (c == '%' && i + 2 < len
                 && isXDIGIT((U8)s[i + 1]) && isXDIGIT((U8)s[i + 2])) {
            unsigned hi = isDIGIT((U8)s[i+1]) ? (unsigned)(s[i+1] - '0')
                        : (unsigned)((s[i+1] | 0x20) - 'a' + 10);
            unsigned lo = isDIGIT((U8)s[i+2]) ? (unsigned)(s[i+2] - '0')
                        : (unsigned)((s[i+2] | 0x20) - 'a' + 10);
            d[o++] = (char)((hi << 4) | lo);
            i += 2;
        }
        else d[o++] = c;
    }
    d[o] = '\0';
    SvCUR_set(out, o);
    return out;
}

/* One decoded pair into the hash, promoting repeats to an arrayref. */
static void pq_store_pair(pTHX_ HV *out,
                          const char *k, STRLEN kl,
                          const char *v, STRLEN vl) {
    SV *key = sv_2mortal(pq_decode(aTHX_ k, kl));
    SV *val = pq_decode(aTHX_ v, vl);
    HE *he  = hv_fetch_ent(out, key, 0, 0);
    if (he) {
        SV *have = HeVAL(he);
        AV *list;
        if (SvROK(have) && SvTYPE(SvRV(have)) == SVt_PVAV)
            list = (AV *)SvRV(have);
        else {
            list = newAV();
            av_push(list, newSVsv(have));
            (void)hv_store_ent(out, key, newRV_noinc((SV *)list), 0);
        }
        av_push(list, val);
    }
    else (void)hv_store_ent(out, key, val, 0);
}

/* application/x-www-form-urlencoded pairs -> owned HV. */
static HV *pq_parse_pairs(pTHX_ const char *s, STRLEN len) {
    HV *out = newHV();
    STRLEN start = 0, i;
    for (i = 0; i <= len; i++) {
        if (i == len || s[i] == '&' || s[i] == ';') {
            if (i > start) {
                const char *pair = s + start;
                STRLEN plen = i - start, j, eq = plen;
                for (j = 0; j < plen; j++)
                    if (pair[j] == '=') { eq = j; break; }
                pq_store_pair(aTHX_ out, pair, eq,
                              eq < plen ? pair + eq + 1 : "",
                              eq < plen ? plen - eq - 1 : 0);
            }
            start = i + 1;
        }
    }
    return out;
}

/* The Cookie header -> owned HV; first value wins, values decoded. */
static HV *pq_parse_cookies(pTHX_ const char *s, STRLEN len) {
    HV *out = newHV();
    STRLEN start = 0, i;
    for (i = 0; i <= len; i++) {
        if (i == len || s[i] == ';') {
            if (i > start) {
                const char *pair = s + start;
                STRLEN plen = i - start, j, eq = plen;
                for (j = 0; j < plen; j++)
                    if (pair[j] == '=') { eq = j; break; }
                if (eq > 0) {
                    SV *key = sv_2mortal(newSVpvn(pair, eq));
                    if (!hv_exists_ent(out, key, 0)) {
                        SV *val = eq < plen
                            ? pq_decode(aTHX_ pair + eq + 1, plen - eq - 1)
                            : newSVpvs("");
                        (void)hv_store_ent(out, key, val, 0);
                    }
                }
            }
            start = i + 1;
            /* Perl splits on semicolon-plus-whitespace: eat the spaces */
            while (start < len && isSPACE((U8)s[start])) start++;
            i = start - 1;
        }
    }
    return out;
}

/* Cached-slot access: return the slot's hashref, building it with
 * `build` on first use. The returned SV is the live cached ref. */
static SV *pq_cached(pTHX_ AV *req, I32 slot, HV *built) {
    SV *rv = newRV_noinc((SV *)built);
    (void)av_store(req, slot, rv);
    return rv;
}

/* The raw request body: read CONTENT_LENGTH bytes from psgi.input via
 * PerlIO on first call (then rewind, matching the Perl semantics),
 * cache in the BODY slot. Returns the cached SV (borrowed) - undef SV
 * when there is no body. sv_2io croaks on a non-handle the same way
 * the read builtin would. */
static SV *pq_body(pTHX_ AV *req) {
    SV **flag = av_fetch(req, PQ_READ, 0);
    SV **b;
    if (!(flag && *flag && SvTRUE(*flag))) {
        HV *env = punk_req_env(aTHX_ req);
        SV **in = hv_fetchs(env, "psgi.input", 0);
        SV **cl = hv_fetchs(env, "CONTENT_LENGTH", 0);
        IV len  = (cl && *cl && SvOK(*cl)) ? SvIV(*cl) : 0;
        (void)av_store(req, PQ_READ, newSViv(1));
        if (in && *in && SvTRUE(*in) && len > 0) {
            IO *io = sv_2io(*in);
            PerlIO *fp = io ? IoIFP(io) : NULL;
            if (fp) {
                SV *raw = newSV(len + 1);
                char *d;
                IV got = 0;
                SvPOK_on(raw);
                d = SvPVX(raw);
                while (got < len) {
                    SSize_t n = PerlIO_read(fp, d + got, (Size_t)(len - got));
                    if (n <= 0) break;
                    got += (IV)n;
                }
                d[got] = '\0';
                SvCUR_set(raw, (STRLEN)got);
                (void)PerlIO_seek(fp, 0, SEEK_SET);
                (void)av_store(req, PQ_BODY, raw);
            }
            else (void)av_store(req, PQ_BODY, newSV(0));
        }
        else (void)av_store(req, PQ_BODY, newSV(0));
    }
    b = av_fetch(req, PQ_BODY, 0);
    return b && *b ? *b : &PL_sv_undef;
}

#endif /* PUNK_REQUEST_H */
