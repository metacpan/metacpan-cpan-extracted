#ifndef PUNK_CGET_H
#define PUNK_CGET_H

/* Punk::Plugin::ConditionalGet - the strong validator.
 *
 *     get '/api/orders' => sub { ... }, {
 *         etag => sub { $_[0]->model('Order')->max_updated_at },
 *     };
 *
 * The application supplies something it knows cheaply that identifies the
 * entity. An unchanged one answers 304 WITHOUT RUNNING THE HANDLER: no
 * render, no queries, no serialisation. That is the whole point - the body
 * ETag saves bandwidth, this saves the server.
 *
 * ---- why this is here and not in a hook --------------------------------
 *
 * A web route runs the before_dispatch chain, THEN the route's guards, then
 * the handler. So a validator on the public before_dispatch hook would run
 * BEFORE authentication - and a user who has logged out, still holding a tag
 * from when they were logged in, would send it, get a 304, and their browser
 * would render the private page it still has instead of the login redirect
 * the guard would have produced. The plugin would have turned an
 * authorisation check into a cache hit.
 *
 * So the check sits between the guards and the handler, where no public hook
 * phase runs. Phase 0 recorded that gap rather than working around it: as it
 * stands, `before_dispatch` cannot be used for anything that must respect a
 * guard.
 */

/* Is this a method a 304 may answer? RFC 9110 13.1.3 - a conditional POST
 * means If-Match and optimistic concurrency, which is a different feature
 * wearing the same header family, and is deliberately out of scope. */
static int pcg_cond_method(const char *method, STRLEN mlen) {
    return (mlen == 3 && memEQ(method, "GET", 3))
        || (mlen == 4 && memEQ(method, "HEAD", 4));
}

/* A strong entity-tag from whatever the application returned.
 *
 * Quoting is done here so an application returning 42 and one returning "42"
 * cannot produce two different tags for one entity - the same rule
 * psf_respond already applies to its `etag` option.
 *
 * Strong, never W/: the application is asserting that this value identifies
 * the entity, which is exactly what a strong validator means. */
static SV *pcg_quote(pTHX_ SV *v) {
    STRLEN l;
    const char *p = SvPV_const(v, l);
    if (l >= 2 && p[0] == '"' && p[l - 1] == '"') return newSVpvn(p, l);
    {
        SV *out = newSVpvs("\"");
        STRLEN i;
        for (i = 0; i < l; i++) {
            /* A validator is application data - a column value, a build
             * revision - and it is about to become a response header. A quote
             * or a control byte in it would end the tag early or split the
             * response, so they are dropped rather than escaped: an
             * entity-tag has no escaping mechanism to use. */
            unsigned char ch = (unsigned char)p[i];
            if (ch < 0x21 || ch == '"' || ch == 0x7f) continue;
            sv_catpvn(out, (const char *)&ch, 1);
        }
        sv_catpvs(out, "\"");
        return out;
    }
}

/* Set a header on the response object the handler will add to, so the 200
 * carries the tag as well. A client never given a tag can never send one
 * back, which would make the whole feature inert on its second request.
 *
 * The response object is FORCED here even when the handler would never have
 * touched it - that is the cost of putting a tag on a plain `$c->text`
 * response, and it is one allocation on a route that opted in. */
static void pcg_set_etag(pTHX_ SV *c, SV *tag) {
    AV *cav = pcx_av(aTHX_ c);
    SV *resobj;
    AV *res, *hdrs;
    if (!cav) return;
    resobj = pcx_force(aTHX_ cav, PCX_RES, "Punk::Response", NULL);
    if (!resobj || !SvROK(resobj) || SvTYPE(SvRV(resobj)) != SVt_PVAV) return;
    res  = (AV *)SvRV(resobj);
    /* punk_res_headers, not pcx_res_headers: the second only reads, and a
     * response nothing has set a header on yet has no pair-AV to read - the
     * tag would be dropped on exactly the plain `$c->text` route this is
     * most worth having on. This is the accessor $c->header reaches. */
    hdrs = punk_res_headers(aTHX_ res);
    if (!hdrs) return;
    av_push(hdrs, newSVpvs("ETag"));
    av_push(hdrs, newSVsv(tag));
}

