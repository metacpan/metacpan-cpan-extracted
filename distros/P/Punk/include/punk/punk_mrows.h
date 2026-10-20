/* punk_mrows.h - the Punk::Model contract over rows held in memory, and the
 * two backends built on it: Punk::Model::JSONFile (rows in a JSON file, read
 * and write) and Punk::Model::Markdown (the pages of a `markdown` mount,
 * read-only).
 *
 * Everything that is not SQL is punk_dbq.h's - the operator set, the column
 * checks and their croaks, the ordering with its primary-key tie-breaker, the
 * search options, the keyset token and the page - so a filter, an order_by or
 * a `next` token means the same here as on Punk::Model::DBI. What this file
 * adds is evaluating them against Perl rows instead of writing them as SQL:
 *
 *   - three-valued logic, as SQL has it: NULL (undef) never equals, compares
 *     or is `in` anything; `!=` leaves NULLs out; `not_in` over a list that
 *     holds NULL matches nothing, and over an empty list matches everything;
 *   - values compare as numbers when both look like numbers, else as strings
 *     (sv_cmp), and NULL sorts before every value, as on SQLite;
 *   - `like` takes `%` and `_`, case-sensitively; `starts_with` is a literal
 *     prefix.
 *
 * The object is the blessed hash pdbi_build_self makes (opts/table/primary/
 * columns/col), so pdbq_check_keys and the rest read it unchanged.
 *
 * Include after punk_dbq.h, punk_markdown.h and punk_app.h. */

#ifndef PUNK_MROWS_H
#define PUNK_MROWS_H

/* ---- comparing two values -------------------------------------------------- */

/* A value's number, read WITHOUT caching one on the SV: SvNV would set NOK
 * on a row held in the JSON cache, and the encoder would then write an
 * integer id back as 2.0. */
static NV pmr_num(pTHX_ SV *sv) {
    if (SvNOK(sv)) return SvNVX(sv);
    if (SvIOK(sv)) return SvIsUV(sv) ? (NV)SvUVX(sv) : (NV)SvIVX(sv);
    return SvPOK(sv) ? Atof(SvPVX(sv)) : 0.0;
}

/* An integer key as an IV, without touching the SV's flags: an integer SV,
 * or a string of digits with an optional sign. 0 when it is not one. */
static int pmr_int(pTHX_ SV *sv, IV *out) {
    if (SvIOK(sv) && !SvNOK(sv) && !SvPOK(sv)) { *out = SvIVX(sv); return 1; }
    if (SvNOK(sv) && !SvPOK(sv)) {
        NV v = SvNVX(sv);
        if (v != (NV)(IV)v) return 0;
        *out = (IV)v;
        return 1;
    }
    if (SvPOK(sv)) {
        STRLEN l, i = 0;
        const char *p = SvPV_const(sv, l);
        if (l && (p[0] == '-' || p[0] == '+')) i = 1;
        if (i == l) return 0;
        for (; i < l; i++) if (!isDIGIT(p[i])) return 0;
        *out = (IV)Atof(p);
        return 1;
    }
    return 0;
}

/* A value to string-compare, never the row's own SV unless it already is a
 * string: sv_cmp stringifies, and a cached PV on a number changes how it is
 * encoded. */
static SV *pmr_str(pTHX_ SV *sv) {
    return SvPOK(sv) ? sv : sv_2mortal(newSVsv(sv));
}

/* <0, 0, >0 with NULL lowest. Numbers compare as numbers when both sides
 * look like one ("10" after "9"), everything else as strings. Neither side
 * is changed. */
static int pmr_cmp(pTHX_ SV *a, SV *b) {
    int da = a && SvOK(a), db = b && SvOK(b);
    if (!da || !db) return da == db ? 0 : (da ? 1 : -1);
    if (!SvROK(a) && !SvROK(b) && looks_like_number(a) && looks_like_number(b)) {
        NV x = pmr_num(aTHX_ a), y = pmr_num(aTHX_ b);
        return x < y ? -1 : x > y ? 1 : 0;
    }
    return sv_cmp(pmr_str(aTHX_ a), pmr_str(aTHX_ b));
}

/* SQL LIKE: `%` any run, `_` one character, everything else literal and
 * case-sensitive. Character-wise on a UTF-8 value, so `_` is one character
 * and not one byte. */
static int pmr_like(const U8 *s, const U8 *se, const U8 *p, const U8 *pe,
                    int utf8) {
    while (p < pe) {
        if (*p == '%') {
            while (p < pe && *p == '%') p++;
            if (p == pe) return 1;
            for (;;) {
                if (pmr_like(s, se, p, pe, utf8)) return 1;
                if (s >= se) return 0;
                s += utf8 ? UTF8SKIP(s) : 1;
            }
        }
        if (s >= se) return 0;
        if (*p == '_') {
            s += utf8 ? UTF8SKIP(s) : 1;
            p++;
            continue;
        }
        if (*p != *s) return 0;
        p++; s++;
    }
    return s == se;
}

