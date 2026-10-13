/* punk_dbq.h - the query shapes both model backends share.
 *
 * The filter with its operators, the ordering, the keyset continuation and
 * the token that carries it, and the count: built here, once, so an operator
 * that works on Punk::Model::DBI works on Punk::Model::DBIx::Loop and a
 * `next` token minted by either decodes on the other. The two backends
 * differ in HOW a statement runs (a DBI call, or a future on the worker's
 * loop), never in WHAT the statement says.
 *
 * Three rules hold everywhere below:
 *
 *   - A column is validated against the model's declared fields and an
 *     operator against a fixed set, both before any SQL is built, so a
 *     filter hash that arrived in a request body is safe to hand straight
 *     to search: the only thing a client controls is bound values.
 *   - Identifiers are quoted through the connection's cache and values are
 *     bound, never interpolated. The ONE literal this file writes into SQL
 *     is `1=0` / `1=1`, for an `in` / `not_in` over an empty list.
 *   - Keys are sorted before they become SQL, so the same filter produces
 *     the same statement and prepare_cached sees one shape, not one per
 *     permutation.
 *
 * Include after punk_dbi.h (pdbi_qi_slot, pdbi_sorted_keys, the base64url
 * codec, punk_frj) and before punk_model.h and punk_dbil.h. */

#ifndef PUNK_DBQ_H
#define PUNK_DBQ_H

/* ---- the operator set ------------------------------------------------------ */

enum {
    PDBQ_EQ = 0, PDBQ_NE, PDBQ_LT, PDBQ_LE, PDBQ_GT, PDBQ_GE,
    PDBQ_IN, PDBQ_NOT_IN, PDBQ_LIKE, PDBQ_STARTS_WITH,
    PDBQ_N_OPS
};

static const struct { const char *name; STRLEN len; const char *sql; }
PDBQ_OPS[PDBQ_N_OPS] = {
    { "=",           1,  " = ?"   },
    { "!=",          2,  " <> ?"  },
    { "<",           1,  " < ?"   },
    { "<=",          2,  " <= ?"  },
    { ">",           1,  " > ?"   },
    { ">=",          2,  " >= ?"  },
    { "in",          2,  NULL     },
    { "not_in",      6,  NULL     },
    { "like",        4,  " LIKE ?" },
    { "starts_with", 11, NULL     },
};

static int pdbq_op_index(const char *k, STRLEN kl) {
    int i;
    for (i = 0; i < PDBQ_N_OPS; i++)
        if (PDBQ_OPS[i].len == kl && memEQ(PDBQ_OPS[i].name, k, kl)) return i;
    return -1;
}

/* the operator list, for a croak */
static SV *pdbq_op_list(pTHX) {
    SV *s = sv_2mortal(newSVpvs(""));
    int i;
    for (i = 0; i < PDBQ_N_OPS; i++) {
        if (i) sv_catpvs(s, ", ");
        sv_catpv(s, PDBQ_OPS[i].name);
    }
    return s;
}

/* ---- columns --------------------------------------------------------------- */

/* the declared field names, comma-joined, for a croak */
static SV *pdbq_col_list(pTHX_ HV *col) {
    AV *keys = pdbi_sorted_keys(aTHX_ col);
    SV *s = sv_2mortal(newSVpvs(""));
    SSize_t i, n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        if (i) sv_catpvs(s, ", ");
        sv_catsv(s, *av_fetch(keys, i, 0));
    }
    return s;
}

/* A column named in a filter or an ordering must be one of the model's
 * declared fields. A model that declares none has nothing to check against
 * and anything goes - the same rule create and update apply when they keep
 * only the known columns. */
static void pdbq_check_col(pTHX_ HV *col, SV *name, SV *table,
                           const char *cls, const char *what) {
    if (!col || !HvUSEDKEYS(col)) return;
    if (hv_exists_ent(col, name, 0)) return;
    croak("%s: %s names '%s', which is not a field of %s (have: %s)",
          cls, what, SvPV_nolen(name),
          table && SvOK(table) ? SvPV_nolen(table) : "the model",
          SvPV_nolen(pdbq_col_list(aTHX_ col)));
}