/* ---- the 304, in one place ---------------------------------------------------
 *
 * A 304 is a response whose correctness is mostly about what is ABSENT, and
 * getting that wrong produces the worst failure in this feature: a client
 * that waits for a body which will never arrive, or a cache that stores an
 * entry it can never validate again. Neither is caught by a test asserting
 * the status is 304.
 *
 * Both halves of this plugin build theirs here, and it has to agree with the
 * third producer in the dist - psf_respond's, for files - because two
 * answers to "what does a 304 look like" inside one framework is a bug
 * waiting for somebody to compare them.
 *
 * RFC 9110 15.4.5: send the headers that would have gone on the 200 and that
 * the cache needs to update its entry. So everything the response had
 * gathered is kept - Cache-Control, Vary, the security headers, the
 * Set-Cookie the session write-back just added - EXCEPT the ones describing
 * a representation that is not being sent.
 */

/* Does this header describe the representation rather than the resource?
 * Content-Length above all: a bodyless response that claims a length is how
 * a client is taught to wait. psf_respond's 304 sends none of these either. */
static int pcg_entity_header(pTHX_ const char *k, STRLEN l) {
    return (l == 12 && foldEQ(k, "Content-Type", 12))
        || (l == 14 && foldEQ(k, "Content-Length", 14))
        || (l == 16 && foldEQ(k, "Content-Encoding", 16));
}

/* The 304 triplet (+1), with `tag` (ownership moves) and everything in `src`
 * that a 304 may carry. src may be NULL - a route where nothing set a header
 * before the check ran. */
static SV *pcg_304(pTHX_ SV *tag, AV *src) {
    AV *resp = newAV(), *hdr = newAV(), *body = newAV();
    SSize_t i, n = src ? av_len(src) + 1 : 0;

    av_push(hdr, newSVpvs("ETag"));
    av_push(hdr, tag);                            /* ownership moves */
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(src, i, 0);
        SV **v = av_fetch(src, i + 1, 0);
        STRLEN kl;
        const char *kp;
        if (!(k && *k && SvOK(*k))) continue;
        kp = SvPV_const(*k, kl);
        if (pcg_entity_header(aTHX_ kp, kl)) continue;
        /* the tag just added wins over one already in the source - which is
         * the strong half's own, put there so the 200 would carry it */
        if (kl == 4 && foldEQ(kp, "ETag", 4)) continue;
        av_push(hdr, newSVsv(*k));
        av_push(hdr, (v && *v) ? newSVsv(*v) : newSV(0));
    }
    av_push(resp, newSViv(304));
    av_push(resp, newRV_noinc((SV *)hdr));
    av_push(resp, newRV_noinc((SV *)body));       /* empty: a 304 has no body */
    return newRV_noinc((SV *)resp);
}

/* The check, run between a route's guards and its handler.
 *
 * Returns 1 when the request has been ANSWERED and the handler must be
 * skipped, with exactly one of *out (the 304 triplet) and *errp (what the
 * validator croaked with) set. Returns 0 to carry on.
 *
 * A croaking validator is the app's 500, not a silent full response: it is
 * application code running before the handler, and swallowing its error
 * would hide a broken query behind a page that merely got slower.
 */
static int pcg_check(pTHX_ SV *c, HV *rech, HV *env, const char *method,
                     STRLEN mlen, SV **out, SV **errp) {
    SV **ep = hv_fetchs(rech, K_ETAG, 0);
    SV *cb, *val, *tag;
    int matched;

    *out = NULL;
    *errp = NULL;
    if (!ep || !*ep || !SvROK(*ep) || SvTYPE(SvRV(*ep)) != SVt_PVCV) return 0;
    if (!pcg_cond_method(method, mlen)) return 0;
    cb = *ep;

    {   /* The validator runs on EVERY request to the route, not only the
         * conditional ones: the 200 needs the tag too, and a client never
         * given one can never send one back. */
        dSP; int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1);
        PUSHs(c);
        PUTBACK;
        count = call_sv(cb, G_SCALAR | G_EVAL);
        SPAGAIN;
        val = count > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;
        if (SvTRUE(ERRSV)) {
            SvREFCNT_dec(val);
            *errp = newSVsv(ERRSV);
            return 1;
        }
    }

    /* undef means "I do not know", and the request proceeds with no ETag at
     * all. A validator that cannot answer must not be able to produce a wrong
     * 304, and saying so has to be cheaper to write than guessing. */
    if (!SvOK(val)) { SvREFCNT_dec(val); return 0; }

    tag = pcg_quote(aTHX_ val);
    SvREFCNT_dec(val);

    /* Two characters is an empty tag - nothing the validator returned
     * survived. Treat it as undef rather than emitting `""`, which every
     * client would then match against for ever. */
    if (SvCUR(tag) <= 2) { SvREFCNT_dec(tag); return 0; }

    pcg_set_etag(aTHX_ c, tag);

    {   STRLEN tl;
        const char *tp = SvPV_const(tag, tl);
        matched = psf_not_modified(aTHX_ env, tp, tl, NULL);
    }
    if (!matched) { SvREFCNT_dec(tag); return 0; }

    {   /* A 304 is a RESPONSE, not an absence of one. It goes back as an
         * ordinary triplet and through punk_finish_c like any other, so
         * everything that decorates a response still decorates it - the
         * session write-back, the security headers - and only the handler is
         * skipped.
         *
         * The headers a guard or a before_dispatch hook already set come with
         * it. They were set by code that DID run, on a request that is being
         * answered, and a `Vary` or a `Cache-Control` among them is exactly
         * what a 304 must not lose. */
        AV *cav = pcx_av(aTHX_ c);
        AV *res = cav ? pcx_res_av(aTHX_ cav) : NULL;
        *out = pcg_304(aTHX_ tag, res ? pcx_res_headers(aTHX_ res) : NULL);
        return 1;
    }
}

