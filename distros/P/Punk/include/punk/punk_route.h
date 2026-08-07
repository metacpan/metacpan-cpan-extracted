/* punk_route.h - the C web router (phase 5 tier 2, completed in phase 6).
 *
 * Compiled once at to_app from the frozen Perl route table. The whole match
 * path now lives here: an exact-match table for static routes, typed-segment
 * records for dynamic ones (:param / *splat, held in one malloc'd arena and
 * walked with memcmp - no regex engine), and the 405 Allow computation on a
 * miss. lib/Punk/Router.pm is the pure-Perl reference tier (PUNK_PURE_PERL);
 * t/17 proves the two agree on every case.
 *
 * Every record carries `idx`, its position in the one Perl array of compiled
 * records (code + guards) the dispatcher indexes into; a static hit, a
 * dynamic hit and the reference tier all speak that same index.
 *
 * Semantics mirror the Perl exactly: :param captures one non-empty segment,
 * *splat captures the non-empty remainder including slashes, HEAD matches GET,
 * ANY matches every method, and Allow lists the methods a path answers under.
 */

#ifndef PUNK_ROUTE_H
#define PUNK_ROUTE_H

#define PR_LIT   0
#define PR_PARAM 1
#define PR_SPLAT 2

#define PR_MAX_SEGS 64

typedef struct {
    int    type;
    char  *lit;      /* PR_LIT: the bytes to match */
    STRLEN litlen;
    SV    *name;     /* PR_PARAM / PR_SPLAT: capture name (owned) */
} pr_seg;

typedef struct {
    char  *method;   /* uppercase (kept even for ANY, for Allow) */
    STRLEN mlen;
    int    is_any;   /* matches every method */
    int    is_get;   /* HEAD falls back onto these */
    int    nsegs;
    int    splat;    /* last segment is a splat */
    pr_seg *segs;
    IV     idx;      /* position in the Perl @recs array */
} pr_rec;

typedef struct {
    AV     *raw;          /* accumulation: { method, path, target, guards }
                           * hashrefs pushed by add(), unresolved */
    int     compiled;
    int     n;
    pr_rec *recs;         /* dynamic records */
    HV     *statics;      /* "METHOD path" -> IV record index */
    HV     *static_paths; /* path -> AV of uppercase method SVs (for Allow) */
    AV     *records;      /* per-route { code, guards, method, path } hashrefs,
                           * indexed by the record index match returns */
} pr_router;

static pr_router *pr_new(pTHX) {
    pr_router *rt;
    Newxz(rt, 1, pr_router);
    rt->raw = newAV();
    return rt;
}

/* the methods an ANY route answers */
static const char *const PR_ANY_METHODS[] =
    { "GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS" };
#define PR_N_ANY 7

/* Split a path on '/' (skipping the leading one) into borrowed segment
 * pointers/lengths. Returns the count, or -1 if it does not start with '/'
 * or overflows PR_MAX_SEGS. */
static int pr_split(const char *path, STRLEN plen,
                    const char **seg_p, STRLEN *seg_l) {
    int nsegs = 0;
    STRLEN j;
    const char *start;
    if (!plen || path[0] != '/') return -1;
    start = path + 1;
    for (j = 1; j <= plen; j++) {
        if (j == plen || path[j] == '/') {
            if (nsegs == PR_MAX_SEGS) return -1;
            seg_p[nsegs] = start;
            seg_l[nsegs] = (STRLEN)((path + j) - start);
            nsegs++;
            start = path + j + 1;
        }
    }
    return nsegs;
}

/* Do a record's segments match these request segments? Method-agnostic, no
 * captures - the shared core of hit matching and the Allow scan. */
static int pr_segs_match(pr_rec *r, const char *path, STRLEN plen,
                         const char **seg_p, STRLEN *seg_l, int nsegs) {
    int k;
    if (r->splat ? (nsegs < r->nsegs) : (nsegs != r->nsegs)) return 0;
    for (k = 0; k < r->nsegs; k++) {
        pr_seg *s = &r->segs[k];
        if (s->type == PR_LIT) {
            if (seg_l[k] != s->litlen
                || (s->litlen && memNE(seg_p[k], s->lit, s->litlen)))
                return 0;
        }
        else if (s->type == PR_PARAM) {
            if (!seg_l[k]) return 0;                  /* [^/]+ needs one char */
        }
        else {   /* PR_SPLAT (always last): non-empty remainder */
            return ((STRLEN)((path + plen) - seg_p[k])) ? 1 : 0;
        }
    }
    return 1;
}

static int pr_method_ok(pr_rec *r, const char *method, STRLEN mlen, int is_head) {
    if (r->is_any) return 1;
    if (mlen == r->mlen && memEQ(method, r->method, mlen)) return 1;
    if (is_head && r->is_get) return 1;
    return 0;
}

