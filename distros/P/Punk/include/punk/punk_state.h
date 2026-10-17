/* punk_state.h - the compiled application as a C struct.
 *
 * to_app freezes the application into a hash of named entries (router,
 * records, mounts, hooks, policies) that the request path used to read by
 * name: about twenty hv_fetch per request, each a strlen and a hash of a
 * constant key, plus six more on the matched route's record and a stash
 * lookup by class name for the context. All of it is known at compile time.
 *
 * So the hash is read ONCE, here, into a struct the app closure carries
 * beside it. Every pointer is borrowed from the hash, which the same closure
 * capture owns and which outlives the struct; the struct owns only the
 * record mirror it allocates. Nothing outside this translation unit reads
 * the hash by key (the plugin dists attach through on_compile, the observers
 * and the context slots), so the hash could go; it stays because it is the
 * shape `punk routes` and the tests know, and it costs nothing per request.
 *
 * The record mirror holds the fields the dispatcher reads from a matched
 * route's record on every request, indexed by the record index the router
 * returns. A record hash is never written after to_app (on_compile and
 * compile_extras run before the state is built), which is what makes a
 * mirror frozen here true for the life of the app.
 */

#ifndef PUNK_STATE_H
#define PUNK_STATE_H

typedef struct {
    SV *code;                /* the handler, borrowed; may be undef       */
    AV *guards;              /* NULL when the route has none              */
    IV  max_body;            /* valid when has_max_body                   */
    unsigned char has_max_body, etag, idempotent, ws, sse, nocompress;
} pk_rec_c;

typedef struct {
    HV *hv;                  /* the state hash, for anything rare         */
    SV *router_sv;
    pr_router *rt;
    AV *recs;
    AV *apims;               /* api mounts, possibly empty                */
    AV *mounts;              /* NULL when there are none                  */
    SV *ctxcls;
    HV *ctxstash;            /* gv_stashsv(ctxcls), done once             */
    SV *app;
    SV *upload_dir;          /* NULL when unset                           */
    AV *before, *after;
    AV *before_req;          /* NULL when the chain is empty              */
    SV *on_err;              /* may be undef                              */
    SV *on_nf;               /* NULL when unset                           */
    const pp_policy *proxy;  /* NULL without a `proxy` policy             */
    IV  max_body;
    int has_max_body;
    SV *cget;                /* NULL unless Punk::Plugin::ConditionalGet  */
    SV *idem;                /* NULL unless Punk::Plugin::Idempotency     */
    HV *cors;                /* NULL without the keyword                  */
    AV *headers;             /* the frozen pair list, or NULL             */
    AV *headers_scoped;      /* NULL when no scope has a policy           */
    HV *csp;                 /* NULL unless Punk::Plugin::CSP             */
    pk_rec_c *rec;
    int nrec;
} pk_state;

static SV *pks_get(pTHX_ HV *h, const char *k) {
    SV **e = hv_fetch(h, k, (I32)strlen(k), 0);
    return (e && *e) ? *e : NULL;
}
static SV *pks_def(pTHX_ HV *h, const char *k) {
    SV *v = pks_get(aTHX_ h, k);
    return (v && SvOK(v)) ? v : NULL;
}
static AV *pks_av(pTHX_ HV *h, const char *k) {
    SV *v = pks_get(aTHX_ h, k);
    return (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) ? (AV *)SvRV(v) : NULL;
}
static HV *pks_hv(pTHX_ HV *h, const char *k) {
    SV *v = pks_get(aTHX_ h, k);
    return (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) ? (HV *)SvRV(v) : NULL;
}

