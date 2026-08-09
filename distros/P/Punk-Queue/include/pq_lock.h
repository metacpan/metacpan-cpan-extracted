#ifndef PQ_LOCK_H
#define PQ_LOCK_H

/* pq_lock.h - distributed locks, two disciplines behind one API.
 *
 * The two have genuinely different races and genuinely different arbiters:
 *
 *   limit 1, the LEASE: an owned row under the partial unique index
 *   pq_locks_name (name WHERE owner IS NOT NULL). DELETE the expired
 *   holder, then INSERT - exactly one insert wins, the rest take a
 *   constraint violation and back off. No count-then-insert race exists,
 *   which is what makes this the phase-9 leader-election arbiter.
 *
 *   limit N, the COUNTED lock (Minion's semantics): ownerless rows, count
 *   the live ones, insert if under the limit. Count-then-insert needs a
 *   serialisation point: BEGIN IMMEDIATE is already one on SQLite; on Pg
 *   the counted path takes a transaction-scoped advisory lock keyed on a
 *   C hash of the name, so two counters cannot both see "under the limit".
 *
 * Expiry is honoured on READ everywhere - an expired row never counts and
 * never blocks - not just swept by repair, so a stalled repair cannot
 * deadlock the queue.
 *
 * Include after pq_backend.h. */

/* FNV-1a over the name, folded positive for pg_advisory_xact_lock. A
 * collision only costs false serialisation on the counted path, never
 * correctness, so the 32-bit fallback on a 32-bit-UV perl is fine. */
static IV pq_lock_hash(const char *s, STRLEN len) {
#if UVSIZE >= 8
    UV h = (UV)UINT64_C(14695981039346656037);
    const UV prime = (UV)UINT64_C(1099511628211);
#else
    UV h = 2166136261u;
    const UV prime = 16777619u;
#endif
    STRLEN i;
    for (i = 0; i < len; i++) {
        h ^= (U8)s[i];
        h *= prime;
    }
    return (IV)(h >> 1);    /* clear the sign bit portably */
}

static void pq_lock_serialise(pTHX_ SV *self, SV *name) {
    pq_txn_begin(aTHX_ self);
    if (pq_is_pg(aTHX_ self)) {
        STRLEN len;
        const char *s = SvPV_const(name, len);
        AV *b = pq_binds(aTHX);
        pq_bind_iv(aTHX_ b, pq_lock_hash(s, len));
        (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT pg_advisory_xact_lock(?)")), b);
    }
}

/* Acquire. Returns 1 on success, 0 when the lock is held to its limit.
 * duration is seconds from now; owner identifies the holder for renewal
 * (leases only - counted locks are ownerless by design). */
static IV pq_lock(pTHX_ SV *self, SV *name, double duration, IV limit,
                  IV owner) {
    double now, expires;

    pq_name_check(aTHX_ name, "lock");
    if (duration <= 0)
        croak("Punk::Queue: lock duration must be positive");
    if (limit < 1) limit = 1;
    now = pq_now(aTHX_ self);
    expires = now + duration;

    if (limit == 1) {
        /* the lease: sweep the expired holder, then let the unique index
         * arbitrate. Autocommit on both statements - a trapped violation
         * inside a transaction would abort it on Pg. */
        {
            AV *b = pq_binds(aTHX);
            pq_bind_sv(aTHX_ b, name);
            pq_bind_nv(aTHX_ b, now);
            (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                "DELETE FROM pq_locks WHERE name = ? AND expires <= ?"
                " AND owner IS NOT NULL")), b);
        }
        {
            int died = 0;
            SV *sth = pq_sth(aTHX_ self, sv_2mortal(newSVpvs(
                "INSERT INTO pq_locks (name, owner, expires)"
                " VALUES (?, ?, ?)")));
            SV *ea[3], *r;
            ea[0] = name;
            ea[1] = sv_2mortal(newSViv(owner));
            ea[2] = sv_2mortal(newSVnv(expires));
            r = pq_call_meth_ev(aTHX_ sth, "execute", ea, 3, 1, &died);
            if (r) SvREFCNT_dec(r);
            return died ? 0 : 1;    /* the violation IS the losing ticket */
        }
    }

    /* the counted lock */
    {
        IV live = 0, got = 0;
        pq_lock_serialise(aTHX_ self, name);
        {
            AV *b = pq_binds(aTHX), *row;
            pq_bind_sv(aTHX_ b, name);
            pq_bind_nv(aTHX_ b, now);
            row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
                "SELECT count(*) FROM pq_locks"
                " WHERE name = ? AND expires > ? AND owner IS NULL")), b);
            if (row) { live = pq_col_iv(aTHX_ row, 0); SvREFCNT_dec((SV *)row); }
        }
        if (live < limit) {
            AV *b = pq_binds(aTHX);
            pq_bind_sv(aTHX_ b, name);
            pq_bind_nv(aTHX_ b, expires);
            (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                "INSERT INTO pq_locks (name, owner, expires)"
                " VALUES (?, NULL, ?)")), b);
            got = 1;
        }
        pq_txn_commit(aTHX_ self);
        return got;
    }
}

