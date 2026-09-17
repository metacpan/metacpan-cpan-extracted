MODULE = Punk        PACKAGE = Punk::Model::DBI

PROTOTYPES: DISABLE

# The shipped model backend, in C (punk_dbi.h). Plain DBI, no ORM: the six
# contract methods build their SQL here and hand it to DBI, which is still
# where every round trip happens. Punk::Model::DBI.pm is the documentation.

SV *
new(class, ...)
        SV *class
    CODE:
        RETVAL = pdbi_build_self(aTHX_ class, &ST(0), items,
                                 "Punk::Model::DBI");
    OUTPUT:
        RETVAL

# The live per-worker handle for this backend's dsn, connected on first use
# and shared with every other backend on the same database.
SV *
dbh(self)
        SV *self
    CODE:
        RETVAL = newSVsv(pdbi_dbh(aTHX_ self));
    OUTPUT:
        RETVAL

# create/update read this; connecting is what detects it, so make sure a
# connection exists before the answer is believed.
IV
_returning(self)
        SV *self
    CODE:
    {
        SV *r;
        (void)pdbi_dbh(aTHX_ self);
        r = pdbi_get(aTHX_ pdbi_hv(aTHX_ self), "returning");
        RETVAL = r ? SvIV(r) : 0;
    }
    OUTPUT:
        RETVAL

IV
_detect_returning(self, dbh)
        SV *self
        SV *dbh
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = pdbi_detect_returning(aTHX_ dbh);
    OUTPUT:
        RETVAL

SV *
_sth(self, sql)
        SV *self
        SV *sql
    CODE:
        RETVAL = newSVsv(pdbi_sth(aTHX_ self, sql));
    OUTPUT:
        RETVAL

SV *
_qi(self, name)
        SV *self
        SV *name
    CODE:
        RETVAL = newSVsv(pdbi_qi(aTHX_ self, name));
    OUTPUT:
        RETVAL

# ---- reads ------------------------------------------------------------------

# get(%key) -> the row hashref, or undef.
SV *
get(self, ...)
        SV *self
    CODE:
    {
        HV *key;
        AV *keys = pdbi_key_args(aTHX_ &ST(0), items, &key, "get", "Punk::Model::DBI");
        AV *bind = (AV *)sv_2mortal((SV *)newAV());
        HV *slot = pdbi_slot_for(aTHX_ self);
        SV *sig  = pdbi_sig(aTHX_ "get",
                            pdbi_get(aTHX_ pdbi_hv(aTHX_ self), "table"), keys);
        SV *sql  = pdbi_sql_cached(aTHX_ slot, sig, NULL);
        SV *sth, *row;

        /* the statement is the same for every get on these key columns, so it
         * is built once and only the bind values change */
        if (sql) pdbi_bind_keys(aTHX_ key, keys, bind);
        else {
            SV *dbh   = pdbi_get(aTHX_ slot, "dbh");
            SV *where = pdbi_where_eq_slot(aTHX_ slot, dbh, key, keys, bind);
            SV *table = pdbi_get(aTHX_ pdbi_hv(aTHX_ self), "table");
            SV *built = sv_2mortal(newSVpvs("SELECT * FROM "));
            sv_catsv(built, pdbi_qi_slot(aTHX_ slot, dbh, table));
            sv_catpvs(built, " WHERE ");
            sv_catsv(built, where);
            sv_catpvs(built, " LIMIT 1");
            sql = pdbi_sql_cached(aTHX_ slot, sig, built);
        }

        sth = pdbi_sth_dbh(aTHX_ pdbi_get(aTHX_ slot, "dbh"), sql);
        pdbi_execute_sql(aTHX_ sth, bind, sql);
        row = pdbi_meth0(aTHX_ sth, "fetchrow_hashref");
        { SV *f = pdbi_meth0(aTHX_ sth, "finish"); if (f) SvREFCNT_dec(f); }
        RETVAL = (row && SvOK(row)) ? row : (row ? (SvREFCNT_dec(row), newSV(0))
                                                 : newSV(0));
    }
    OUTPUT:
        RETVAL

