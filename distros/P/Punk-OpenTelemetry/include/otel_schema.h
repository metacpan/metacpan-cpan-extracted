/* otel_schema.h - schema-version conversion.
 *
 * A schema file records what CHANGED going up to each version. Converting a
 * payload between two versions is therefore a walk over the versions between
 * them, applying each one's rename maps in turn.
 *
 * The YAML parse is the one thing here that is not C: the format needs a
 * parser, which parser is a runtime question (the feature is opt-in and most
 * deployments never touch it, so a hard dependency would tax everyone for the
 * few), and the result is ordinary Perl data that the rest of this file walks.
 * So the parser is called by name, as the exporter calls HTTP::Date.
 *
 * Needs otel_trace.h (otel_h / otel_h_hv / otel_h_av).
 */

#ifndef OTEL_SCHEMA_H
#define OTEL_SCHEMA_H

/* The marker a metric rename is stored under, so one map can carry both
 * attribute and metric renames without them colliding: no attribute name
 * contains a NUL. */
#define OTEL_METRIC_MARK     "\0metric\0"
#define OTEL_METRIC_MARK_LEN 8

/* ---- semantic version ordering ------------------------------------------ *
 *
 * Versions are applied ONE AT A TIME, in order, so this has to be right:
 * comparing "1.10.0" and "1.9.0" as strings puts them the wrong way round and
 * silently applies the changes backwards. */
static int otel_schema_vcmp(pTHX_ SV *a, SV *b) {
    STRLEN al, bl;
    const char *ap = SvOK(a) ? SvPV_const(a, al) : "";
    const char *bp = SvOK(b) ? SvPV_const(b, bl) : "";
    STRLEN ai = 0, bi = 0;
    int part;
    if (!SvOK(a)) al = 0;
    if (!SvOK(b)) bl = 0;
    for (part = 0; part < 3; part++) {
        IV av = 0, bv = 0;
        while (ai < al && ap[ai] != '.') {
            if (isDIGIT(ap[ai])) av = av * 10 + (ap[ai] - '0');
            ai++;
        }
        if (ai < al) ai++;                     /* step over the dot */
        while (bi < bl && bp[bi] != '.') {
            if (isDIGIT(bp[bi])) bv = bv * 10 + (bp[bi] - '0');
            bi++;
        }
        if (bi < bl) bi++;
        if (av != bv) return av < bv ? -1 : 1;
    }
    return 0;
}

/* sortsv comparator over the version keys */
static I32 otel_schema_sortcmp(pTHX_ SV *a, SV *b) {
    return (I32)otel_schema_vcmp(aTHX_ a, b);
}

/* ---- the version string inside a schema URL ------------------------------ *
 * m{([0-9]+(?:\.[0-9]+)*)/?\z} - the trailing version, with an optional
 * trailing slash. Mortal SV, or NULL. */
static SV *otel_schema_url_version(pTHX_ SV *url) {
    STRLEN l;
    const char *p;
    STRLEN end, start;
    if (!url || !SvOK(url)) return NULL;
    p = SvPV_const(url, l);
    end = l;
    if (end && p[end - 1] == '/') end--;       /* the optional slash */
    if (!end) return NULL;
    if (!isDIGIT(p[end - 1])) return NULL;     /* must end in a digit */
    start = end;
    while (start > 0 && (isDIGIT(p[start - 1]) || p[start - 1] == '.')) start--;
    /* the match is anchored on a digit run, so step over any leading dots */
    while (start < end && p[start] == '.') start++;
    if (start >= end) return NULL;
    return sv_2mortal(newSVpvn(p + start, end - start));
}

/* ---- the rename map for one version -------------------------------------- *
 *
 * A version's `all` section applies to every signal, and its per-signal
 * section to that one. Both are merged, `all` first so a signal-specific
 * rename wins. Attribute renames go in under their own name; metric renames
 * go in under the NUL marker. Mortal HV. */