/* The key columns of a get or a delete, checked the way a filter's are. An
 * unknown one is a caller's typo, and SQLite reads a quoted name it does not
 * know as a string literal: the statement ran, matched nothing, and said
 * nothing, where search would have named the mistake. */
static void pdbq_check_keys(pTHX_ SV *self, AV *keys, const char *cls,
                            const char *what) {
    HV *h = pdbi_hv(aTHX_ self);
    SV *col = pdbi_get(aTHX_ h, "col");
    SSize_t i, n = av_len(keys) + 1;
    if (!(col && SvROK(col) && SvTYPE(SvRV(col)) == SVt_PVHV)) return;
    for (i = 0; i < n; i++)
        pdbq_check_col(aTHX_ (HV *)SvRV(col), *av_fetch(keys, i, 0),
                       pdbi_get(aTHX_ h, "table"), cls, what);
}

/* ---- one term of the filter ------------------------------------------------ */

/* `\` `%` and `_` are LIKE's metacharacters; a prefix search escapes them so
 * that "100%" means the four characters and not "starts with 100". Mortal. */
static SV *pdbq_like_prefix(pTHX_ SV *val) {
    STRLEN vl, i;
    const char *v = SvPV_const(val, vl);
    SV *out = sv_2mortal(newSV(vl * 2 + 2));
    SvPOK_on(out);
    if (SvUTF8(val)) SvUTF8_on(out);
    for (i = 0; i < vl; i++) {
        if (v[i] == '\\' || v[i] == '%' || v[i] == '_') sv_catpvn(out, "\\", 1);
        sv_catpvn(out, v + i, 1);
    }
    sv_catpvs(out, "%");
    return out;
}

/* Append '<qcol> <op> ?' (or its IS NULL / IN (...) / 1=0 form) to `out`,
 * pushing the bind values onto `bind`. */
static void pdbq_term(pTHX_ SV *out, SV *qcol, int op, SV *val, AV *bind,
                      const char *cls, SV *colname) {
    int defined = val && SvOK(val);
    switch (op) {
    case PDBQ_EQ:
    case PDBQ_NE:
        sv_catsv(out, qcol);
        if (!defined) {
            sv_catpv(out, op == PDBQ_EQ ? " IS NULL" : " IS NOT NULL");
            return;
        }
        sv_catpv(out, PDBQ_OPS[op].sql);
        av_push(bind, newSVsv(val));
        return;
    case PDBQ_LT: case PDBQ_LE: case PDBQ_GT: case PDBQ_GE:
    case PDBQ_LIKE:
        if (!defined)
            croak("%s: '%s' on %s needs a value, not undef",
                  cls, PDBQ_OPS[op].name, SvPV_nolen(colname));
        if (SvROK(val))
            croak("%s: '%s' on %s takes a plain value, not a %s",
                  cls, PDBQ_OPS[op].name, SvPV_nolen(colname),
                  sv_reftype(SvRV(val), 0));
        sv_catsv(out, qcol);
        sv_catpv(out, PDBQ_OPS[op].sql);
        av_push(bind, newSVsv(val));
        return;
    case PDBQ_STARTS_WITH:
        if (!defined)
            croak("%s: 'starts_with' on %s needs a value, not undef",
                  cls, SvPV_nolen(colname));
        if (SvROK(val))
            croak("%s: 'starts_with' on %s takes a plain value, not a %s",
                  cls, SvPV_nolen(colname), sv_reftype(SvRV(val), 0));
        sv_catsv(out, qcol);
        sv_catpvs(out, " LIKE ? ESCAPE '\\'");
        av_push(bind, newSVsv(pdbq_like_prefix(aTHX_ val)));
        return;
    case PDBQ_IN:
    case PDBQ_NOT_IN: {
        AV *list;
        SSize_t i, n;
        if (!(defined && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV))
            croak("%s: '%s' on %s takes an arrayref",
                  cls, PDBQ_OPS[op].name, SvPV_nolen(colname));
        list = (AV *)SvRV(val);
        n = av_len(list) + 1;
        if (n == 0) {
            /* nothing is in an empty list, and everything is not in one:
             * the answer the caller meant, rather than a syntax error */
            sv_catpv(out, op == PDBQ_IN ? "1=0" : "1=1");
            return;
        }
        sv_catsv(out, qcol);
        sv_catpv(out, op == PDBQ_IN ? " IN (" : " NOT IN (");
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(list, i, 0);
            if (i) sv_catpvs(out, ", ");
            sv_catpvs(out, "?");
            av_push(bind, (e && *e) ? newSVsv(*e) : newSV(0));
        }
        sv_catpvs(out, ")");
        return;
    }
    default:
        croak("%s: unknown operator", cls);
    }
}

