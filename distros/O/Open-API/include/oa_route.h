#ifndef OA_ROUTE_H
#define OA_ROUTE_H

/* The router: match (method, path) against the compiled operation table.
 * Per-method linear scan over pre-split templates with literal-segment
 * rejects - specs are tens of routes; a trie is a later optimization behind
 * the same functions. Distinguishes the two miss cases so callers can send
 * 404 (no path) vs 405 + Allow (path exists, method does not). */

#define OA_MAXSEGS 64

typedef struct oa_pseg { const char *p; STRLEN l; } oa_pseg;

static int oa_split_path(const char *path, STRLEN pl, oa_pseg *out, int max) {
    int n = 0;
    STRLEN s = 0;
    while (s < pl) {
        STRLEN e;
        while (s < pl && path[s] == '/') s++;
        if (s >= pl) break;
        e = s;
        while (e < pl && path[e] != '/') e++;
        if (n == max) return -1;
        out[n].p = path + s;
        out[n].l = e - s;
        n++;
        s = e;
    }
    return n;
}

/* does this op's template fit these path segments? (method not considered) */
static int oa_segs_fit(pTHX_ oa_op *o, oa_pseg *segs, int nsegs) {
    int i;
    if (o->nsegs != nsegs) return 0;
    for (i = 0; i < nsegs; i++) {
        if (o->segs[i].lit) {
            STRLEN ll; const char *lp = SvPV_const(o->segs[i].lit, ll);
            if (ll != segs[i].l || memNE(lp, segs[i].p, ll)) return 0;
        }
    }
    return 1;
}

/* Match. On success returns the op and fills `captures` (raw, undecoded
 * segment bytes keyed by template parameter name). On failure returns NULL;
 * when `allow` is given it is filled with the uppercased methods that DO
 * match the path - empty means 404, non-empty means 405. */
static oa_op *oa_route(pTHX_ oa_api *a, const char *method, STRLEN ml,
                       const char *path, STRLEN pl,
                       HV *captures, AV *allow) {
    oa_ops *t = (oa_ops *)a->ops;
    oa_pseg segs[OA_MAXSEGS];
    char m[16];
    int nsegs, i;
    STRLEN k;

    if (!t) return NULL;
    if (ml >= sizeof m) return NULL;
    for (k = 0; k < ml; k++) m[k] = (char)toLOWER((U8)method[k]);

    nsegs = oa_split_path(path, pl, segs, OA_MAXSEGS);
    if (nsegs < 0) return NULL;

    for (i = 0; i < t->n; i++) {
        oa_op *o = &t->ops[i];
        STRLEN oml; const char *omp = SvPV_const(o->method, oml);
        if (oml != ml || memNE(omp, m, ml)) continue;
        if (!oa_segs_fit(aTHX_ o, segs, nsegs)) continue;
        if (captures) {
            int s;
            for (s = 0; s < o->nsegs; s++) {
                if (o->segs[s].pname) {
                    STRLEN nl; const char *np = SvPV_const(o->segs[s].pname, nl);
                    (void)hv_store(captures, np, (I32)nl,
                                   newSVpvn(segs[s].p, segs[s].l), 0);
                }
            }
        }
        return o;
    }

    if (allow) {           /* any other method on this path? -> 405 material */
        for (i = 0; i < t->n; i++) {
            oa_op *o = &t->ops[i];
            if (oa_segs_fit(aTHX_ o, segs, nsegs)) {
                STRLEN oml; const char *omp = SvPV_const(o->method, oml);
                SV *up = newSVpvn(omp, oml);
                STRLEN j; char *pv = SvPVX(up);
                for (j = 0; j < oml; j++) pv[j] = (char)toUPPER((U8)pv[j]);
                av_push(allow, up);
            }
        }
    }
    return NULL;
}

#endif /* OA_ROUTE_H */