/* ---- the filter -------------------------------------------------------------
 *
 * Compiled once per call into terms (column, operator, value), validated
 * exactly as pdbq_where validates - the same croaks, in the same order - and
 * then run against each row. */

typedef struct { SV *col; int op; SV *val; } pmr_term;

/* Mortal AV of terms, each an AV [col, op, val]. */
static AV *pmr_compile(pTHX_ HV *col, SV *table, HV *filter, const char *cls) {
    AV *terms = (AV *)sv_2mortal((SV *)newAV());
    AV *keys;
    SSize_t i, n;
    if (!filter) return terms;
    keys = pdbi_sorted_keys(aTHX_ filter);
    n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV *k  = *av_fetch(keys, i, 0);
        HE *he = hv_fetch_ent(filter, k, 0, 0);
        SV *val = he ? HeVAL(he) : NULL;
        pdbq_check_col(aTHX_ col, k, table, cls, "the filter");
        if (val && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
            HV *ops = (HV *)SvRV(val);
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
                SV *v;
                AV *t;
                if (idx < 0)
                    croak("%s: unknown operator '%s' on %s (known: %s)",
                          cls, op, SvPV_nolen(k),
                          SvPV_nolen(pdbq_op_list(aTHX)));
                oe = hv_fetch_ent(ops, on, 0, 0);
                v = oe ? HeVAL(oe) : NULL;
                switch (idx) {
                case PDBQ_LT: case PDBQ_LE: case PDBQ_GT: case PDBQ_GE:
                case PDBQ_LIKE: case PDBQ_STARTS_WITH:
                    if (!(v && SvOK(v)))
                        croak("%s: '%s' on %s needs a value, not undef",
                              cls, PDBQ_OPS[idx].name, SvPV_nolen(k));
                    if (SvROK(v))
                        croak("%s: '%s' on %s takes a plain value, not a %s",
                              cls, PDBQ_OPS[idx].name, SvPV_nolen(k),
                              sv_reftype(SvRV(v), 0));
                    break;
                case PDBQ_IN: case PDBQ_NOT_IN:
                    if (!(v && SvOK(v) && SvROK(v)
                          && SvTYPE(SvRV(v)) == SVt_PVAV))
                        croak("%s: '%s' on %s takes an arrayref",
                              cls, PDBQ_OPS[idx].name, SvPV_nolen(k));
                    break;
                default: break;
                }
                t = newAV();
                av_push(t, newSVsv(k));
                av_push(t, newSViv(idx));
                av_push(t, v ? newSVsv(v) : newSV(0));
                av_push(terms, newRV_noinc((SV *)t));
            }
            continue;
        }
        if (val && SvROK(val))
            croak("%s: the filter on %s is a %s - a list is spelled "
                  "{ in => [...] }, and everything else is a plain value or "
                  "{ operator => value }", cls, SvPV_nolen(k),
                  SvTYPE(SvRV(val)) == SVt_PVAV ? "plain arrayref"
                                                : sv_reftype(SvRV(val), 0));
        {
            AV *t = newAV();
            av_push(t, newSVsv(k));
            av_push(t, newSViv(PDBQ_EQ));
            av_push(t, val ? newSVsv(val) : newSV(0));
            av_push(terms, newRV_noinc((SV *)t));
        }
    }
    return terms;
}

static int pmr_term_ok(pTHX_ int op, SV *rv, SV *val) {
    int rdef = rv && SvOK(rv);
    switch (op) {
    case PDBQ_EQ:
        if (!SvOK(val)) return !rdef;
        return rdef && pmr_cmp(aTHX_ rv, val) == 0;
    case PDBQ_NE:
        if (!SvOK(val)) return rdef;
        return rdef && pmr_cmp(aTHX_ rv, val) != 0;
    case PDBQ_LT: return rdef && pmr_cmp(aTHX_ rv, val) <  0;
    case PDBQ_LE: return rdef && pmr_cmp(aTHX_ rv, val) <= 0;
    case PDBQ_GT: return rdef && pmr_cmp(aTHX_ rv, val) >  0;
    case PDBQ_GE: return rdef && pmr_cmp(aTHX_ rv, val) >= 0;
    case PDBQ_IN:
    case PDBQ_NOT_IN: {
        AV *list = (AV *)SvRV(val);
        SSize_t i, n = av_len(list) + 1;
        int found = 0, has_null = 0;
        if (n == 0) return op == PDBQ_NOT_IN;     /* 1=0 / 1=1 */
        if (!rdef) return 0;                      /* NULL [NOT] IN (...) */
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(list, i, 0);
            if (!(e && *e && SvOK(*e))) { has_null = 1; continue; }
            if (pmr_cmp(aTHX_ rv, *e) == 0) { found = 1; break; }
        }
        if (op == PDBQ_IN) return found;
        return !found && !has_null;               /* x NOT IN (.., NULL) */
    }
    case PDBQ_LIKE:
    case PDBQ_STARTS_WITH: {
        STRLEN sl, pl;
        const U8 *s, *p;
        if (!rdef) return 0;
        s = (const U8 *)SvPV_const(rv, sl);
        p = (const U8 *)SvPV_const(val, pl);
        if (op == PDBQ_STARTS_WITH) return sl >= pl && memEQ(s, p, pl);
        return pmr_like(s, s + sl, p, p + pl, SvUTF8(rv) ? 1 : 0);
    }
    default: return 0;
    }
}

