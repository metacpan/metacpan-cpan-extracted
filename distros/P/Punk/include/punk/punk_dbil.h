/* punk_dbil.h - Punk::Model::DBIx::Loop, the async model backend, in C.
 *
 * The same six-method contract as Punk::Model::DBI, but every method returns a
 * Punk::Future instead of a value: the statement runs on DBIx::Loop (a worker
 * pool, or native fd async on Pg) over the Hyperman worker's own loop, so the
 * worker serves other requests while the database round trip is in flight.
 * This is the one place a Punk request still blocked.
 *
 * Everything goes through DBIx::Loop's C ABI (dbil_abi.h, reached through
 * ExtUtils::Depends): exec_shaped runs the statement and applies the reshape,
 * and future_on_ready registers a C continuation, so no Perl closure is
 * compiled per query and no Perl frame runs when the rows land. The bridge to
 * Punk::Future is that one continuation: it post-processes per operation and
 * settles a pf the dispatcher already knows how to await.
 *
 * The model tier needs no change for this backend to exist: pm_delegate
 * passes the future through untouched, and punk_serve.h already awaits any
 * future a handler returns.
 *
 * Must be included after punk_dbi.h (the shared SQL helpers and the keyset
 * token codec - sharing the codec is a correctness requirement, a `next`
 * token minted by one backend must decode in the other), punk_wsconn.h
 * (punk_hm) and punk_future.h (pf_*, pf_wake_hf_cb).
 */

#ifndef PUNK_DBIL_H
#define PUNK_DBIL_H

#include "dbil_abi.h"

#define PDL_CLS "Punk::Model::DBIx::Loop"

/* ---- DBIx::Loop's ABI, resolved once (the punk_stencil.h idiom) ---------- */

static const dbil_abi *PUNK_DBIL = NULL;
static int PUNK_DBIL_TRIED = 0;

/* Resolve (once) DBIx::Loop's ABI table, or NULL. PUNK_FAKE_DBIL_BAD
 * simulates a version mismatch for the guard test. */
static const dbil_abi *punk_dbil_try(pTHX) {
    if (!PUNK_DBIL_TRIED) {
        dSP; int count, ok; IV p = 0;
        PUNK_DBIL_TRIED = 1;
        ok = pk_require_once(aTHX_ "DBIx::Loop", FALSE);
        SPAGAIN;   /* the require may have reallocated the value stack */
        if (ok) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("DBIx::Loop::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const dbil_abi *a = INT2PTR(const dbil_abi *, p);
                if (a && !getenv("PUNK_FAKE_DBIL_BAD")
                    && a->abi_version >= DBIL_ABI_VERSION)
                    PUNK_DBIL = a;
            }
        }
    }
    return PUNK_DBIL;
}

/* The table, croaking if it is missing or too old. DBIx::Loop 0.02+ is a hard
 * prerequisite, so this is a boot-environment error, not a per-request
 * fallback - there is no synchronous path to fall back to here. */
static const dbil_abi *punk_dbil(pTHX) {
    const dbil_abi *a = punk_dbil_try(aTHX);
    if (!a)
        croak(PDL_CLS ": needs DBIx::Loop with a compatible C ABI "
              "(DBIL_ABI_VERSION %d); upgrade DBIx::Loop to 0.02+",
              DBIL_ABI_VERSION);
    return a;
}

/* ---- the per-worker handle -------------------------------------------------
 *
 * One DBIx::Loop per distinct connection (dsn + credentials + pool sizes),
 * shared by every model on it. The pool sizes are in the key on purpose: two
 * `database` blocks naming one dsn with different worker counts must not
 * silently share one pool. Built lazily on the first STATEMENT, not at new,
 * so `punk console` and tests that only instantiate never fork a pool. The
 * pid rides in the slot, exactly as punk_dbi.h does - DBIx::Loop 0.02 disowns
 * an inherited pool itself, so this is belt-and-braces, in that order. */

static HV *PDL_POOL = NULL;

static HV *pdl_pool(pTHX) {
    if (!PDL_POOL) PDL_POOL = newHV();
    return PDL_POOL;
}

/* The loop adapter for this process. Inside a Hyperman worker it is built on
 * THE WORKER'S OWN LOOP, named explicitly - never left for the adapter to
 * choose, because an adapter that picks for itself when no loop is running
 * quietly constructs an orphan loop the server never pumps, and every future
 * then hangs. Outside a worker (a script, a test) there is no loop to name,
 * so the adapter carries its own; backend->await pumps it. */
