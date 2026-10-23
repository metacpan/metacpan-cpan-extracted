/* punk_computed.h - Punk::Model::Computed, a base class for read-only model
 * backends whose rows are worked out from the question rather than stored,
 * and Punk::Model::Computed::Error, the error a visitor's input raises there.
 *
 * A subclass declares its tables (`answers`): which fields each may be asked
 * by, which operators a field takes, and which fields are taken whole. The
 * base checks every filter and option against that, as Punk's own backends
 * check theirs, and hands the normalised question ({ field => { op => value }})
 * to the subclass's _get_<table>, _search_<table> and _count_<table>. Nothing
 * is stored, so create, update and delete croak.
 *
 * The declarations live in the subclass's own package (%PUNK_COMPUTED), not
 * in a C static: they are made at compile time and a static would hold the
 * parent interpreter's SVs in a pseudo-forked child.
 *
 * The object is the blessed hash pdbi_build_self makes, plus spec (the
 * table's declaration), app (weak), and the cache's slots.
 *
 * Include after punk_dbq.h. */

#ifndef PUNK_COMPUTED_H
#define PUNK_COMPUTED_H

#define PMC  "Punk::Model::Computed"
#define PMCE "Punk::Model::Computed::Error"
#define PMC_CACHE_DEFAULT 256

/* ---- the error ----------------------------------------------------------------- */

static SV *pmce_new(pTHX_ SV *cls, SV *field, SV *message) {
    HV *h = newHV();
    HV *stash;
    if (cls && SvROK(cls) && SvOBJECT(SvRV(cls))) stash = SvSTASH(SvRV(cls));
    else stash = gv_stashsv(cls ? cls : sv_2mortal(newSVpvs(PMCE)), GV_ADD);
    (void)hv_stores(h, "field",   field ? newSVsv(field) : newSV(0));
    (void)hv_stores(h, "message", message ? newSVsv(message) : newSV(0));
    return sv_bless(newRV_noinc((SV *)h), stash);
}

static int pmce_is(pTHX_ SV *e) {
    return e && sv_isobject(e) && sv_derived_from(e, PMCE);
}

static void pmce_throw(pTHX_ SV *cls, SV *field, SV *message) {
    croak_sv(sv_2mortal(pmce_new(aTHX_ cls, field, message)));
}

static void pmce_throw_pv(pTHX_ const char *field, SV *message) {
    pmce_throw(aTHX_ NULL, sv_2mortal(newSVpv(field, 0)), message);
}

static int pmce_word(char c) { return isALNUM(c) || c == '_'; }

/* The length of `s` without a trailing " at FILE line N." (with perl's
 * optional ", <FH> line N" or "chunk N" after it), the place a die names. */
static STRLEN pmce_strip_at(const char *s, STRLEN len) {
    STRLEN p;
    for (p = 0; p + 4 <= len; p++) {
        STRLEN q;
        if (memNE(s + p, " at ", 4)) continue;
        q = p + 4;
        if (q >= len || isSPACE(s[q])) continue;
        while (q < len && !isSPACE(s[q])) q++;
        if (q + 6 > len || memNE(s + q, " line ", 6)) continue;
        q += 6;
        if (q >= len || !isDIGIT(s[q])) continue;
        while (q < len && isDIGIT(s[q])) q++;
        if (q + 3 <= len && memEQ(s + q, ", <", 3)) {
            STRLEN r = q + 3;
            while (r < len && s[r] != '>') r++;
            if (r < len && r + 2 <= len && s[r + 1] == ' ') {
                r += 2;
                if (r + 5 <= len && (memEQ(s + r, "line ", 5) || memEQ(s + r, "chunk", 5))) {
                    r += 5;
                    if (r < len && s[r] == ' ') r++;
                    if (r < len && isDIGIT(s[r])) {
                        while (r < len && isDIGIT(s[r])) r++;
                        q = r;
                    }
                }
            }
        }
        if (q < len && s[q] == '.') q++;
        if (q < len && s[q] == '\n') q++;
        if (q == len) return p;
    }
    if (len && s[len - 1] == '\n') return len - 1;
    return len;
}

/* The length of a leading "Class->method: ", the prefix a dist's croak
 * names itself with, or 0. */