static int pmr_match(pTHX_ AV *terms, HV *row) {
    SSize_t i, n = av_len(terms) + 1;
    for (i = 0; i < n; i++) {
        AV *t = (AV *)SvRV(*av_fetch(terms, i, 0));
        SV *col = *av_fetch(t, 0, 0);
        HE *he = hv_fetch_ent(row, col, 0, 0);
        if (!pmr_term_ok(aTHX_ (int)SvIV(*av_fetch(t, 1, 0)),
                         he ? HeVAL(he) : NULL, *av_fetch(t, 2, 0)))
            return 0;
    }
    return 1;
}

/* ---- copies ------------------------------------------------------------------
 *
 * A row handed out is the caller's to change, so it is copied all the way
 * down: a JSON file's rows sit in a per-process cache, and a caller editing
 * a nested hash must not edit the next caller's answer. */

static SV *pmr_deep(pTHX_ SV *sv) {
    if (!sv) return newSV(0);
    if (SvROK(sv) && !sv_isobject(sv)) {
        SV *r = SvRV(sv);
        if (SvTYPE(r) == SVt_PVHV) {
            HV *src = (HV *)r, *dst = newHV();
            HE *he;
            hv_iterinit(src);
            while ((he = hv_iternext(src)))
                (void)hv_store_ent(dst, hv_iterkeysv(he),
                                   pmr_deep(aTHX_ HeVAL(he)), 0);
            return newRV_noinc((SV *)dst);
        }
        if (SvTYPE(r) == SVt_PVAV) {
            AV *src = (AV *)r, *dst = newAV();
            SSize_t i, n = av_len(src) + 1;
            av_extend(dst, n > 0 ? n - 1 : 0);
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(src, i, 0);
                av_push(dst, pmr_deep(aTHX_ e ? *e : NULL));
            }
            return newRV_noinc((SV *)dst);
        }
    }
    return newSVsv(sv);
}

/* ---- ordering ---------------------------------------------------------------- */

typedef struct { AV *cols; AV *desc; } pmr_spec;
typedef struct { HV *row; const pmr_spec *spec; } pmr_item;

static int pmr_rowcmp(pTHX_ const pmr_spec *sp, HV *a, HV *b, AV *bvals) {
    SSize_t i, n = av_len(sp->cols) + 1;
    for (i = 0; i < n; i++) {
        SV *c = *av_fetch(sp->cols, i, 0);
        HE *ha = hv_fetch_ent(a, c, 0, 0);
        SV *vb;
        int r;
        if (bvals) { SV **e = av_fetch(bvals, i, 0); vb = e ? *e : NULL; }
        else       { HE *hb = hv_fetch_ent(b, c, 0, 0); vb = hb ? HeVAL(hb) : NULL; }
        r = pmr_cmp(aTHX_ ha ? HeVAL(ha) : NULL, vb);
        if (r) return SvIV(*av_fetch(sp->desc, i, 0)) ? -r : r;
    }
    return 0;
}

static int pmr_qsort_cmp(const void *x, const void *y) {
    dTHX;
    const pmr_item *a = (const pmr_item *)x, *b = (const pmr_item *)y;
    return pmr_rowcmp(aTHX_ a->spec, a->row, b->row, NULL);
}

/* ---- the contract over a row list -------------------------------------------- */

static HV *pmr_self(pTHX_ SV *self, const char *cls) {
    if (!(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV))
        croak("%s: not a backend object", cls);
    return (HV *)SvRV(self);
}

static HV *pmr_colset(pTHX_ HV *h) {
    SV *c = pdbi_get(aTHX_ h, "col");
    return (c && SvROK(c) && SvTYPE(SvRV(c)) == SVt_PVHV) ? (HV *)SvRV(c) : NULL;
}