static int pk_state_free(pTHX_ SV *sv, MAGIC *mg) {
    pk_state *S = (pk_state *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (S) { if (S->rec) Safefree(S->rec); Safefree(S); }
    return 0;
}
static MGVTBL pk_state_vtbl = { NULL, NULL, NULL, NULL, pk_state_free,
                                NULL, NULL, NULL };

/* One record's hot fields. A missing key reads as the dispatcher always
 * read it: no guards, no ceiling, not a socket, compression allowed. */
static void pk_rec_mirror(pTHX_ pk_rec_c *R, SV *recsv) {
    HV *rh;
    SV **x;
    Zero(R, 1, pk_rec_c);
    if (!(recsv && SvROK(recsv) && SvTYPE(SvRV(recsv)) == SVt_PVHV)) return;
    rh = (HV *)SvRV(recsv);
    x = hv_fetchs(rh, "code", 0);
    R->code = (x && *x) ? *x : NULL;
    x = hv_fetchs(rh, "guards", 0);
    if (x && *x && SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVAV
        && av_len((AV *)SvRV(*x)) >= 0)
        R->guards = (AV *)SvRV(*x);
    x = hv_fetch(rh, K_MAX_BODY, (I32)strlen(K_MAX_BODY), 0);
    if (x && *x && SvOK(*x)) { R->max_body = SvIV(*x); R->has_max_body = 1; }
    x = hv_fetch(rh, K_ETAG, (I32)strlen(K_ETAG), 0);
    R->etag = (x && *x && SvOK(*x) && !SvROK(*x) && SvTRUE(*x)) ? 1 : 0;
    x = hv_fetch(rh, K_IDEMPOTENT, (I32)strlen(K_IDEMPOTENT), 0);
    R->idempotent = (x && *x && SvTRUE(*x)) ? 1 : 0;
    x = hv_fetch(rh, K_WS, (I32)strlen(K_WS), 0);
    R->ws = (x && *x && SvTRUE(*x)) ? 1 : 0;
    x = hv_fetchs(rh, "sse", 0);
    R->sse = (x && *x && SvTRUE(*x)) ? 1 : 0;
    x = hv_fetch(rh, K_COMPRESS, (I32)strlen(K_COMPRESS), 0);
    R->nocompress = (x && *x && !SvTRUE(*x)) ? 1 : 0;
}

/* Read the frozen hash into a struct. Returns the SV that carries it (+1);
 * the struct lives as long as that SV. */
static SV *pk_state_build(pTHX_ HV *state) {
    SV *holder = newSV(0);
    pk_state *S;
    Newxz(S, 1, pk_state);
    S->hv = state;
    S->router_sv = pks_get(aTHX_ state, K_ROUTER);
    S->rt = (S->router_sv && SvROK(S->router_sv) && SvIOK(SvRV(S->router_sv)))
          ? (pr_router *)INT2PTR(void *, SvIV(SvRV(S->router_sv))) : NULL;
    S->recs   = pks_av(aTHX_ state, K_RECS);
    S->apims  = pks_av(aTHX_ state, K_API_MOUNTS);
    S->mounts = pks_av(aTHX_ state, K_MOUNTS);
    S->ctxcls = pks_get(aTHX_ state, K_CTX);
    S->ctxstash = S->ctxcls ? gv_stashsv(S->ctxcls, GV_ADD) : NULL;
    S->app    = pks_get(aTHX_ state, K_APP);
    S->upload_dir = pks_def(aTHX_ state, "upload_dir");
    S->before = pks_av(aTHX_ state, K_BEFORE);
    S->after  = pks_av(aTHX_ state, K_AFTER);
    S->before_req = pks_av(aTHX_ state, K_BEFORE_REQ);
    if (S->before_req && av_len(S->before_req) < 0) S->before_req = NULL;
    S->on_err = pks_get(aTHX_ state, K_ON_ERROR);
    S->on_nf  = pks_def(aTHX_ state, K_ON_NOT_FOUND);
    {
        SV *px = pks_get(aTHX_ state, K_PROXY);
        S->proxy = (px && SvROK(px) && SvIOK(SvRV(px)))
                 ? (const pp_policy *)INT2PTR(void *, SvIV(SvRV(px))) : NULL;
    }
    {
        SV *mb = pks_def(aTHX_ state, K_MAX_BODY);
        if (mb) { S->max_body = SvIV(mb); S->has_max_body = 1; }
    }
    {
        SV *cg = pks_get(aTHX_ state, K_CGET);
        S->cget = (cg && SvTRUE(cg)) ? cg : NULL;
    }
    S->idem = pks_def(aTHX_ state, K_IDEM);
    S->cors = pks_hv(aTHX_ state, K_CORS);
    S->headers = pks_av(aTHX_ state, K_HEADERS);
    S->headers_scoped = pks_av(aTHX_ state, K_HEADERS_SCOPED);
    S->csp = pks_hv(aTHX_ state, K_CSP);
    if (S->recs) {
        SSize_t i, n = av_len(S->recs) + 1;
        Newxz(S->rec, n > 0 ? n : 1, pk_rec_c);
        S->nrec = (int)n;
        for (i = 0; i < n; i++) {
            SV **rp = av_fetch(S->recs, i, 0);
            pk_rec_mirror(aTHX_ &S->rec[i], (rp && *rp) ? *rp : NULL);
        }
    }
    sv_magicext(holder, NULL, PERL_MAGIC_ext, &pk_state_vtbl, (char *)S, 0);
    return holder;
}

/* the struct a carrier SV holds, or NULL */
static pk_state *pk_state_of(pTHX_ SV *holder) {
    MAGIC *mg = holder ? mg_findext(holder, PERL_MAGIC_ext, &pk_state_vtbl)
                       : NULL;
    return mg ? (pk_state *)mg->mg_ptr : NULL;
}

#endif /* PUNK_STATE_H */