static HV *otel_schema_renames(pTHX_ HV *self, SV *version, const char *signal,
                               STRLEN siglen) {
    HV *out = (HV *)sv_2mortal((SV *)newHV());
    HV *versions = otel_h_hv(aTHX_ self, "versions");
    HE *he;
    HV *v;
    int pass;
    if (!versions) return out;
    he = hv_fetch_ent(versions, version, 0, 0);
    if (!(he && HeVAL(he))) return out;
    v = otel_hv_of(aTHX_ HeVAL(he));
    if (!v) return out;

    for (pass = 0; pass < 2; pass++) {
        SV **sp = (pass == 0) ? hv_fetchs(v, "all", 0)
                              : hv_fetch(v, signal, (I32)siglen, 0);
        HV *sect = (sp && *sp) ? otel_hv_of(aTHX_ *sp) : NULL;
        AV *changes;
        SSize_t i, n;
        if (!sect) continue;
        changes = otel_h_av(aTHX_ sect, "changes");
        if (!changes) continue;
        n = av_len(changes) + 1;
        for (i = 0; i < n; i++) {
            SV **cp = av_fetch(changes, i, 0);
            HV *ch = (cp && *cp) ? otel_hv_of(aTHX_ *cp) : NULL;
            SV **mp;
            HV *m;
            if (!ch) continue;

            mp = hv_fetchs(ch, "rename_attributes", 0);
            m  = (mp && *mp) ? otel_hv_of(aTHX_ *mp) : NULL;
            if (m) {
                /* the spec nests the map under attribute_map; a file that
                 * writes it flat is accepted too */
                SV **inner = hv_fetchs(m, "attribute_map", 0);
                HV *im = (inner && *inner) ? otel_hv_of(aTHX_ *inner) : NULL;
                if (im) m = im;
                hv_iterinit(m);
                while ((he = hv_iternext(m))) {
                    STRLEN kl;
                    const char *k = HePV(he, kl);
                    (void)hv_store(out, k, (I32)kl, newSVsv(HeVAL(he)), 0);
                }
            }

            /* a metric rename renames the METRIC as well as its attributes */
            mp = hv_fetchs(ch, "rename_metrics", 0);
            m  = (mp && *mp) ? otel_hv_of(aTHX_ *mp) : NULL;
            if (m) {
                hv_iterinit(m);
                while ((he = hv_iternext(m))) {
                    STRLEN kl;
                    const char *k = HePV(he, kl);
                    SV *key = sv_2mortal(newSVpvn(OTEL_METRIC_MARK,
                                                  OTEL_METRIC_MARK_LEN));
                    sv_catpvn(key, k, kl);
                    (void)hv_store_ent(out, key, newSVsv(HeVAL(he)), 0);
                }
            }
        }
    }
    return out;
}

/* ---- which versions to apply, and in which direction --------------------- *
 *
 * THE RULE THAT MATTERS: they are applied ONE AT A TIME, in order. A single
 * merged rename map computed in one pass gives the wrong answer whenever an
 * attribute was renamed twice - a -> b in 1.1 and b -> c in 1.2 has to become
 * a -> c, and a flattened map produces a -> b and b -> c as independent
 * entries, so `a` arrives as `b` and stops there.
 *
 * Fills *dir with the direction and returns the steps (mortal AV). */
static AV *otel_schema_walk(pTHX_ HV *self, SV *from, SV *to, int *dir) {
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    AV *order = otel_h_av(aTHX_ self, "order");
    SSize_t i, n;
    int d = otel_schema_vcmp(aTHX_ to, from);
    *dir = d;
    if (d == 0 || !order) return out;
    n = av_len(order) + 1;
    if (d > 0) {
        /* forward: apply every version ABOVE from, up to and including to */
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(order, i, 0);
            if (!(e && *e)) continue;
            if (otel_schema_vcmp(aTHX_ *e, from) > 0
                && otel_schema_vcmp(aTHX_ *e, to) <= 0)
                av_push(out, newSVsv(*e));
        }
    }
    else {
        /* backward: undo every version above to, down to and including from,
         * newest first */
        for (i = n - 1; i >= 0; i--) {
            SV **e = av_fetch(order, i, 0);
            if (!(e && *e)) continue;
            if (otel_schema_vcmp(aTHX_ *e, to) > 0
                && otel_schema_vcmp(aTHX_ *e, from) <= 0)
                av_push(out, newSVsv(*e));
        }
    }
    return out;
}

