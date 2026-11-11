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
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 class:ignore_covered_err */
        if (ok) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("DBIx::Loop::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 class:ignore_covered_err
             # uncoverable condition right count:2 class:ignore_covered_err */
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            /*
             # uncoverable statement
             # uncoverable branch true
             # uncoverable branch false
             # uncoverable condition left count:1
             # uncoverable condition right count:1 */
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 class:ignore_covered_err */
            if (p) {
                const dbil_abi *a = INT2PTR(const dbil_abi *, p);
                /*
                 # uncoverable condition right count:1 class:ignore_covered_err
                 # uncoverable condition right count:3 class:ignore_covered_err */
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
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (!a)
        croak(PDL_CLS ": needs DBIx::Loop with a compatible C ABI " /* # uncoverable statement */
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
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (!hm)
        croak(PDL_CLS ": needs Hyperman's C ABI for the loop adapter"); /* # uncoverable statement */
    {
        void *loop = hm->cur_loop(aTHX);
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err */
        if (loop) loop_sv = sv_2mortal(hm->sv_of_loop(aTHX_ loop));
    }
    adapter = A->hyperman_adapter(aTHX_ loop_sv, &err);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (!adapter) {
        SV *e = err ? sv_2mortal(err) /* # uncoverable statement */
                    : sv_2mortal(newSVpvs(PDL_CLS ": could not build the " /* # uncoverable statement */
                                          "DBIx::Loop Hyperman adapter"));
        croak_sv(e); /* # uncoverable statement */
    }
    return adapter;
}

/* The slot for this backend's connection: { pid, db, dbh, adapter,
 * returning }, connected on first use in this process. Borrowed. */
static HV *pdl_handle_opts(pTHX_ HV *o) {
    const dbil_abi *A = punk_dbil(aTHX);
    SV *dsn  = o ? pdbi_get(aTHX_ o, "dsn") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    SV *user = o ? pdbi_get(aTHX_ o, "user") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    SV *pass = o ? pdbi_get(aTHX_ o, "password") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    SV *attr = o ? pdbi_get(aTHX_ o, "attr") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    SV *wv   = o ? pdbi_get(aTHX_ o, "workers") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    SV *mq   = o ? pdbi_get(aTHX_ o, "max_queue") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    /*
     # uncoverable condition right count:1 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
    int workers   = (wv && SvOK(wv)) ? (int)SvIV(wv) : 0;
    /*
     # uncoverable condition left count:1 class:ignore_covered_err
     # uncoverable condition left count:2 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
    int max_queue = (mq && SvOK(mq)) ? (int)SvIV(mq) : 0;
    SV *key, *slot_sv, *pid;
    HV *pool = pdl_pool(aTHX), *slot;

    /*
     # uncoverable condition left count:2 class:ignore_covered_err
     # uncoverable condition left count:3 class:ignore_covered_err */
    if (!(dsn && SvOK(dsn) && SvTRUE(dsn)))
        croak(PDL_CLS ": no dsn - add a database keyword");

    /* NUL-joined, sizes included */
    key = sv_2mortal(newSVsv(dsn));
    sv_catpvn(key, "\0", 1);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err
     # uncoverable condition left count:2 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
    if (user && SvOK(user)) sv_catsv(key, user);
    sv_catpvn(key, "\0", 1);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err
     # uncoverable condition left count:2 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
    if (pass && SvOK(pass)) sv_catsv(key, pass);
    sv_catpvn(key, "\0", 1);
    sv_catpvf(key, "%d", workers);
    sv_catpvn(key, "\0", 1);
    sv_catpvf(key, "%d", max_queue);

    slot_sv = pdbi_slot(aTHX_ pool, key);
    slot = (HV *)SvRV(slot_sv);
    pid  = pdbi_get(aTHX_ slot, "pid");

    /*
     # uncoverable condition left count:1 class:ignore_covered_err
     # uncoverable condition left count:2 class:ignore_covered_err
     # uncoverable condition left count:4 class:ignore_covered_err */
    if (!(pid && SvOK(pid) && SvIV(pid) == (IV)PerlProc_getpid())
        || !pdbi_get(aTHX_ slot, "db")) {
        SV *adapter = pdl_build_adapter(aTHX_ A);
        SV *err = NULL;
        SV *db  = A->connect(aTHX_ dsn,
                             (user && SvOK(user)) ? user : NULL, /* # uncoverable statement class:ignore_covered_err */
                             (pass && SvOK(pass)) ? pass : NULL, /* # uncoverable statement class:ignore_covered_err */
                             (attr && SvROK(attr)) ? attr : NULL,
                             sv_2mortal(adapter), workers, max_queue, &err);
        SV *dbh;
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err */
        if (!db) {
            SV *e = err ? sv_2mortal(err) /* # uncoverable statement */
                        : sv_2mortal(newSVpvs(PDL_CLS ": connect failed")); /* # uncoverable statement */
            croak_sv(e); /* # uncoverable statement */
        }
        dbh = pcx_call_meth(aTHX_ db, "dbh", NULL, 0, 1);
        (void)hv_stores(slot, "db",      db);
        (void)hv_stores(slot, "dbh",     dbh ? dbh : newSV(0)); /* # uncoverable condition left count:1 class:ignore_covered_err */
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
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 class:ignore_covered_err
             # uncoverable condition right count:2 class:ignore_covered_err
             # uncoverable condition right count:3 class:ignore_covered_err */
            if (hm && loop_sv && SvROK(loop_sv)) {
                void *lp = hm->loop_of_sv(aTHX_ loop_sv);
                (void)hv_stores(slot, "loop_sv", loop_sv);
                (void)hv_stores(slot, "_loop",   newSViv(PTR2IV(lp)));
            }
            /*
             # uncoverable statement
             # uncoverable branch true
             # uncoverable branch false
             # uncoverable condition left count:1
             # uncoverable condition right count:1 */
            else if (loop_sv) SvREFCNT_dec(loop_sv);
        }
    }
    return slot;
}

static HV *pdl_handle(pTHX_ SV *self) {
    HV *h    = pdbi_hv(aTHX_ self);
    SV *opts = pdbi_get(aTHX_ h, "opts");
    HV *o    = (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
               ? (HV *)SvRV(opts) : NULL;
    HV *slot = pdl_handle_opts(aTHX_ o);
    {   /* keep the instance's slot in step, as the DBI backend does */
        SV *r = pdbi_get(aTHX_ slot, "returning");
        (void)hv_stores(h, "returning", newSViv(r ? SvIV(r) : 0)); /* # uncoverable condition right count:1 class:ignore_covered_err */
    }
    return slot;
}

/* The transaction this backend instance is bound to, or NULL. Set by
 * Punk::Txn::model on a copy of the instance, never on the shared one: a
 * "current transaction" on the worker would be wrong under an event loop,
 * where the requests in flight between two of this request's queries are
 * somebody else's. */
static SV *pdl_tx_of(pTHX_ SV *self) {
    SV *tx = pdbi_get(aTHX_ pdbi_hv(aTHX_ self), "_tx");
    return (tx && SvROK(tx)) ? tx : NULL; /* # uncoverable condition right count:2 class:ignore_covered_err */
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
    AV *cols;      /* SEARCH: the resolved ordering, for the token (+1) */
    AV *desc;      /* SEARCH: its directions (+1)                      */
    int pk_only;   /* SEARCH: no order_by asked - the one-value token  */
    SV *tx;        /* the DBIx::Loop::Txn the statement ran on (+1), or NULL */
    int shape;     /* a raw result still to be reshaped (tx path), or 0 */
} pdl_pend;

static void pdl_pend_free(pTHX_ pdl_pend *p) {
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 class:ignore_covered_err */
    if (p->pf)    SvREFCNT_dec(p->pf);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (p->db)    SvREFCNT_dec(p->db);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (p->dbh)   SvREFCNT_dec(p->dbh);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (p->pk)    SvREFCNT_dec(p->pk);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (p->pkval) SvREFCNT_dec(p->pkval);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (p->table) SvREFCNT_dec(p->table);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (p->data)  SvREFCNT_dec(p->data);
    if (p->cols)  SvREFCNT_dec((SV *)p->cols);
    if (p->desc)  SvREFCNT_dec((SV *)p->desc);
    if (p->tx)    SvREFCNT_dec(p->tx);
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
    SV *e = sv_2mortal(err ? newSVsv(err) /* # uncoverable condition right count:1 class:ignore_covered_err */
                           : newSVpvs(PDL_CLS ": query failed"));
    pf_settle_argv(aTHX_ p->pf, PF_FAILED, &e, 1);
}

/* Run one statement for a pending op and attach the continuation: on the
 * worker's connection through the ABI, or - when the instance is bound to a
 * transaction - on the DBIx::Loop::Txn handle pinned to it, through its own
 * query/do, with the shape recorded for the continuation to apply. */
static void pdl_exec(pTHX_ pdl_pend *p, SV *db, SV *tx, int is_query,
                     SV *sql, AV *bind, int shape) {
    const dbil_abi *A = p->A;
    if (tx && SvROK(tx)) { /* # uncoverable condition right count:2 class:ignore_covered_err */
        SSize_t i, n = bind ? av_len(bind) + 1 : 0; /* # uncoverable condition right count:1 class:ignore_covered_err */
        SV **argv, *f;
        Newx(argv, n + 1, SV *);
        argv[0] = sql;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(bind, i, 0);
            /*
             # uncoverable condition right count:1 class:ignore_covered_err
             # uncoverable condition right count:2 class:ignore_covered_err */
            argv[i + 1] = (e && *e) ? *e : &PL_sv_undef;
        }
        {   /* Under an eval: this runs from the continuation of the
             * previous statement, inside DBIx::Loop's settle path, where a
             * croak would longjmp out of a fire loop. A handle that dies
             * (the transaction already ended) fails the future instead. */
            dSP;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, n + 2);
            PUSHs(tx);
            for (i = 0; i <= n; i++) PUSHs(argv[i]);
            PUTBACK;
            count = call_method(is_query ? "query" : "do", G_SCALAR | G_EVAL); /* # uncoverable condition right count:1 class:ignore_covered_err */
            SPAGAIN;
            f = (count > 0) ? SvREFCNT_inc(POPs) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
            PUTBACK; FREETMPS; LEAVE;
            /*
             # uncoverable branch true
             # uncoverable condition right count:1 class:ignore_covered_err
             # uncoverable condition left count:2 class:ignore_covered_err */
            if (SvTRUE(ERRSV)) {
                /*
                 # uncoverable statement
                 # uncoverable branch true
                 # uncoverable branch false
                 # uncoverable condition left count:1
                 # uncoverable condition right count:1 */
                if (f) SvREFCNT_dec(f);
                Safefree(argv); /* # uncoverable statement */
                pdl_fail(aTHX_ p, ERRSV); /* # uncoverable statement */
                return; /* # uncoverable statement */
            }
        }
        Safefree(argv);
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err */
        if (!f) {
            pdl_fail(aTHX_ p, sv_2mortal(newSVpvs( /* # uncoverable statement */
                PDL_CLS ": the transaction handle returned no future")));
            return; /* # uncoverable statement */
        }
        p->shape = is_query ? shape : 0; /* # uncoverable condition right count:1 class:ignore_covered_err */
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 class:ignore_covered_err */
        if (!p->tx) p->tx = newSVsv(tx);
        pdl_attach(aTHX_ f, p);
        return;
    }
    pdl_attach(aTHX_ is_query ? A->exec_shaped(aTHX_ db, sql, bind, shape, NULL)
                              : A->exec(aTHX_ db, 0, sql, bind), p);
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

    /* A statement on a transaction handle settles with the raw result -
     * the pinned handle has no shaped form - so the shape exec_shaped would
     * have applied is applied here instead, before the op sees it. */
    if (p->shape && n > 0) { /* # uncoverable condition right count:2 class:ignore_covered_err */
        AV *out = (AV *)sv_2mortal((SV *)newAV());
        SV *err = A->reshape(aTHX_ p->shape, v[0], NULL, out);
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err */
        if (err) {
            pdl_fail(aTHX_ p, err); /* # uncoverable statement */
            SvREFCNT_dec(err); /* # uncoverable statement */
            pdl_pend_free(aTHX_ p); /* # uncoverable statement */
            return; /* # uncoverable statement */
        }
        n = av_len(out) + 1;
        v[0] = n > 0 ? *av_fetch(out, 0, 0) : &PL_sv_undef; /* # uncoverable condition right count:1 class:ignore_covered_err */
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 class:ignore_covered_err */
        if (n > 0) n = 1;
        p->shape = 0;
    }

    /*
     # uncoverable branch true count:5
     # uncoverable branch true count:6 */
    switch (p->op) {

    case PDL_OP_PASS: {
        SV *r = (n > 0 && SvOK(v[0])) ? v[0] : &PL_sv_undef; /* # uncoverable condition right count:1 class:ignore_covered_err */
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
        /* the rows are borrowed from the DBIx::Loop future; pdbq_page takes
         * ownership of the reference it is handed, so hand it one of ours */
        SV *rows_rv = (n > 0 && SvROK(v[0]) && SvTYPE(SvRV(v[0])) == SVt_PVAV)
                    ? newRV_inc(SvRV(v[0])) : NULL;
        SV *out_rv = sv_2mortal(pdbq_page(aTHX_ rows_rv, p->limit,
                                          p->cols, p->desc, p->pk_only));
        pf_settle_argv(aTHX_ p->pf, PF_DONE, &out_rv, 1);
        break;
    }

    case PDL_OP_COUNT: {
        HV *r = (n > 0 && SvROK(v[0]) && SvTYPE(SvRV(v[0])) == SVt_PVHV)
              ? (HV *)SvRV(v[0]) : NULL;
        SV *ra = r ? pdbi_get(aTHX_ r, "rows_affected") : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
        /*
         # uncoverable condition right count:1 class:ignore_covered_err
         # uncoverable condition right count:2 class:ignore_covered_err */
        SV *c  = sv_2mortal(newSViv(ra && SvOK(ra) ? SvIV(ra) : 0));
        pf_settle_argv(aTHX_ p->pf, PF_DONE, &c, 1);
        break;
    }

    /* the do() half of a write on a driver without RETURNING: chain the
     * re-get so server-side defaults still come back, exactly as the DBI
     * backend does synchronously. insert_id comes from the DO RESULT - the
     * worker's own handle, the connection the INSERT actually ran on -
     * never from $db->dbh, which is the parent's separate connection. */
    case PDL_OP_CREATE_FB: /* # uncoverable statement */
    case PDL_OP_UPDATE_FB: {
        SV *id = p->pkval; /* # uncoverable statement */
        /*
         # uncoverable statement
         # uncoverable branch true
         # uncoverable branch false
         # uncoverable condition left count:1
         # uncoverable condition right count:1
         # uncoverable condition left count:2
         # uncoverable condition right count:2 */
        if (!id && p->op == PDL_OP_CREATE_FB) {
            HV *r = (n > 0 && SvROK(v[0]) && SvTYPE(SvRV(v[0])) == SVt_PVHV) /* # uncoverable statement */
                  ? (HV *)SvRV(v[0]) : NULL; /* # uncoverable statement */
            /*
             # uncoverable statement
             # uncoverable condition left count:1
             # uncoverable condition right count:1 */
            id = r ? pdbi_get(aTHX_ r, "insert_id") : NULL;
        }
        /*
         # uncoverable statement
         # uncoverable branch true
         # uncoverable branch false
         # uncoverable condition left count:1
         # uncoverable condition right count:1
         # uncoverable condition left count:2
         # uncoverable condition right count:2
         # uncoverable condition left count:3
         # uncoverable condition right count:3 */
        if (!p->pk || !id || !SvOK(id)) {
            /* no key to re-fetch by: echo the payload, as the DBI backend
             * does for a keyless create */
            SV *r = p->data && SvROK(p->data) /* # uncoverable statement */
                  ? sv_2mortal(newRV_noinc((SV *)newHVhv((HV *)SvRV(p->data)))) /* # uncoverable statement */
                  : &PL_sv_undef; /* # uncoverable statement */
            pf_settle_argv(aTHX_ p->pf, PF_DONE, &r, 1); /* # uncoverable statement */
            break; /* # uncoverable statement */
        }
        {
            AV *bind = (AV *)sv_2mortal((SV *)newAV()); /* # uncoverable statement */
            SV *sql  = sv_2mortal(newSVpvs("SELECT * FROM ")); /* # uncoverable statement */
            SV *nf;
            sv_catsv(sql, pdbi_qi_slot(aTHX_ p->slot, p->dbh, p->table)); /* # uncoverable statement */
            sv_catpvs(sql, " WHERE "); /* # uncoverable statement */
            sv_catsv(sql, pdbi_qi_slot(aTHX_ p->slot, p->dbh, p->pk)); /* # uncoverable statement */
            sv_catpvs(sql, " = ? LIMIT 1"); /* # uncoverable statement */
            av_push(bind, newSVsv(id)); /* # uncoverable statement */
            p->op = PDL_OP_PASS; /* # uncoverable statement */
            /* inside a transaction the re-get must run on the pinned
             * handle, or it runs on another slot and cannot see the row */
            pdl_exec(aTHX_ p, p->db, p->tx, 1, sql, bind, /* # uncoverable statement */
                     DBIL_ABI_ROW_HASHREF);   /* the same pend rides along */
            PERL_UNUSED_VAR(nf);
            return;                    /* not freed: the follow-up owns it */ /* # uncoverable statement */
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
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 class:ignore_covered_err
         # uncoverable condition right count:2 class:ignore_covered_err
         # uncoverable condition right count:3 class:ignore_covered_err */
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

    pdbq_check_keys(aTHX_ self, keys, PDL_CLS, "get");

    sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, table));
    sv_catpvs(sql, " WHERE ");
    sv_catsv(sql, where);
    sv_catpvs(sql, " LIMIT 1");

    p = pdl_start(aTHX_ A, slot, &out);
    p->op = PDL_OP_PASS;
    pdl_exec(aTHX_ p, db, pdl_tx_of(aTHX_ self), 1, sql, bind, DBIL_ABI_ROW_HASHREF);
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
    SV *colsv  = pdbi_get(aTHX_ h, "col");
    /*
     # uncoverable condition right count:1 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
    HV *col    = (colsv && SvROK(colsv)) ? (HV *)SvRV(colsv) : NULL;
    HV *slot   = pdl_handle(aTHX_ self);
    SV *db     = pdbi_get(aTHX_ slot, "db");
    SV *dbh    = pdbi_get(aTHX_ slot, "dbh");
    AV *bind   = (AV *)sv_2mortal((SV *)newAV());
    const dbil_abi *A = punk_dbil(aTHX);
    AV *cols, *desc;
    IV limit;
    int pk_only;
    SV *sql, *out;
    pdl_pend *p;

    /* synchronous, before the exec: a bad filter, option or token is a
     * caller error and croaks here, exactly as the DBI backend's does */
    sql = pdbq_search_sql(aTHX_ slot, dbh, col, table, pk, f, o, PDL_CLS,
                          bind, &limit, &cols, &desc, &pk_only);

    p = pdl_start(aTHX_ A, slot, &out);
    p->op      = PDL_OP_SEARCH;
    p->limit   = limit;
    p->cols    = (AV *)SvREFCNT_inc((SV *)cols);
    p->desc    = (AV *)SvREFCNT_inc((SV *)desc);
    p->pk_only = pk_only;
    pdl_exec(aTHX_ p, db, pdl_tx_of(aTHX_ self), 1, sql, bind, DBIL_ABI_ALL_ROWHASH);
    return out;
}

/* count(\%filter) -> future of the matching row count */
static SV *pdl_count(pTHX_ SV *self, SV *filter) {
    HV *h  = pdbi_hv(aTHX_ self);
    HV *f  = (SvROK(filter) && SvTYPE(SvRV(filter)) == SVt_PVHV)
             ? (HV *)SvRV(filter) : NULL;
    SV *table  = pdbi_get(aTHX_ h, "table");
    SV *colsv  = pdbi_get(aTHX_ h, "col");
    /*
     # uncoverable condition right count:1 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
    HV *col    = (colsv && SvROK(colsv)) ? (HV *)SvRV(colsv) : NULL;
    HV *slot   = pdl_handle(aTHX_ self);
    SV *db     = pdbi_get(aTHX_ slot, "db");
    SV *dbh    = pdbi_get(aTHX_ slot, "dbh");
    AV *bind   = (AV *)sv_2mortal((SV *)newAV());
    const dbil_abi *A = punk_dbil(aTHX);
    SV *sql = pdbq_count_sql(aTHX_ slot, dbh, col, table, f, PDL_CLS, bind);
    SV *out;
    pdl_pend *p;

    p = pdl_start(aTHX_ A, slot, &out);
    /* the first row as a list, and the first value of that list is the
     * count: the PASS continuation settles with values[0] */
    p->op = PDL_OP_PASS;
    pdl_exec(aTHX_ p, db, pdl_tx_of(aTHX_ self), 1, sql, bind, DBIL_ABI_ROW_ARRAY);
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
    /*
     # uncoverable condition right count:1 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
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
        HE *he = d ? hv_fetch_ent(d, k, 0, 0) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
        if (!(known && hv_exists_ent(known, k, 0))) continue; /* # uncoverable condition left count:1 class:ignore_covered_err */
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err
         # uncoverable condition left count:2 class:ignore_covered_err */
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

    /*
     # uncoverable branch false
     # uncoverable condition right count:1 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
    if (ret && SvIV(ret)) {
        /* RETURNING goes through the QUERY path, not do - do discards rows.
         * The row arrives already reshaped. */
        sv_catpvs(sql, " RETURNING *");
        p->op = PDL_OP_PASS;
        pdl_exec(aTHX_ p, db, pdl_tx_of(aTHX_ self), 1, sql, bind, DBIL_ABI_ROW_HASHREF);
        return out;
    }

    p->op    = PDL_OP_CREATE_FB; /* # uncoverable statement */
    p->db    = newSVsv(db); /* # uncoverable statement */
    p->dbh   = newSVsv(dbh); /* # uncoverable statement */
    p->table = newSVsv(table); /* # uncoverable statement */
    /*
     # uncoverable statement
     # uncoverable branch true
     # uncoverable branch false
     # uncoverable condition left count:1
     # uncoverable condition right count:1
     # uncoverable condition left count:2
     # uncoverable condition right count:2 */
    if (pk && SvOK(pk)) {
        /*
         # uncoverable statement
         # uncoverable condition left count:1
         # uncoverable condition right count:1 */
        HE *he = d ? hv_fetch_ent(d, pk, 0, 0) : NULL;
        p->pk = newSVsv(pk); /* # uncoverable statement */
        /*
         # uncoverable statement
         # uncoverable branch true
         # uncoverable branch false
         # uncoverable condition left count:1
         # uncoverable condition right count:1
         # uncoverable condition left count:2
         # uncoverable condition right count:2 */
        if (he && SvOK(HeVAL(he))) p->pkval = newSVsv(HeVAL(he));
    }
    /*
     # uncoverable statement
     # uncoverable branch true
     # uncoverable branch false
     # uncoverable condition left count:1
     # uncoverable condition right count:1 */
    if (d) p->data = newSVsv(data);
    pdl_exec(aTHX_ p, db, pdl_tx_of(aTHX_ self), 0, sql, bind, 0); /* # uncoverable statement */
    return out; /* # uncoverable statement */
}

