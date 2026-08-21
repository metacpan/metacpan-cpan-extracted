/* punk_idem.h - Punk::Plugin::Idempotency.
 *
 *     plugin 'Idempotency' => { scope => sub { $_[0]->current_user->{id} } };
 *     post '/orders' => sub { ... }, { idempotent => 1 };
 *
 * A client that sends POST /orders and loses the connection cannot know
 * whether the order was created. It has two choices and both are bad: retry
 * and risk two orders, or give up and risk none. An `Idempotency-Key`
 * removes the choice - the server recognises the retry and replays the first
 * response.
 *
 * ---- what this guarantees, exactly -------------------------------------
 *
 * A retry carrying the same key, WITHIN THE TTL, that reaches a worker able
 * to see the store, AFTER the first request's response was recorded, replays
 * that response instead of executing the work again.
 *
 * Every clause is load-bearing, and the last one is a window: between the
 * handler committing the order and the entry reaching the store, this
 * provides nothing. A process killed there leaves an order created and no
 * key recorded, so the retry executes and creates a second one - the exact
 * failure the plugin exists to prevent, in the one situation where a client
 * is most likely to retry.
 *
 * CACHE-BACKED IDEMPOTENCY COLLAPSES THAT WINDOW. IT DOES NOT REMOVE IT.
 * Closing it needs the key written inside the same transaction as the work,
 * which means the store has to BE the database - and the plugin does not own
 * the handler's transaction. So the store is reached through a narrow seam
 * (read, write, lock) that a database-backed implementation could take over,
 * rather than through Punk::Cache calls scattered across this file.
 *
 * ---- where the two halves run ------------------------------------------
 *
 * Replay is between a route's GUARDS and its handler. Not before_dispatch,
 * which runs ahead of the guards: a replay returns a STORED RESPONSE BODY,
 * so answering there hands somebody else's order to a caller the guard was
 * about to refuse. Not a timing leak - the document.
 *
 * Recording is last on the after-dispatch chain, so what is stored is what
 * was actually sent, after every application hook has had its say.
 *
 * Include after punk_cachefront.h (the store), punk_request.h (pq_body) and
 * punk_session.h (ps_stash).
 */

#ifndef PUNK_IDEM_H
#define PUNK_IDEM_H

#define PI_STASH_KEY "punk.idem"
#define PI_HEADER    "HTTP_IDEMPOTENCY_KEY"

/* ---- the inbound key is request bytes ---------------------------------------
 *
 * It reaches a cache key, and with the file store a cache key reaches the
 * filesystem. That is the bug class this workspace keeps meeting
 * (CVE-2026-75628, the markdown 301, the Reverse::Proxy smuggling fix), so
 * the rules are Punk::Plugin::RequestId's for an adopted id, for the same
 * reasons: bounded, a conservative charset, and REFUSED rather than repaired.
 *
 * Repairing is the subtle half. Trimming a bad key into a good one means two
 * different client keys can become one server key, which is the collision
 * this whole file exists to prevent. */
static int pi_key_valid(const char *k, STRLEN l) {
    STRLEN i;
    if (l < 1 || l > 255) return 0;
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)k[i];
        if (c <= 0x20 || c >= 0x7f) return 0;   /* no CR, LF, NUL, tab, space */
    }
    return 1;
}

/* The methods a key means anything on. GET is already idempotent, and
 * storing responses to it is Punk::Cache - a different feature with expiry
 * semantics an application chooses deliberately. */
static int pi_unsafe_method(const char *m, STRLEN l) {
    return (l == 4 && memEQ(m, "POST", 4))
        || (l == 3 && memEQ(m, "PUT", 3))
        || (l == 5 && memEQ(m, "PATCH", 5))
        || (l == 6 && memEQ(m, "DELETE", 6));
}

static void pi_sha256_hex(pTHX_ const char *p, STRLEN l, char *out) {
    unsigned char sum[32];
    pk_sha256((const unsigned char *)p, (size_t)l, sum);
    pa_hex(sum, 16, out);                        /* 32 hex characters */
}

