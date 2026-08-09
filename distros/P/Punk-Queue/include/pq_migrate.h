#ifndef PQ_MIGRATE_H
#define PQ_MIGRATE_H

/* pq_migrate.h - the migration runner, shared by both backends.
 *
 * Minion's model, kept: a single named row in pq_migrations holds the
 * schema version, and migrate($to) applies steps version+1 .. $to inside
 * one transaction. Both backends have transactional DDL, so a failed
 * migration leaves the schema exactly as it was rather than half-applied.
 *
 * v0.01 is forward-only, and says so rather than shipping a down path that
 * has never been run. `punk-queue migrate --check` (phase 3) is the deploy
 * hook.
 *
 * The lock is per-backend: pg_advisory_xact_lock on Pg, BEGIN IMMEDIATE on
 * SQLite. Without one, two workers booting together race to apply step 1
 * and one of them gets "table already exists".
 *
 * Include after pq_dbi.h and the per-backend step arrays. */

#define PQ_MIGRATION_NAME "punk_queue"

/* Split one migration into statements on a line containing only "-- @@".
 * Mortal AV of mortal-safe copies. */
static AV *pq_migrate_split(pTHX_ const char *step) {
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    const char *p = step, *start = step;
    for (;;) {
        const char *nl = strchr(p, '\n');
        STRLEN linelen = nl ? (STRLEN)(nl - p) : strlen(p);
        /* a separator line is exactly "-- @@" possibly with trailing space */
        int sep = 0;
        if (linelen >= 5 && memEQ(p, "-- @@", 5)) {
            STRLEN i;
            sep = 1;
            for (i = 5; i < linelen; i++)
                if (p[i] != ' ' && p[i] != '\t' && p[i] != '\r') { sep = 0; break; }
        }
        if (sep) {
            if (p > start) av_push(out, newSVpvn(start, (STRLEN)(p - start)));
            start = nl ? nl + 1 : p + linelen;
        }
        if (!nl) break;
        p = nl + 1;
    }
    if (*start) av_push(out, newSVpvn(start, strlen(start)));
    return out;
}

/* The schema version recorded in the database, or 0 when the table does not
 * exist yet. Never croaks on a missing table - that is the first-run case. */
static IV pq_schema_version(pTHX_ SV *self) {
    SV *sth, *sql = sv_2mortal(newSVpvs(
        "SELECT version FROM pq_migrations WHERE name = ?"));
    AV *bind = pq_binds(aTHX), *row;
    IV v = 0;
    int died = 0;
    SV *dbh = pq_dbh(aTHX_ self);
    SV *argv[3];

    pq_bind_pv(aTHX_ bind, PQ_MIGRATION_NAME);

    argv[0] = sql;
    argv[1] = &PL_sv_undef;
    argv[2] = sv_2mortal(newSViv(3));
    sth = pq_call_meth_ev(aTHX_ dbh, "prepare_cached", argv, 3, 1, &died);
    if (died || !sth) { if (sth) SvREFCNT_dec(sth); return 0; }
    sv_2mortal(sth);

    {
        SSize_t n = av_len(bind) + 1, i;
        SV **ea = n ? (SV **)pq_xmalloc(aTHX_ sizeof(SV *) * (size_t)n) : NULL;
        SV *r;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(bind, i, 0);
            ea[i] = (e && *e) ? *e : &PL_sv_undef;
        }
        r = pq_call_meth_ev(aTHX_ sth, "execute", ea, (int)n, 1, &died);
        if (ea) safefree(ea);
        if (r) SvREFCNT_dec(r);
        if (died) return 0;               /* no such table: version 0 */
    }

    row = pq_fetchrow(aTHX_ sth);
    if (row) {
        v = pq_col_iv(aTHX_ row, 0);
        SvREFCNT_dec((SV *)row);
    }
    { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
      if (r) SvREFCNT_dec(r); }
    return v;
}