SV *
all(self)
        SV *self
    CODE:
    {
        SV *argv[2];
        argv[0] = sv_2mortal(newRV_noinc((SV *)newHV()));
        argv[1] = sv_2mortal(newRV_noinc((SV *)newHV()));
        RETVAL = pcx_call_meth(aTHX_ self, "search", argv, 2, 1);
        if (!RETVAL) RETVAL = newSV(0);
    }
    OUTPUT:
        RETVAL

# search(\%filter, \%opts) -> { rows, has_more_data, next }
#
# The filter and its operators, the ordering and the keyset continuation are
# built in punk_dbq.h, shared with the async backend. LIMIT n+1 so one row
# past the limit answers "is there another page" without a second COUNT.
SV *
search(self, filter = &PL_sv_undef, opts = &PL_sv_undef)
        SV *self
        SV *filter
        SV *opts
    CODE:
    {
        HV *h  = pdbi_hv(aTHX_ self);
        HV *f  = (SvROK(filter) && SvTYPE(SvRV(filter)) == SVt_PVHV)
                 ? (HV *)SvRV(filter) : NULL;
        HV *o  = (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
                 ? (HV *)SvRV(opts) : NULL;
        SV *pk    = pdbi_get(aTHX_ h, "primary");
        SV *table = pdbi_get(aTHX_ h, "table");
        SV *colsv = pdbi_get(aTHX_ h, "col");
        HV *col   = (colsv && SvROK(colsv)) ? (HV *)SvRV(colsv) : NULL;
        HV *slot  = pdbi_slot_for(aTHX_ self);
        SV *dbh   = pdbi_get(aTHX_ slot, "dbh");
        AV *bind  = (AV *)sv_2mortal((SV *)newAV());
        AV *cols, *desc;
        IV limit;
        int pk_only;
        SV *sql, *sth, *rows_sv;

        sql = pdbq_search_sql(aTHX_ slot, dbh, col, table, pk, f, o,
                              "Punk::Model::DBI", bind,
                              &limit, &cols, &desc, &pk_only);

        sth = pdbi_sth_dbh(aTHX_ dbh, sql);
        pdbi_execute_sql(aTHX_ sth, bind, sql);
        {
            SV *argv[1];
            argv[0] = sv_2mortal(newRV_noinc((SV *)newHV()));
            rows_sv = pcx_call_meth(aTHX_ sth, "fetchall_arrayref", argv, 1, 1);
        }
        { SV *f2 = pdbi_meth0(aTHX_ sth, "finish"); if (f2) SvREFCNT_dec(f2); }

        RETVAL = pdbq_page(aTHX_ rows_sv, limit, cols, desc, pk_only);
    }
    OUTPUT:
        RETVAL

# count(\%filter) -> how many rows match. The same filter search takes, and
# the same validation; no page, no order, no token.
IV
count(self, filter = &PL_sv_undef)
        SV *self
        SV *filter
    CODE:
    {
        HV *h  = pdbi_hv(aTHX_ self);
        HV *f  = (SvROK(filter) && SvTYPE(SvRV(filter)) == SVt_PVHV)
                 ? (HV *)SvRV(filter) : NULL;
        SV *table = pdbi_get(aTHX_ h, "table");
        SV *colsv = pdbi_get(aTHX_ h, "col");
        HV *col   = (colsv && SvROK(colsv)) ? (HV *)SvRV(colsv) : NULL;
        HV *slot  = pdbi_slot_for(aTHX_ self);
        SV *dbh   = pdbi_get(aTHX_ slot, "dbh");
        AV *bind  = (AV *)sv_2mortal((SV *)newAV());
        SV *sql   = pdbq_count_sql(aTHX_ slot, dbh, col, table, f,
                                   "Punk::Model::DBI", bind);
        SV *sth, *row;

        sth = pdbi_sth_dbh(aTHX_ dbh, sql);
        pdbi_execute_sql(aTHX_ sth, bind, sql);
        row = pdbi_meth0(aTHX_ sth, "fetchrow_arrayref");
        { SV *f2 = pdbi_meth0(aTHX_ sth, "finish"); if (f2) SvREFCNT_dec(f2); }
        RETVAL = 0;
        if (row && SvROK(row) && SvTYPE(SvRV(row)) == SVt_PVAV) {
            SV **n = av_fetch((AV *)SvRV(row), 0, 0);
            if (n && *n && SvOK(*n)) RETVAL = SvIV(*n);
        }
        if (row) SvREFCNT_dec(row);
    }
    OUTPUT:
        RETVAL

# ---- writes -----------------------------------------------------------------

# create(\%data): insert the known columns and hand back the stored row -
# through RETURNING where the driver has it, otherwise re-fetched by key so
# server-side defaults still come back.
SV *
create(self, data)
        SV *self
        SV *data
    CODE:
    {
        HV *h   = pdbi_hv(aTHX_ self);
        HV *d   = (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)
                  ? (HV *)SvRV(data) : NULL;
        SV *colset = pdbi_get(aTHX_ h, "col");
        HV *known  = (colset && SvROK(colset)) ? (HV *)SvRV(colset) : NULL;
        SV *table  = pdbi_get(aTHX_ h, "table");
        SV *pk     = pdbi_get(aTHX_ h, "primary");
        AV *all    = pdbi_sorted_keys(aTHX_ d);
        AV *cols   = (AV *)sv_2mortal((SV *)newAV());
        AV *bind   = (AV *)sv_2mortal((SV *)newAV());
        SV *sql, *cl, *ph, *sth;
        SSize_t i, n = av_len(all) + 1;

        for (i = 0; i < n; i++) {
            SV *k = *av_fetch(all, i, 0);
            HE *he = d ? hv_fetch_ent(d, k, 0, 0) : NULL;
            if (!(known && hv_exists_ent(known, k, 0))) continue;
            if (!(he && SvOK(HeVAL(he)))) continue;   /* defined values only */
            av_push(cols, newSVsv(k));
            av_push(bind, newSVsv(HeVAL(he)));
        }
        if (av_len(cols) < 0)
            croak("Punk::Model::DBI: create with no known columns");

        cl = sv_2mortal(newSVpvs(""));
        ph = sv_2mortal(newSVpvs(""));
        n = av_len(cols) + 1;
        for (i = 0; i < n; i++) {
            if (i) { sv_catpvs(cl, ", "); sv_catpvs(ph, ", "); }
            sv_catsv(cl, pdbi_qi(aTHX_ self, *av_fetch(cols, i, 0)));
            sv_catpvs(ph, "?");
        }
        sql = sv_2mortal(newSVpvs("INSERT INTO "));
        sv_catsv(sql, pdbi_qi(aTHX_ self, table));
        sv_catpvs(sql, " (");   sv_catsv(sql, cl);
        sv_catpvs(sql, ") VALUES ("); sv_catsv(sql, ph);
        sv_catpvs(sql, ")");

        (void)pdbi_dbh(aTHX_ self);          /* connect, so returning is set */
        {
            SV *r = pdbi_get(aTHX_ h, "returning");
            if (r && SvIV(r)) {
                SV *row;
                sv_catpvs(sql, " RETURNING *");
                sth = pdbi_sth(aTHX_ self, sql);
                pdbi_execute_sql(aTHX_ sth, bind, sql);
                row = pdbi_meth0(aTHX_ sth, "fetchrow_hashref");
                { SV *f = pdbi_meth0(aTHX_ sth, "finish");
                  if (f) SvREFCNT_dec(f); }
                RETVAL = (row && SvOK(row)) ? row
                       : (row ? (SvREFCNT_dec(row), newSV(0)) : newSV(0));
                goto done_create;
            }
        }

        sth = pdbi_sth(aTHX_ self, sql);
        pdbi_execute_sql(aTHX_ sth, bind, sql);
        if (pk && SvOK(pk)) {
            HE *he = d ? hv_fetch_ent(d, pk, 0, 0) : NULL;
            SV *id;
            if (he && SvOK(HeVAL(he))) id = sv_2mortal(newSVsv(HeVAL(he)));
            else {
                SV *argv[4];
                argv[0] = &PL_sv_undef; argv[1] = &PL_sv_undef;
                argv[2] = table;        argv[3] = &PL_sv_undef;
                id = pcx_call_meth(aTHX_ pdbi_dbh(aTHX_ self),
                                   "last_insert_id", argv, 4, 1);
                id = id ? sv_2mortal(id) : &PL_sv_undef;
            }
            {
                SV *argv[2];
                argv[0] = pk; argv[1] = id;
                RETVAL = pcx_call_meth(aTHX_ self, "get", argv, 2, 1);
                if (!RETVAL) RETVAL = newSV(0);
            }
        }
        else RETVAL = d ? newRV_noinc((SV *)newHVhv(d)) : newSV(0);
      done_create: ;
    }
    OUTPUT:
        RETVAL

# update(\%key_and_changes): the primary key names the row, the rest is what
# changes.
SV *
update(self, data)
        SV *self
        SV *data
    CODE:
    {
        HV *h   = pdbi_hv(aTHX_ self);
        HV *d   = (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)
                  ? (HV *)SvRV(data) : NULL;
        SV *colset = pdbi_get(aTHX_ h, "col");
        HV *known  = (colset && SvROK(colset)) ? (HV *)SvRV(colset) : NULL;
        SV *table  = pdbi_get(aTHX_ h, "table");
        SV *pk     = pdbi_get(aTHX_ h, "primary");
        AV *all, *cols, *bind;
        SV *sql, *set, *id, *sth;
        HE *pke;
        SSize_t i, n;

        if (!(pk && SvOK(pk)))
            croak("Punk::Model::DBI: update needs a primary key");
        pke = d ? hv_fetch_ent(d, pk, 0, 0) : NULL;
        if (!(pke && SvOK(HeVAL(pke))))
            croak("Punk::Model::DBI: update needs the primary key in the data");
        id = sv_2mortal(newSVsv(HeVAL(pke)));

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
            croak("Punk::Model::DBI: update with no columns to change");

        set = sv_2mortal(newSVpvs(""));
        n = av_len(cols) + 1;
        for (i = 0; i < n; i++) {
            if (i) sv_catpvs(set, ", ");
            sv_catsv(set, pdbi_qi(aTHX_ self, *av_fetch(cols, i, 0)));
            sv_catpvs(set, " = ?");
        }
        sql = sv_2mortal(newSVpvs("UPDATE "));
        sv_catsv(sql, pdbi_qi(aTHX_ self, table));
        sv_catpvs(sql, " SET "); sv_catsv(sql, set);
        sv_catpvs(sql, " WHERE "); sv_catsv(sql, pdbi_qi(aTHX_ self, pk));
        sv_catpvs(sql, " = ?");
        av_push(bind, newSVsv(id));          /* the key binds last */

        (void)pdbi_dbh(aTHX_ self);
        {
            SV *r = pdbi_get(aTHX_ h, "returning");
            if (r && SvIV(r)) {
                SV *row;
                sv_catpvs(sql, " RETURNING *");
                sth = pdbi_sth(aTHX_ self, sql);
                pdbi_execute_sql(aTHX_ sth, bind, sql);
                row = pdbi_meth0(aTHX_ sth, "fetchrow_hashref");
                { SV *f = pdbi_meth0(aTHX_ sth, "finish");
                  if (f) SvREFCNT_dec(f); }
                RETVAL = (row && SvOK(row)) ? row
                       : (row ? (SvREFCNT_dec(row), newSV(0)) : newSV(0));
                goto done_update;
            }
        }
        sth = pdbi_sth(aTHX_ self, sql);
        pdbi_execute_sql(aTHX_ sth, bind, sql);
        {
            SV *argv[2];
            argv[0] = pk; argv[1] = id;
            RETVAL = pcx_call_meth(aTHX_ self, "get", argv, 2, 1);
            if (!RETVAL) RETVAL = newSV(0);
        }
      done_update: ;
    }
    OUTPUT:
        RETVAL

# delete(%key) -> the affected row count.
IV
delete(self, ...)
        SV *self
    CODE:
    {
        HV *key;
        AV *keys = pdbi_key_args(aTHX_ &ST(0), items, &key, "delete", "Punk::Model::DBI");
        AV *bind = (AV *)sv_2mortal((SV *)newAV());
        HV *slot = pdbi_slot_for(aTHX_ self);
        SV *sig  = pdbi_sig(aTHX_ "delete",
                            pdbi_get(aTHX_ pdbi_hv(aTHX_ self), "table"), keys);
        SV *sql  = pdbi_sql_cached(aTHX_ slot, sig, NULL);
        SV *sth, *n;

        if (sql) pdbi_bind_keys(aTHX_ key, keys, bind);
        else {
            SV *dbh   = pdbi_get(aTHX_ slot, "dbh");
            SV *where = pdbi_where_eq_slot(aTHX_ slot, dbh, key, keys, bind);
            SV *table = pdbi_get(aTHX_ pdbi_hv(aTHX_ self), "table");
            SV *built = sv_2mortal(newSVpvs("DELETE FROM "));
            sv_catsv(built, pdbi_qi_slot(aTHX_ slot, dbh, table));
            sv_catpvs(built, " WHERE ");
            sv_catsv(built, where);
            sql = pdbi_sql_cached(aTHX_ slot, sig, built);
        }

        sth = pdbi_sth_dbh(aTHX_ pdbi_get(aTHX_ slot, "dbh"), sql);
        pdbi_execute_sql(aTHX_ sth, bind, sql);
        n = pdbi_meth0(aTHX_ sth, "rows");
        { SV *f = pdbi_meth0(aTHX_ sth, "finish"); if (f) SvREFCNT_dec(f); }
        RETVAL = (n && SvOK(n)) ? SvIV(n) : 0;
        if (n) SvREFCNT_dec(n);
    }
    OUTPUT:
        RETVAL

# ---- the opaque keyset token ------------------------------------------------

SV *
_encode_token(self, val)
        SV *self
        SV *val
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = pdbi_encode_token(aTHX_ val);
    OUTPUT:
        RETVAL

SV *
_decode_token(self, tok)
        SV *self
        SV *tok
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = pdbi_decode_token(aTHX_ tok, "Punk::Model::DBI");
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::DBI::db

# The database-handle methods DBI implements in its own dispatch rather than
# through the public prepare/execute pair. A Callbacks hash cannot see these:
# they reach the inner execute without passing anything a consumer can
# register on, and a callback runs before the method, so there is no done side
# to report from. Wrapping is what gives both.
void
do(...)
    ALIAS:
        selectall_arrayref = 1
        selectall_hashref  = 2
        selectcol_arrayref = 3
        selectrow_array    = 4
        selectrow_arrayref = 5
        selectrow_hashref  = 6
    PPCODE:
    {
        const punk_dbiobs_m *m = &PUNK_DBIOBS[ix];
        void *tok = NULL;
        I32 flags = ((GIMME_V == G_ARRAY) ? G_ARRAY : G_SCALAR) | G_EVAL;
        I32 count, i;
        SV **out = NULL;
        SV *err = NULL;
        int nbind = (items > m->bind_from) ? (int)(items - m->bind_from) : 0;

        if (!PUNK_DBIOBS_IN && PK_OBS_WANT_QUERY)
            tok = pk_obs_query_start(aTHX_
                      punk_dbiobs_sql(aTHX_ items > 1 ? ST(1) : NULL), nbind);

        ENTER;
        SAVEDESTRUCTOR_X(punk_dbiobs_leave, INT2PTR(void *, (IV)PUNK_DBIOBS_IN));
        PUNK_DBIOBS_IN = 1;

        PUSHMARK(SP);
        EXTEND(SP, items);
        for (i = 0; i < items; i++) PUSHs(ST(i));
        PUTBACK;
        count = call_sv((SV *)punk_dbiobs_super(aTHX_ (int)ix, m->super), flags);
        SPAGAIN;

        if (count > 0) {
            Newx(out, count, SV *);
            for (i = count - 1; i >= 0; i--) out[i] = sv_2mortal(SvREFCNT_inc(POPs));
        }
        PUTBACK;
        LEAVE;                      /* puts PUNK_DBIOBS_IN back */

        if (SvTRUE(ERRSV)) err = sv_2mortal(newSVsv(ERRSV));

        /* Success here is "it ran", not what it returned: these hand back
         * data, and a query that legitimately matched no rows has not failed.
         * One that went wrong raised, because RaiseError is this framework's
         * default, and that is the failure worth reporting. */
        if (tok) pk_obs_query_done(aTHX_ tok, err ? &PL_sv_no : &PL_sv_yes);

        if (err) { if (out) Safefree(out); croak_sv(err); }

        SP = PL_stack_base + ax - 1;
        EXTEND(SP, count);
        for (i = 0; i < count; i++) PUSHs(out[i]);
        if (out) Safefree(out);
        PUTBACK;
        return;
    }

MODULE = Punk        PACKAGE = Punk::DBI::st

# The path Punk::Model::DBI's own generated methods take, through
# prepare_cached. `ok` is what DBI's execute returned, which is the contract
# pk_abi.h states for on_query: a false or absent value is a failure.
void
execute(...)
    PPCODE:
    {
        void *tok = NULL;
        I32 count, i;
        SV **out = NULL;
        SV *err = NULL, *r = NULL;

        /* Inside a Punk::DBI::db wrapper this is DBI's own inner execute and
         * the statement was already reported at the altitude the caller asked
         * for. */
        if (!PUNK_DBIOBS_IN && PK_OBS_WANT_QUERY && items > 0)
            tok = pk_obs_query_start(aTHX_
                      punk_dbiobs_sql(aTHX_ ST(0)), (int)(items - 1));

        ENTER;
        SAVEDESTRUCTOR_X(punk_dbiobs_leave, INT2PTR(void *, (IV)PUNK_DBIOBS_IN));
        PUNK_DBIOBS_IN = 1;

        PUSHMARK(SP);
        EXTEND(SP, items);
        for (i = 0; i < items; i++) PUSHs(ST(i));
        PUTBACK;
        count = call_sv((SV *)punk_dbiobs_super(aTHX_ 7, "DBI::st::execute"),
                        G_SCALAR | G_EVAL);
        SPAGAIN;

        if (count > 0) {
            Newx(out, count, SV *);
            for (i = count - 1; i >= 0; i--) out[i] = sv_2mortal(SvREFCNT_inc(POPs));
            r = out[0];
        }
        PUTBACK;
        LEAVE;

        if (SvTRUE(ERRSV)) err = sv_2mortal(newSVsv(ERRSV));
        if (tok) pk_obs_query_done(aTHX_ tok, err ? &PL_sv_no : r);

        if (err) { if (out) Safefree(out); croak_sv(err); }

        SP = PL_stack_base + ax - 1;
        EXTEND(SP, count);
        for (i = 0; i < count; i++) PUSHs(out[i]);
        if (out) Safefree(out);
        PUTBACK;
        return;
    }