static STRLEN pmce_prefix(const char *s, STRLEN len) {
    STRLEN q = 0;
    while (q < len && (pmce_word(s[q]) || s[q] == ':')) q++;
    if (!q || q + 2 > len || s[q] != '-' || s[q + 1] != '>') return 0;
    q += 2;
    if (q >= len || !pmce_word(s[q])) return 0;
    while (q < len && pmce_word(s[q])) q++;
    if (q + 2 > len || s[q] != ':' || s[q + 1] != ' ') return 0;
    return q + 2;
}

/* A die's text in the dist's own words, for a visitor: without where it was
 * raised and without the method that raised it. An object other than the
 * error is its string. Mortal. */
static SV *pmce_said(pTHX_ SV *e) {
    SV *s = sv_2mortal(newSVsv(e));
    const char *p;
    STRLEN len, end, start;
    SV *out;
    if (SvROK(e)) {
        (void)SvPV_nolen(s);
        return s;
    }
    p = SvPV_const(s, len);
    end = pmce_strip_at(p, len);
    start = pmce_prefix(p, end);
    out = sv_2mortal(newSVpvn(p + start, end - start));
    if (SvUTF8(s)) SvUTF8_on(out);
    return out;
}

/* The error a die becomes: itself when it is one already, else a new one for
 * `field` in the dist's words. Mortal. */
static SV *pmce_from(pTHX_ SV *cls, SV *field, SV *e) {
    if (pmce_is(aTHX_ e)) return e;
    return sv_2mortal(pmce_new(aTHX_ cls, field, pmce_said(aTHX_ e)));
}

static HV *pmce_hv(pTHX_ SV *self) {
    if (!(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV))
        croak(PMCE ": not an error object");
    return (HV *)SvRV(self);
}

/* ---- the declarations ------------------------------------------------------------ */

static const char *pmc_cls(pTHX_ SV *self) {
    if (SvROK(self) && SvOBJECT(SvRV(self))) return HvNAME(SvSTASH(SvRV(self)));
    return SvPV_nolen(self);
}

static HV *pmc_decl_hv(pTHX_ const char *cls, I32 flags) {
    SV *name = sv_2mortal(newSVpvf("%s::PUNK_COMPUTED", cls));
    return get_hv(SvPV_nolen(name), flags);
}

/* The declaration of `table` for `cls` or the nearest class it inherits one
 * from, or NULL. */
static HV *pmc_spec(pTHX_ const char *cls, SV *table) {
    HV *stash = gv_stashpv(cls, 0);
    AV *isa;
    SSize_t i, n;
    if (!stash) return NULL;
    isa = mro_get_linear_isa(stash);
    n = av_len(isa) + 1;
    for (i = 0; i < n; i++) {
        SV **c = av_fetch(isa, i, 0);
        HV *d = c && *c ? pmc_decl_hv(aTHX_ SvPV_nolen(*c), 0) : NULL;
        HE *he = d ? hv_fetch_ent(d, table, 0, 0) : NULL;
        if (he && SvROK(HeVAL(he))) return (HV *)SvRV(HeVAL(he));
    }
    return NULL;
}

/* Every table `cls` answers, its own and inherited, sorted. Mortal AV. */
static AV *pmc_tables(pTHX_ const char *cls) {
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    HV *stash = gv_stashpv(cls, 0);
    if (stash) {
        AV *isa = mro_get_linear_isa(stash);
        SSize_t i, n = av_len(isa) + 1;
        for (i = 0; i < n; i++) {
            SV **c = av_fetch(isa, i, 0);
            HV *d = c && *c ? pmc_decl_hv(aTHX_ SvPV_nolen(*c), 0) : NULL;
            HE *he;
            if (!d) continue;
            hv_iterinit(d);
            while ((he = hv_iternext(d)))
                (void)hv_store_ent(seen, HeSVKEY_force(he), newSViv(1), 0);
        }
    }
    return pdbi_sorted_keys(aTHX_ seen);
}

static SV *pmc_join(pTHX_ AV *av) {
    SV *s = sv_2mortal(newSVpvs(""));
    SSize_t i, n = av_len(av) + 1;
    for (i = 0; i < n; i++) {
        if (i) sv_catpvs(s, ", ");
        sv_catsv(s, *av_fetch(av, i, 0));
    }
    return s;
}

static int pmc_ident(pTHX_ SV *sv) {
    STRLEN l, i;
    const char *p;
    if (!(sv && SvOK(sv) && !SvROK(sv))) return 0;
    p = SvPV_const(sv, l);
    if (!l || isDIGIT(p[0])) return 0;
    for (i = 0; i < l; i++) if (!pmce_word(p[i])) return 0;
    return 1;
}

