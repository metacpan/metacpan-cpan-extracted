#ifndef PQ_DBI_H
#define PQ_DBI_H

/* pq_dbi.h - the DBI seam, adapted from Punk's punk_dbi.h.
 *
 * What this buys and what it does not is worth stating plainly, because the
 * shape of the win is unusual. Every database operation is still a DBI
 * method call - connect, prepare_cached, execute, fetchrow_arrayref - and
 * those are Perl-level calls into DBI's own XS that no amount of C on this
 * side removes. The round trip to the database dominates either way.
 *
 * What moves into C is the glue around them: assembling the SQL, building
 * the bind vectors, decoding rows positionally, the JSON codec (through
 * frj_abi), and the connection pool bookkeeping. The queue's contract
 * methods are XSUBs, so an enqueue is one C frame calling DBI rather than
 * two or three Perl frames doing it.
 *
 * (This shape - every op ending in a DBI method call - is also why the
 * once-planned C ABI was dropped: it could never have been a speed
 * feature, and its only consumer lived in this dist. See
 * plan_punk_queue/phase-7-abi.md.)
 *
 * Include after pq_compat.h, pq_frj.h and pq_time.h. */

/* ---- small helpers -------------------------------------------------------- */

static HV *pq_hv(pTHX_ SV *self, const char *what) {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("%s: not an object", what);
    return (HV *)SvRV(self);
}

static SV *pq_get(pTHX_ HV *h, const char *k) {
    SV **e = h ? hv_fetch(h, k, (I32)strlen(k), 0) : NULL;
    return (e && *e) ? *e : NULL;
}

static HV *pq_get_hv(pTHX_ HV *h, const char *k) {
    SV *v = pq_get(aTHX_ h, k);
    return (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) ? (HV *)SvRV(v)
                                                          : NULL;
}

/* Call $obj->$meth(@argv) in its own stack scope, returning the scalar
 * result (+1) when want is true, else NULL. argv holds stable SV* captured
 * before any stack manipulation - EXTEND may move the caller's stack, so
 * ST() is stale afterwards.
 *
 * Note the SvREFCNT_inc before FREETMPS: a value that is only mortal when
 * FREETMPS runs is freed by it, and the caller gets a corpse. This is the
 * bug that cost Punk's logging tier a day. */
static SV *pq_call_meth(pTHX_ SV *obj, const char *meth,
                        SV **argv, int nargs, int want) {
    dSP; SV *r = NULL; int count, i;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, nargs + 1);
    PUSHs(obj);
    for (i = 0; i < nargs; i++) PUSHs(argv[i]);
    PUTBACK;
    count = call_method(meth, want ? G_SCALAR : G_VOID);
    SPAGAIN;
    if (want && count > 0) r = SvREFCNT_inc(POPs);
    PUTBACK; FREETMPS; LEAVE;
    return r;
}

/* As above but trapping a die; *died is set and ERRSV holds the message.
 * Used where a failure is expected and recoverable - a BEGIN IMMEDIATE that
 * loses a race, a unique-constraint violation on a dedupe key. */
static SV *pq_call_meth_ev(pTHX_ SV *obj, const char *meth,
                           SV **argv, int nargs, int want, int *died) {
    dSP; SV *r = NULL; int count, i;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, nargs + 1);
    PUSHs(obj);
    for (i = 0; i < nargs; i++) PUSHs(argv[i]);
    PUTBACK;
    count = call_method(meth, (want ? G_SCALAR : G_VOID) | G_EVAL);
    SPAGAIN;
    if (want && count > 0) r = SvREFCNT_inc(POPs);
    *died = SvTRUE(ERRSV) ? 1 : 0;
    PUTBACK; FREETMPS; LEAVE;
    if (*died && r) { SvREFCNT_dec(r); r = NULL; }
    return r;
}

/* An attribute off a DBI handle's hash ($dbh->{Driver}). DBI handles are
 * magical hashes, so this goes through hv_fetch, which runs the magic. */