/* A warn line on the request logger, so it carries the request id and the
 * method and path the rest of the log has. Built the way $c->log builds it,
 * and cached in the stash the same way, so this does not make a second
 * logger per request. */
static void pi_warn(pTHX_ SV *c, const char *msg) {
    AV *av = pcx_av(aTHX_ c);
    SV *st, *lg = NULL;
    HV *stash;
    SV **cached;
    if (!av) return;
    st = pcx_get(aTHX_ av, PCX_STASH);
    if (!st) {
        st = newRV_noinc((SV *)newHV());
        (void)av_store(av, PCX_STASH, st);
    }
    stash = (HV *)SvRV(st);
    cached = hv_fetchs(stash, "punk.logger", 0);
    if (cached && *cached && SvROK(*cached)) lg = *cached;
    else {
        lg = pl_make_logger(aTHX_ pcx_get(aTHX_ av, PCX_APP), c);
        (void)hv_stores(stash, "punk.logger", newSVsv(lg));
        lg = *hv_fetchs(stash, "punk.logger", 0);
    }
    pl_emit(aTHX_ lg, PL_WARN, sv_2mortal(newSVpv(msg, 0)), NULL);
}

/* ---- the composite key ------------------------------------------------------
 *
 *     idem:<scope>:<METHOD> <declared path>:<hash of the client key>
 *
 * The scope, because one account's key must never collide with another's -
 * the stored value is a whole response, so a collision is a way to read
 * somebody else's order by guessing a UUID.
 *
 * The route as DECLARED (/orders/:id, not /orders/7), because the same key
 * against two endpoints is a client bug that must surface rather than replay
 * one endpoint's answer for the other. The method is in there with it:
 * POST /orders and DELETE /orders are different operations a client could
 * legitimately key the same way.
 *
 * The client's key HASHED rather than interpolated. The file store already
 * hashes and shards its keys - a key never becomes a path there - but this
 * does not depend on that: a backend that stored keys more literally would
 * still get 32 hex characters from us. */
static SV *pi_composite(pTHX_ SV *scope, HV *rech, const char *method,
                        STRLEN mlen, const char *key, STRLEN klen) {
    char hex[33];
    SV **pp = hv_fetchs(rech, K_PATH, 0);
    SV *out = newSVpvs("idem:");
    pi_sha256_hex(aTHX_ key, klen, hex);
    if (scope && SvOK(scope)) sv_catsv(out, scope);
    sv_catpvs(out, ":");
    sv_catpvn(out, method, mlen);
    sv_catpvs(out, " ");
    if (pp && *pp && SvOK(*pp)) sv_catsv(out, *pp);
    sv_catpvs(out, ":");
    sv_catpvn(out, hex, 32);
    return out;
}

/* The request fingerprint: the method, the declared route and the body.
 *
 * A key reused with a DIFFERENT body is a client bug, and a silent replay of
 * an unrelated response is the worst possible answer - the client believes
 * its second, different order succeeded, and it never ran.
 *
 * $c->req->body reads once and rewinds, so this costs one hash of bytes
 * already in memory rather than a second read of the socket. */
static SV *pi_fingerprint(pTHX_ SV *c, HV *rech, const char *method,
                          STRLEN mlen) {
    AV *cav = pcx_av(aTHX_ c);
    SV *reqsv = cav ? pcx_req(aTHX_ cav) : NULL;
    SV *acc = newSVpvn(method, mlen);
    SV **pp = hv_fetchs(rech, K_PATH, 0);
    char hex[33];
    sv_catpvs(acc, " ");
    if (pp && *pp && SvOK(*pp)) sv_catsv(acc, *pp);
    sv_catpvs(acc, "\n");
    if (reqsv && SvROK(reqsv) && SvTYPE(SvRV(reqsv)) == SVt_PVAV) {
        SV *b = pq_body(aTHX_ (AV *)SvRV(reqsv));
        if (b && SvOK(b)) sv_catsv(acc, b);
    }
    pi_sha256_hex(aTHX_ SvPVX(acc), SvCUR(acc), hex);
    SvREFCNT_dec(acc);
    return newSVpvn(hex, 32);
}