/* ---- the body ETag ----------------------------------------------------------
 *
 *     get '/dashboard' => sub { ... }, { etag => 1 };
 *
 * The rendered bytes are hashed and an unchanged response becomes a 304.
 *
 * BE HONEST ABOUT WHAT THIS BUYS. It saves the wire and the client's parse
 * and re-render, which on a polled JSON route is most of what the client was
 * spending. It saves the server NOTHING: the queries ran, the template
 * rendered, the encoder ran, and the hash is added cost on top - paid on
 * every request to the route, including the ones that end in a full 200.
 * Measured at ~3.5 us on a 1.7 KB body against a route that took 1.3 us to
 * produce it. Against a route that spends 5 ms in the database it is 0.07%
 * and worth having; against a route like that one it is not.
 *
 * It runs on the after-dispatch chain, which is public, and it is appended
 * LAST at compile: an application hook that rewrites the body must have
 * already run, or the tag would describe bytes nobody was sent. Being last
 * also puts it after the session write-back, which is why the 304 below
 * keeps the 200's headers rather than building a fresh set - dropping a
 * Set-Cookie the write-back had just added would log the user out. */

/* Weak, not strong: two responses with identical bytes are the same entity
 * for the purpose of not re-sending them, but nothing here can promise
 * byte-equality across a Vary axis this does not control, and a strong tag
 * would license If-Range on a body that has no ranges. */
static SV *pcg_body_tag(pTHX_ AV *body) {
    U32 h[8];
    unsigned char sum[32];
    char hex[PA_DIGEST_LEN + 1];
    unsigned char buf[64];
    size_t total = 0, rem = 0;
    SSize_t i, n = av_len(body) + 1;
    SV *out;

    memcpy(h, ps_sha256_iv, sizeof h);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(body, i, 0);
        const char *p;
        STRLEN l;
        if (!(e && *e && SvOK(*e))) continue;
        p = SvPV_const(*e, l);
        total += l;
        /* The pieces are hashed as one stream, so how the handler happened
         * to split its body does not change the tag: a template that
         * returns one string and one that returns three must agree. */
        while (l) {
            size_t take = (rem + l >= 64) ? 64 - rem : l;
            memcpy(buf + rem, p, take);
            rem += take; p += take; l -= take;
            if (rem == 64) { ps_sha256_blocks(h, buf, 1); rem = 0; }
        }
    }
    ps_sha256_final(h, buf, rem, total, sum);
    pa_hex(sum, PA_DIGEST_LEN / 2, hex);
    out = newSVpvs("W/\"");
    sv_catpvn(out, hex, PA_DIGEST_LEN);
    sv_catpvs(out, "\"");
    return out;
}

/* ---- what a validator does to a shared cache --------------------------------
 *
 * An ETag is a storage instruction. A response that is per-user, or
 * per-encoding, and that carries a validator with nothing saying what it
 * depends on, can be stored by any intermediary and handed to the next
 * request for the same URL - and then confidently revalidated, because now
 * there is a tag to revalidate with. For a per-user dashboard that is a
 * disclosure, and this plugin is exactly what will be reached for on those
 * routes.
 *
 * Two rules, and both resolve ambiguity by saying MORE rather than less. A
 * missing header costs a re-send; a wrong one costs correctness, and in the
 * authenticated case, confidentiality.
 */