/* Parse one route path into a record's typed segments. */
static void pr_parse_path(pTHX_ pr_rec *r, const char *p, STRLEN pl) {
    const char *seg_start;
    STRLEN j;
    int ns = 0, k;
    for (j = 1; j <= pl; j++)
        if (j == pl || p[j] == '/') ns++;
    if (ns > PR_MAX_SEGS)
        croak("punk router: '%.*s' has more than %d segments",
              (int)pl, p, PR_MAX_SEGS);
    r->nsegs = ns;
    Newxz(r->segs, ns ? ns : 1, pr_seg);
    seg_start = p + 1;
    for (k = 0, j = 1; j <= pl; j++) {
        if (j == pl || p[j] == '/') {
            STRLEN slen = (STRLEN)((p + j) - seg_start);
            pr_seg *s = &r->segs[k];
            if (slen > 1 && seg_start[0] == ':') {
                s->type = PR_PARAM;
                s->name = newSVpvn(seg_start + 1, slen - 1);
            }
            else if (slen > 1 && seg_start[0] == '*') {
                s->type = PR_SPLAT;
                s->name = newSVpvn(seg_start + 1, slen - 1);
                if (k != ns - 1)
                    croak("punk router: *splat must be the last segment "
                          "in '%.*s'", (int)pl, p);
                r->splat = 1;
            }
            else {
                s->type   = PR_LIT;
                s->lit    = savepvn(seg_start, slen);
                s->litlen = slen;
            }
            k++;
            seg_start = p + j + 1;
        }
    }
}

/* Insert one static "METHOD path" -> idx into the exact table and the
 * per-path Allow list, croaking on a duplicate. */
static void pr_add_static(pTHX_ pr_router *rt, HV *seen,
                          const char *m, STRLEN ml,
                          const char *p, STRLEN pl, IV idx) {
    STRLEN kl = ml + 1 + pl;
    SV *key = sv_2mortal(newSV(kl + 1));
    char *kbuf;
    SV **slot;
    SvPOK_on(key);
    kbuf = SvPVX(key);
    memcpy(kbuf, m, ml); kbuf[ml] = ' ';
    memcpy(kbuf + ml + 1, p, pl); kbuf[kl] = '\0';
    SvCUR_set(key, kl);
    if (hv_exists_ent(seen, key, 0))
        croak("Punk::Router: duplicate route %.*s %.*s",
              (int)ml, m, (int)pl, p);
    (void)hv_store_ent(seen, key, &PL_sv_yes, 0);
    (void)hv_store_ent(rt->statics, key, newSViv(idx), 0);
    slot = hv_fetch(rt->static_paths, p, (I32)pl, 1);
    if (!(*slot && SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVAV))
        sv_setsv(*slot, sv_2mortal(newRV_noinc((SV *)newAV())));
    av_push((AV *)SvRV(*slot), newSVpvn(m, ml));
}

/* Compile the whole route table in C from one AV of resolved routes -
 * each [ METHOD, path, code, guards ]. Classifies static vs dynamic (a ':'
 * or '*' anywhere makes it dynamic), expands ANY static routes per method,
 * rejects duplicates and a misplaced *splat, parses dynamic paths into typed
 * segments, and builds the exact table, the per-path Allow lists, the
 * dynamic records and the per-route { code, guards, method, path } record
 * hashrefs the dispatcher indexes into. The only work left in Perl is
 * resolving the targets to those coderefs. */
/* Call the app's Perl $resolve->($target, $desc) to turn a route target or
 * guard into a coderef. Returns the resolved SV (+1). A bad target croaks
 * inside $resolve, unwinding to_app - the boot-time contract. */
static SV *pr_resolve(pTHX_ SV *resolve, SV *target, SV *desc) {
    dSP;
    SV *ret;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(target);
    PUSHs(desc);
    PUTBACK;
    count = call_sv(resolve, G_SCALAR);
    SPAGAIN;
    ret = count > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
    PUTBACK;
    FREETMPS; LEAVE;
    return ret;
}

/* One { method, path, target, guards } record -> a resolved
 * [ method, path, code, \@guards ] route pushed onto `routes`. */