/* ---- the store seam ---------------------------------------------------------
 * Three operations, and nothing else reaches the cache from here: read, write
 * with a TTL, and a best-effort lock. A database-backed store closing the
 * window would implement these three. */

static punk_cachefront *pi_store(pTHX_ SV *c, SV **errp) {
    AV *cav = pcx_av(aTHX_ c);
    SV *app = cav ? pcx_get(aTHX_ cav, PCX_APP) : NULL;
    SV **built = NULL, **slot = NULL;
    *errp = NULL;
    if (app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV)
        built = hv_fetchs((HV *)SvRV(app), "cache", 0);
    if (built && *built && SvROK(*built) && SvTYPE(SvRV(*built)) == SVt_PVHV)
        slot = hv_fetchs((HV *)SvRV(*built), K_DEFAULT, 0);
    if (!(slot && *slot && SvOK(*slot))) {
        *errp = newSVpvs("Punk::Plugin::Idempotency: no cache configured - "
                         "add a `cache` keyword for the keys to live in\n");
        return NULL;
    }
    return pkc_of(aTHX_ *slot);
}

/* ---- the stored entry -------------------------------------------------------
 * [ status, [ header pairs ], body, fingerprint ], JSON through the ABI Punk
 * already consumes. The cache stores bytes; this decodes at the edge. */

static SV *pi_encode(pTHX_ AV *ra, SV *fp) {
    AV *out = newAV();
    SV **st = av_fetch(ra, 0, 0), **hp = av_fetch(ra, 1, 0),
       **bp = av_fetch(ra, 2, 0);
    SV *body = newSVpvs("");
    av_push(out, newSViv(st && *st ? SvIV(*st) : 200));
    if (hp && *hp && SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV) {
        AV *h = (AV *)SvRV(*hp), *h2 = newAV();
        SSize_t i, n = av_len(h) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(h, i, 0);
            av_push(h2, (e && *e) ? newSVsv(*e) : newSV(0));
        }
        av_push(out, newRV_noinc((SV *)h2));
    }
    else av_push(out, newRV_noinc((SV *)newAV()));
    if (bp && *bp && SvROK(*bp) && SvTYPE(SvRV(*bp)) == SVt_PVAV) {
        AV *b = (AV *)SvRV(*bp);
        SSize_t i, n = av_len(b) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(b, i, 0);
            if (e && *e && SvOK(*e)) sv_catsv(body, *e);
        }
    }
    av_push(out, body);
    av_push(out, newSVsv(fp));
    return sv_2mortal(newRV_noinc((SV *)out));
}

/* The replay triplet from a stored entry (+1), or NULL when the entry is not
 * the shape this wrote (a store shared with something else, or a format from
 * a previous version - a miss is always safer than a guess). */
static SV *pi_replay(pTHX_ SV *entry, SV *fp_now, int *conflict) {
    AV *e;
    SV **st, **hp, **bp, **fp;
    AV *resp, *hdr, *body;
    *conflict = 0;
    if (!(entry && SvROK(entry) && SvTYPE(SvRV(entry)) == SVt_PVAV)) return NULL;
    e = (AV *)SvRV(entry);
    if (av_len(e) < 3) return NULL;
    st = av_fetch(e, 0, 0); hp = av_fetch(e, 1, 0);
    bp = av_fetch(e, 2, 0); fp = av_fetch(e, 3, 0);
    if (!(st && *st && hp && *hp && bp && *bp && fp && *fp)) return NULL;

    /* the same key attached to a different request: a client bug, and the
     * one answer that must never be a replay */
    if (!sv_eq(*fp, fp_now)) { *conflict = 1; return NULL; }

    hdr = newAV();
    if (SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV) {
        AV *h = (AV *)SvRV(*hp);
        SSize_t i, n = av_len(h) + 1;
        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(h, i, 0);
            SV **v = av_fetch(h, i + 1, 0);
            STRLEN kl;
            const char *kp;
            if (!(k && *k && SvOK(*k))) continue;
            kp = SvPV_const(*k, kl);
            /* A stored Set-Cookie is NOT replayed, and this is the one
             * deliberate exception to "return what they got". That cookie
             * carries the first request's session state; handing it to a
             * retry - which may arrive from a newer session, or another tab -
             * writes back a stale session. The entry keeps it, because the
             * entry is a faithful record of what was sent; the replay drops
             * it. */
            if (kl == 10 && foldEQ(kp, "Set-Cookie", 10)) continue;
            av_push(hdr, newSVsv(*k));
            av_push(hdr, (v && *v) ? newSVsv(*v) : newSV(0));
        }
    }
    /* A client that cannot tell a replay from a fresh execution cannot debug
     * anything, and neither can the application's own log. */
    av_push(hdr, newSVpvs("Idempotency-Replayed"));
    av_push(hdr, newSVpvs("true"));

    body = newAV();
    av_push(body, newSVsv(*bp));
    resp = newAV();
    av_push(resp, newSViv(SvIV(*st)));
    av_push(resp, newRV_noinc((SV *)hdr));
    av_push(resp, newRV_noinc((SV *)body));
    return newRV_noinc((SV *)resp);
}