/* ---- the filter ------------------------------------------------------------ */

/* The WHERE body for a filter hash, or "" for an empty one. Mortal.
 *
 *   { a => 1 }                        a = ?
 *   { a => undef }                    a IS NULL
 *   { a => { '>=' => 1, '<' => 9 } }  a >= ? AND a < ?     (operators sorted)
 *   { a => { in => [] } }             1=0
 *
 * Terms are AND-joined in sorted column order, operators sorted within a
 * column, for one statement per shape. */
static SV *pdbq_where(pTHX_ HV *slot, SV *dbh, HV *col, SV *table,
                      HV *filter, AV *bind, const char *cls) {
    SV *out = sv_2mortal(newSVpvs(""));
    AV *keys = pdbi_sorted_keys(aTHX_ filter);
    SSize_t i, n = av_len(keys) + 1;
    int terms = 0;
    for (i = 0; i < n; i++) {
        SV *k   = *av_fetch(keys, i, 0);
        HE *he  = hv_fetch_ent(filter, k, 0, 0);
        SV *val = he ? HeVAL(he) : NULL;
        SV *qcol;
        pdbq_check_col(aTHX_ col, k, table, cls, "the filter");
        qcol = pdbi_qi_slot(aTHX_ slot, dbh, k);
        if (val && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
            HV *ops  = (HV *)SvRV(val);
            AV *onames = pdbi_sorted_keys(aTHX_ ops);
            SSize_t j, m = av_len(onames) + 1;
            if (m == 0)
                croak("%s: the filter on %s is an empty hashref - it needs an "
                      "operator (%s)", cls, SvPV_nolen(k),
                      SvPV_nolen(pdbq_op_list(aTHX)));
            for (j = 0; j < m; j++) {
                SV *on = *av_fetch(onames, j, 0);
                STRLEN ol; const char *op = SvPV_const(on, ol);
                int idx = pdbq_op_index(op, ol);
                HE *oe;
                if (idx < 0)
                    croak("%s: unknown operator '%s' on %s (known: %s)",
                          cls, op, SvPV_nolen(k),
                          SvPV_nolen(pdbq_op_list(aTHX)));
                oe = hv_fetch_ent(ops, on, 0, 0);
                if (terms++) sv_catpvs(out, " AND ");
                pdbq_term(aTHX_ out, qcol, idx, oe ? HeVAL(oe) : NULL,
                          bind, cls, k);
            }
            continue;
        }
        if (val && SvROK(val))
            croak("%s: the filter on %s is a %s - a list is spelled "
                  "{ in => [...] }, and everything else is a plain value or "
                  "{ operator => value }", cls, SvPV_nolen(k),
                  SvTYPE(SvRV(val)) == SVt_PVAV ? "plain arrayref"
                                                : sv_reftype(SvRV(val), 0));
        if (terms++) sv_catpvs(out, " AND ");
        pdbq_term(aTHX_ out, qcol, PDBQ_EQ, val, bind, cls, k);
    }
    return out;
}

/* ---- the ordering ---------------------------------------------------------- */

/* Resolve `order_by` into parallel lists of column names and descending
 * flags, with the primary key appended as the tie-breaker when it is not
 * already named, in the direction of the last named column - so `created =>
 * 'desc'` pages newest-first all the way down, ids included.
 *
 *   undef                         -> (pk)                 asc
 *   'created'                     -> (created, pk)        asc, asc
 *   [ created => 'desc' ]         -> (created, pk)        desc, desc
 *   [ a => 'asc', b => 'desc' ]   -> (a, b, pk)           asc, desc, desc
 *
 * `pk_only` reports that nothing was asked for, which is what keeps the
 * token in its original one-value shape for that case. */