/* Is a header present, and what is its value? */
static SV *pcg_hdr_get(pTHX_ AV *h, const char *name, STRLEN nl) {
    SSize_t i, n = h ? av_len(h) + 1 : 0;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(h, i, 0);
        STRLEN kl;
        const char *kp;
        if (!(k && *k && SvOK(*k))) continue;
        kp = SvPV_const(*k, kl);
        if (kl == nl && foldEQ(kp, name, nl)) {
            SV **v = av_fetch(h, i + 1, 0);
            return (v && *v) ? *v : &PL_sv_undef;
        }
    }
    return NULL;
}

/* The cache-safety pass, run over anything this plugin tagged - the 200 and
 * the 304, from either half. */
static void pcg_cache_safety(pTHX_ AV *h, HV *env) {
    if (!h) return;

    /* Vary: Accept-Encoding, always. Punk does not compress - Hyperman does,
     * on the write path, after Punk has stopped looking - so two clients,
     * one accepting gzip and one not, get the same entity and the same tag
     * from here and different BYTES from the server. A shared cache needs to
     * be told that, or it stores one and serves it to both. It is the same
     * reasoning that puts this header on every response from a static mount,
     * compressed or not, and it is the honest place for it: we are the ones
     * handing out the validator the cache will key on.
     *
     * Merged through pa_vary_add, so an application that already declared
     * what it varies on keeps every token it named. */
    pa_vary_add(aTHX_ h, "Accept-Encoding", 15);

    /* Cache-Control: private, when the response could be about one person
     * and the application has not said what it wants.
     *
     * Two signals, and the second is the one that matters. A Set-Cookie on
     * the RESPONSE is the obvious one - a session, an auth identity, a CSRF
     * mirror - but it is not enough on its own: a signed-in user reading a
     * page that changes nothing gets no write-back and no Set-Cookie, which
     * is precisely the per-user response somebody put an ETag on. So a
     * Cookie or Authorization on the REQUEST counts too.
     *
     * That is deliberately broad. A public page carrying an analytics
     * cookie loses shared-cache storage on the routes that opted into
     * ETags, which costs a re-send; the other direction costs one user
     * being handed another user's dashboard. An application that knows the
     * page is public says so, and is never overruled - it may have meant
     * `public` and known why.
     *
     * (Authorization is already covered for shared caches by RFC 9111 3.5;
     * saying `private` as well costs a header and covers the caches that
     * read this one and not that rule.) */
    if (!pcg_hdr_get(aTHX_ h, "Cache-Control", 13)) {
        int personal = pcg_hdr_get(aTHX_ h, "Set-Cookie", 10) ? 1 : 0;
        if (!personal && env) {
            SV **e = hv_fetchs(env, "HTTP_COOKIE", 0);
            if (e && *e && SvOK(*e) && SvCUR(*e)) personal = 1;
            else {
                e = hv_fetchs(env, "HTTP_AUTHORIZATION", 0);
                if (e && *e && SvOK(*e) && SvCUR(*e)) personal = 1;
            }
        }
        if (personal) {
            av_push(h, newSVpvs("Cache-Control"));
            av_push(h, newSVpvs("private"));
        }
    }
}

/* The after-dispatch hook: ($c, $triplet) -> a triplet, or nothing.
 *
 * It does two jobs, and runs for BOTH halves. For `etag => 1` it hashes the
 * body and may turn the response into a 304; for either half it then runs
 * the cache-safety pass, which has to happen here rather than at the check
 * because the Set-Cookie it reads is added by the session write-back - and
 * this hook is appended after that one. */