static SV *pdl_build_adapter(pTHX_ const dbil_abi *A) {
    const hm_abi *hm = punk_hm(aTHX);
    SV *loop_sv = NULL, *adapter, *err = NULL;
    if (!hm)
        croak(PDL_CLS ": needs Hyperman's C ABI for the loop adapter");
    {
        void *loop = hm->cur_loop(aTHX);
        if (loop) loop_sv = sv_2mortal(hm->sv_of_loop(aTHX_ loop));
    }
    adapter = A->hyperman_adapter(aTHX_ loop_sv, &err);
    if (!adapter) {
        SV *e = err ? sv_2mortal(err)
                    : sv_2mortal(newSVpvs(PDL_CLS ": could not build the "
                                          "DBIx::Loop Hyperman adapter"));
        croak_sv(e);
    }
    return adapter;
}

/* The slot for this backend's connection: { pid, db, dbh, adapter,
 * returning }, connected on first use in this process. Borrowed. */
static HV *pdl_handle(pTHX_ SV *self) {
    const dbil_abi *A = punk_dbil(aTHX);
    HV *h    = pdbi_hv(aTHX_ self);
    SV *opts = pdbi_get(aTHX_ h, "opts");
    HV *o    = (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
               ? (HV *)SvRV(opts) : NULL;
    SV *dsn  = o ? pdbi_get(aTHX_ o, "dsn") : NULL;
    SV *user = o ? pdbi_get(aTHX_ o, "user") : NULL;
    SV *pass = o ? pdbi_get(aTHX_ o, "password") : NULL;
    SV *attr = o ? pdbi_get(aTHX_ o, "attr") : NULL;
    SV *wv   = o ? pdbi_get(aTHX_ o, "workers") : NULL;
    SV *mq   = o ? pdbi_get(aTHX_ o, "max_queue") : NULL;
    int workers   = (wv && SvOK(wv)) ? (int)SvIV(wv) : 0;
    int max_queue = (mq && SvOK(mq)) ? (int)SvIV(mq) : 0;
    SV *key, *slot_sv, *pid;
    HV *pool = pdl_pool(aTHX), *slot;

    if (!(dsn && SvOK(dsn) && SvTRUE(dsn)))
        croak(PDL_CLS ": no dsn - add a database keyword");

    /* NUL-joined, sizes included */
    key = sv_2mortal(newSVsv(dsn));
    sv_catpvn(key, "\0", 1);
    if (user && SvOK(user)) sv_catsv(key, user);
    sv_catpvn(key, "\0", 1);
    if (pass && SvOK(pass)) sv_catsv(key, pass);
    sv_catpvn(key, "\0", 1);
    sv_catpvf(key, "%d", workers);
    sv_catpvn(key, "\0", 1);
    sv_catpvf(key, "%d", max_queue);

    slot_sv = pdbi_slot(aTHX_ pool, key);
    slot = (HV *)SvRV(slot_sv);
    pid  = pdbi_get(aTHX_ slot, "pid");

    if (!(pid && SvOK(pid) && SvIV(pid) == (IV)PerlProc_getpid())
        || !pdbi_get(aTHX_ slot, "db")) {
        SV *adapter = pdl_build_adapter(aTHX_ A);
        SV *err = NULL;
        SV *db  = A->connect(aTHX_ dsn,
                             (user && SvOK(user)) ? user : NULL,
                             (pass && SvOK(pass)) ? pass : NULL,
                             (attr && SvROK(attr)) ? attr : NULL,
                             sv_2mortal(adapter), workers, max_queue, &err);
        SV *dbh;
        if (!db) {
            SV *e = err ? sv_2mortal(err)
                        : sv_2mortal(newSVpvs(PDL_CLS ": connect failed"));
            croak_sv(e);
        }
        dbh = pcx_call_meth(aTHX_ db, "dbh", NULL, 0, 1);
        (void)hv_stores(slot, "db",      db);
        (void)hv_stores(slot, "dbh",     dbh ? dbh : newSV(0));
        (void)hv_stores(slot, "adapter", newSVsv(adapter));
        (void)hv_stores(slot, "pid",     newSViv((IV)PerlProc_getpid()));
        (void)hv_stores(slot, "returning",
                        newSViv(dbh ? pdbi_detect_returning(aTHX_ dbh) : 0));
        {   /* The adapter's underlying hm_loop, kept so this backend's
             * futures can be LOOP-BACKED even off a worker: get/await then
             * pump the adapter's own loop - the one the query watchers are
             * actually on - instead of croaking in block mode. The loop SV
             * rides in the slot so the pointer cannot dangle. */
            const hm_abi *hm = punk_hm(aTHX);
            SV *loop_sv = pcx_call_meth(aTHX_ adapter, "loop", NULL, 0, 1);
            if (hm && loop_sv && SvROK(loop_sv)) {
                void *lp = hm->loop_of_sv(aTHX_ loop_sv);
                (void)hv_stores(slot, "loop_sv", loop_sv);
                (void)hv_stores(slot, "_loop",   newSViv(PTR2IV(lp)));
            }
            else if (loop_sv) SvREFCNT_dec(loop_sv);
        }
    }

    {   /* keep the instance's slot in step, as the DBI backend does */
        SV *r = pdbi_get(aTHX_ slot, "returning");
        (void)hv_stores(h, "returning", newSViv(r ? SvIV(r) : 0));
    }
    return slot;
}

/* ---- the bridge: one C continuation from DBIx::Loop into Punk::Future ---- */

/* what the continuation does with the settled result */
enum {
    PDL_OP_PASS = 0,    /* settle with values[0] (row hashref or undef)  */
    PDL_OP_SEARCH,      /* rows -> { rows, has_more_data, next }         */
    PDL_OP_COUNT,       /* { rows_affected } -> the count                */
    PDL_OP_CREATE_FB,   /* do done -> re-get by pk (insert_id fallback)  */
    PDL_OP_UPDATE_FB,   /* do done -> re-get by pk                       */
    PDL_OP_WRAP         /* settle with ALL the values - backend->future  */
};

/* how many settled values PDL_OP_WRAP carries across; every shipped
 * DBIx::Loop method settles with one, selectrow_array with a row's worth */
#define PDL_WRAP_MAX 64

typedef struct pdl_pend {
    const dbil_abi *A;
    SV *pf;        /* the Punk::Future to settle (+1)                  */
    SV *db;        /* the DBIx::Loop object, for chained follow-ups (+1) */
    SV *dbh;       /* the parent handle, for quote_identifier (+1)     */
    int op;
    IV  limit;     /* SEARCH */
    SV *pk;        /* primary key name (+1) or NULL                    */
    SV *pkval;     /* the key value for a fallback re-get (+1) or NULL */
    SV *table;     /* (+1) for follow-up SQL                           */
    HV *slot;      /* the pool slot, borrowed - for the quoting cache  */
    SV *data;      /* CREATE_FB with no pk: the payload to echo (+1)   */
} pdl_pend;

static void pdl_pend_free(pTHX_ pdl_pend *p) {
    if (p->pf)    SvREFCNT_dec(p->pf);
    if (p->db)    SvREFCNT_dec(p->db);
    if (p->dbh)   SvREFCNT_dec(p->dbh);
    if (p->pk)    SvREFCNT_dec(p->pk);
    if (p->pkval) SvREFCNT_dec(p->pkval);
    if (p->table) SvREFCNT_dec(p->table);
    if (p->data)  SvREFCNT_dec(p->data);
    Safefree(p);
}

static void pdl_ready_cb(pTHX_ SV *fut, void *ud);   /* below */

/* attach the bridge and release our handle on the DBIx::Loop future - its
 * own chain keeps it alive until it settles */
static void pdl_attach(pTHX_ SV *fut, pdl_pend *p) {
    p->A->future_on_ready(aTHX_ fut, pdl_ready_cb, p);
    SvREFCNT_dec(fut);
}

/* settle the pending Punk::Future as failed with err (borrowed) */
static void pdl_fail(pTHX_ pdl_pend *p, SV *err) {
    SV *e = sv_2mortal(err ? newSVsv(err)
                           : newSVpvs(PDL_CLS ": query failed"));
    pf_settle_argv(aTHX_ p->pf, PF_FAILED, &e, 1);
}

/* The continuation. This runs inside DBIx::Loop's settle path, so it must
 * not croak - a longjmp out of a fire loop leaves the queue half-run. Every
 * failure becomes a failed Punk::Future instead. */
static void pdl_ready_cb(pTHX_ SV *fut, void *ud) {
    pdl_pend *p = (pdl_pend *)ud;
    const dbil_abi *A = p->A;
    SV *v[1];
    SSize_t n;

    if (A->future_state(aTHX_ fut) != DBIL_ABI_DONE) {
        pdl_fail(aTHX_ p, A->future_error(aTHX_ fut));
        pdl_pend_free(aTHX_ p);
        return;
    }
    n = A->future_values(aTHX_ fut, v, 1);

    switch (p->op) {

    case PDL_OP_PASS: {
        SV *r = (n > 0 && SvOK(v[0])) ? v[0] : &PL_sv_undef;
        pf_settle_argv(aTHX_ p->pf, PF_DONE, &r, 1);
        break;
    }

    case PDL_OP_WRAP: {
        SV *vs[PDL_WRAP_MAX];
        SSize_t m = A->future_values(aTHX_ fut, vs, PDL_WRAP_MAX);
        pf_settle_argv(aTHX_ p->pf, PF_DONE, vs, (int)m);
        break;
    }

    case PDL_OP_SEARCH: {
        AV *rows = (n > 0 && SvROK(v[0])
                    && SvTYPE(SvRV(v[0])) == SVt_PVAV)
                 ? (AV *)SvRV(v[0]) : NULL;
        HV *out = newHV();
        SSize_t got = rows ? av_len(rows) + 1 : 0;
        int has_more = (got > p->limit) ? 1 : 0;
        SV *out_rv;
        if (has_more && rows) { SV *x = av_pop(rows); if (x) SvREFCNT_dec(x); }
        (void)hv_stores(out, "rows",
            rows ? newRV_inc((SV *)rows) : newRV_noinc((SV *)newAV()));
        (void)hv_stores(out, "has_more_data", newSViv(has_more));
        if (has_more && p->pk && rows && av_len(rows) >= 0) {
            SV **last = av_fetch(rows, av_len(rows), 0);
            HE *he = (last && *last && SvROK(*last)
                      && SvTYPE(SvRV(*last)) == SVt_PVHV)
                     ? hv_fetch_ent((HV *)SvRV(*last), p->pk, 0, 0) : NULL;
            (void)hv_stores(out, "next",
                he ? pdbi_encode_token(aTHX_ HeVAL(he)) : newSV(0));
        }
        else (void)hv_stores(out, "next", newSV(0));
        out_rv = sv_2mortal(newRV_noinc((SV *)out));
        pf_settle_argv(aTHX_ p->pf, PF_DONE, &out_rv, 1);
        break;
    }

    case PDL_OP_COUNT: {
        HV *r = (n > 0 && SvROK(v[0]) && SvTYPE(SvRV(v[0])) == SVt_PVHV)
              ? (HV *)SvRV(v[0]) : NULL;
        SV *ra = r ? pdbi_get(aTHX_ r, "rows_affected") : NULL;
        SV *c  = sv_2mortal(newSViv(ra && SvOK(ra) ? SvIV(ra) : 0));
        pf_settle_argv(aTHX_ p->pf, PF_DONE, &c, 1);
        break;
    }

    /* the do() half of a write on a driver without RETURNING: chain the
     * re-get so server-side defaults still come back, exactly as the DBI
     * backend does synchronously. insert_id comes from the DO RESULT - the
     * worker's own handle, the connection the INSERT actually ran on -
     * never from $db->dbh, which is the parent's separate connection. */
    case PDL_OP_CREATE_FB:
    case PDL_OP_UPDATE_FB: {
        SV *id = p->pkval;
        if (!id && p->op == PDL_OP_CREATE_FB) {
            HV *r = (n > 0 && SvROK(v[0]) && SvTYPE(SvRV(v[0])) == SVt_PVHV)
                  ? (HV *)SvRV(v[0]) : NULL;
            id = r ? pdbi_get(aTHX_ r, "insert_id") : NULL;
        }
        if (!p->pk || !id || !SvOK(id)) {
            /* no key to re-fetch by: echo the payload, as the DBI backend
             * does for a keyless create */
            SV *r = p->data && SvROK(p->data)
                  ? sv_2mortal(newRV_noinc((SV *)newHVhv((HV *)SvRV(p->data))))
                  : &PL_sv_undef;
            pf_settle_argv(aTHX_ p->pf, PF_DONE, &r, 1);
            break;
        }
        {
            AV *bind = (AV *)sv_2mortal((SV *)newAV());
            SV *sql  = sv_2mortal(newSVpvs("SELECT * FROM "));
            SV *nf;
            sv_catsv(sql, pdbi_qi_slot(aTHX_ p->slot, p->dbh, p->table));
            sv_catpvs(sql, " WHERE ");
            sv_catsv(sql, pdbi_qi_slot(aTHX_ p->slot, p->dbh, p->pk));
            sv_catpvs(sql, " = ? LIMIT 1");
            av_push(bind, newSVsv(id));
            nf = A->exec_shaped(aTHX_ p->db, sql, bind,
                                DBIL_ABI_ROW_HASHREF, NULL);
            p->op = PDL_OP_PASS;
            pdl_attach(aTHX_ nf, p);   /* the same pend rides along */
            return;                    /* not freed: the follow-up owns it */
        }
    }
    }

    pdl_pend_free(aTHX_ p);
}

/* a pending Punk::Future and its bridge record. The blessed SV is returned
 * to the caller; the pend holds its own reference until the bridge fires.
 *
 * On a worker, pf_new already bound the future to the worker's loop. Off a
 * worker it came back block-mode, and a block-mode future settled by a loop
 * callback would hang (or croak) on get - so it is bound to the ADAPTER'S
 * loop instead, the loop the query watchers are on. get/await then pump the
 * right loop wherever they run, and then-chains inherit the binding. */
static pdl_pend *pdl_start(pTHX_ const dbil_abi *A, HV *slot, SV **pf_out) {
    punk_future *pf = pf_new(aTHX);
    SV *self;
    pdl_pend *p;
    if (!pf->is_loop) {
        const hm_abi *hm = punk_hm(aTHX);
        SV *lp = pdbi_get(aTHX_ slot, "_loop");
        if (hm && lp && SvIOK(lp)) {
            pf->is_loop = 1;
            pf->abi     = hm;
            pf->loop    = INT2PTR(void *, SvIV(lp));
        }
    }
    self = pf_bless(aTHX_ pf, "Punk::Future");
    p = NULL;
    Newxz(p, 1, pdl_pend);
    p->A    = A;
    p->slot = slot;   /* borrowed: the pool holds it for the process */
    p->pf = SvREFCNT_inc(self);
    *pf_out = self;
    return p;
}

/* ---- the six operations --------------------------------------------------- */

/* get(%key) -> future of the row hashref, or undef */
static SV *pdl_get(pTHX_ SV *self, SV **st, I32 items) {
    HV *key;
    AV *keys  = pdbi_key_args(aTHX_ st, items, &key, "get", PDL_CLS);
    HV *slot  = pdl_handle(aTHX_ self);
    SV *db    = pdbi_get(aTHX_ slot, "db");
    SV *dbh   = pdbi_get(aTHX_ slot, "dbh");
    AV *bind  = (AV *)sv_2mortal((SV *)newAV());
    SV *where = pdbi_where_eq_slot(aTHX_ slot, dbh, key, keys, bind);
    SV *table = pdbi_get(aTHX_ pdbi_hv(aTHX_ self), "table");
    SV *sql   = sv_2mortal(newSVpvs("SELECT * FROM "));
    const dbil_abi *A = punk_dbil(aTHX);
    SV *out;
    pdl_pend *p;

    sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, table));
    sv_catpvs(sql, " WHERE ");
    sv_catsv(sql, where);
    sv_catpvs(sql, " LIMIT 1");

    p = pdl_start(aTHX_ A, slot, &out);
    p->op = PDL_OP_PASS;
    pdl_attach(aTHX_ A->exec_shaped(aTHX_ db, sql, bind,
                                    DBIL_ABI_ROW_HASHREF, NULL), p);
    return out;
}