/* A list of field names as a set, each checked. Owned HV. */
static HV *pmc_name_set(pTHX_ const char *cls, SV *table, const char *what,
                        SV *list) {
    HV *set;
    AV *av;
    SSize_t i, n;
    if (!(list && SvROK(list) && SvTYPE(SvRV(list)) == SVt_PVAV))
        croak("%s: %s's %s is a list of field names", cls, SvPV_nolen(table), what);
    set = newHV();
    av = (AV *)SvRV(list);
    n = av_len(av) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        if (!(e && *e && SvOK(*e) && !SvROK(*e) && SvCUR(*e))) {
            SvREFCNT_dec((SV *)set);
            croak("%s: %s's %s is a list of field names", cls, SvPV_nolen(table), what);
        }
        (void)hv_store_ent(set, *e, newSViv(1), 0);
    }
    return set;
}

/* `answers(table => { ask => [...], ops => { f => [...] }, as_is => [...] })`:
 * one table's declaration, checked and stored normalised as
 * { ask => {f=>1}, ops => { f => {op=>1} }, as_is => {f=>1} }. */
static void pmc_declare(pTHX_ const char *cls, SV *table, SV *spec) {
    HV *s, *out, *ask, *ops, *as_is;
    HE *he;
    SV *v;
    if (!pmc_ident(aTHX_ table))
        croak("%s: a table's name is a word, not '%s'", cls,
              table && SvOK(table) ? SvPV_nolen(table) : "undef");
    if (!(spec && SvROK(spec) && SvTYPE(SvRV(spec)) == SVt_PVHV))
        croak("%s: %s's declaration is a hash reference", cls, SvPV_nolen(table));
    s = (HV *)SvRV(spec);
    hv_iterinit(s);
    while ((he = hv_iternext(s))) {
        STRLEN kl; const char *k = HePV(he, kl);
        if ((kl == 3 && memEQ(k, "ask", 3)) || (kl == 3 && memEQ(k, "ops", 3))
         || (kl == 5 && memEQ(k, "as_is", 5))) continue;
        croak("%s: %s's declaration has no '%.*s' (known: ask, as_is, ops)",
              cls, SvPV_nolen(table), (int)kl, k);
    }
    v = pdbi_get(aTHX_ s, "ask");
    ask = v ? pmc_name_set(aTHX_ cls, table, "ask", v) : newHV();
    sv_2mortal((SV *)ask);
    v = pdbi_get(aTHX_ s, "as_is");
    as_is = v ? pmc_name_set(aTHX_ cls, table, "as_is", v) : newHV();
    sv_2mortal((SV *)as_is);
    hv_iterinit(as_is);
    while ((he = hv_iternext(as_is)))
        if (!hv_exists_ent(ask, HeSVKEY_force(he), 0))
            croak("%s: %s's as_is names '%s', which it is not asked by",
                  cls, SvPV_nolen(table), SvPV_nolen(HeSVKEY_force(he)));
    ops = (HV *)sv_2mortal((SV *)newHV());
    v = pdbi_get(aTHX_ s, "ops");
    if (v) {
        HV *o;
        if (!(SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV))
            croak("%s: %s's ops is { field => [operators] }", cls, SvPV_nolen(table));
        o = (HV *)SvRV(v);
        hv_iterinit(o);
        while ((he = hv_iternext(o))) {
            SV *f = HeSVKEY_force(he), *l = HeVAL(he);
            HV *set;
            AV *av;
            SSize_t i, n;
            if (!hv_exists_ent(ask, f, 0))
                croak("%s: %s's ops names '%s', which it is not asked by",
                      cls, SvPV_nolen(table), SvPV_nolen(f));
            if (hv_exists_ent(as_is, f, 0))
                croak("%s: %s's '%s' is taken as it is and takes no operators",
                      cls, SvPV_nolen(table), SvPV_nolen(f));
            if (!(SvROK(l) && SvTYPE(SvRV(l)) == SVt_PVAV))
                croak("%s: %s's ops is { field => [operators] }", cls, SvPV_nolen(table));
            set = (HV *)sv_2mortal((SV *)newHV());
            av = (AV *)SvRV(l);
            n = av_len(av) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                STRLEN ol;
                const char *op = (e && *e && SvOK(*e)) ? SvPV_const(*e, ol) : NULL;
                if (!op || pdbq_op_index(op, ol) < 0)
                    croak("%s: %s's '%s' names an operator '%s' (known: %s)",
                          cls, SvPV_nolen(table), SvPV_nolen(f), op ? op : "undef",
                          SvPV_nolen(pdbq_op_list(aTHX)));
                (void)hv_store_ent(set, *e, newSViv(1), 0);
            }
            (void)hv_store_ent(ops, f, newRV_inc((SV *)set), 0);
        }
    }
    out = newHV();
    (void)hv_stores(out, "ask",   newRV_inc((SV *)ask));
    (void)hv_stores(out, "ops",   newRV_inc((SV *)ops));
    (void)hv_stores(out, "as_is", newRV_inc((SV *)as_is));
    (void)hv_store_ent(pmc_decl_hv(aTHX_ cls, GV_ADD | GV_ADDMULTI), table,
                       newRV_noinc((SV *)out), 0);
}

