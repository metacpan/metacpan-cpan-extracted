/* punk_obs.h - the C ABI's observer registry and its firing points.
 *
 * Split out from pk_abi_impl.h and included EARLY, because the two places
 * that fire an observer - punk_deliver (punk_context.h) and the dispatcher
 * (punk_serve.h) - are compiled long before the accessor half of the table
 * can be, and only the storage and the fire loops are needed there.
 *
 * Needs pk_abi.h (the callback typedefs) and nothing else of Punk's.
 */

#ifndef PUNK_OBS_H
#define PUNK_OBS_H

#include "pk_abi.h"

static struct { pk_abi_req_cb cb; void *ud; }
    PK_OBS_REQ[PK_ABI_MAX_OBSERVERS];
static struct { pk_abi_res_cb cb; void *ud; }
    PK_OBS_RES[PK_ABI_MAX_OBSERVERS];

static int PK_OBS_REQ_N = 0;
static int PK_OBS_RES_N = 0;

/* Registering either kind makes the dispatcher build the context before
 * routing, so a response observer is handed the same context the request
 * observer saw whatever answered the request. One int to test on the hot
 * path. */
static int PK_OBS_ANY = 0;

static int pk_obs_add_req(pTHX_ pk_abi_req_cb cb, void *ud) {
    PERL_UNUSED_CONTEXT;
    if (!cb || PK_OBS_REQ_N >= PK_ABI_MAX_OBSERVERS) return 0;
    PK_OBS_REQ[PK_OBS_REQ_N].cb = cb;
    PK_OBS_REQ[PK_OBS_REQ_N].ud = ud;
    PK_OBS_REQ_N++;
    PK_OBS_ANY = 1;
    return 1;
}

static int pk_obs_add_res(pTHX_ pk_abi_res_cb cb, void *ud) {
    PERL_UNUSED_CONTEXT;
    if (!cb || PK_OBS_RES_N >= PK_ABI_MAX_OBSERVERS) return 0;
    PK_OBS_RES[PK_OBS_RES_N].cb = cb;
    PK_OBS_RES[PK_OBS_RES_N].ud = ud;
    PK_OBS_RES_N++;
    PK_OBS_ANY = 1;
    return 1;
}

/* Fire, in registration order. A callback is C and is documented as unable to
 * croak, so there is no eval frame here and no per-request cost for one. */
static void pk_obs_fire_req(pTHX_ SV *c) {
    int i;
    for (i = 0; i < PK_OBS_REQ_N; i++)
        PK_OBS_REQ[i].cb(aTHX_ c, PK_OBS_REQ[i].ud);
}

static void pk_obs_fire_res(pTHX_ SV *c, SV *response) {
    int i;
    for (i = 0; i < PK_OBS_RES_N; i++)
        PK_OBS_RES[i].cb(aTHX_ c, response, PK_OBS_RES[i].ud);
}

/* ---- v2: the shipped Punk::Model::DBI backend's statements -------------- */

static struct { pk_abi_query_cb start; pk_abi_query_done_cb done; void *ud; }
    PK_OBS_QRY[PK_ABI_MAX_OBSERVERS];
static int PK_OBS_QRY_N = 0;

typedef struct { void *tok[PK_ABI_MAX_OBSERVERS]; int n; } pk_obs_qtokens;

static int pk_obs_add_query(pTHX_ pk_abi_query_cb start,
                            pk_abi_query_done_cb done, void *ud) {
    PERL_UNUSED_CONTEXT;
    if (!start || PK_OBS_QRY_N >= PK_ABI_MAX_OBSERVERS) return 0;
    PK_OBS_QRY[PK_OBS_QRY_N].start = start;
    PK_OBS_QRY[PK_OBS_QRY_N].done  = done;
    PK_OBS_QRY[PK_OBS_QRY_N].ud    = ud;
    PK_OBS_QRY_N++;
    return 1;
}

/* Returns the tokens, or NULL when nobody is listening - the branch every
 * uninstrumented statement takes, allocating nothing. */
static void *pk_obs_query_start(pTHX_ SV *sql, int nbind) {
    pk_obs_qtokens *t;
    STRLEN sl = 0;
    const char *sp = (sql && SvOK(sql)) ? SvPV_const(sql, sl) : "";
    int i;
    if (!PK_OBS_QRY_N) return NULL;
    Newxz(t, 1, pk_obs_qtokens);
    t->n = PK_OBS_QRY_N;
    for (i = 0; i < PK_OBS_QRY_N; i++)
        t->tok[i] = PK_OBS_QRY[i].start(aTHX_ sp, sl, nbind,
                                        PK_OBS_QRY[i].ud);
    return t;
}

/* `r` is what DBI's execute returned: a false or absent value is a failure. */
static void pk_obs_query_done(pTHX_ void *tv, SV *r) {
    pk_obs_qtokens *t = (pk_obs_qtokens *)tv;
    int ok = (r && SvOK(r) && SvTRUE(r)) ? 1 : 0;
    int i;
    if (!t) return;
    for (i = 0; i < t->n && i < PK_OBS_QRY_N; i++)
        if (PK_OBS_QRY[i].done)
            PK_OBS_QRY[i].done(aTHX_ t->tok[i], ok, PK_OBS_QRY[i].ud);
    Safefree(t);
}

/* ---- the log observer --------------------------------------------------- *
 * A registration point for something that wants a COPY of every record: the
 * logs signal of a telemetry layer, an audit sink, a test harness.
 *
 * A TAP, not a replacement. The line still goes wherever it was going -
 * stderr, psgix.logger, a `to` coderef - and the observer gets a duplicate.
 * The alternative, letting an observer take over the sink, means a telemetry
 * layer silently redirects an operator's logs, and that when its collector is
 * unreachable the logs simply vanish. Nobody should have to weigh "do I want
 * my logs, or do I want them exported".
 *
 * The observer is C and must not croak: it runs inside the logger, which
 * already promises that a failing sink never takes the request down. */
typedef void (*pl_obs_cb)(pTHX_ const char *level, STRLEN llen, SV *msg,
                          HV *fields, void *ud);

#define PL_OBS_MAX 4
static struct { pl_obs_cb cb; void *ud; } PL_OBS[PL_OBS_MAX];
static int PL_OBS_N = 0;

static int pl_observe(pTHX_ pl_obs_cb cb, void *ud) {
    PERL_UNUSED_CONTEXT;
    if (!cb || PL_OBS_N >= PL_OBS_MAX) return 0;
    PL_OBS[PL_OBS_N].cb = cb;
    PL_OBS[PL_OBS_N].ud = ud;
    PL_OBS_N++;
    return 1;
}

/* The guard the firing sites use, so "is anybody listening" is one load and
 * one branch where a request would otherwise pay nothing at all. */
#define PK_OBS_WANT_RES   (PK_OBS_RES_N > 0)
#define PK_OBS_WANT_REQ   (PK_OBS_REQ_N > 0)
#define PK_OBS_WANT_QUERY (PK_OBS_QRY_N > 0)

#endif /* PUNK_OBS_H */