/* Extend a held lease. 0 rows means the lease was LOST - expired and
 * possibly taken by someone else - and the caller must re-acquire, not
 * assume. This return-value honesty is what phase 9's leader loop leans
 * on: a leader that pauses past its expiry discovers it. */
static IV pq_renew_lock(pTHX_ SV *self, SV *name, IV owner,
                        double duration) {
    AV *b = pq_binds(aTHX);
    double now = pq_now(aTHX_ self);
    pq_name_check(aTHX_ name, "lock");
    pq_bind_nv(aTHX_ b, now + duration);
    pq_bind_sv(aTHX_ b, name);
    pq_bind_iv(aTHX_ b, owner);
    pq_bind_nv(aTHX_ b, now);
    return pq_do(aTHX_ self, sv_2mortal(newSVpvs(
        "UPDATE pq_locks SET expires = ?"
        " WHERE name = ? AND owner = ? AND expires > ?")), b) > 0 ? 1 : 0;
}

/* Release. With an owner: that holder's lease. Without: one counted slot,
 * oldest first (Minion's semantics - unlock releases A hold, not all of
 * them). Returns 1 when a row was released. */
static IV pq_unlock(pTHX_ SV *self, SV *name, IV owner, int has_owner) {
    AV *b = pq_binds(aTHX);
    pq_name_check(aTHX_ name, "lock");
    if (has_owner) {
        pq_bind_sv(aTHX_ b, name);
        pq_bind_iv(aTHX_ b, owner);
        return pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "DELETE FROM pq_locks WHERE name = ? AND owner = ?")), b) > 0
            ? 1 : 0;
    }
    pq_bind_sv(aTHX_ b, name);
    pq_bind_sv(aTHX_ b, name);
    return pq_do(aTHX_ self, sv_2mortal(newSVpvs(
        "DELETE FROM pq_locks WHERE id ="
        " (SELECT min(id) FROM pq_locks WHERE name = ?)"
        " AND name = ?")), b) > 0 ? 1 : 0;
}

static SV *pq_list_locks(pTHX_ SV *self, IV offset, IV limit, HV *filter) {
    SV *where = pq_sql_new(aTHX_ "");
    AV *fbind = pq_binds(aTHX);
    HV *out = newHV();
    AV *ls = newAV();
    SV *v;

    if (filter && (v = pq_get(aTHX_ filter, "name")) && SvOK(v)) {
        pq_sql_cat(aTHX_ where, " WHERE name = ?");
        pq_bind_sv(aTHX_ fbind, v);
    }
    {
        static const char *const cols[] =
            { "name", "CAST(owner AS TEXT)", NULL };
        int first = !(filter && (v = pq_get(aTHX_ filter, "name"))
                      && SvOK(v));
        pq_search_filter(aTHX_ where, fbind, &first, filter, cols);
    }

    {
        SV *sql = pq_sql_new(aTHX_ "SELECT count(*) FROM pq_locks");
        AV *row;
        pq_sql_cat_all(aTHX_ sql, where);
        row = pq_selectrow(aTHX_ self, sql, fbind);
        (void)hv_stores(out, "total",
                        newSViv(row ? pq_col_iv(aTHX_ row, 0) : 0));
        if (row) SvREFCNT_dec((SV *)row);
    }

    {
        SV *sql = pq_sql_new(aTHX_
            "SELECT id, name, owner, expires FROM pq_locks");
        SV *sth;
        AV *bind = pq_binds(aTHX), *row;
        SSize_t n = av_len(fbind) + 1, k;
        for (k = 0; k < n; k++) pq_bind_sv(aTHX_ bind, *av_fetch(fbind, k, 0));
        pq_sql_cat_all(aTHX_ sql, where);
        pq_sql_cat(aTHX_ sql, " ORDER BY id LIMIT ? OFFSET ?");
        pq_bind_iv(aTHX_ bind, limit  > 0 ? limit  : 50);
        pq_bind_iv(aTHX_ bind, offset > 0 ? offset : 0);

        sth = pq_sth(aTHX_ self, sql);
        (void)pq_execute(aTHX_ sth, bind);
        while ((row = pq_fetchrow(aTHX_ sth))) {
            HV *h = newHV();
            SV *o = pq_col(aTHX_ row, 2);
            pq_hv_set_iv(aTHX_ h, "id",   pq_col_iv(aTHX_ row, 0));
            pq_hv_set_sv(aTHX_ h, "name", pq_col(aTHX_ row, 1));
            (void)hv_stores(h, "owner",
                            SvOK(o) ? newSViv(SvIV(o)) : newSV(0));
            pq_hv_set_nv_or_undef(aTHX_ h, "expires",
                                  pq_col(aTHX_ row, 3));
            av_push(ls, newRV_noinc((SV *)h));
            SvREFCNT_dec((SV *)row);
        }
        { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
          if (r) SvREFCNT_dec(r); }
    }

    (void)hv_stores(out, "locks", newRV_noinc((SV *)ls));
    return newRV_noinc((SV *)out);
}

#endif /* PQ_LOCK_H */