XS_INTERNAL(pcg_after_cb);
XS_INTERNAL(pcg_after_cb) {
    dXSARGS;
    SV *c, *resp;
    AV *ra, *hdrs = NULL, *body;
    SV **sp2, **hp, **bp;
    HV *env, *rech = NULL;
    const char *method;
    STRLEN mlen = 3;
    SV *tag;
    SSize_t i, hn;
    int strong = 0;

    if (items < 2) XSRETURN_EMPTY;
    c    = ST(0);
    resp = ST(1);
    if (!(SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVAV)) XSRETURN_EMPTY;
    ra = (AV *)SvRV(resp);

    {   /* the matched route, and its option. A route that did not ask for a
         * body ETag costs two hv_fetches on the way out, which is what an
         * app-wide hook has to cost when most routes are not using it. */
        AV *cav = pcx_av(aTHX_ c);
        SV *m = cav ? pcx_get(aTHX_ cav, PCX_MATCH) : NULL;
        SV **rp;
        if (!(m && SvROK(m) && SvTYPE(SvRV(m)) == SVt_PVHV)) XSRETURN_EMPTY;
        rp = hv_fetchs((HV *)SvRV(m), "route", 0);
        if (!(rp && *rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVHV))
            XSRETURN_EMPTY;
        rech = (HV *)SvRV(*rp);
    }
    {   /* the body ETag is `etag => 1`; a coderef is the strong validator,
         * which answered for itself before the handler ran and only wants
         * the cache-safety pass below */
        SV **et = hv_fetchs(rech, K_ETAG, 0);
        if (!(et && *et && SvOK(*et))) XSRETURN_EMPTY;
        strong = SvROK(*et) ? 1 : 0;
    }

    {   /* GET and HEAD. Only a 200 is hashed - an error response is not the
         * resource, and a 500 that renders identically twice must not be
         * cached as though it were - but a 304 still gets the cache-safety
         * pass, since it is the response a cache will store against. */
        AV *cav = pcx_av(aTHX_ c);
        SV *envsv = cav ? pcx_get(aTHX_ cav, PCX_ENV) : NULL;
        SV **stp = av_fetch(ra, 0, 0);
        IV status;
        if (!(envsv && SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV))
            XSRETURN_EMPTY;
        env = (HV *)SvRV(envsv);
        status = (stp && *stp) ? SvIV(*stp) : 0;
        sp2 = hv_fetchs(env, "REQUEST_METHOD", 0);
        method = (sp2 && *sp2 && SvOK(*sp2)) ? SvPV_const(*sp2, mlen) : "GET";
        if (!pcg_cond_method(method, mlen)) XSRETURN_EMPTY;
        if (status != 200 && status != 304) XSRETURN_EMPTY;

        /* the strong half, and any 304: nothing to hash, but the response
         * carries a validator and needs saying what it depends on */
        if (strong || status == 304) {
            SV **hh = av_fetch(ra, 1, 0);
            if (hh && *hh && SvROK(*hh) && SvTYPE(SvRV(*hh)) == SVt_PVAV)
                pcg_cache_safety(aTHX_ (AV *)SvRV(*hh), env);
            XSRETURN_EMPTY;
        }
    }

    hp = av_fetch(ra, 1, 0);
    bp = av_fetch(ra, 2, 0);
    if (hp && *hp && SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV)
        hdrs = (AV *)SvRV(*hp);
    /* Only an arrayref body can be hashed. A filehandle or a
     * Punk::SendFile::Reader would have to be consumed to be read, and a
     * send_file response already carries a strong validator of its own -
     * there is nothing to add there and something to break. */
    if (!(bp && *bp && SvROK(*bp) && SvTYPE(SvRV(*bp)) == SVt_PVAV))
        XSRETURN_EMPTY;
    body = (AV *)SvRV(*bp);

    /* A response that already carries a tag has been validated by something
     * that knew more than this does - send_file, or the strong validator on
     * the same route. Do not replace it. */
    hn = hdrs ? av_len(hdrs) + 1 : 0;
    for (i = 0; i + 1 < hn; i += 2) {
        SV **k = av_fetch(hdrs, i, 0);
        STRLEN kl;
        const char *kp;
        if (!(k && *k && SvOK(*k))) continue;
        kp = SvPV_const(*k, kl);
        if (kl == 4 && foldEQ(kp, "ETag", 4)) XSRETURN_EMPTY;
    }

    tag = pcg_body_tag(aTHX_ body);

    /* Compare the QUOTED part, not the `W/` prefix. psf_etag_in strips a
     * weak prefix off each list entry before comparing, so handing it our
     * own prefix would mean a tag we issued could never match itself coming
     * back - which looks exactly like a working feature that never 304s. */
    if (!psf_not_modified(aTHX_ env, SvPVX(tag) + 2, SvCUR(tag) - 2, NULL)) {
        if (hdrs) {                                  /* the 200 carries it */
            av_push(hdrs, newSVpvs("ETag"));
            av_push(hdrs, tag);
            pcg_cache_safety(aTHX_ hdrs, env);
        }
        else SvREFCNT_dec(tag);
        XSRETURN_EMPTY;                              /* the response stands */
    }

    /* the 304, through the one builder - the 200's headers minus the ones
     * describing a body that is no longer being sent. Everything else the
     * response gathered is kept, and being LAST on the after chain means
     * that includes the session write-back's Set-Cookie. */
    {
        SV *out = pcg_304(aTHX_ tag, hdrs);
        SV **h2 = av_fetch((AV *)SvRV(out), 1, 0);
        if (h2 && *h2 && SvROK(*h2))
            pcg_cache_safety(aTHX_ (AV *)SvRV(*h2), env);
        ST(0) = sv_2mortal(out);
    }
    XSRETURN(1);
}

#endif /* PUNK_CGET_H */