/* ---- applying one step --------------------------------------------------- */

/* Rename the keys of one attribute hash, in place, for one version step.
 * Collected first and applied after, because renaming while iterating a hash
 * is undefined and a rename can land on a key not yet visited. */
static void otel_schema_apply_map(pTHX_ SV *attrs_sv, HV *map, int forward) {
    HV *attrs = otel_hv_of(aTHX_ attrs_sv);
    HV *renamed;
    HE *he;
    if (!attrs || !HvUSEDKEYS(attrs)) return;
    renamed = (HV *)sv_2mortal((SV *)newHV());

    hv_iterinit(attrs);
    while ((he = hv_iternext(attrs))) {
        STRLEN kl;
        const char *k = HePV(he, kl);
        SV *to = NULL;
        if (forward) {
            SV **t = hv_fetch(map, k, (I32)kl, 0);
            if (t && *t && SvOK(*t)) to = *t;
        }
        else {
            /* backward: the map is old -> new, so invert it */
            HE *m;
            hv_iterinit(map);
            while ((m = hv_iternext(map))) {
                STRLEN ml;
                const char *mk = HePV(m, ml);
                SV *mv = HeVAL(m);
                STRLEN vl;
                const char *vp;
                if (ml >= OTEL_METRIC_MARK_LEN
                    && memEQ(mk, OTEL_METRIC_MARK, OTEL_METRIC_MARK_LEN))
                    continue;                  /* a metric rename, not ours */
                if (!(mv && SvOK(mv))) continue;
                vp = SvPV_const(mv, vl);
                if (vl == kl && memEQ(vp, k, kl)) {
                    to = sv_2mortal(newSVpvn(mk, ml));
                    break;
                }
            }
        }
        if (!to || !SvOK(to)) continue;
        {
            STRLEN tl;
            const char *tp = SvPV_const(to, tl);
            if (tl == kl && memEQ(tp, k, kl)) continue;   /* renamed to itself */
            (void)hv_store(renamed, k, (I32)kl, newSVsv(to), 0);
        }
    }

    hv_iterinit(renamed);
    while ((he = hv_iternext(renamed))) {
        STRLEN kl, nl;
        const char *k = HePV(he, kl);
        const char *n = SvPV_const(HeVAL(he), nl);
        SV *val = hv_delete(attrs, k, (I32)kl, 0);        /* mortal */
        if (val) (void)hv_store(attrs, n, (I32)nl, newSVsv(val), 0);
    }
}

/* The new name for a metric, or the name unchanged. */
static SV *otel_schema_metric_name(pTHX_ HV *map, SV *name, int forward) {
    STRLEN nl;
    const char *np;
    if (!name || !SvOK(name)) return NULL;
    np = SvPV_const(name, nl);
    if (forward) {
        SV *key = sv_2mortal(newSVpvn(OTEL_METRIC_MARK, OTEL_METRIC_MARK_LEN));
        HE *he;
        sv_catpvn(key, np, nl);
        he = hv_fetch_ent(map, key, 0, 0);
        return (he && HeVAL(he) && SvOK(HeVAL(he))) ? HeVAL(he) : NULL;
    }
    {
        HE *he;
        hv_iterinit(map);
        while ((he = hv_iternext(map))) {
            STRLEN kl, vl;
            const char *k = HePV(he, kl);
            SV *v = HeVAL(he);
            const char *vp;
            if (kl <= OTEL_METRIC_MARK_LEN
                || !memEQ(k, OTEL_METRIC_MARK, OTEL_METRIC_MARK_LEN)) continue;
            if (!(v && SvOK(v))) continue;
            vp = SvPV_const(v, vl);
            if (vl == nl && memEQ(vp, np, nl))
                return sv_2mortal(newSVpvn(k + OTEL_METRIC_MARK_LEN,
                                           kl - OTEL_METRIC_MARK_LEN));
        }
    }
    return NULL;
}