/* A small JSON error triplet, the shape the dispatcher's own 404 and 405
 * use, so a refusal from here does not look foreign beside them. */
static SV *pi_error(pTHX_ IV status, const char *msg) {
    SV *body = newSVpvs("{\"errors\":[{\"message\":\"");
    AV *resp = newAV(), *hdr = newAV(), *bav = newAV();
    sv_catpv(body, (char *)msg);
    sv_catpvs(body, "\"}]}");
    av_push(hdr, newSVpvs("Content-Type"));
    av_push(hdr, newSVpvs("application/json"));
    av_push(hdr, newSVpvs("Content-Length"));
    av_push(hdr, newSViv((IV)SvCUR(body)));
    av_push(bav, body);
    av_push(resp, newSViv(status));
    av_push(resp, newRV_noinc((SV *)hdr));
    av_push(resp, newRV_noinc((SV *)bav));
    return newRV_noinc((SV *)resp);
}

/* ---- the replay check, between the guards and the handler --------------------
 *
 * Returns 1 when the request has been ANSWERED (*out) and the handler must be
 * skipped; 0 to carry on, having left what the recorder needs in the stash.
 */
static int pi_check(pTHX_ SV *c, HV *rech, HV *env, const char *method,
                    STRLEN mlen, SV *cfg, SV **out, SV **errp) {
    SV **kp;
    const char *key;
    STRLEN klen;
    SV *scope = NULL, *comp, *fp, *entry = NULL;
    punk_cachefront *f;
    HV *ocfg;

    *out = NULL; *errp = NULL;
    if (!(cfg && SvROK(cfg) && SvTYPE(SvRV(cfg)) == SVt_PVHV)) return 0;
    ocfg = (HV *)SvRV(cfg);
    if (!pi_unsafe_method(method, mlen)) return 0;

    kp = hv_fetchs(env, PI_HEADER, 0);
    /* No key is not an error. Requiring one is an API decision an
     * application makes in a guard - some endpoints want to refuse an
     * unkeyed write, most do not care - and a plugin that imposed it would
     * break the second kind. */
    if (!(kp && *kp && SvOK(*kp) && SvCUR(*kp))) return 0;
    key = SvPV_const(*kp, klen);
    if (!pi_key_valid(key, klen)) {
        *out = pi_error(aTHX_ 400,
            "Idempotency-Key must be 1 to 255 printable ASCII characters "
            "with no space");
        return 1;
    }

    {   /* the scope: the application's, and there is no default. The plugin
         * cannot know what an account is - a session, an auth identity, an
         * OAuth2 token, an API key are four this workspace already ships -
         * and inventing one means picking one and being silently wrong for
         * the rest. */
        SV **sc = hv_fetchs(ocfg, "scope", 0);
        dSP; int count;
        if (!(sc && *sc && SvROK(*sc) && SvTYPE(SvRV(*sc)) == SVt_PVCV))
            return 0;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(c); PUTBACK;
        count = call_sv(*sc, G_SCALAR | G_EVAL);
        SPAGAIN;
        scope = count > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;
        if (SvTRUE(ERRSV)) {
            SvREFCNT_dec(scope);
            *errp = newSVsv(ERRSV);
            return 1;
        }
    }

    /* An undefined scope means the plugin cannot say whose key this is, and
     * it will not invent an answer: the request proceeds as though the
     * plugin were not there, and nothing is stored. An application that
     * wants idempotency for anonymous callers - a signup, a payment carrying
     * its own token - returns something itself; it is a coderef, and that
     * puts the decision with the person able to make it safely. */
    if (!SvOK(scope)) {
        SvREFCNT_dec(scope);
        pi_warn(aTHX_ c,
               "idempotency: scope returned undef, so this request is not "
               "idempotent - see Punk::Plugin::Idempotency");
        return 0;
    }

    f = pi_store(aTHX_ c, errp);
    if (!f) { SvREFCNT_dec(scope); return *errp ? 1 : 0; }

    comp = pi_composite(aTHX_ scope, rech, method, mlen, key, klen);
    SvREFCNT_dec(scope);
    sv_2mortal(comp);
    fp = sv_2mortal(pi_fingerprint(aTHX_ c, rech, method, mlen));

    {   /* Look, and on a miss take the lock so two retries arriving together
         * do not both execute. Hyperman serves a worker's requests one at a
         * time, so the concurrency is ACROSS workers - which is exactly the
         * arrangement a dropped connection produces.
         *
         * pkc_be_get, NOT pkc_read: the read goes STRAIGHT TO THE BACKEND
         * and never through the memory tier. A tier is a copy per worker,
         * eventually consistent and invalidated best-effort, and that trade
         * is right for a cache and wrong here - a tier that has not yet seen
         * a write answers "no entry", and "no entry" means execute the work
         * a second time. The failure is in the dangerous direction, so the
         * plugin does not use the tier for its own keys even when the
         * application configured one. */
        SV *raw = pkc_be_get(aTHX_ f, comp, NULL);
        if (raw) entry = pkc_ready(aTHX_ raw, 1);
        if (!entry && (f->caps & PKC_CAN_LOCK) && !pkc_be_lock(aTHX_ f, comp)) {
            double deadline = pc_now(aTHX) + pkc_be_lock_wait(aTHX_ f);
            while (pc_now(aTHX) < deadline) {
                pkc_sleep(0.002);
                raw = pkc_be_get(aTHX_ f, comp, NULL);
                if (raw) { entry = pkc_ready(aTHX_ raw, 1); break; }
                if (pkc_be_lock(aTHX_ f, comp)) break;  /* the holder gave up */
            }
            /* waited it out with nothing to replay: execute rather than
             * hang. Duplicated work is a cost; a stalled request is an
             * outage. The same rule Punk::Cache's compute follows. */
        }
    }

    if (entry) {
        int conflict = 0;
        SV *rep = pi_replay(aTHX_ entry, fp, &conflict);
        SvREFCNT_dec(entry);
        if (f->caps & PKC_CAN_UNLOCK) pkc_be_unlock(aTHX_ f, comp);
        if (conflict) {
            *out = pi_error(aTHX_ 422,
                "Idempotency-Key was already used for a different request");
            return 1;
        }
        if (rep) { *out = rep; return 1; }
        /* an entry we cannot read is a miss, and a miss re-executes */
    }

    {   /* what the recorder needs, left where it can find it */
        AV *cav = pcx_av(aTHX_ c);
        HV *stash = ps_stash(aTHX_ cav);
        AV *pending = newAV();
        av_push(pending, newSVsv(comp));
        av_push(pending, newSVsv(fp));
        (void)hv_stores(stash, PI_STASH_KEY, newRV_noinc((SV *)pending));
    }
    return 0;
}