/* ---- the object ---------------------------------------------------------------- */

static HV *pmc_self(pTHX_ SV *self) {
    if (!(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV))
        croak(PMC ": not a backend object");
    return (HV *)SvRV(self);
}

static HV *pmc_sub(pTHX_ HV *spec, const char *k) {
    SV *v = pdbi_get(aTHX_ spec, k);
    return v && SvROK(v) ? (HV *)SvRV(v) : NULL;
}

static SV *pmc_build(pTHX_ SV *class, SV **st, I32 items) {
    SV *self = pdbi_build_self(aTHX_ class, st, items, SvPV_nolen(class));
    HV *h = (HV *)SvRV(self);
    const char *cls = HvNAME(SvSTASH((SV *)h));
    SV *table = pdbi_get(aTHX_ h, "table");
    SV *o = pdbi_get(aTHX_ h, "opts");
    SV *app = NULL, *size = NULL;
    HV *spec;
    IV max = PMC_CACHE_DEFAULT;
    I32 i;
    sv_2mortal(self);
    spec = pmc_spec(aTHX_ cls, table);
    if (!spec) {
        AV *t = pmc_tables(aTHX_ cls);
        croak("%s: no table '%s' (%s%s)", cls, SvPV_nolen(table),
              av_len(t) >= 0 ? "it answers " : "it declares none: answers(table => {...})",
              SvPV_nolen(pmc_join(aTHX_ t)));
    }
    if (o && SvROK(o)) size = pdbi_get(aTHX_ (HV *)SvRV(o), "cache");
    if (size && SvOK(size)) {
        STRLEN l, j;
        const char *p = SvPV_const(size, l);
        for (j = 0; j < l; j++) if (!isDIGIT(p[j])) break;
        if (!l || j < l)
            croak("%s: the database's cache is how many answers to keep, a whole "
                  "number (0 for none), not '%s'", cls, p);
        max = SvIV(size);
    }
    for (i = 1; i + 1 < items; i += 2) {
        STRLEN kl; const char *k = SvPV_const(st[i], kl);
        if (kl == 3 && memEQ(k, "app", 3)) app = st[i + 1];
    }
    if (app && SvROK(app)) {
        SV *w = newSVsv(app);
        sv_rvweaken(w);
        (void)hv_stores(h, "app", w);
    }
    (void)hv_stores(h, "spec", newRV_inc((SV *)spec));
    (void)hv_stores(h, "cache", newRV_noinc((SV *)newHV()));
    (void)hv_stores(h, "cache_max", newSViv(max));
    (void)hv_stores(h, "cache_tick", newSViv(0));
    return SvREFCNT_inc_simple_NN(self);
}

/* ---- the question --------------------------------------------------------------- */

/* A filter as { field => { op => value } }: each field one of the model's,
 * one the table is asked by, each operator one the field takes. A field
 * taken as it is keeps its value whole, a hash or a list included. A
 * program's fault croaks. Mortal RV. */