/* search(\%filter, \%opts) -> future of { rows, has_more_data, next } */
static SV *pdl_search(pTHX_ SV *self, SV *filter, SV *opts) {
    HV *h  = pdbi_hv(aTHX_ self);
    HV *f  = (SvROK(filter) && SvTYPE(SvRV(filter)) == SVt_PVHV)
             ? (HV *)SvRV(filter) : NULL;
    HV *o  = (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
             ? (HV *)SvRV(opts) : NULL;
    SV *pk     = pdbi_get(aTHX_ h, "primary");
    SV *table  = pdbi_get(aTHX_ h, "table");
    SV *lim_sv = o ? pdbi_get(aTHX_ o, "limit") : NULL;
    SV *after  = o ? pdbi_get(aTHX_ o, "after") : NULL;
    IV limit   = (lim_sv && SvOK(lim_sv)) ? SvIV(lim_sv) : 20;
    HV *slot   = pdl_handle(aTHX_ self);
    SV *db     = pdbi_get(aTHX_ slot, "db");
    SV *dbh    = pdbi_get(aTHX_ slot, "dbh");
    AV *bind   = (AV *)sv_2mortal((SV *)newAV());
    AV *keys   = pdbi_sorted_keys(aTHX_ f);
    const dbil_abi *A = punk_dbil(aTHX);
    SV *sql, *out;
    pdl_pend *p;

    if (limit < 1) limit = 1;

    sql = sv_2mortal(newSVpvs("SELECT * FROM "));
    sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, table));

    if (av_len(keys) >= 0 || (after && SvOK(after) && SvCUR(after))) {
        SV *where = pdbi_where_eq_slot(aTHX_ slot, dbh, f, keys, bind);
        sv_catpvs(sql, " WHERE ");
        sv_catsv(sql, where);
        if (after && SvOK(after) && SvCUR(after)) {
            if (!(pk && SvOK(pk)))
                croak(PDL_CLS ": pagination needs a primary key");
            if (av_len(keys) >= 0) sv_catpvs(sql, " AND ");
            sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, pk));
            sv_catpvs(sql, " > ?");
            /* synchronous, before the exec: a bad token is a client error
             * and croaks here, exactly as the DBI backend's search does */
            av_push(bind, pdbi_decode_token(aTHX_ after, PDL_CLS));
        }
    }
    if (pk && SvOK(pk)) {
        sv_catpvs(sql, " ORDER BY ");
        sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, pk));
    }
    sv_catpvf(sql, " LIMIT %" IVdf, (IV)(limit + 1));

    p = pdl_start(aTHX_ A, slot, &out);
    p->op    = PDL_OP_SEARCH;
    p->limit = limit;
    if (pk && SvOK(pk)) p->pk = newSVsv(pk);
    pdl_attach(aTHX_ A->exec_shaped(aTHX_ db, sql, bind,
                                    DBIL_ABI_ALL_ROWHASH, NULL), p);
    return out;
}

