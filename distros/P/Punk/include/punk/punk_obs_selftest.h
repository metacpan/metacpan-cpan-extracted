/* punk_obs_selftest.h - a C consumer of Punk's own C ABI, for the tests.
 *
 * The point of testing an ABI through itself is that a static function called
 * directly proves nothing about the TABLE: a mis-ordered initialiser, a
 * signature that drifted from the header, a version that was not bumped, are
 * all invisible until something goes through the function pointers. So this
 * registers with the table and reads the request back through it, exactly as
 * Punk::OpenTelemetry will, and t/0011-pk-abi.t reads what it recorded.
 *
 * Included by Punk.xs after pk_abi_impl.h (it needs the PK_ABI table).
 * Private; nothing here is part of any interface.
 */

#ifndef PUNK_OBS_SELFTEST_H
#define PUNK_OBS_SELFTEST_H

static AV *PK_SELFTEST_EVENTS = NULL;
static int PK_SELFTEST_ON     = 0;
static IV  PK_SELFTEST_SEQ    = 0;

static AV *pk_selftest_av(pTHX) {
    if (!PK_SELFTEST_EVENTS) PK_SELFTEST_EVENTS = newAV();
    return PK_SELFTEST_EVENTS;
}

/* One recorded event. Everything is read back through the table's own
 * pointers, including the accessors, so a broken entry shows up as a wrong
 * value in the test rather than as a compile error nobody sees. */
static HV *pk_selftest_event(pTHX_ SV *c, const char *kind) {
    const pk_abi *A = &PK_ABI;
    HV *e  = newHV();
    SV *rp = A->route_pattern_of(aTHX_ c);
    SV *op = A->operation_of(aTHX_ c);
    SV *en = A->env_of(aTHX_ c);
    SV *ap = A->app_of(aTHX_ c);
    SV *mt = A->match_of(aTHX_ c);

    (void)hv_stores(e, "kind",      newSVpv(kind, 0));
    (void)hv_stores(e, "route",     rp ? newSVsv(rp) : newSV(0));
    (void)hv_stores(e, "operation", op ? newSVsv(op) : newSV(0));
    (void)hv_stores(e, "has_env",   newSViv(en ? 1 : 0));
    (void)hv_stores(e, "has_app",   newSViv(ap ? 1 : 0));
    (void)hv_stores(e, "has_match", newSViv(mt ? 1 : 0));

    /* the request path, straight off the env, so the test can tell which
     * request an event belongs to without depending on ordering */
    if (en && SvROK(en) && SvTYPE(SvRV(en)) == SVt_PVHV) {
        SV **p = hv_fetchs((HV *)SvRV(en), "PATH_INFO", 0);
        (void)hv_stores(e, "path", (p && *p && SvOK(*p)) ? newSVsv(*p)
                                                         : newSV(0));
    }
    else (void)hv_stores(e, "path", newSV(0));

    return e;
}

/* The stash hash through the table, or NULL. */
static HV *pk_selftest_stash(pTHX_ SV *c) {
    SV *st = PK_ABI.stash_of(aTHX_ c);
    if (!(st && SvROK(st) && SvTYPE(SvRV(st)) == SVt_PVHV)) return NULL;
    return (HV *)SvRV(st);
}

static void pk_selftest_req(pTHX_ SV *c, void *ud) {
    HV *e = pk_selftest_event(aTHX_ c, "request");
    HV *st = pk_selftest_stash(aTHX_ c);
    PERL_UNUSED_ARG(ud);
    /* Leave a mark, and record that we could. The response side reads it back
     * out: if the dispatcher ever built a second context, the mark would be
     * missing there and the test says so. */
    (void)hv_stores(e, "has_stash", newSViv(st ? 1 : 0));
    if (st) (void)hv_stores(st, "pk.selftest", newSViv(++PK_SELFTEST_SEQ));
    (void)hv_stores(e, "mark", newSViv(PK_SELFTEST_SEQ));
    av_push(pk_selftest_av(aTHX), newRV_noinc((SV *)e));
}

static void pk_selftest_res(pTHX_ SV *c, SV *response, void *ud) {
    HV *e = pk_selftest_event(aTHX_ c, "response");
    HV *st = pk_selftest_stash(aTHX_ c);
    SV **m = st ? hv_fetchs(st, "pk.selftest", 0) : NULL;
    PERL_UNUSED_ARG(ud);
    (void)hv_stores(e, "has_stash", newSViv(st ? 1 : 0));
    (void)hv_stores(e, "mark", (m && *m && SvOK(*m)) ? newSVsv(*m) : newSViv(0));
    (void)hv_stores(e, "status", newSViv(PK_ABI.status_of(aTHX_ response)));
    av_push(pk_selftest_av(aTHX), newRV_noinc((SV *)e));
}

/* ---- v2 on_query, for t/0011-pk-abi.t ------------------------------------- */
static IV  PK_SELFTEST_Q_STARTS = 0;
static IV  PK_SELFTEST_Q_DONES  = 0;
static IV  PK_SELFTEST_Q_OK     = 0;
static IV  PK_SELFTEST_Q_BIND   = -1;
static char PK_SELFTEST_Q_SQL[512];

static void *pk_selftest_query(pTHX_ const char *sql, STRLEN sql_len,
                               int nbind, void *ud) {
    PERL_UNUSED_ARG(ud);
    PERL_UNUSED_CONTEXT;
    PK_SELFTEST_Q_STARTS++;
    PK_SELFTEST_Q_BIND = nbind;
    if (sql_len >= sizeof(PK_SELFTEST_Q_SQL))
        sql_len = sizeof(PK_SELFTEST_Q_SQL) - 1;
    memcpy(PK_SELFTEST_Q_SQL, sql, sql_len);
    PK_SELFTEST_Q_SQL[sql_len] = '\0';
    return INT2PTR(void *, PK_SELFTEST_Q_STARTS);
}

static void pk_selftest_query_done(pTHX_ void *token, int ok, void *ud) {
    PERL_UNUSED_ARG(ud);
    PERL_UNUSED_CONTEXT;
    PK_SELFTEST_Q_DONES++;
    if (ok) PK_SELFTEST_Q_OK++;
    if (PTR2IV(token) < 1 || PTR2IV(token) > PK_SELFTEST_Q_STARTS)
        PK_SELFTEST_Q_OK = -1;      /* correlation broke */
}

#endif /* PUNK_OBS_SELFTEST_H */