/* search(\%filter, \%opts) over `rows` (an AV of hashrefs): the page hash. */
static SV *pmr_search(pTHX_ SV *self, AV *rows, SV *filter, SV *opts,
                      const char *cls) {
    HV *h  = pmr_self(aTHX_ self, cls);
    HV *f  = (filter && SvROK(filter) && SvTYPE(SvRV(filter)) == SVt_PVHV)
             ? (HV *)SvRV(filter) : NULL;
    HV *o  = (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
             ? (HV *)SvRV(opts) : NULL;
    SV *table = pdbi_get(aTHX_ h, "table");
    SV *pk    = pdbi_get(aTHX_ h, "primary");
    HV *col   = pmr_colset(aTHX_ h);
    SV *lim_sv = o ? pdbi_get(aTHX_ o, "limit") : NULL;
    SV *after  = o ? pdbi_get(aTHX_ o, "after") : NULL;
    SV *order  = o ? pdbi_get(aTHX_ o, "order_by") : NULL;
    IV limit;
    AV *cols, *desc, *terms, *vals = NULL, *out;
    int pk_only;
    pmr_spec spec;
    pmr_item *items;
    SSize_t i, n = rows ? av_len(rows) + 1 : 0, kept = 0, from = 0, taken;

    pdbq_check_opts(aTHX_ o, cls);
    limit = (lim_sv && SvOK(lim_sv)) ? SvIV(lim_sv) : 20;
    if (lim_sv && SvOK(lim_sv) && SvNV(lim_sv) >= (NV)IV_MAX) limit = IV_MAX - 1;
    if (limit < 1) limit = 1;
    terms = pmr_compile(aTHX_ col, table, f, cls);
    pdbq_order(aTHX_ col, table, pk, order, cls, &cols, &desc, &pk_only);
    if (after && SvOK(after) && SvCUR(after)) {
        if (av_len(cols) < 0)
            croak("%s: pagination needs a primary key or an order_by", cls);
        vals = pdbq_decode_token(aTHX_ after, cols, desc, pk_only, cls);
    }

    Newx(items, n > 0 ? n : 1, pmr_item);
    SAVEFREEPV(items);
    spec.cols = cols;
    spec.desc = desc;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(rows, i, 0);
        HV *r;
        if (!(e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)) continue;
        r = (HV *)SvRV(*e);
        if (!pmr_match(aTHX_ terms, r)) continue;
        items[kept].row  = r;
        items[kept].spec = &spec;
        kept++;
    }
    if (kept > 1) qsort(items, (size_t)kept, sizeof *items, pmr_qsort_cmp);
    if (vals)
        while (from < kept
               && pmr_rowcmp(aTHX_ &spec, items[from].row, NULL, vals) <= 0)
            from++;

    out = newAV();
    for (taken = 0, i = from; i < kept && taken <= limit; i++, taken++)
        av_push(out, pmr_deep(aTHX_ sv_2mortal(newRV_inc((SV *)items[i].row))));
    return pdbq_page(aTHX_ newRV_noinc((SV *)out), limit, cols, desc, pk_only);
}

static IV pmr_count(pTHX_ SV *self, AV *rows, SV *filter, const char *cls) {
    HV *h = pmr_self(aTHX_ self, cls);
    HV *f = (filter && SvROK(filter) && SvTYPE(SvRV(filter)) == SVt_PVHV)
            ? (HV *)SvRV(filter) : NULL;
    AV *terms = pmr_compile(aTHX_ pmr_colset(aTHX_ h),
                            pdbi_get(aTHX_ h, "table"), f, cls);
    SSize_t i, n = rows ? av_len(rows) + 1 : 0;
    IV c = 0;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(rows, i, 0);
        if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV
            && pmr_match(aTHX_ terms, (HV *)SvRV(*e)))
            c++;
    }
    return c;
}

/* get(%key): the first row whose key columns equal the given values, copied,
 * or undef. The keys are checked against the fields as DBI checks them. */
static SV *pmr_get(pTHX_ SV *self, AV *rows, SV **st, I32 items,
                   const char *cls) {
    HV *key;
    AV *keys = pdbi_key_args(aTHX_ st, items, &key, "get", cls);
    AV *terms;
    SSize_t i, n = rows ? av_len(rows) + 1 : 0;
    pdbq_check_keys(aTHX_ self, keys, cls, "get");
    terms = pmr_compile(aTHX_ NULL, NULL, key, cls);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(rows, i, 0);
        if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV
            && pmr_match(aTHX_ terms, (HV *)SvRV(*e)))
            return pmr_deep(aTHX_ *e);
    }
    return newSV(0);
}

/* ---- Punk::Model::JSONFile ----------------------------------------------------
 *
 * The file is a JSON object and a model's `table` names the array of rows in
 * it, so one file can hold several tables (and values beside them, which
 * `document` hands back). Read through the File::Raw::JSON ABI and kept per
 * process until the file changes - its inode, size or mtime, because a write
 * renames a new file into place and can land in the same second as the read
 * before it. */

#define PMJ "Punk::Model::JSONFile"

static HV *PMJ_CACHE = NULL;    /* file => [ stamp, doc-or-undef ] */

static SV *pmj_file(pTHX_ HV *h) {
    SV *o = pdbi_get(aTHX_ h, "opts");
    SV *f = (o && SvROK(o)) ? pdbi_get(aTHX_ (HV *)SvRV(o), "file") : NULL;
    if (!(f && SvOK(f) && SvCUR(f)))
        croak(PMJ ": the database needs a `file` (database name => "
              "{ backend => '" PMJ "', file => 'data.json' })");
    return f;
}