/* the INSERT/UPDATE SQL builders, shared shape with xs/dbi.xs but quoting on
 * the handle from the slot */

/* create(\%data) -> future of the stored row */
static SV *pdl_create(pTHX_ SV *self, SV *data) {
    HV *h   = pdbi_hv(aTHX_ self);
    HV *d   = (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)
              ? (HV *)SvRV(data) : NULL;
    SV *colset = pdbi_get(aTHX_ h, "col");
    HV *known  = (colset && SvROK(colset)) ? (HV *)SvRV(colset) : NULL;
    SV *table  = pdbi_get(aTHX_ h, "table");
    SV *pk     = pdbi_get(aTHX_ h, "primary");
    HV *slot   = pdl_handle(aTHX_ self);
    SV *db     = pdbi_get(aTHX_ slot, "db");
    SV *dbh    = pdbi_get(aTHX_ slot, "dbh");
    SV *ret    = pdbi_get(aTHX_ slot, "returning");
    AV *all    = pdbi_sorted_keys(aTHX_ d);
    AV *cols   = (AV *)sv_2mortal((SV *)newAV());
    AV *bind   = (AV *)sv_2mortal((SV *)newAV());
    const dbil_abi *A = punk_dbil(aTHX);
    SV *sql, *cl, *ph, *out;
    pdl_pend *p;
    SSize_t i, n = av_len(all) + 1;

    for (i = 0; i < n; i++) {
        SV *k = *av_fetch(all, i, 0);
        HE *he = d ? hv_fetch_ent(d, k, 0, 0) : NULL;
        if (!(known && hv_exists_ent(known, k, 0))) continue;
        if (!(he && SvOK(HeVAL(he)))) continue;    /* defined values only */
        av_push(cols, newSVsv(k));
        av_push(bind, newSVsv(HeVAL(he)));
    }
    if (av_len(cols) < 0)
        croak(PDL_CLS ": create with no known columns");

    cl = sv_2mortal(newSVpvs(""));
    ph = sv_2mortal(newSVpvs(""));
    n = av_len(cols) + 1;
    for (i = 0; i < n; i++) {
        if (i) { sv_catpvs(cl, ", "); sv_catpvs(ph, ", "); }
        sv_catsv(cl, pdbi_qi_slot(aTHX_ slot, dbh, *av_fetch(cols, i, 0)));
        sv_catpvs(ph, "?");
    }
    sql = sv_2mortal(newSVpvs("INSERT INTO "));
    sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, table));
    sv_catpvs(sql, " (");   sv_catsv(sql, cl);
    sv_catpvs(sql, ") VALUES ("); sv_catsv(sql, ph);
    sv_catpvs(sql, ")");

    p = pdl_start(aTHX_ A, slot, &out);

    if (ret && SvIV(ret)) {
        /* RETURNING goes through the QUERY path, not do - do discards rows.
         * The row arrives already reshaped. */
        sv_catpvs(sql, " RETURNING *");
        p->op = PDL_OP_PASS;
        pdl_attach(aTHX_ A->exec_shaped(aTHX_ db, sql, bind,
                                        DBIL_ABI_ROW_HASHREF, NULL), p);
        return out;
    }

    p->op    = PDL_OP_CREATE_FB;
    p->db    = newSVsv(db);
    p->dbh   = newSVsv(dbh);
    p->table = newSVsv(table);
    if (pk && SvOK(pk)) {
        HE *he = d ? hv_fetch_ent(d, pk, 0, 0) : NULL;
        p->pk = newSVsv(pk);
        if (he && SvOK(HeVAL(he))) p->pkval = newSVsv(HeVAL(he));
    }
    if (d) p->data = newSVsv(data);
    pdl_attach(aTHX_ A->exec(aTHX_ db, 0, sql, bind), p);
    return out;
}