static void pdbq_order(pTHX_ HV *col, SV *table, SV *pk, SV *opt,
                       const char *cls, AV **cols_out, AV **desc_out,
                       int *pk_only) {
    AV *cols = (AV *)sv_2mortal((SV *)newAV());
    AV *desc = (AV *)sv_2mortal((SV *)newAV());
    int last_desc = 0, has_pk = 0;
    SSize_t i, n;
    *pk_only = 1;
    if (opt && SvOK(opt)) {
        AV *pairs = NULL;
        *pk_only = 0;
        if (SvROK(opt) && SvTYPE(SvRV(opt)) == SVt_PVAV) pairs = (AV *)SvRV(opt);
        else if (SvROK(opt))
            croak("%s: order_by takes a column name or [ column => 'asc'|"
                  "'desc', ... ], not a %s", cls, sv_reftype(SvRV(opt), 0));
        if (!pairs) {
            pdbq_check_col(aTHX_ col, opt, table, cls, "order_by");
            av_push(cols, newSVsv(opt));
            av_push(desc, newSViv(0));
        }
        else {
            n = av_len(pairs) + 1;
            if (n == 0 || (n & 1))
                croak("%s: order_by takes [ column => 'asc'|'desc', ... ] "
                      "pairs", cls);
            for (i = 0; i + 1 < n; i += 2) {
                SV **cp = av_fetch(pairs, i, 0);
                SV **dpp = av_fetch(pairs, i + 1, 0);
                SV *c = (cp && *cp) ? *cp : NULL;
                SV *d = (dpp && *dpp) ? *dpp : NULL;
                STRLEN dl; const char *dp;
                SSize_t j, have = av_len(cols) + 1;
                int is_desc;
                /* an array with a hole in it has no SV there at all */
                if (!(c && SvOK(c)))
                    croak("%s: order_by takes [ column => 'asc'|'desc', ... ] "
                          "pairs, and one of the columns is undefined", cls);
                pdbq_check_col(aTHX_ col, c, table, cls, "order_by");
                dp = (d && SvOK(d)) ? SvPV_const(d, dl) : "";
                if (!(d && SvOK(d))) dl = 0;
                if (dl == 3 && (memEQ(dp, "asc", 3) || memEQ(dp, "ASC", 3)))
                    is_desc = 0;
                else if (dl == 4 && (memEQ(dp, "desc", 4) || memEQ(dp, "DESC", 4)))
                    is_desc = 1;
                else
                    croak("%s: order_by direction for %s must be 'asc' or "
                          "'desc', not '%s'", cls, SvPV_nolen(c), dp);
                for (j = 0; j < have; j++)
                    if (sv_eq(*av_fetch(cols, j, 0), c))
                        croak("%s: order_by names %s twice", cls,
                              SvPV_nolen(c));
                av_push(cols, newSVsv(c));
                av_push(desc, newSViv(is_desc));
                last_desc = is_desc;
            }
        }
    }
    if (pk && SvOK(pk)) {
        n = av_len(cols) + 1;
        for (i = 0; i < n; i++)
            if (sv_eq(*av_fetch(cols, i, 0), pk)) { has_pk = 1; break; }
        if (!has_pk) {
            av_push(cols, newSVsv(pk));
            av_push(desc, newSViv(last_desc));
        }
    }
    *cols_out = cols;
    *desc_out = desc;
}

/* 'ORDER BY a DESC, id DESC' - "" when there is nothing to order by. Mortal. */
static SV *pdbq_order_sql(pTHX_ HV *slot, SV *dbh, AV *cols, AV *desc) {
    SV *out = sv_2mortal(newSVpvs(""));
    SSize_t i, n = av_len(cols) + 1;
    for (i = 0; i < n; i++) {
        SV *d = *av_fetch(desc, i, 0);
        sv_catpv(out, i ? ", " : " ORDER BY ");
        sv_catsv(out, pdbi_qi_slot(aTHX_ slot, dbh, *av_fetch(cols, i, 0)));
        sv_catpv(out, SvIV(d) ? " DESC" : " ASC");
    }
    return out;
}