/* The bytes of the file decoded, or NULL with *err set to why. Owned. */
static SV *pmj_decode_file(pTHX_ const char *path, SV **err) {
    SV *bytes = pmd_slurp(aTHX_ path);
    SV *doc = NULL;
    *err = NULL;
    if (!bytes) return NULL;
    /* the backend is XS registered at boot, so its .pm - and with it the
     * module the decode is called in - may never have been required */
    (void)pk_require_once(aTHX_ "File::Raw::JSON", TRUE);
    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(bytes); PUTBACK;
        count = call_pv("File::Raw::JSON::file_json_decode", G_SCALAR | G_EVAL);
        SPAGAIN;
        doc = (count > 0) ? newSVsv(POPs) : NULL;
        PUTBACK;
        if (SvTRUE(ERRSV)) {
            *err = newSVsv(ERRSV);
            if (doc) { SvREFCNT_dec(doc); doc = NULL; }
        }
        FREETMPS; LEAVE;
    }
    if (doc && !(SvROK(doc) && SvTYPE(SvRV(doc)) == SVt_PVHV)) {
        SvREFCNT_dec(doc);
        doc = NULL;
        *err = newSVpvs("it is not a JSON object\n");
    }
    return doc;
}

/* The decoded file, borrowed from the cache, or NULL (no file, or a broken
 * one - which warns once per version of it). */
static HV *pmj_document(pTHX_ SV *self) {
    HV *h = pmr_self(aTHX_ self, PMJ);
    SV *file = pmj_file(aTHX_ h);
    const char *path = SvPV_nolen(file);
    Stat_t st;
    SV *stamp;
    HE *he;
    if (!PMJ_CACHE) PMJ_CACHE = newHV();
    if (PerlLIO_stat(path, &st) < 0) {
        (void)hv_delete_ent(PMJ_CACHE, file, G_DISCARD, 0);
        return NULL;
    }
    stamp = sv_2mortal(newSVpvf("%" UVuf ":%" IVdf ":%" IVdf,
                                (UV)st.st_ino, (IV)st.st_size, (IV)st.st_mtime));
    he = hv_fetch_ent(PMJ_CACHE, file, 0, 0);
    if (he && SvROK(HeVAL(he))) {
        AV *slot = (AV *)SvRV(HeVAL(he));
        if (sv_eq(*av_fetch(slot, 0, 0), stamp)) {
            SV *d = *av_fetch(slot, 1, 0);
            return SvROK(d) ? (HV *)SvRV(d) : NULL;
        }
    }
    {
        SV *err = NULL;
        SV *doc = pmj_decode_file(aTHX_ path, &err);
        AV *slot = newAV();
        av_push(slot, newSVsv(stamp));
        av_push(slot, doc ? doc : newSV(0));
        (void)hv_store_ent(PMJ_CACHE, file, newRV_noinc((SV *)slot), 0);
        if (!doc) {
            warn(PMJ ": %s is unusable, so it has no rows: %s", path,
                 err ? SvPV_nolen(err) : "it could not be read\n");
            if (err) SvREFCNT_dec(err);
            return NULL;
        }
        return (HV *)SvRV(doc);
    }
}

/* The table's rows, borrowed, or NULL. */
static AV *pmj_rows(pTHX_ SV *self) {
    HV *doc = pmj_document(aTHX_ self);
    SV *t, *rows;
    if (!doc) return NULL;
    t = pdbi_get(aTHX_ pmr_self(aTHX_ self, PMJ), "table");
    rows = pdbi_get(aTHX_ doc, SvPV_nolen(t));
    return (rows && SvROK(rows) && SvTYPE(SvRV(rows)) == SVt_PVAV)
           ? (AV *)SvRV(rows) : NULL;
}

/* ---- writing ------------------------------------------------------------------
 *
 * Every write is read-modify-write of the whole file under an exclusive lock
 * on `<file>.lock` (so two workers cannot lose each other's change), from a
 * FRESH read rather than the cache, encoded pretty with sorted keys (so the
 * file diffs well), written to a temporary file and renamed over the old one
 * (so a reader never sees half of it). */

typedef struct { int fd; } pmj_lock;

static void pmj_lock_take(pTHX_ const char *path, pmj_lock *l) {
    SV *lp = sv_2mortal(newSVpvf("%s.lock", path));
    l->fd = PerlLIO_open3(SvPV_nolen(lp), O_RDWR | O_CREAT, 0644);
    if (l->fd < 0)
        croak(PMJ ": cannot open %s: %s", SvPV_nolen(lp), Strerror(errno));
#if defined(HAS_FLOCK) && defined(LOCK_EX)
    while (flock(l->fd, LOCK_EX) < 0) {
        if (errno == EINTR) continue;
        PerlLIO_close(l->fd);
        croak(PMJ ": cannot lock %s: %s", SvPV_nolen(lp), Strerror(errno));
    }
#endif
}