static SV *pq_attr(pTHX_ SV *h, const char *name) {
    SV **e;
    if (!(h && SvROK(h) && SvTYPE(SvRV(h)) == SVt_PVHV)) return NULL;
    e = hv_fetch((HV *)SvRV(h), name, (I32)strlen(name), 0);
    if (!(e && *e)) return NULL;
    SvGETMAGIC(*e);
    return *e;
}

/* $dbh->{Driver}{Name}: "SQLite", "Pg", ... Borrowed, or NULL. */
static SV *pq_driver_name(pTHX_ SV *dbh) {
    SV *drv = pq_attr(aTHX_ dbh, "Driver");
    return drv ? pq_attr(aTHX_ drv, "Name") : NULL;
}

static int pq_driver_is(pTHX_ SV *dbh, const char *want) {
    SV *n = pq_driver_name(aTHX_ dbh);
    STRLEN l, wl = strlen(want);
    const char *s;
    if (!(n && SvOK(n))) return 0;
    s = SvPV_const(n, l);
    return (l == wl && memEQ(s, want, wl)) ? 1 : 0;
}

/* ---- the connection pool ---------------------------------------------------
 *
 * One handle per distinct connection (dsn + credentials), shared by every
 * backend object using it, so a queue and a worker on the same database open
 * one connection per process rather than two. The pid lives in the reconnect
 * check, so a fork gets a fresh handle instead of a corrupted shared one -
 * which matters more here than in a web app, because forking is the worker
 * pool's whole design. */

static HV *PQ_POOL = NULL;

static HV *pq_pool(pTHX) {
    if (!PQ_POOL) PQ_POOL = newHV();
    return PQ_POOL;
}

static SV *pq_slot(pTHX_ HV *pool, SV *key) {
    HE *he = hv_fetch_ent(pool, key, 0, 0);
    if (!he) {
        HV *slot = newHV();
        (void)hv_stores(slot, "pid", newSViv(-1));
        he = hv_store_ent(pool, key, newRV_noinc((SV *)slot), 0);
    }
    return HeVAL(he);
}

/* RETURNING support, feature-detected once per connection: PostgreSQL
 * always, SQLite from 3.35. Anything else re-reads the row after a write.
 * Detection failing is not fatal - a 0 here only costs an extra SELECT. */
static int pq_detect_returning(pTHX_ SV *dbh) {
    if (pq_driver_is(aTHX_ dbh, "Pg")) return 1;
    if (pq_driver_is(aTHX_ dbh, "SQLite")) {
        SV *v = pq_attr(aTHX_ dbh, "sqlite_version");
        if (v && SvOK(v)) {
            STRLEN vl;
            const char *s = SvPV_const(v, vl);
            int maj = 0, min = 0;
            STRLEN i = 0;
            while (i < vl && isDIGIT((U8)s[i])) maj = maj * 10 + (s[i++] - '0');
            if (i < vl && s[i] == '.') {
                i++;
                while (i < vl && isDIGIT((U8)s[i])) min = min * 10 + (s[i++] - '0');
            }
            if (maj > 3 || (maj == 3 && min >= 35)) return 1;
        }
    }
    return 0;
}

/* $dbh->do($sql) with no binds, for pragmas and transaction control. */
static void pq_dbh_do_pv(pTHX_ SV *dbh, const char *sql) {
    SV *argv[1], *r;
    argv[0] = sv_2mortal(newSVpv(sql, 0));
    r = pq_call_meth(aTHX_ dbh, "do", argv, 1, 1);
    if (r) SvREFCNT_dec(r);
}

/* Per-driver connect-time setup.
 *
 * This lives here rather than behind a vtable because there are exactly two
 * drivers, both of them ours, and a function-pointer registry for two cases
 * is indirection that costs more to read than it saves. When a third
 * backend arrives, this is the function that grows a branch.
 *
 * SQLite: WAL is mandatory (readers must not block the claim transaction),
 * busy_timeout turns SQLITE_BUSY into a wait rather than an error under
 * contending workers, and foreign_keys must be enabled per connection or
 * the ON DELETE CASCADE on pq_job_deps silently does nothing. */