/* update(\%key_and_changes) -> future of the stored row */
static SV *pdl_update(pTHX_ SV *self, SV *data) {
    HV *h   = pdbi_hv(aTHX_ self);
    HV *d   = (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)
              ? (HV *)SvRV(data) : NULL;
    SV *colset = pdbi_get(aTHX_ h, "col");
    HV *known  = (colset && SvROK(colset)) ? (HV *)SvRV(colset) : NULL;
    SV *table  = pdbi_get(aTHX_ h, "table");
    SV *pk     = pdbi_get(aTHX_ h, "primary");
    HV *slot, *key;
    SV *db, *dbh, *ret;
    AV *all, *cols, *bind;
    const dbil_abi *A = punk_dbil(aTHX);
    SV *sql, *set, *id, *out;
    pdl_pend *p;
    HE *pke;
    SSize_t i, n;
    PERL_UNUSED_VAR(key);

    if (!(pk && SvOK(pk)))
        croak(PDL_CLS ": update needs a primary key");
    pke = d ? hv_fetch_ent(d, pk, 0, 0) : NULL;
    if (!(pke && SvOK(HeVAL(pke))))
        croak(PDL_CLS ": update needs the primary key in the data");
    id = sv_2mortal(newSVsv(HeVAL(pke)));

    slot = pdl_handle(aTHX_ self);
    db   = pdbi_get(aTHX_ slot, "db");
    dbh  = pdbi_get(aTHX_ slot, "dbh");
    ret  = pdbi_get(aTHX_ slot, "returning");

    all  = pdbi_sorted_keys(aTHX_ d);
    cols = (AV *)sv_2mortal((SV *)newAV());
    bind = (AV *)sv_2mortal((SV *)newAV());
    n = av_len(all) + 1;
    for (i = 0; i < n; i++) {
        SV *k = *av_fetch(all, i, 0);
        HE *he;
        if (sv_eq(k, pk)) continue;
        if (!(known && hv_exists_ent(known, k, 0))) continue;
        he = hv_fetch_ent(d, k, 0, 0);
        av_push(cols, newSVsv(k));
        av_push(bind, newSVsv(he ? HeVAL(he) : &PL_sv_undef));
    }
    if (av_len(cols) < 0)
        croak(PDL_CLS ": update with no columns to change");

    set = sv_2mortal(newSVpvs(""));
    n = av_len(cols) + 1;
    for (i = 0; i < n; i++) {
        if (i) sv_catpvs(set, ", ");
        sv_catsv(set, pdbi_qi_slot(aTHX_ slot, dbh, *av_fetch(cols, i, 0)));
        sv_catpvs(set, " = ?");
    }
    sql = sv_2mortal(newSVpvs("UPDATE "));
    sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, table));
    sv_catpvs(sql, " SET "); sv_catsv(sql, set);
    sv_catpvs(sql, " WHERE "); sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, pk));
    sv_catpvs(sql, " = ?");
    av_push(bind, newSVsv(id));              /* the key binds last */

    p = pdl_start(aTHX_ A, slot, &out);

    if (ret && SvIV(ret)) {
        sv_catpvs(sql, " RETURNING *");
        p->op = PDL_OP_PASS;
        pdl_attach(aTHX_ A->exec_shaped(aTHX_ db, sql, bind,
                                        DBIL_ABI_ROW_HASHREF, NULL), p);
        return out;
    }

    p->op    = PDL_OP_UPDATE_FB;
    p->db    = newSVsv(db);
    p->dbh   = newSVsv(dbh);
    p->table = newSVsv(table);
    p->pk    = newSVsv(pk);
    p->pkval = newSVsv(id);
    pdl_attach(aTHX_ A->exec(aTHX_ db, 0, sql, bind), p);
    return out;
}