static void pr_add_route(pTHX_ AV *routes, SV *resolve, HV *rec) {
    SV **m = hv_fetchs(rec, "method", 0);
    SV **p = hv_fetchs(rec, "path", 0);
    SV **t = hv_fetchs(rec, "target", 0);
    SV **g = hv_fetchs(rec, "guards", 0);
    SV *mv = (m && *m) ? *m : &PL_sv_undef;
    SV *pv = (p && *p) ? *p : &PL_sv_undef;
    AV *route = newAV();
    AV *gav   = newAV();
    SV *desc  = sv_2mortal(newSVpvf("route %s %s",
                    SvPV_nolen(mv), SvPV_nolen(pv)));
    av_push(route, newSVsv(mv));
    av_push(route, newSVsv(pv));
    av_push(route, pr_resolve(aTHX_ resolve, (t && *t) ? *t : &PL_sv_undef, desc));
    if (g && *g && SvROK(*g) && SvTYPE(SvRV(*g)) == SVt_PVAV) {
        AV *gs = (AV *)SvRV(*g);
        SSize_t i, n = av_len(gs) + 1;
        SV *gdesc = sv_2mortal(newSVpvf("guard on %s", SvPV_nolen(pv)));
        for (i = 0; i < n; i++) {
            SV **gp = av_fetch(gs, i, 0);
            av_push(gav, pr_resolve(aTHX_ resolve,
                        (gp && *gp) ? *gp : &PL_sv_undef, gdesc));
        }
    }
    av_push(route, newRV_noinc((SV *)gav));
    av_push(routes, newRV_noinc((SV *)route));
}

static void pr_build(pTHX_ pr_router *rt, AV *routes) {
    int n = (int)(av_len(routes) + 1), i, dn = 0, di = 0;
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    rt->statics      = newHV();
    rt->static_paths = newHV();
    rt->records      = newAV();
    if (n > 0) av_extend(rt->records, n - 1);

    for (i = 0; i < n; i++) {   /* count dynamics for the record array */
        SV **e = av_fetch(routes, i, 0);
        AV *t; SV **psv; STRLEN pl; const char *p;
        if (!e || !*e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVAV)
            croak("Punk::Router::_compile: route %d is not an arrayref", i);
        t = (AV *)SvRV(*e);
        psv = av_fetch(t, 1, 0);
        p = SvPV_const(*psv, pl);
        if (memchr(p, ':', pl) || memchr(p, '*', pl)) dn++;
    }
    Newxz(rt->recs, dn ? dn : 1, pr_rec);

    for (i = 0; i < n; i++) {
        SV **e = av_fetch(routes, i, 0);
        AV *t = (AV *)SvRV(*e);
        SV **msv = av_fetch(t, 0, 0), **psv = av_fetch(t, 1, 0);
        SV **csv = av_fetch(t, 2, 0), **gsv = av_fetch(t, 3, 0);
        STRLEN ml, pl;
        const char *m = SvPV_const(*msv, ml);
        const char *p = SvPV_const(*psv, pl);
        int is_any = (ml == 3 && memEQ(m, "ANY", 3));
        HV *rec = newHV();

        (void)hv_stores(rec, "code",   csv && *csv ? SvREFCNT_inc(*csv) : newSV(0));
        (void)hv_stores(rec, "guards", gsv && *gsv ? SvREFCNT_inc(*gsv) : newRV_noinc((SV *)newAV()));
        (void)hv_stores(rec, "method", newSVpvn(m, ml));
        (void)hv_stores(rec, "path",   newSVpvn(p, pl));
        (void)av_store(rt->records, i, newRV_noinc((SV *)rec));

        if (!memchr(p, ':', pl) && !memchr(p, '*', pl)) {   /* static */
            if (is_any) {
                int k;
                for (k = 0; k < PR_N_ANY; k++)
                    pr_add_static(aTHX_ rt, seen, PR_ANY_METHODS[k],
                                  strlen(PR_ANY_METHODS[k]), p, pl, (IV)i);
            }
            else pr_add_static(aTHX_ rt, seen, m, ml, p, pl, (IV)i);
        }
        else {                                              /* dynamic */
            pr_rec *r = &rt->recs[di++];
            r->method = savepvn(m, ml);
            r->mlen   = ml;
            r->is_any = is_any;
            r->is_get = (ml == 3 && memEQ(m, "GET", 3));
            r->idx    = (IV)i;
            pr_parse_path(aTHX_ r, p, pl);   /* croaks on a misplaced *splat */
        }
    }
    rt->n = di;
    rt->compiled = 1;
}

static void pr_free(pTHX_ pr_router *rt) {
    int i, k;
    if (!rt) return;
    if (rt->raw) SvREFCNT_dec((SV *)rt->raw);
    for (i = 0; i < rt->n; i++) {
        pr_rec *r = &rt->recs[i];
        for (k = 0; k < r->nsegs; k++) {
            if (r->segs[k].lit)  Safefree(r->segs[k].lit);
            if (r->segs[k].name) SvREFCNT_dec(r->segs[k].name);
        }
        Safefree(r->segs);
        if (r->method) Safefree(r->method);
    }
    Safefree(rt->recs);
    if (rt->statics)      SvREFCNT_dec((SV *)rt->statics);
    if (rt->static_paths) SvREFCNT_dec((SV *)rt->static_paths);
    if (rt->records)      SvREFCNT_dec((SV *)rt->records);
    Safefree(rt);
}