/* ---- the recorder, last on the after chain ---------------------------------- */

XS_INTERNAL(pi_record_cb);
XS_INTERNAL(pi_record_cb) {
    dXSARGS;
    SV *c, *resp;
    AV *cav, *ra;
    HV *stash;
    SV **pend, **st, **bp;
    AV *pending;
    IV status;
    punk_cachefront *f;
    SV *err = NULL;
    AV *cap = punk_clos_cap(aTHX_ cv);
    NV ttl = 86400;

    if (items < 2) XSRETURN_EMPTY;
    c = ST(0); resp = ST(1);
    cav = pcx_av(aTHX_ c);
    if (!cav) XSRETURN_EMPTY;
    stash = ps_stash(aTHX_ cav);
    pend = hv_fetchs(stash, PI_STASH_KEY, 0);
    if (!(pend && *pend && SvROK(*pend) && SvTYPE(SvRV(*pend)) == SVt_PVAV))
        XSRETURN_EMPTY;                        /* not an idempotent request */
    pending = (AV *)SvRV(*pend);
    if (av_len(pending) < 1) XSRETURN_EMPTY;
    /* Once: a second after-hook pass must not write twice. The reference is
     * taken BEFORE the delete - hv_delete with G_DISCARD frees the value,
     * and everything below still reads through `pending`, so deleting first
     * is a use-after-free that survives every small test and crashes under
     * a real one. */
    sv_2mortal(SvREFCNT_inc((SV *)pending));
    (void)hv_delete(stash, PI_STASH_KEY, sizeof(PI_STASH_KEY) - 1, G_DISCARD);

    if (cap) {
        SV **t = av_fetch(cap, 0, 0);
        if (t && *t && SvOK(*t)) ttl = SvNV(*t);
    }

    f = pi_store(aTHX_ c, &err);
    if (err) SvREFCNT_dec(err);
    if (!f) XSRETURN_EMPTY;

    if (!(SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVAV)) goto unrecorded;
    ra = (AV *)SvRV(resp);
    st = av_fetch(ra, 0, 0);
    bp = av_fetch(ra, 2, 0);
    status = (st && *st) ? SvIV(*st) : 0;

    /* 2xx, 3xx and 4xx are recorded; 5xx is not.
     *
     * A 5xx is transient by construction, and replaying one turns a single
     * bad minute into a permanent bad day for the life of the TTL: the
     * client retries, gets the stored 500 instantly, retries again, and the
     * endpoint is broken for that key until it expires. Exactly backwards.
     *
     * A 4xx IS recorded, which is less obvious: a 422 for a malformed order
     * is a real answer about that request, and replaying it is correct. */
    if (status < 200 || status >= 500) goto unrecorded;

    /* Only an arrayref body can be stored. A filehandle or a reader would
     * have to be consumed to be recorded, and consuming it is the response. */
    if (!(bp && *bp && SvROK(*bp) && SvTYPE(SvRV(*bp)) == SVt_PVAV))
        goto unrecorded;

    {
        SV *fp = *av_fetch(pending, 1, 0);
        SV *key = *av_fetch(pending, 0, 0);
        SV *val = pi_encode(aTHX_ ra, fp);
        SV *bytes = sv_2mortal(punk_frj(aTHX)->encode(aTHX_ val, NULL));
        SV *r = pkc_be_set(aTHX_ f, key, bytes, ttl);
        if (r) SvREFCNT_dec(r);
        if (f->caps & PKC_CAN_UNLOCK) pkc_be_unlock(aTHX_ f, key);
    }
    XSRETURN_EMPTY;

  unrecorded:
    /* The window's only symptom an operator will ever see. A response that
     * was NOT recorded means the next retry re-executes, and without this
     * line a doubled order is indistinguishable from a client bug. */
    {
        SV *key = *av_fetch(pending, 0, 0);
        if (f->caps & PKC_CAN_UNLOCK) pkc_be_unlock(aTHX_ f, key);
        pi_warn(aTHX_ c,
               "idempotency: response not recorded, so a retry of this key "
               "will execute again");
    }
    XSRETURN_EMPTY;
}

#endif /* PUNK_IDEM_H */