/* Forward declarations: transaction control and the step table are
 * per-backend. */
static void   pq_txn_begin_exclusive(pTHX_ SV *self);
static void   pq_txn_commit(pTHX_ SV *self);
static void   pq_txn_rollback(pTHX_ SV *self);
static const char *const *pq_migration_steps(pTHX_ SV *self);
static void   pq_check_server_version(pTHX_ SV *self);

static IV pq_migration_count(pTHX_ SV *self) {
    const char *const *steps = pq_migration_steps(aTHX_ self);
    IV n = 0;
    while (steps && steps[n]) n++;
    return n;
}

/* Apply steps up to `to` (or all of them when to <= 0). Returns the version
 * now in the database. Idempotent: re-running against a current schema does
 * nothing and returns the same number. */
static IV pq_migrate(pTHX_ SV *self, IV to) {
    const char *const *steps = pq_migration_steps(aTHX_ self);
    IV have, want = pq_migration_count(aTHX_ self), i;

    pq_check_server_version(aTHX_ self);

    if (to > 0 && to < want) want = to;

    /* Cheap pre-check outside the lock: the overwhelmingly common call is
     * "already current" on every worker boot, and taking an exclusive lock
     * for that would serialise startup across the fleet. */
    have = pq_schema_version(aTHX_ self);
    if (have >= want) return have;

    pq_txn_begin_exclusive(aTHX_ self);

    /* The version table is created BEFORE it is read inside the
     * transaction, unconditionally. Order matters on PostgreSQL: any error
     * inside a transaction aborts the whole transaction, so the tolerant
     * "read the version, treat a missing table as 0" trick that works on
     * autocommit (and that SQLite forgives anywhere) would poison the
     * migration transaction on a fresh Pg database. With the CREATE first,
     * the in-transaction read can never fail. */
    (void)pq_do_pv(aTHX_ self,
        "CREATE TABLE IF NOT EXISTS pq_migrations ("
        "name TEXT PRIMARY KEY, version INTEGER NOT NULL)");

    /* Re-read under the lock: another process may have applied everything
     * between the pre-check and here. */
    {
        AV *b = pq_binds(aTHX), *row;
        pq_bind_pv(aTHX_ b, PQ_MIGRATION_NAME);
        row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT version FROM pq_migrations WHERE name = ?")), b);
        if (row) {
            have = pq_col_iv(aTHX_ row, 0);
            SvREFCNT_dec((SV *)row);
        }
        else {
            have = 0;
            b = pq_binds(aTHX);
            pq_bind_pv(aTHX_ b, PQ_MIGRATION_NAME);
            (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                "INSERT INTO pq_migrations (name, version) VALUES (?, 0)")), b);
        }
    }
    if (have >= want) { pq_txn_commit(aTHX_ self); return have; }

    for (i = have; i < want; i++) {
        AV *stmts = pq_migrate_split(aTHX_ steps[i]);
        SSize_t n = av_len(stmts) + 1, j;
        for (j = 0; j < n; j++) {
            SV **e = av_fetch(stmts, j, 0);
            if (!(e && *e)) continue;
            /* Skip a chunk that is only whitespace - a trailing separator
             * or a blank line between statements. */
            {
                STRLEN l;
                const char *s = SvPV_const(*e, l);
                STRLEN k = 0;
                while (k < l && isSPACE((U8)s[k])) k++;
                if (k == l) continue;
            }
            (void)pq_do(aTHX_ self, *e, NULL);
        }
    }

    {
        AV *b = pq_binds(aTHX);
        pq_bind_iv(aTHX_ b, want);
        pq_bind_pv(aTHX_ b, PQ_MIGRATION_NAME);
        (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "UPDATE pq_migrations SET version = ? WHERE name = ?")), b);
    }

    pq_txn_commit(aTHX_ self);
    return want;
}

#endif /* PQ_MIGRATE_H */