/* ---- walking a payload --------------------------------------------------- *
 *
 * Every attribute hash in a payload: the resource, each scope, and each span /
 * data point / log record, plus span events and links. */
static void otel_schema_each_attrs(pTHX_ HV *payload, const char *signal,
                                   STRLEN siglen, HV *map, int forward) {
    const char *rkey, *skey, *ikey;
    AV *rs;
    SSize_t ri, rn;
    int is_metrics = (siglen == 7 && memEQ(signal, "metrics", 7));
    int is_logs    = (siglen == 4 && memEQ(signal, "logs", 4));

    rkey = is_metrics ? "resource_metrics" : is_logs ? "resource_logs"
                                                     : "resource_spans";
    skey = is_metrics ? "scope_metrics"    : is_logs ? "scope_logs"
                                                     : "scope_spans";
    ikey = is_metrics ? "metrics"          : is_logs ? "log_records"
                                                     : "spans";

    rs = otel_h_av(aTHX_ payload, rkey);
    if (!rs) return;
    rn = av_len(rs) + 1;
    for (ri = 0; ri < rn; ri++) {
        SV **rp = av_fetch(rs, ri, 0);
        HV *r = (rp && *rp) ? otel_hv_of(aTHX_ *rp) : NULL;
        HV *res;
        AV *ss;
        SSize_t si, sn;
        if (!r) continue;
        res = otel_h_hv(aTHX_ r, "resource");
        if (res) {
            SV **a = hv_fetchs(res, "attributes", 0);
            if (a && *a) otel_schema_apply_map(aTHX_ *a, map, forward);
        }
        ss = otel_h_av(aTHX_ r, skey);
        if (!ss) continue;
        sn = av_len(ss) + 1;
        for (si = 0; si < sn; si++) {
            SV **sp = av_fetch(ss, si, 0);
            HV *s = (sp && *sp) ? otel_hv_of(aTHX_ *sp) : NULL;
            HV *scope;
            AV *items;
            SSize_t ii, in;
            if (!s) continue;
            scope = otel_h_hv(aTHX_ s, "scope");
            if (scope) {
                SV **a = hv_fetchs(scope, "attributes", 0);
                if (a && *a) otel_schema_apply_map(aTHX_ *a, map, forward);
            }
            items = otel_h_av(aTHX_ s, ikey);
            if (!items) continue;
            in = av_len(items) + 1;
            for (ii = 0; ii < in; ii++) {
                SV **ip = av_fetch(items, ii, 0);
                HV *item = (ip && *ip) ? otel_hv_of(aTHX_ *ip) : NULL;
                static const char *nested[3] = { "events", "links",
                                                 "data_points" };
                int ni;
                SV **a;
                if (!item) continue;
                a = hv_fetchs(item, "attributes", 0);
                if (a && *a) otel_schema_apply_map(aTHX_ *a, map, forward);
                for (ni = 0; ni < 3; ni++) {
                    AV *sub = otel_h_av(aTHX_ item, nested[ni]);
                    SSize_t bi, bn;
                    if (!sub) continue;
                    bn = av_len(sub) + 1;
                    for (bi = 0; bi < bn; bi++) {
                        SV **bp = av_fetch(sub, bi, 0);
                        HV *b = (bp && *bp) ? otel_hv_of(aTHX_ *bp) : NULL;
                        SV **ba;
                        if (!b) continue;
                        ba = hv_fetchs(b, "attributes", 0);
                        if (ba && *ba)
                            otel_schema_apply_map(aTHX_ *ba, map, forward);
                    }
                }
            }
        }
    }
}