static void pq_after_connect(pTHX_ SV *dbh) {
    if (pq_driver_is(aTHX_ dbh, "SQLite")) {
        pq_dbh_do_pv(aTHX_ dbh, "PRAGMA journal_mode = WAL");
        pq_dbh_do_pv(aTHX_ dbh, "PRAGMA synchronous = NORMAL");
        pq_dbh_do_pv(aTHX_ dbh, "PRAGMA busy_timeout = 5000");
        pq_dbh_do_pv(aTHX_ dbh, "PRAGMA foreign_keys = ON");
    }
}

/* Forward declaration: the clock probe is per-backend SQL, defined in
 * pq_sqlite.h / pq_pg.h, but the pool has to run it at connect time. */
static double pq_probe_clock(pTHX_ SV *dbh);

/* The live handle for this backend's dsn, connected on first use in this
 * process and shared with every other object on the same one. Borrowed. */
static SV *pq_dbh(pTHX_ SV *self) {
    HV *h    = pq_hv(aTHX_ self, "Punk::Queue::Backend");
    HV *o    = pq_get_hv(aTHX_ h, "opts");
    SV *dsn  = o ? pq_get(aTHX_ o, "dsn") : NULL;
    SV *user = o ? pq_get(aTHX_ o, "user") : NULL;
    SV *pass = o ? pq_get(aTHX_ o, "password") : NULL;
    SV *key, *slot_sv, *dbh, *pid;
    HV *pool = pq_pool(aTHX), *slot;

    /* An externally supplied handle ($q = Punk::Queue->new(dbh => $dbh))
     * bypasses the pool entirely: we did not open it and must not pool,
     * reconnect or close it. */
    {
        SV *ext = pq_get(aTHX_ h, "dbh");
        if (ext && SvROK(ext)) return ext;
    }

    if (!(dsn && SvOK(dsn) && SvTRUE(dsn)))
        croak("Punk::Queue: no dsn - pass dsn => 'dbi:SQLite:dbname=...' "
              "or dbh => $dbh");

    /* NUL-joined so a dsn containing the separator cannot collide */
    key = sv_2mortal(newSVsv(dsn));
    sv_catpvn(key, "\0", 1);
    if (user && SvOK(user)) sv_catsv(key, user);
    sv_catpvn(key, "\0", 1);
    if (pass && SvOK(pass)) sv_catsv(key, pass);

    slot_sv = pq_slot(aTHX_ pool, key);
    slot = (HV *)SvRV(slot_sv);
    pid  = pq_get(aTHX_ slot, "pid");
    dbh  = pq_get(aTHX_ slot, "dbh");

    if (!(pid && SvOK(pid) && SvIV(pid) == (IV)PerlProc_getpid())
        || !(dbh && SvROK(dbh))) {
        SV *argv[4], *attr_rv, *conn;
        HV *attr = newHV();
        SV *user_attr = o ? pq_get(aTHX_ o, "attr") : NULL;
        (void)hv_stores(attr, "RaiseError", newSViv(1));
        (void)hv_stores(attr, "AutoCommit", newSViv(1));
        (void)hv_stores(attr, "PrintError", newSViv(0));
        /* A forked child inherits the parent's handle, and a normal DESTROY
         * in the child sends a termination on the SHARED socket - killing
         * the parent's connection from another process. AutoInactiveDestroy
         * makes DESTROY a no-op in any process that did not create the
         * handle. Forking is the worker pool's whole design, so this is
         * core behaviour, not a test workaround. (DBI 1.614+.) */
        (void)hv_stores(attr, "AutoInactiveDestroy", newSViv(1));
        if (user_attr && SvROK(user_attr)
            && SvTYPE(SvRV(user_attr)) == SVt_PVHV) {
            HV *ua = (HV *)SvRV(user_attr);
            HE *he;
            hv_iterinit(ua);
            while ((he = hv_iternext(ua)))
                (void)hv_store_ent(attr, HeSVKEY_force(he),
                                   newSVsv(HeVAL(he)), 0);
        }
        attr_rv = sv_2mortal(newRV_noinc((SV *)attr));

        eval_pv("require DBI;", TRUE);
        argv[0] = dsn;
        argv[1] = (user && SvOK(user)) ? user : &PL_sv_undef;
        argv[2] = (pass && SvOK(pass)) ? pass : &PL_sv_undef;
        argv[3] = attr_rv;
        conn = pq_call_meth(aTHX_ sv_2mortal(newSVpvs("DBI")), "connect",
                            argv, 4, 1);
        if (!conn || !SvROK(conn)) {
            if (conn) SvREFCNT_dec(conn);
            croak("Punk::Queue: DBI->connect failed for %s",
                  SvPV_nolen(dsn));
        }
        pq_after_connect(aTHX_ conn);
        (void)hv_stores(slot, "dbh", conn);
        (void)hv_stores(slot, "pid", newSViv((IV)PerlProc_getpid()));
        (void)hv_stores(slot, "returning",
                        newSViv(pq_detect_returning(aTHX_ conn)));
        /* Probed once per connection, and therefore re-probed after a fork
         * and after a reconnect, which is exactly when it can have moved. */
        (void)hv_stores(slot, PQ_DELTA_KEY,
                        newSVnv(pq_probe_clock(aTHX_ conn)));
        dbh = conn;
    }

    /* Mirror the pooled facts onto the instance, which is where the rest of
     * the code reads them. */
    {
        SV *r = pq_get(aTHX_ slot, "returning");
        SV *d = pq_get(aTHX_ slot, PQ_DELTA_KEY);
        (void)hv_stores(h, "returning", newSViv(r ? SvIV(r) : 0));
        (void)hv_stores(h, PQ_DELTA_KEY, newSVnv(d ? SvNV(d) : 0.0));
    }
    return dbh;
}