static void pmj_lock_drop(pmj_lock *l) {
    if (l->fd >= 0) {
#if defined(HAS_FLOCK) && defined(LOCK_UN)
        (void)flock(l->fd, LOCK_UN);
#endif
        PerlLIO_close(l->fd);
        l->fd = -1;
    }
}

/* The lock, held until the enclosing LEAVE - on a croak as much as on a
 * return, because the save stack unwinds either way. Call between ENTER and
 * LEAVE. */
static void pmj_unlock_cb(pTHX_ void *p) {
    pmj_lock *l = (pmj_lock *)p;
    PERL_UNUSED_CONTEXT;
    pmj_lock_drop(l);
    Safefree(l);
}

static void pmj_lock_scoped(pTHX_ const char *path) {
    pmj_lock *l;
    Newx(l, 1, pmj_lock);
    l->fd = -1;
    SAVEDESTRUCTOR_X(pmj_unlock_cb, l);
    pmj_lock_take(aTHX_ path, l);
}

/* Write `doc` to `path` atomically. Croaks on failure (the old file stays). */
static void pmj_write(pTHX_ const char *path, HV *doc) {
    frj_opts o;
    SV *json, *tmp;
    PerlIO *fp;
    STRLEN jl;
    const char *jp;
    const frj_abi *frj = punk_frj(aTHX);
    frj->opts_init(&o);
    o.pretty = 1;
    o.sort_keys = 1;
    json = sv_2mortal(frj->encode(aTHX_ sv_2mortal(newRV_inc((SV *)doc)), &o));
    jp = SvPV_const(json, jl);
    tmp = sv_2mortal(newSVpvf("%s.tmp.%" IVdf, path, (IV)PerlProc_getpid()));
    fp = PerlIO_open(SvPV_nolen(tmp), "wb");
    if (!fp) croak(PMJ ": cannot write %s: %s", SvPV_nolen(tmp), Strerror(errno));
    if (PerlIO_write(fp, jp, jl) != (SSize_t)jl || PerlIO_write(fp, "\n", 1) != 1) {
        PerlIO_close(fp);
        (void)PerlLIO_unlink(SvPV_nolen(tmp));
        croak(PMJ ": cannot write %s: %s", SvPV_nolen(tmp), Strerror(errno));
    }
    if (PerlIO_close(fp) != 0) {
        (void)PerlLIO_unlink(SvPV_nolen(tmp));
        croak(PMJ ": cannot write %s: %s", SvPV_nolen(tmp), Strerror(errno));
    }
    if (PerlLIO_rename(SvPV_nolen(tmp), path) != 0) {
        int e = errno;
        (void)PerlLIO_unlink(SvPV_nolen(tmp));
        croak(PMJ ": cannot replace %s: %s", path, Strerror(e));
    }
}

/* The file as it is now, for a write: decoded fresh (never the cache), or a
 * new empty object when there is no file. Croaks on a broken file rather
 * than writing over what somebody may still want. Mortal HV. The table's
 * array is created when missing; *rows_out points at it. */
static HV *pmj_fresh(pTHX_ SV *self, const char *path, AV **rows_out) {
    HV *h = pmr_self(aTHX_ self, PMJ);
    SV *t = pdbi_get(aTHX_ h, "table");
    Stat_t st;
    HV *doc;
    SV *rows;
    if (PerlLIO_stat(path, &st) < 0) doc = (HV *)sv_2mortal((SV *)newHV());
    else {
        SV *err = NULL;
        SV *d = pmj_decode_file(aTHX_ path, &err);
        if (!d) {
            SV *why = sv_2mortal(err ? err : newSVpvs("it could not be read\n"));
            croak(PMJ ": %s is unusable, so nothing was written: %s", path,
                  SvPV_nolen(why));
        }
        sv_2mortal(d);
        doc = (HV *)SvRV(d);
    }
    rows = pdbi_get(aTHX_ doc, SvPV_nolen(t));
    if (!(rows && SvROK(rows) && SvTYPE(SvRV(rows)) == SVt_PVAV)) {
        AV *a = newAV();
        (void)hv_store_ent(doc, t, newRV_noinc((SV *)a), 0);
        *rows_out = a;
    }
    else *rows_out = (AV *)SvRV(rows);
    return doc;
}

/* The known, defined columns of `data`, as a fresh HV. */
static HV *pmj_known(pTHX_ HV *col, HV *d, int keep_undef) {
    HV *out = newHV();
    HE *he;
    if (!d) return out;
    hv_iterinit(d);
    while ((he = hv_iternext(d))) {
        SV *k = hv_iterkeysv(he);
        SV *v = HeVAL(he);
        if (col && HvUSEDKEYS(col) && !hv_exists_ent(col, k, 0)) continue;
        if (!keep_undef && !SvOK(v)) continue;
        (void)hv_store_ent(out, k, pmr_deep(aTHX_ v), 0);
    }
    return out;
}