/* Every metric in a payload, for the name rename. */
static void otel_schema_each_metric(pTHX_ HV *payload, HV *map, int forward) {
    AV *rs = otel_h_av(aTHX_ payload, "resource_metrics");
    SSize_t ri, rn;
    if (!rs) return;
    rn = av_len(rs) + 1;
    for (ri = 0; ri < rn; ri++) {
        SV **rp = av_fetch(rs, ri, 0);
        HV *r = (rp && *rp) ? otel_hv_of(aTHX_ *rp) : NULL;
        AV *ss;
        SSize_t si, sn;
        if (!r) continue;
        ss = otel_h_av(aTHX_ r, "scope_metrics");
        if (!ss) continue;
        sn = av_len(ss) + 1;
        for (si = 0; si < sn; si++) {
            SV **sp = av_fetch(ss, si, 0);
            HV *s = (sp && *sp) ? otel_hv_of(aTHX_ *sp) : NULL;
            AV *ms;
            SSize_t mi, mn;
            if (!s) continue;
            ms = otel_h_av(aTHX_ s, "metrics");
            if (!ms) continue;
            mn = av_len(ms) + 1;
            for (mi = 0; mi < mn; mi++) {
                SV **mp = av_fetch(ms, mi, 0);
                HV *m = (mp && *mp) ? otel_hv_of(aTHX_ *mp) : NULL;
                SV *name, *to;
                if (!m) continue;
                name = otel_h(aTHX_ m, "name");
                to = otel_schema_metric_name(aTHX_ map, name, forward);
                if (to) (void)hv_stores(m, "name", newSVsv(to));
            }
        }
    }
}

/* ---- the search path, and the file on it --------------------------------- *
 *
 * Shared by file_for, for_url and load, so all three answer the same question
 * the same way: a caller's dir, then OTEL_SCHEMA_DIR, then the directory this
 * module was loaded from. Mortal AV. */
static AV *otel_schema_dirs(pTHX_ SV **args, int nargs) {
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    int a;
    for (a = 0; a + 1 < nargs; a += 2) {
        STRLEN kl;
        const char *k = SvPV_const(args[a], kl);
        if (kl == 3 && memEQ(k, "dir", 3) && SvOK(args[a + 1]))
            av_push(out, newSVsv(args[a + 1]));
    }
    {
        SV **e = hv_fetchs(GvHV(PL_envgv), "OTEL_SCHEMA_DIR", 0);
        if (e && *e && SvOK(*e) && SvCUR(*e)) av_push(out, newSVsv(*e));
    }
    {   /* through %INC rather than guessed, so it is right under blib, under
         * a local::lib, and installed */
        HV *inc = GvHV(PL_incgv);
        SV **e = inc ? hv_fetchs(inc, "Punk/OpenTelemetry/Schema.pm", 0) : NULL;
        if (e && *e && SvOK(*e)) {
            STRLEN l;
            const char *p = SvPV_const(*e, l);
            if (l > 3 && memEQ(p + l - 3, ".pm", 3))
                av_push(out, newSVpvn(p, l - 3));
        }
    }
    return out;
}

/* The file for a version on that path, or NULL. Mortal SV. */
static SV *otel_schema_file_for(pTHX_ SV *version, SV **args, int nargs) {
    AV *dirs;
    SSize_t i, n;
    STRLEN vl, j;
    const char *vp;
    if (!version || !SvOK(version)) return NULL;
    vp = SvPV_const(version, vl);
    if (!vl || !isDIGIT(vp[0])) return NULL;
    for (j = 0; j < vl; j++)
        if (!isDIGIT(vp[j]) && vp[j] != '.') return NULL;
    dirs = otel_schema_dirs(aTHX_ args, nargs);
    n = av_len(dirs) + 1;
    for (i = 0; i < n; i++) {
        SV **d = av_fetch(dirs, i, 0);
        SV *path;
        Stat_t st;
        if (!(d && *d && SvOK(*d))) continue;
        path = sv_2mortal(newSVsv(*d));
        sv_catpvs(path, "/");
        sv_catsv(path, version);
        sv_catpvs(path, ".yaml");
        if (PerlLIO_stat(SvPV_nolen(path), &st) == 0 && S_ISREG(st.st_mode))
            return path;
    }
    return NULL;
}

#endif /* OTEL_SCHEMA_H */