/* now(), in the database's frame. Every timestamp this dist binds comes
 * from here, never from pq_now_local directly. */
static double pq_now(pTHX_ SV *self) {
    HV *h = pq_hv(aTHX_ self, "Punk::Queue::Backend");
    SV *d;
    (void)pq_dbh(aTHX_ self);            /* ensures the delta is populated */
    d = pq_get(aTHX_ h, PQ_DELTA_KEY);
    return pq_now_delta(aTHX_ d ? SvNV(d) : 0.0);
}

static int pq_has_returning(pTHX_ SV *self) {
    HV *h = pq_hv(aTHX_ self, "Punk::Queue::Backend");
    SV *r;
    (void)pq_dbh(aTHX_ self);
    r = pq_get(aTHX_ h, "returning");
    return r ? (int)SvIV(r) : 0;
}

/* ---- statements ----------------------------------------------------------- */

/* prepare_cached: one statement handle per distinct SQL string on the
 * connection, which is what keeps repeated queries off the parser. This is
 * also why the SQL text must be stable - an IN list expanded to a different
 * arity, or a filter built in hash order, defeats it silently. Mortal. */
static SV *pq_sth(pTHX_ SV *self, SV *sql) {
    SV *dbh = pq_dbh(aTHX_ self);
    SV *argv[3], *sth;
    argv[0] = sql;
    argv[1] = &PL_sv_undef;
    argv[2] = sv_2mortal(newSViv(3));   /* 3 = reuse even if still Active */
    sth = pq_call_meth(aTHX_ dbh, "prepare_cached", argv, 3, 1);
    if (!sth) croak("Punk::Queue: prepare_cached returned nothing");
    return sv_2mortal(sth);
}

/* $sth->execute(@bind) -> rows affected. DBI returns "0E0" for zero, which
 * is true but numifies to 0, so SvIV is the right read. */
static IV pq_execute(pTHX_ SV *sth, AV *bind) {
    SSize_t n = bind ? av_len(bind) + 1 : 0, i;
    SV **argv = n ? (SV **)pq_xmalloc(aTHX_ sizeof(SV *) * (size_t)n) : NULL;
    SV *r;
    IV rows;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(bind, i, 0);
        argv[i] = (e && *e) ? *e : &PL_sv_undef;
    }
    r = pq_call_meth(aTHX_ sth, "execute", argv, (int)n, 1);
    if (argv) safefree(argv);
    rows = r ? SvIV(r) : 0;
    if (r) SvREFCNT_dec(r);
    return rows;
}