/* ---- the keyset continuation ----------------------------------------------- */

/* The rows after a given (a, b, id) under an ordering, as the expanded
 * comparison every driver takes:
 *
 *   (a < ?) OR (a = ? AND b > ?) OR (a = ? AND b = ? AND id > ?)
 *
 * each column compared in its own direction, which is what lets a mixed
 * ordering page correctly - the row-value form (a, b) < (?, ?) cannot.
 *
 * A NULL in a sort column needs its own branches, because `a > NULL` and
 * `a = NULL` are never true: a page that ended on a row with a NULL there
 * used to mint a token nothing came after, and every later row was
 * unreachable. Where the NULLs sort is the database's choice (pdbq_nulls),
 * so the branches depend on it:
 *
 *   the token holds NULL, NULLs come first:  after = a IS NOT NULL
 *   the token holds NULL, NULLs come last:   after = nothing
 *   a value, NULLs come last:                after = a > ? OR a IS NULL
 *   a value, NULLs come first:               after = a > ?
 *
 * and "equal" is `a IS NULL` for a NULL. Mortal; pushes the binds in order. */

enum { PDBQ_NULLS_UNKNOWN = 0, PDBQ_NULLS_LOW = 1, PDBQ_NULLS_HIGH = 2 };

/* Does this database sort NULL below every value or above? SQLite, MySQL and
 * MariaDB put it below; PostgreSQL and Oracle above. Asked once per
 * connection. Anything else is unknown, and a continuation that would have
 * to guess croaks instead. */
static int pdbq_nulls(pTHX_ HV *slot, SV *dbh) {
    SV *have = slot ? pdbi_get(aTHX_ slot, "nulls") : NULL;
    SV *drv, *name;
    int r = PDBQ_NULLS_UNKNOWN;
    if (have && SvOK(have)) return (int)SvIV(have);
    drv  = pdbi_attr(aTHX_ dbh, "Driver");
    name = drv ? pdbi_attr(aTHX_ drv, "Name") : NULL;
    if (name && SvOK(name)) {
        STRLEN nl;
        const char *n = SvPV_const(name, nl);
        if ((nl == 6 && memEQ(n, "SQLite", 6)) || (nl == 5 && memEQ(n, "mysql", 5))
            || (nl == 7 && memEQ(n, "MariaDB", 7)))
            r = PDBQ_NULLS_LOW;
        else if ((nl == 2 && memEQ(n, "Pg", 2)) || (nl == 6 && memEQ(n, "Oracle", 6)))
            r = PDBQ_NULLS_HIGH;
    }
    if (slot) (void)hv_stores(slot, "nulls", newSViv(r));
    return r;
}