/* Static exact match: the record index, or -1. HEAD falls back to GET. */
static IV pr_static_match(pTHX_ pr_router *rt,
                          const char *method, STRLEN mlen,
                          const char *path, STRLEN plen) {
    char buf[256], *kbuf;
    STRLEN kl = mlen + 1 + plen;
    SV **e;
    IV idx = -1;
    kbuf = kl + 1 <= sizeof buf ? buf : (char *)safemalloc(kl + 1);
    memcpy(kbuf, method, mlen); kbuf[mlen] = ' ';
    memcpy(kbuf + mlen + 1, path, plen);
    e = hv_fetch(rt->statics, kbuf, (I32)kl, 0);
    if (!e && mlen == 4 && memEQ(method, "HEAD", 4)) {
        memcpy(kbuf, "GET", 3); kbuf[3] = ' ';
        memcpy(kbuf + 4, path, plen);
        e = hv_fetch(rt->statics, kbuf, (I32)(4 + plen), 0);
    }
    if (e && *e) idx = SvIV(*e);
    if (kbuf != buf) safefree(kbuf);
    return idx;
}

/* Dynamic hit: the record index (its @recs idx) and fills caps, or -1. */
static IV pr_match(pTHX_ pr_router *rt,
                   const char *method, STRLEN mlen,
                   const char *path, STRLEN plen, HV *caps) {
    const char *seg_p[PR_MAX_SEGS];
    STRLEN      seg_l[PR_MAX_SEGS];
    int nsegs = pr_split(path, plen, seg_p, seg_l);
    int is_head = (mlen == 4 && memEQ(method, "HEAD", 4));
    int i, c;
    if (nsegs < 0) return -1;
    for (i = 0; i < rt->n; i++) {
        pr_rec *r = &rt->recs[i];
        if (!pr_method_ok(r, method, mlen, is_head)) continue;
        if (!pr_segs_match(r, path, plen, seg_p, seg_l, nsegs)) continue;
        for (c = 0; c < r->nsegs; c++) {
            pr_seg *s = &r->segs[c];
            if (s->type == PR_PARAM)
                (void)hv_store_ent(caps, s->name,
                                   newSVpvn(seg_p[c], seg_l[c]), 0);
            else if (s->type == PR_SPLAT)
                (void)hv_store_ent(caps, s->name,
                    newSVpvn(seg_p[c], (STRLEN)((path + plen) - seg_p[c])), 0);
        }
        return r->idx;
    }
    return -1;
}

/* The 405 Allow set for a path the request method missed: every method the
 * path answers under (static exact + dynamic, method-agnostic), minus the
 * request method. Pushes sorted method SVs into `allow`; returns the count. */
static int pr_allow(pTHX_ pr_router *rt,
                    const char *method, STRLEN mlen,
                    const char *path, STRLEN plen, AV *allow) {
    const char *seg_p[PR_MAX_SEGS];
    STRLEN      seg_l[PR_MAX_SEGS];
    int nsegs = pr_split(path, plen, seg_p, seg_l);
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    SV **sp;
    int i;

    sp = hv_fetch(rt->static_paths, path, (I32)plen, 0);
    if (sp && *sp && SvROK(*sp) && SvTYPE(SvRV(*sp)) == SVt_PVAV) {
        AV *ms = (AV *)SvRV(*sp);
        SSize_t j, n = av_len(ms) + 1;
        for (j = 0; j < n; j++) {
            SV **mv = av_fetch(ms, j, 0);
            if (mv && *mv) (void)hv_store_ent(seen, *mv, &PL_sv_yes, 0);
        }
    }
    if (nsegs >= 0) {
        for (i = 0; i < rt->n; i++) {
            pr_rec *r = &rt->recs[i];
            if (!pr_segs_match(r, path, plen, seg_p, seg_l, nsegs)) continue;
            (void)hv_store(seen, r->method, (I32)r->mlen, &PL_sv_yes, 0);
        }
    }
    /* the request method is not "other" */
    (void)hv_delete(seen, method, (I32)mlen, 0);

    {
        SSize_t na = 0;
        HE *he;
        hv_iterinit(seen);
        while ((he = hv_iternext(seen))) { av_push(allow, newSVsv(hv_iterkeysv(he))); na++; }
        /* sort the Allow list, matching the Perl `sort keys %allow` */
        if (na > 1) sortsv(AvARRAY(allow), (STRLEN)na, Perl_sv_cmp);
        return (int)na;
    }
}

#endif /* PUNK_ROUTE_H */