/* The index of the row whose `pk` equals `id`, or -1. */
static SSize_t pmj_find(pTHX_ AV *rows, SV *pk, SV *id) {
    SSize_t i, n = av_len(rows) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(rows, i, 0);
        HE *he;
        if (!(e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)) continue;
        he = hv_fetch_ent((HV *)SvRV(*e), pk, 0, 0);
        if (he && SvOK(HeVAL(he)) && pmr_cmp(aTHX_ HeVAL(he), id) == 0) return i;
    }
    return -1;
}

static SV *pmj_create(pTHX_ SV *self, SV *data) {
    HV *h  = pmr_self(aTHX_ self, PMJ);
    HV *d  = (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV) ? (HV *)SvRV(data) : NULL;
    SV *pk = pdbi_get(aTHX_ h, "primary");
    const char *path = SvPV_nolen(pmj_file(aTHX_ h));
    HV *row = (HV *)sv_2mortal((SV *)pmj_known(aTHX_ pmr_colset(aTHX_ h), d, 0));
    AV *rows;
    HV *doc;
    SV *out;
    if (!HvUSEDKEYS(row)) croak(PMJ ": create with no known columns");
    ENTER;
    pmj_lock_scoped(aTHX_ path);
    {
        {
            doc = pmj_fresh(aTHX_ self, path, &rows);
            if (pk && SvOK(pk)) {
                HE *he = hv_fetch_ent(row, pk, 0, 0);
                if (he && SvOK(HeVAL(he))) {
                    if (pmj_find(aTHX_ rows, pk, HeVAL(he)) >= 0)
                        croak(PMJ ": a row with %s = %s already exists in %s",
                              SvPV_nolen(pk), SvPV_nolen(HeVAL(he)), path);
                }
                else {
                    /* the next integer key, when every key so far is one */
                    SSize_t i, n = av_len(rows) + 1;
                    IV max = 0;
                    for (i = 0; i < n; i++) {
                        SV **e = av_fetch(rows, i, 0);
                        HE *ke;
                        SV *k;
                        if (!(e && *e && SvROK(*e))) continue;
                        ke = hv_fetch_ent((HV *)SvRV(*e), pk, 0, 0);
                        k = ke ? HeVAL(ke) : NULL;
                        if (!(k && SvOK(k))) continue;
                        {
                            IV kv;
                            if (!pmr_int(aTHX_ k, &kv))
                                croak(PMJ ": create needs a value for %s - its "
                                      "existing keys are not all integers, so "
                                      "there is no next one", SvPV_nolen(pk));
                            if (kv > max) max = kv;
                        }
                    }
                    (void)hv_store_ent(row, pk, newSViv(max + 1), 0);
                }
            }
            av_push(rows, newRV_inc((SV *)row));
            pmj_write(aTHX_ path, doc);
        }
    }
    LEAVE;
    out = pmr_deep(aTHX_ sv_2mortal(newRV_inc((SV *)row)));
    return out;
}

static SV *pmj_update(pTHX_ SV *self, SV *data) {
    HV *h  = pmr_self(aTHX_ self, PMJ);
    HV *d  = (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV) ? (HV *)SvRV(data) : NULL;
    SV *pk = pdbi_get(aTHX_ h, "primary");
    const char *path;
    HV *changes;
    HE *pke;
    SV *id;
    SV *out = NULL;
    if (!(pk && SvOK(pk)))
        croak(PMJ ": update needs a primary key");
    pke = d ? hv_fetch_ent(d, pk, 0, 0) : NULL;
    if (!(pke && SvOK(HeVAL(pke))))
        croak(PMJ ": update needs the primary key in the data");
    id = sv_2mortal(newSVsv(HeVAL(pke)));
    path = SvPV_nolen(pmj_file(aTHX_ h));
    changes = (HV *)sv_2mortal((SV *)pmj_known(aTHX_ pmr_colset(aTHX_ h), d, 1));
    (void)hv_delete_ent(changes, pk, G_DISCARD, 0);
    ENTER;
    pmj_lock_scoped(aTHX_ path);
    {
        {
            AV *rows;
            HV *doc = pmj_fresh(aTHX_ self, path, &rows);
            SSize_t at = pmj_find(aTHX_ rows, pk, id);
            if (at >= 0) {
                HV *row = (HV *)SvRV(*av_fetch(rows, at, 0));
                HE *he;
                hv_iterinit(changes);
                while ((he = hv_iternext(changes)))
                    (void)hv_store_ent(row, hv_iterkeysv(he),
                                       newSVsv(HeVAL(he)), 0);
                if (HvUSEDKEYS(changes)) pmj_write(aTHX_ path, doc);
                out = pmr_deep(aTHX_ *av_fetch(rows, at, 0));
            }
        }
    }
    LEAVE;
    return out ? out : newSV(0);
}