static SV *pdbq_keyset(pTHX_ HV *slot, SV *dbh, AV *cols, AV *desc,
                       AV *vals, AV *bind, const char *cls) {
    SV *out = sv_2mortal(newSVpvs("("));
    SSize_t i, j, n = av_len(cols) + 1;
    int nulls = PDBQ_NULLS_UNKNOWN, any_null = 0, terms = 0;
    for (i = 0; i < n; i++)
        if (!SvOK(*av_fetch(vals, i, 0))) any_null = 1;
    if (any_null) {
        nulls = pdbq_nulls(aTHX_ slot, dbh);
        if (nulls == PDBQ_NULLS_UNKNOWN)
            croak("%s: the page ended on a row with a NULL in an order_by "
                  "column, and this driver's NULL ordering is not known, so "
                  "the next page cannot be found - order by a column that "
                  "is never NULL", cls);
    }
    for (i = 0; i < n; i++) {
        SV *v = *av_fetch(vals, i, 0);
        int is_desc = SvIV(*av_fetch(desc, i, 0)) ? 1 : 0;
        /* NULLs first under this column's direction? Only asked when some
         * token value is NULL; without one the old shape is the right one
         * on every driver, and rows with a NULL keep falling out as the POD
         * says they do. */
        int null_first = (nulls == PDBQ_NULLS_LOW) ? !is_desc : is_desc;
        if (!SvOK(v) && !null_first) continue;      /* nothing sorts after */
        if (terms++) sv_catpvs(out, " OR ");
        sv_catpvs(out, "(");
        for (j = 0; j < i; j++) {
            SV *pv = *av_fetch(vals, j, 0);
            sv_catsv(out, pdbi_qi_slot(aTHX_ slot, dbh, *av_fetch(cols, j, 0)));
            if (SvOK(pv)) {
                sv_catpvs(out, " = ? AND ");
                av_push(bind, newSVsv(pv));
            }
            else sv_catpvs(out, " IS NULL AND ");
        }
        if (!SvOK(v)) {
            sv_catsv(out, pdbi_qi_slot(aTHX_ slot, dbh, *av_fetch(cols, i, 0)));
            sv_catpvs(out, " IS NOT NULL");
        }
        else if (any_null && !null_first) {
            SV *q = pdbi_qi_slot(aTHX_ slot, dbh, *av_fetch(cols, i, 0));
            sv_catpvs(out, "(");
            sv_catsv(out, q);
            sv_catpv(out, is_desc ? " < ? OR " : " > ? OR ");
            sv_catsv(out, q);
            sv_catpvs(out, " IS NULL)");
            av_push(bind, newSVsv(v));
        }
        else {
            sv_catsv(out, pdbi_qi_slot(aTHX_ slot, dbh, *av_fetch(cols, i, 0)));
            sv_catpv(out, is_desc ? " < ?" : " > ?");
            av_push(bind, newSVsv(v));
        }
        sv_catpvs(out, ")");
    }
    if (!terms) sv_catpvs(out, "1=0");
    sv_catpvs(out, ")");
    return out;
}

/* ---- the token --------------------------------------------------------------
 *
 * Without an ordering the token is what it always was - base64url of
 * {"k":<pk>} - so a URL minted before this existed still pages. With one it
 * is {"s":"created:d,id:d","v":[...]}: the ordering's signature and the last
 * row's values under it. A token presented against a different ordering is
 * refused, because the values would be compared against the wrong columns
 * and the page would be wrong rather than an error. */

static SV *pdbq_order_sig(pTHX_ AV *cols, AV *desc) {
    SV *s = sv_2mortal(newSVpvs(""));
    SSize_t i, n = av_len(cols) + 1;
    for (i = 0; i < n; i++) {
        if (i) sv_catpvs(s, ",");
        sv_catsv(s, *av_fetch(cols, i, 0));
        sv_catpv(s, SvIV(*av_fetch(desc, i, 0)) ? ":d" : ":a");
    }
    return s;
}

/* The `next` token for the last row of a page, or undef when the row lacks
 * a value the ordering needs. Owned by the caller. */
static SV *pdbq_next_token(pTHX_ AV *cols, AV *desc, int pk_only, HV *last) {
    SSize_t i, n = av_len(cols) + 1;
    if (pk_only) {
        HE *he = n ? hv_fetch_ent(last, *av_fetch(cols, 0, 0), 0, 0) : NULL;
        return he ? pdbi_encode_token(aTHX_ HeVAL(he)) : newSV(0);
    }
    {
        HV *w = newHV();
        AV *v = newAV();
        SV *json, *tok;
        STRLEN jl; const char *jp;
        for (i = 0; i < n; i++) {
            HE *he = hv_fetch_ent(last, *av_fetch(cols, i, 0), 0, 0);
            if (!he) { SvREFCNT_dec((SV *)w); SvREFCNT_dec((SV *)v); return newSV(0); }
            av_push(v, newSVsv(HeVAL(he)));
        }
        (void)hv_stores(w, "s", newSVsv(pdbq_order_sig(aTHX_ cols, desc)));
        (void)hv_stores(w, "v", newRV_noinc((SV *)v));
        json = punk_frj(aTHX)->encode(aTHX_ sv_2mortal(newRV_noinc((SV *)w)), NULL);
        jp = SvPV_const(json, jl);
        tok = pdbi_b64u_encode(aTHX_ (const unsigned char *)jp, jl);
        SvREFCNT_dec(json);
        return tok;
    }
}

/* The decoded token as the values to continue from, one per ordering
 * column. Mortal AV. Croaks (naming the backend) on a token that is not one
 * or was issued under another ordering. */