/* update(\%key_and_changes) -> future of the stored row */
static SV *pdl_update(pTHX_ SV *self, SV *data) {
    HV *h   = pdbi_hv(aTHX_ self);
    HV *d   = (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)
              ? (HV *)SvRV(data) : NULL;
    SV *colset = pdbi_get(aTHX_ h, "col");
    /*
     # uncoverable condition right count:1 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
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

    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err
     # uncoverable condition left count:2 class:ignore_covered_err */
    if (!(pk && SvOK(pk)))
        croak(PDL_CLS ": update needs a primary key"); /* # uncoverable statement */
    pke = d ? hv_fetch_ent(d, pk, 0, 0) : NULL; /* # uncoverable condition right count:1 class:ignore_covered_err */
    if (!(pke && SvOK(HeVAL(pke)))) /* # uncoverable condition left count:2 class:ignore_covered_err */
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
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err
         # uncoverable condition left count:2 class:ignore_covered_err */
        if (!(known && hv_exists_ent(known, k, 0))) continue;
        he = hv_fetch_ent(d, k, 0, 0);
        av_push(cols, newSVsv(k));
        av_push(bind, newSVsv(he ? HeVAL(he) : &PL_sv_undef)); /* # uncoverable condition right count:1 class:ignore_covered_err */
    }
    if (av_len(cols) < 0)
        croak(PDL_CLS ": update with no columns to change");

    set = sv_2mortal(newSVpvs(""));
    n = av_len(cols) + 1;
    for (i = 0; i < n; i++) {
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err */
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

    /*
     # uncoverable branch false
     # uncoverable condition right count:1 class:ignore_covered_err
     # uncoverable condition right count:2 class:ignore_covered_err */
    if (ret && SvIV(ret)) {
        sv_catpvs(sql, " RETURNING *");
        p->op = PDL_OP_PASS;
        pdl_exec(aTHX_ p, db, pdl_tx_of(aTHX_ self), 1, sql, bind, DBIL_ABI_ROW_HASHREF);
        return out;
    }

    p->op    = PDL_OP_UPDATE_FB; /* # uncoverable statement */
    p->db    = newSVsv(db); /* # uncoverable statement */
    p->dbh   = newSVsv(dbh); /* # uncoverable statement */
    p->table = newSVsv(table); /* # uncoverable statement */
    p->pk    = newSVsv(pk); /* # uncoverable statement */
    p->pkval = newSVsv(id); /* # uncoverable statement */
    pdl_exec(aTHX_ p, db, pdl_tx_of(aTHX_ self), 0, sql, bind, 0); /* # uncoverable statement */
    return out; /* # uncoverable statement */
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

    pdbq_check_keys(aTHX_ self, keys, PDL_CLS, "delete");

    sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, table));
    sv_catpvs(sql, " WHERE ");
    sv_catsv(sql, where);

    p = pdl_start(aTHX_ A, slot, &out);
    p->op = PDL_OP_COUNT;
    pdl_exec(aTHX_ p, db, pdl_tx_of(aTHX_ self), 0, sql, bind, 0);
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
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err
         # uncoverable condition left count:2 class:ignore_covered_err */
        if (!hm || !adapter)
            croak(PDL_CLS ": await with no loop adapter to pump"); /* # uncoverable statement */
        loop_sv = pcx_call_meth(aTHX_ adapter, "loop", NULL, 0, 1);
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 class:ignore_covered_err
         # uncoverable condition left count:2 class:ignore_covered_err */
        if (!(loop_sv && SvROK(loop_sv)))
            croak(PDL_CLS ": the adapter has no loop to pump"); /* # uncoverable statement */
        sv_2mortal(loop_sv);
        loop = hm->loop_of_sv(aTHX_ loop_sv);
        hf   = hm->future_new(aTHX);
        cap  = newAV();
        av_push(cap, newSVsv(hf));
        clos = sv_2mortal(punk_closure(aTHX_ pf_wake_hf_cb, cap));
        pf_react(aTHX_ pf, f, PFR_ON_READY, clos);
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 class:ignore_covered_err */
        if (pf->state == PF_PENDING)
            hm->run_until(aTHX_ loop, hf);
        SvREFCNT_dec(hf);
    }
}

#endif /* PUNK_DBIL_H */