/* delete(%key) -> future of the affected row count */
static SV *pdl_delete(pTHX_ SV *self, SV **st, I32 items) {
    HV *key;
    AV *keys  = pdbi_key_args(aTHX_ st, items, &key, "delete", PDL_CLS);
    HV *slot  = pdl_handle(aTHX_ self);
    SV *db    = pdbi_get(aTHX_ slot, "db");
    SV *dbh   = pdbi_get(aTHX_ slot, "dbh");
    AV *bind  = (AV *)sv_2mortal((SV *)newAV());
    SV *where = pdbi_where_eq_slot(aTHX_ slot, dbh, key, keys, bind);
    SV *table = pdbi_get(aTHX_ pdbi_hv(aTHX_ self), "table");
    SV *sql   = sv_2mortal(newSVpvs("DELETE FROM "));
    const dbil_abi *A = punk_dbil(aTHX);
    SV *out;
    pdl_pend *p;

    sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, table));
    sv_catpvs(sql, " WHERE ");
    sv_catsv(sql, where);

    p = pdl_start(aTHX_ A, slot, &out);
    p->op = PDL_OP_COUNT;
    pdl_attach(aTHX_ A->exec(aTHX_ db, 0, sql, bind), p);
    return out;
}

/* future($dbil_future) -> Punk::Future: the public bridge, for custom model
 * methods that run their own SQL on $backend->db and want to hand back the
 * framework's own future type. All the settled values carry across. */