static AV *pdbq_decode_token(pTHX_ SV *tok, AV *cols, AV *desc, int pk_only,
                             const char *cls) {
    STRLEN tl;
    const char *tp = SvOK(tok) ? SvPV_const(tok, tl) : "";
    SV *json, *doc;
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    HV *d;
    if (!SvOK(tok)) tl = 0;
    json = pdbi_b64u_decode(aTHX_ tp, tl);
    if (!json) croak("%s: invalid pagination token", cls);
    sv_2mortal(json);
    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(json); PUTBACK;
        count = call_pv("File::Raw::JSON::file_json_decode",
                        G_SCALAR | G_EVAL);
        SPAGAIN;
        doc = (count > 0) ? SvREFCNT_inc(POPs) : NULL;
        PUTBACK; FREETMPS; LEAVE;
        if (SvTRUE(ERRSV)) { SvREFCNT_dec(doc); doc = NULL; }
    }
    if (!(doc && SvROK(doc) && SvTYPE(SvRV(doc)) == SVt_PVHV)) {
        if (doc) SvREFCNT_dec(doc);
        croak("%s: invalid pagination token", cls);
    }
    sv_2mortal(doc);
    d = (HV *)SvRV(doc);
    {
        SV *k = pdbi_get(aTHX_ d, "k");
        SV *s = pdbi_get(aTHX_ d, "s");
        SV *v = pdbi_get(aTHX_ d, "v");
        if (k && !s) {
            /* the one-value token: valid only for the plain ordering */
            if (!pk_only)
                croak("%s: this pagination token was issued without an "
                      "order_by and cannot continue one", cls);
            av_push(out, newSVsv(k));
            return out;
        }
        if (s && v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) {
            AV *vals = (AV *)SvRV(v);
            SSize_t i, n = av_len(cols) + 1;
            if (!sv_eq(s, pdbq_order_sig(aTHX_ cols, desc)))
                croak("%s: this pagination token was issued for a different "
                      "ordering", cls);
            if (av_len(vals) + 1 != n)
                croak("%s: invalid pagination token", cls);
            for (i = 0; i < n; i++) av_push(out, newSVsv(*av_fetch(vals, i, 0)));
            return out;
        }
    }
    croak("%s: invalid pagination token", cls);
    return out;   /* not reached */
}

/* ---- the statements --------------------------------------------------------- */

/* The options search takes. Anything else is a typo, and a typo in `limit`
 * that silently returned twenty rows would be the worse outcome. */
static void pdbq_check_opts(pTHX_ HV *o, const char *cls) {
    HE *he;
    if (!o) return;
    hv_iterinit(o);
    while ((he = hv_iternext(o))) {
        STRLEN kl; const char *k = HePV(he, kl);
        if ((kl == 5 && memEQ(k, "limit", 5))
         || (kl == 5 && memEQ(k, "after", 5))
         || (kl == 8 && memEQ(k, "order_by", 8))) continue;
        croak("%s: unknown search option '%.*s' (known: after, limit, "
              "order_by)", cls, (int)kl, k);
    }
}

/* SELECT * FROM t [WHERE ...] [ORDER BY ...] LIMIT n+1, with the binds, the
 * resolved ordering (for the next token) and the limit. Mortal SV. */