static IV pmj_delete(pTHX_ SV *self, SV **st, I32 items) {
    HV *h = pmr_self(aTHX_ self, PMJ);
    HV *key;
    AV *keys = pdbi_key_args(aTHX_ st, items, &key, "delete", PMJ);
    AV *terms;
    const char *path;
    IV gone = 0;
    pdbq_check_keys(aTHX_ self, keys, PMJ, "delete");
    terms = pmr_compile(aTHX_ NULL, NULL, key, PMJ);
    path = SvPV_nolen(pmj_file(aTHX_ h));
    ENTER;
    pmj_lock_scoped(aTHX_ path);
    {
        {
            Stat_t st0;
            if (PerlLIO_stat(path, &st0) == 0) {
                AV *rows;
                HV *doc = pmj_fresh(aTHX_ self, path, &rows);
                AV *keep = newAV();
                SSize_t i, n = av_len(rows) + 1;
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(rows, i, 0);
                    if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV
                        && pmr_match(aTHX_ terms, (HV *)SvRV(*e))) {
                        gone++;
                        continue;
                    }
                    av_push(keep, e && *e ? newSVsv(*e) : newSV(0));
                }
                (void)hv_store_ent(doc, pdbi_get(aTHX_ h, "table"),
                                   newRV_noinc((SV *)keep), 0);
                if (gone) pmj_write(aTHX_ path, doc);
            }
        }
    }
    LEAVE;
    return gone;
}

/* ---- Punk::Model::Markdown ----------------------------------------------------
 *
 * The pages of a `markdown` mount, as rows: what $app->markdown_pages gives,
 * read straight from the mount's page table. The files are the pages, so the
 * backend does not write. */

#define PMM "Punk::Model::Markdown"

/* The capture of the markdown mount at `prefix` (trailing slash ignored), or
 * a croak naming why: not compiled yet, or no such mount (listing the ones
 * there are). `who` prefixes the croak. Borrowed. */
static AV *pmd_mount_cap(pTHX_ SV *app, SV *prefix, const char *who) {
    HV *h = app_hv(aTHX_ app);
    SV *mp = h ? app_get(aTHX_ h, K_MOUNTS_C) : NULL;
    SV *pf = sv_2mortal(app_strip_slash(aTHX_ prefix));
    SV *have = sv_2mortal(newSVpvs(""));
    AV *mounts;
    SSize_t i, n;
    if (!(mp && SvROK(mp) && SvTYPE(SvRV(mp)) == SVt_PVAV))
        croak("%s: the application has not been compiled yet (call it from "
              "a route, or after to_app)", who);
    mounts = (AV *)SvRV(mp);
    n = av_len(mounts) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(mounts, i, 0);
        HV *m;
        SV **flag, **mpf, **mapp;
        AV *cap;
        if (!e || !*e || !SvROK(*e)) continue;
        m = (HV *)SvRV(*e);
        flag = hv_fetchs(m, K_MD_MOUNT, 0);
        if (!(flag && *flag && SvTRUE(*flag))) continue;
        mpf = hv_fetchs(m, K_PREFIX, 0);
        if (!(mpf && *mpf)) continue;
        if (sv_cmp(*mpf, pf) != 0) {
            if (SvCUR(have)) sv_catpvs(have, ", ");
            sv_catsv(have, SvCUR(*mpf) ? *mpf : sv_2mortal(newSVpvs("/")));
            continue;
        }
        mapp = hv_fetchs(m, K_APP, 0);
        cap = (mapp && *mapp && SvROK(*mapp) && SvTYPE(SvRV(*mapp)) == SVt_PVCV)
            ? punk_clos_cap(aTHX_ (CV *)SvRV(*mapp)) : NULL;
        if (!cap)
            croak("%s: the mount at '%s' was not built", who, SvPV_nolen(*mpf));
        return cap;
    }
    croak("%s: no markdown mount at '%s' (%s%s)", who,
          SvCUR(pf) ? SvPV_nolen(pf) : "/",
          SvCUR(have) ? "markdown mounts: " : "there are none",
          SvPV_nolen(have));
    return NULL;   /* not reached */
}

/* The mount's pages as rows. Mortal AV. */
static AV *pmm_rows(pTHX_ SV *self) {
    HV *h = pmr_self(aTHX_ self, PMM);
    SV *app = pdbi_get(aTHX_ h, "app");
    SV *o = pdbi_get(aTHX_ h, "opts");
    SV *prefix = (o && SvROK(o)) ? pdbi_get(aTHX_ (HV *)SvRV(o), "prefix") : NULL;
    if (!(app && SvROK(app)))
        croak(PMM ": the application has gone away");
    return (AV *)sv_2mortal((SV *)pmd_pages_av(aTHX_
        pmd_mount_cap(aTHX_ app, prefix, PMM)));
}

#endif /* PUNK_MROWS_H */