static SV *pmc_filter(pTHX_ SV *self, SV *filter) {
    HV *h = pmc_self(aTHX_ self);
    const char *cls = pmc_cls(aTHX_ self);
    SV *table = pdbi_get(aTHX_ h, "table");
    HV *spec = pmc_sub(aTHX_ h, "spec");
    HV *ask = spec ? pmc_sub(aTHX_ spec, "ask") : NULL;
    HV *ops = spec ? pmc_sub(aTHX_ spec, "ops") : NULL;
    HV *as_is = spec ? pmc_sub(aTHX_ spec, "as_is") : NULL;
    HV *col = pmr_colset(aTHX_ h);
    HV *out = newHV();
    SV *rv = sv_2mortal(newRV_noinc((SV *)out));
    AV *keys;
    SSize_t i, n;
    if (filter && SvOK(filter) && !(SvROK(filter) && SvTYPE(SvRV(filter)) == SVt_PVHV))
        croak("%s: a filter is a hash reference", cls);
    if (!(filter && SvROK(filter))) return rv;
    keys = pdbi_sorted_keys(aTHX_ (HV *)SvRV(filter));
    n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV *k = *av_fetch(keys, i, 0);
        HE *he = hv_fetch_ent((HV *)SvRV(filter), k, 0, 0);
        SV *v = he ? HeVAL(he) : &PL_sv_undef;
        HV *term;
        pdbq_check_col(aTHX_ col, k, table, cls, "a filter");
        if (!(ask && hv_exists_ent(ask, k, 0)))
            croak("%s: '%s' is an answer of %s, not something to ask it by",
                  cls, SvPV_nolen(k), SvPV_nolen(table));
        term = newHV();
        (void)hv_store_ent(out, k, newRV_noinc((SV *)term), 0);
        if (as_is && hv_exists_ent(as_is, k, 0)) {
            (void)hv_stores(term, "=", newSVsv(v));
            continue;
        }
        if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV && !SvOBJECT(SvRV(v))) {
            HV *given = (HV *)SvRV(v);
            HE *oe = ops ? hv_fetch_ent(ops, k, 0, 0) : NULL;
            HV *takes = oe && SvROK(HeVAL(oe)) ? (HV *)SvRV(HeVAL(oe)) : NULL;
            AV *gk = pdbi_sorted_keys(aTHX_ given);
            SSize_t j, m = av_len(gk) + 1;
            if (!m) croak("%s: an empty operator hash for '%s'", cls, SvPV_nolen(k));
            for (j = 0; j < m; j++) {
                SV *op = *av_fetch(gk, j, 0);
                STRLEN ol; const char *o = SvPV_const(op, ol);
                HE *ve;
                if (!(ol == 1 && *o == '=') && !(takes && hv_exists_ent(takes, op, 0))) {
                    AV *t = takes ? pdbi_sorted_keys(aTHX_ takes) : NULL;
                    croak("%s: '%s' takes no operator '%s' here (%s%s)", cls,
                          SvPV_nolen(k), o, t && av_len(t) >= 0 ? "it takes =, " : "only =",
                          t && av_len(t) >= 0 ? SvPV_nolen(pmc_join(aTHX_ t)) : "");
                }
                ve = hv_fetch_ent(given, op, 0, 0);
                (void)hv_store_ent(term, op, newSVsv(ve ? HeVAL(ve) : &PL_sv_undef), 0);
            }
        }
        else if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV && !SvOBJECT(SvRV(v)))
            croak("%s: a list for '%s' is { in => [...] }", cls, SvPV_nolen(k));
        else (void)hv_stores(term, "=", newSVsv(v));
    }
    return rv;
}

/* The search options: limit and after. order_by croaks, the rows coming in
 * the order the table works them out in. Mortal RV, a copy. */
static SV *pmc_options(pTHX_ SV *self, SV *opts) {
    HV *h = pmc_self(aTHX_ self);
    const char *cls = pmc_cls(aTHX_ self);
    HV *out = newHV();
    SV *rv = sv_2mortal(newRV_noinc((SV *)out));
    HE *he;
    if (opts && SvOK(opts) && !(SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV))
        croak("%s: options are a hash reference", cls);
    if (!(opts && SvROK(opts))) return rv;
    hv_iterinit((HV *)SvRV(opts));
    while ((he = hv_iternext((HV *)SvRV(opts)))) {
        STRLEN kl; const char *k = HePV(he, kl);
        if (kl == 8 && memEQ(k, "order_by", 8)) {
            if (!SvOK(HeVAL(he))) continue;
            croak("%s: the %s rows come in their own order, which order_by "
                  "cannot change", cls, SvPV_nolen(pdbi_get(aTHX_ h, "table")));
        }
        if (!((kl == 5 && memEQ(k, "limit", 5)) || (kl == 5 && memEQ(k, "after", 5))))
            croak("%s: unknown search option '%.*s' (known: after, limit)", cls, (int)kl, k);
        (void)hv_store_ent(out, HeSVKEY_force(he), newSVsv(HeVAL(he)), 0);
    }
    return rv;
}