static SV *pdbq_search_sql(pTHX_ HV *slot, SV *dbh, HV *col, SV *table,
                           SV *pk, HV *f, HV *o, const char *cls, AV *bind,
                           IV *limit_out, AV **cols_out, AV **desc_out,
                           int *pk_only_out) {
    SV *lim_sv = o ? pdbi_get(aTHX_ o, "limit") : NULL;
    SV *after  = o ? pdbi_get(aTHX_ o, "after") : NULL;
    SV *order  = o ? pdbi_get(aTHX_ o, "order_by") : NULL;
    IV limit   = (lim_sv && SvOK(lim_sv)) ? SvIV(lim_sv) : 20;
    /* a value past what an IV holds does not come back from SvIV as a large
     * one, so it is asked for as a float first */
    int huge   = (lim_sv && SvOK(lim_sv) && SvNV(lim_sv) >= (NV)IV_MAX) ? 1 : 0;
    SV *sql    = sv_2mortal(newSVpvs("SELECT * FROM "));
    SV *where;
    AV *cols, *desc;
    int pk_only, has_after;

    pdbq_check_opts(aTHX_ o, cls);
    if (limit < 1) limit = 1;
    /* the statement asks for one row more, and IV_MAX + 1 is a negative
     * LIMIT: unbounded on SQLite, an error on PostgreSQL */
    if (huge || limit > IV_MAX - 1) limit = IV_MAX - 1;
    has_after = (after && SvOK(after) && SvCUR(after)) ? 1 : 0;

    pdbq_order(aTHX_ col, table, pk, order, cls, &cols, &desc, &pk_only);
    if (has_after && av_len(cols) < 0)
        croak("%s: pagination needs a primary key or an order_by", cls);

    sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, table));
    where = pdbq_where(aTHX_ slot, dbh, col, table, f, bind, cls);
    if (SvCUR(where) || has_after) {
        sv_catpvs(sql, " WHERE ");
        sv_catsv(sql, where);
        if (has_after) {
            AV *vals = pdbq_decode_token(aTHX_ after, cols, desc, pk_only, cls);
            if (SvCUR(where)) sv_catpvs(sql, " AND ");
            sv_catsv(sql, pdbq_keyset(aTHX_ slot, dbh, cols, desc, vals, bind,
                                      cls));
        }
    }
    sv_catsv(sql, pdbq_order_sql(aTHX_ slot, dbh, cols, desc));
    sv_catpvf(sql, " LIMIT %" IVdf, (IV)(limit + 1));

    *limit_out   = limit;
    *cols_out    = cols;
    *desc_out    = desc;
    *pk_only_out = pk_only;
    return sql;
}

/* SELECT COUNT(*) FROM t [WHERE ...]. Mortal SV. */
static SV *pdbq_count_sql(pTHX_ HV *slot, SV *dbh, HV *col, SV *table,
                          HV *f, const char *cls, AV *bind) {
    SV *sql = sv_2mortal(newSVpvs("SELECT COUNT(*) FROM "));
    SV *where;
    sv_catsv(sql, pdbi_qi_slot(aTHX_ slot, dbh, table));
    where = pdbq_where(aTHX_ slot, dbh, col, table, f, bind, cls);
    if (SvCUR(where)) {
        sv_catpvs(sql, " WHERE ");
        sv_catsv(sql, where);
    }
    return sql;
}

/* the search result hash { rows, has_more_data, next } from the fetched
 * rows (one past the limit); takes ownership of rows_rv. Returns an RV. */
static SV *pdbq_page(pTHX_ SV *rows_rv, IV limit, AV *cols, AV *desc,
                     int pk_only) {
    AV *rows;
    SSize_t got;
    int has_more;
    HV *out = newHV();
    if (!(rows_rv && SvROK(rows_rv) && SvTYPE(SvRV(rows_rv)) == SVt_PVAV)) {
        if (rows_rv) SvREFCNT_dec(rows_rv);
        rows_rv = newRV_noinc((SV *)newAV());
    }
    rows = (AV *)SvRV(rows_rv);
    got  = av_len(rows) + 1;
    has_more = (got > limit) ? 1 : 0;
    if (has_more) { SV *x = av_pop(rows); if (x) SvREFCNT_dec(x); }
    (void)hv_stores(out, "rows", rows_rv);
    (void)hv_stores(out, "has_more_data", newSViv(has_more));
    if (has_more && av_len(cols) >= 0 && av_len(rows) >= 0) {
        SV **last = av_fetch(rows, av_len(rows), 0);
        HV *lh = (last && *last && SvROK(*last)
                  && SvTYPE(SvRV(*last)) == SVt_PVHV) ? (HV *)SvRV(*last) : NULL;
        (void)hv_stores(out, "next",
            lh ? pdbq_next_token(aTHX_ cols, desc, pk_only, lh) : newSV(0));
    }
    else (void)hv_stores(out, "next", newSV(0));
    return newRV_noinc((SV *)out);
}

#endif /* PUNK_DBQ_H */