/* One row, positionally, copied out of DBI's reused buffer. +1 or NULL. */
static AV *pq_fetchrow(pTHX_ SV *sth) {
    SV *row = pq_call_meth(aTHX_ sth, "fetchrow_arrayref", NULL, 0, 1);
    AV *out, *in;
    SSize_t n, i;
    if (!row) return NULL;
    if (!SvROK(row) || SvTYPE(SvRV(row)) != SVt_PVAV) {
        SvREFCNT_dec(row);
        return NULL;
    }
    in  = (AV *)SvRV(row);
    n   = av_len(in) + 1;
    out = newAV();
    av_extend(out, n - 1);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(in, i, 0);
        av_push(out, newSVsv((e && *e) ? *e : &PL_sv_undef));
    }
    SvREFCNT_dec(row);
    return out;
}

/* prepare_cached + execute, discarding any result set. Rows affected. */
static IV pq_do(pTHX_ SV *self, SV *sql, AV *bind) {
    SV *sth = pq_sth(aTHX_ self, sql);
    return pq_execute(aTHX_ sth, bind);
}

static IV pq_do_pv(pTHX_ SV *self, const char *sql) {
    return pq_do(aTHX_ self, sv_2mortal(newSVpv(sql, 0)), NULL);
}

/* prepare_cached + execute + first row. +1 or NULL. Finishes the handle so
 * a cached sth is not left Active with rows pending. */
static AV *pq_selectrow(pTHX_ SV *self, SV *sql, AV *bind) {
    SV *sth = pq_sth(aTHX_ self, sql);
    AV *row;
    (void)pq_execute(aTHX_ sth, bind);
    row = pq_fetchrow(aTHX_ sth);
    { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
      if (r) SvREFCNT_dec(r); }
    return row;
}

/* Element i of a fetched row, borrowed; &PL_sv_undef past the end. */
static SV *pq_col(pTHX_ AV *row, SSize_t i) {
    SV **e = row ? av_fetch(row, i, 0) : NULL;
    return (e && *e) ? *e : &PL_sv_undef;
}

static IV pq_col_iv(pTHX_ AV *row, SSize_t i) {
    SV *v = pq_col(aTHX_ row, i);
    return SvOK(v) ? SvIV(v) : 0;
}

/* The id of the row just inserted, when RETURNING was not available. */
static IV pq_last_insert_id(pTHX_ SV *self) {
    SV *dbh = pq_dbh(aTHX_ self);
    SV *argv[4], *r;
    IV id;
    argv[0] = &PL_sv_undef;
    argv[1] = &PL_sv_undef;
    argv[2] = &PL_sv_undef;
    argv[3] = &PL_sv_undef;
    r = pq_call_meth(aTHX_ dbh, "last_insert_id", argv, 4, 1);
    id = (r && SvOK(r)) ? SvIV(r) : 0;
    if (r) SvREFCNT_dec(r);
    return id;
}

/* ---- bind vectors --------------------------------------------------------- */

/* A mortal AV to accumulate binds into. The pq_bind_* helpers below all
 * push a fresh SV, so nothing aliases a caller's value. */
static AV *pq_binds(pTHX) {
    return (AV *)sv_2mortal((SV *)newAV());
}

static void pq_bind_sv(pTHX_ AV *b, SV *v) {
    av_push(b, newSVsv(v ? v : &PL_sv_undef));
}

static void pq_bind_pv(pTHX_ AV *b, const char *s) {
    av_push(b, newSVpv(s, 0));
}

static void pq_bind_iv(pTHX_ AV *b, IV v) {
    av_push(b, newSViv(v));
}

static void pq_bind_nv(pTHX_ AV *b, double v) {
    av_push(b, newSVnv(v));
}

static void pq_bind_undef(pTHX_ AV *b) {
    av_push(b, newSV(0));
}

/* a numeric option off the backend's opts hash, with a default */
static double pq_opt_num(pTHX_ SV *self, const char *key, double dflt) {
    HV *h = pq_hv(aTHX_ self, "Punk::Queue::Backend");
    HV *o = pq_get_hv(aTHX_ h, "opts");
    SV *v = o ? pq_get(aTHX_ o, key) : NULL;
    return (v && SvOK(v)) ? SvNV(v) : dflt;
}

#endif /* PQ_DBI_H */