/* ---- the contract --------------------------------------------------------------- */

static const char *const PMC_VERBS[] = { "get", "search", "count" };

static CV *pmc_hook(pTHX_ SV *self, int verb) {
    HV *h = pmc_self(aTHX_ self);
    SV *table = pdbi_get(aTHX_ h, "table");
    SV *name = sv_2mortal(newSVpvf("_%s_%s", PMC_VERBS[verb], SvPV_nolen(table)));
    GV *gv = gv_fetchmethod_autoload(SvSTASH(SvRV(self)), SvPV_nolen(name), FALSE);
    return gv && isGV(gv) ? GvCV(gv) : NULL;
}

/* `$self->_<verb>_<table>(@args)` in scalar context, or a croak naming what
 * the table does answer. A new SV. */
static SV *pmc_call(pTHX_ SV *self, int verb, SV *a, SV *b) {
    CV *cv = pmc_hook(aTHX_ self, verb);
    SV *ret;
    int count;
    if (!cv) {
        SV *have = sv_2mortal(newSVpvs(""));
        int i;
        for (i = 0; i < 3; i++) {
            if (!pmc_hook(aTHX_ self, i)) continue;
            if (SvCUR(have)) sv_catpvs(have, ", ");
            sv_catpv(have, PMC_VERBS[i]);
        }
        croak("%s: the %s table answers %s, not %s (define _%s_%s)",
              pmc_cls(aTHX_ self), SvPV_nolen(pdbi_get(aTHX_ pmc_self(aTHX_ self), "table")),
              SvCUR(have) ? SvPV_nolen(have) : "nothing", PMC_VERBS[verb],
              PMC_VERBS[verb], SvPV_nolen(pdbi_get(aTHX_ pmc_self(aTHX_ self), "table")));
    }
    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(a);
        if (b) XPUSHs(b);
        PUTBACK;
        count = call_sv((SV *)cv, G_SCALAR);
        SPAGAIN;
        ret = count ? POPs : &PL_sv_undef;
        ret = newSVsv(ret);
        PUTBACK;
        FREETMPS; LEAVE;
    }
    return ret;
}

static SV *pmc_search(pTHX_ SV *self, SV *filter, SV *opts) {
    SV *f = pmc_filter(aTHX_ self, filter);
    SV *o = pmc_options(aTHX_ self, opts);
    return pmc_call(aTHX_ self, 1, f, o);
}

/* ---- limit -------------------------------------------------------------------- */

static IV pmc_limit(pTHX_ SV *opts, SV *dflt, IV max, SV *what) {
    SV *n = NULL;
    STRLEN l, j;
    const char *p;
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
        n = pdbi_get(aTHX_ (HV *)SvRV(opts), "limit");
    if (!(n && SvOK(n))) n = dflt;
    if (!(n && SvOK(n) && !SvROK(n)))
        pmce_throw_pv(aTHX_ "limit", sv_2mortal(newSVpvf(
            "limit must be a whole number from 1 to %" IVdf, max)));
    p = SvPV_const(n, l);
    for (j = 0; j < l; j++) if (!isDIGIT(p[j])) break;
    if (!l || j < l || !SvIV(n))
        pmce_throw_pv(aTHX_ "limit", sv_2mortal(newSVpvf(
            "limit must be a whole number from 1 to %" IVdf, max)));
    if (l > 18 || SvIV(n) > max)
        pmce_throw_pv(aTHX_ "limit", sv_2mortal(newSVpvf(
            "at most %" IVdf " %s at a time", max,
            what && SvOK(what) ? SvPV_nolen(what) : "rows")));
    return SvIV(n);
}

/* ---- the cache ---------------------------------------------------------------- */

/* One part of a cache key, written so that two different values never write
 * the same bytes: each scalar its length first, hashes by sorted key, an
 * object as its string. Read without changing the value. */