static SV *pdl_wrap(pTHX_ SV *self, SV *f) {
    const dbil_abi *A = punk_dbil(aTHX);
    HV *slot = pdl_handle(aTHX_ self);
    SV *out;
    pdl_pend *p;
    if (!A->is_future(aTHX_ f))
        croak(PDL_CLS "->future: need a DBIx::Loop::Future");
    p = pdl_start(aTHX_ A, slot, &out);
    p->op = PDL_OP_WRAP;
    pdl_attach(aTHX_ SvREFCNT_inc(f), p);   /* attach takes ownership */
    return out;
}

/* ---- await: pump the adapter's loop until a Punk::Future settles ---------
 *
 * On a worker, $c->await already works - the future is loop-backed and
 * pf_await pumps the worker's loop, which is the same loop the adapter's
 * watchers are on. This is for scripts and tests, where the adapter carries
 * its own loop and nothing else will ever pump it. */
static void pdl_await(pTHX_ SV *self, SV *f) {
    punk_future *pf = pf_of(aTHX_ f);      /* croaks unless a Punk::Future */
    if (pf->state != PF_PENDING) return;
    if (pf->is_loop) { pf_await(aTHX_ f); return; }
    {
        const hm_abi *hm = punk_hm(aTHX);
        HV *slot = pdl_handle(aTHX_ self);
        SV *adapter = pdbi_get(aTHX_ slot, "adapter");
        SV *loop_sv, *hf, *clos;
        void *loop;
        AV *cap;
        if (!hm || !adapter)
            croak(PDL_CLS ": await with no loop adapter to pump");
        loop_sv = pcx_call_meth(aTHX_ adapter, "loop", NULL, 0, 1);
        if (!(loop_sv && SvROK(loop_sv)))
            croak(PDL_CLS ": the adapter has no loop to pump");
        sv_2mortal(loop_sv);
        loop = hm->loop_of_sv(aTHX_ loop_sv);
        hf   = hm->future_new(aTHX);
        cap  = newAV();
        av_push(cap, newSVsv(hf));
        clos = sv_2mortal(punk_closure(aTHX_ pf_wake_hf_cb, cap));
        pf_react(aTHX_ pf, f, PFR_ON_READY, clos);
        if (pf->state == PF_PENDING)
            hm->run_until(aTHX_ loop, hf);
        SvREFCNT_dec(hf);
    }
}

#endif /* PUNK_DBIL_H */