static void pmc_key_part(pTHX_ SV *out, SV *v, int depth) {
    if (depth > 64) croak(PMC ": a cache key nested deeper than 64 (a cycle?)");
    SvGETMAGIC(v);
    if (!SvOK(v)) { sv_catpvs(out, "u"); return; }
    if (SvROK(v)) {
        SV *r = SvRV(v);
        if (SvOBJECT(r)) {
            SV *s = sv_2mortal(newSVsv(v));
            STRLEN l; const char *p = SvPVutf8(s, l);
            sv_catpvf(out, "o%s=%" UVuf ":", HvNAME(SvSTASH(r)), (UV)l);
            sv_catpvn(out, p, l);
            return;
        }
        if (SvTYPE(r) == SVt_PVHV) {
            AV *k = pdbi_sorted_keys(aTHX_ (HV *)r);
            SSize_t i, n = av_len(k) + 1;
            sv_catpvs(out, "{");
            for (i = 0; i < n; i++) {
                SV *key = *av_fetch(k, i, 0);
                HE *he = hv_fetch_ent((HV *)r, key, 0, 0);
                pmc_key_part(aTHX_ out, key, depth + 1);
                pmc_key_part(aTHX_ out, he ? HeVAL(he) : &PL_sv_undef, depth + 1);
            }
            sv_catpvs(out, "}");
            return;
        }
        if (SvTYPE(r) == SVt_PVAV) {
            SSize_t i, n = av_len((AV *)r) + 1;
            sv_catpvs(out, "[");
            for (i = 0; i < n; i++) {
                SV **e = av_fetch((AV *)r, i, 0);
                pmc_key_part(aTHX_ out, e && *e ? *e : &PL_sv_undef, depth + 1);
            }
            sv_catpvs(out, "]");
            return;
        }
        if (SvTYPE(r) < SVt_PVAV) {
            sv_catpvs(out, "\\");
            pmc_key_part(aTHX_ out, r, depth + 1);
            return;
        }
        croak(PMC ": a cache key is made of plain values, hashes, lists and "
              "objects, not a %s reference", sv_reftype(r, 0));
    }
    {
        SV *s = sv_2mortal(newSVsv(v));
        STRLEN l; const char *p = SvPVutf8(s, l);
        sv_catpvf(out, "s%" UVuf ":", (UV)l);
        sv_catpvn(out, p, l);
    }
}

/* What `code` answers, kept under `key` among the last cache_max answers.
 * An undef key runs it every time. A new SV. */
static SV *pmc_cached(pTHX_ SV *self, SV *key, SV *code) {
    HV *h = pmc_self(aTHX_ self);
    SV *cs = pdbi_get(aTHX_ h, "cache");
    SV *mx = pdbi_get(aTHX_ h, "cache_max");
    SV *tk = pdbi_get(aTHX_ h, "cache_tick");
    HV *cache = cs && SvROK(cs) ? (HV *)SvRV(cs) : NULL;
    IV max = mx ? SvIV(mx) : 0;
    HE *he;
    SV *v;
    int count;
    if (!(code && SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV))
        croak("%s: cached takes a key and a code reference", pmc_cls(aTHX_ self));
    if (cache && max > 0 && key && SvOK(key)
        && (he = hv_fetch_ent(cache, key, 0, 0))) {
        AV *slot = (AV *)SvRV(HeVAL(he));
        sv_setiv(tk, SvIV(tk) + 1);
        sv_setiv(*av_fetch(slot, 1, 0), SvIV(tk));
        return newSVsv(*av_fetch(slot, 0, 0));
    }
    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        count = call_sv(code, G_SCALAR);
        SPAGAIN;
        v = count ? POPs : &PL_sv_undef;
        v = newSVsv(v);
        PUTBACK;
        FREETMPS; LEAVE;
    }
    if (!(cache && max > 0 && key && SvOK(key))) return v;
    while ((IV)HvUSEDKEYS(cache) >= max) {
        SV *oldest = NULL;
        IV at = 0;
        hv_iterinit(cache);
        while ((he = hv_iternext(cache))) {
            IV t = SvIV(*av_fetch((AV *)SvRV(HeVAL(he)), 1, 0));
            if (!oldest || t < at) { oldest = HeSVKEY_force(he); at = t; }
        }
        if (!oldest) break;
        oldest = sv_2mortal(newSVsv(oldest));
        (void)hv_delete_ent(cache, oldest, G_DISCARD, 0);
    }
    {
        AV *slot = newAV();
        sv_setiv(tk, SvIV(tk) + 1);
        av_push(slot, newSVsv(v));
        av_push(slot, newSViv(SvIV(tk)));
        (void)hv_store_ent(cache, key, newRV_noinc((SV *)slot), 0);
    }
    return v;
}

#endif /* PUNK_COMPUTED_H */
