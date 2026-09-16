/* pb_engine.c - the ball engine, a transliteration of the prototype's physics.js.
 *
 * Every expression here is written in the same order as the JavaScript it came
 * from (plan_pool_snooker/prototype/physics.js), because the fixtures recorded
 * from that file are the specification and t/03-bitwise.t asks for the same
 * doubles. Only + - * / and sqrt appear; no hypot, pow or trigonometry. C89:
 * declarations at the top of a block, no //, no variable-length arrays.
 *
 * The JavaScript's function names are kept so the two files can be read side
 * by side: lineRoot, quarticRoot, pairRoot, begin, evalAt, bounce, cluster.
 */

#include <stdlib.h>
#include <math.h>
#include "pb_abi.h"

#define STATIONARY 0
#define SLIDING    1
#define ROLLING    2
#define POCKETED   3

#define K_MODE 0
#define K_BALL 1
#define K_WALL 2
#define K_NOSE 3
#define K_GATE 4

static const double TOUCH    = 1e-5;
static const double TOUCH_S  = 1e-7;
static const double ZENO     = 0.01;
static const double ZENO_BB  = 1e-3;
static const double APPROACH = 1e-6;
static const double EPS_V    = 1e-6;
#define ITER 60
#define CLUSTER_ITER 200

struct pb_world {
    double L, W, R, g, mus, mur, musp, ebb, ec, ecf, erc, vmax;
    int nw; double *walls;   /* x1, y1, ux, uy, len, nx, ny */
    int nn; double *noses;   /* x, y */
    int ng; double *gates;   /* x1, y1, ux, uy, len, nx, ny, pocket */
};

struct pb_world *pb_world_new(const struct pb_desc *w) {
    struct pb_world *W;
    int i;
    double dx, dy, len;
    const double *s;
    W = (struct pb_world *) malloc(sizeof *W);
    if (!W) return NULL;
    W->L = w->L; W->W = w->W; W->R = w->R; W->g = w->g;
    W->mus = w->mu_s; W->mur = w->mu_r; W->musp = w->mu_sp;
    W->ebb = w->e_bb; W->ec = w->e_c; W->ecf = w->e_cf; W->erc = w->e_rc;
    W->vmax = w->vmax;
    W->nw = w->nwalls; W->nn = w->nnoses; W->ng = w->ngates;
    W->walls = (double *) malloc(sizeof(double) * (W->nw ? W->nw * 7 : 1));
    W->noses = (double *) malloc(sizeof(double) * (W->nn ? W->nn * 2 : 1));
    W->gates = (double *) malloc(sizeof(double) * (W->ng ? W->ng * 8 : 1));
    if (!W->walls || !W->noses || !W->gates) { pb_world_free(W); return NULL; }
    for (i = 0; i < W->nw; i++) {
        s = w->walls + i * 4;
        dx = s[2] - s[0]; dy = s[3] - s[1];
        len = sqrt(dx * dx + dy * dy);
        W->walls[i * 7] = s[0];
        W->walls[i * 7 + 1] = s[1];
        W->walls[i * 7 + 2] = dx / len;
        W->walls[i * 7 + 3] = dy / len;
        W->walls[i * 7 + 4] = len;
        W->walls[i * 7 + 5] = -dy / len;
        W->walls[i * 7 + 6] = dx / len;
    }
    for (i = 0; i < W->nn; i++) {
        W->noses[i * 2] = w->noses[i * 2];
        W->noses[i * 2 + 1] = w->noses[i * 2 + 1];
    }
    for (i = 0; i < W->ng; i++) {
        s = w->gates + i * 7;
        dx = s[2] - s[0]; dy = s[3] - s[1];
        len = sqrt(dx * dx + dy * dy);
        W->gates[i * 8] = s[0];
        W->gates[i * 8 + 1] = s[1];
        W->gates[i * 8 + 2] = dx / len;
        W->gates[i * 8 + 3] = dy / len;
        W->gates[i * 8 + 4] = len;
        W->gates[i * 8 + 5] = s[4];
        W->gates[i * 8 + 6] = s[5];
        W->gates[i * 8 + 7] = s[6];
    }
    return W;
}

void pb_world_free(struct pb_world *W) {
    if (!W) return;
    free(W->walls); free(W->noses); free(W->gates);
    free(W);
}

/* ---- the root finders, as physics.js has them ---------------------------------- */

static double lineRoot(double s0, double sv, double sa, double T) {
    double A, B, C, disc, sq, q, t1, t2, lo, hi;
    if (s0 <= TOUCH_S) { return sv < -APPROACH ? 0 : -1; }
    A = 0.5 * sa; B = sv; C = s0;
    if (A > -1e-15 && A < 1e-15) {
        if (B >= 0) { return -1; }
        t1 = -C / B;
        return t1 <= T ? t1 : -1;
    }
    disc = B * B - 4 * A * C;
    if (disc < 0) { return -1; }
    sq = sqrt(disc);
    q = -0.5 * (B + (B >= 0 ? sq : -sq));
    t1 = q / A;
    t2 = q != 0 ? C / q : t1;
    if (t1 <= t2) { lo = t1; hi = t2; } else { lo = t2; hi = t1; }
    if (lo >= 0 && lo <= T && B + 2 * A * lo < 0) { return lo; }
    if (hi >= 0 && hi <= T && B + 2 * A * hi < 0) { return hi; }
    return -1;
}

static double poly4(double c4, double c3, double c2, double c1, double c0, double t) {
    return (((c4 * t + c3) * t + c2) * t + c1) * t + c0;
}
static double dpoly4(double c4, double c3, double c2, double c1, double t) {
    return ((4 * c4 * t + 3 * c3) * t + 2 * c2) * t + c1;
}

static double quarticRoot(double c4, double c3, double c2, double c1, double c0, double T) {
    double A, B, C, disc, sq, q, r1, r2, tmp;
    double b0 = 0, b1 = -1, b2 = -1, b3 = T;
    double bounds[4]; int nb = 0;
    double pb[6]; int np = 0;
    int k, i;
    double a, b, fa, fb, lo, hi, m;
    if (c0 <= TOUCH) { return c1 < 0 ? 0 : -1; }
    A = 12 * c4; B = 6 * c3; C = 2 * c2;
    if (A > 1e-18 || A < -1e-18) {
        disc = B * B - 4 * A * C;
        if (disc >= 0) {
            sq = sqrt(disc);
            q = -0.5 * (B + (B >= 0 ? sq : -sq));
            r1 = q / A;
            r2 = q != 0 ? C / q : r1;
            if (r1 > r2) { tmp = r1; r1 = r2; r2 = tmp; }
            if (r1 > 0 && r1 < T) { b1 = r1; }
            if (r2 > 0 && r2 < T && r2 != r1) { b2 = r2; }
        }
    } else if (B > 1e-18 || B < -1e-18) {
        r1 = -C / B;
        if (r1 > 0 && r1 < T) { b1 = r1; }
    }
    bounds[nb++] = b0;
    if (b1 >= 0) { bounds[nb++] = b1; }
    if (b2 >= 0) { bounds[nb++] = b2; }
    bounds[nb++] = b3;
    pb[np++] = 0;
    for (k = 0; k + 1 < nb; k++) {
        a = bounds[k]; b = bounds[k + 1];
        fa = dpoly4(c4, c3, c2, c1, a);
        fb = dpoly4(c4, c3, c2, c1, b);
        if ((fa < 0 && fb > 0) || (fa > 0 && fb < 0)) {
            lo = a; hi = b;
            for (i = 0; i < ITER; i++) {
                m = 0.5 * (lo + hi);
                if ((dpoly4(c4, c3, c2, c1, m) < 0) == (fa < 0)) { lo = m; } else { hi = m; }
            }
            pb[np++] = hi;
        }
    }
    pb[np++] = T;
    for (k = 0; k + 1 < np; k++) {
        a = pb[k]; b = pb[k + 1];
        fa = poly4(c4, c3, c2, c1, c0, a);
        fb = poly4(c4, c3, c2, c1, c0, b);
        if (fa > 0 && fb <= 0) {
            lo = a; hi = b;
            for (i = 0; i < ITER; i++) {
                m = 0.5 * (lo + hi);
                if (poly4(c4, c3, c2, c1, c0, m) > 0) { lo = m; } else { hi = m; }
            }
            return hi;
        }
    }
    return -1;
}

static double pairRoot(double dx, double dy, double wx, double wy, double hx, double hy, double rho, double T) {
    double dl = sqrt(dx * dx + dy * dy);
    double wl = sqrt(wx * wx + wy * wy);
    double hl = sqrt(hx * hx + hy * hy);
    if (dl - (wl * T + hl * T * T) > rho) { return -1; }
    if (dx * dx + dy * dy - rho * rho <= TOUCH) {
        return 2 * (dx * wx + dy * wy) < -2 * rho * APPROACH ? 0 : -1;
    }
    return quarticRoot(hx * hx + hy * hy,
                       2 * (wx * hx + wy * hy),
                       wx * wx + wy * wy + 2 * (dx * hx + dy * hy),
                       2 * (dx * wx + dy * wy),
                       dx * dx + dy * dy - rho * rho, T);
}

/* ---- the simulation state, what the JavaScript closes over ---------------------- */

struct sim {
    const struct pb_world *W;
    int n;
    int *ids;
    signed char *mode;
    double *t0, *tEnd, *px0, *py0, *vx0, *vy0, *ax, *ay, *rx0, *ry0, *drx, *dry, *z0;
    double *cx, *cy, *cvx, *cvy, *crx, *cry, *cz;
    double zrate, tnow;
    int nev, trace, oom;
    struct pb_outcome *out;
    int evcap, segcap, encap, holcap;
    /* cluster scratch */
    int *ca, *cb; double *cnx, *cny, *cv0, *cj; int ccap;
    signed char *touched; double *ovx, *ovy;
};

static void push_event(struct sim *S, double t, int kind, int a, int b) {
    struct pb_event *e;
    if (S->out->nevents >= S->evcap) {
        int cap = S->evcap ? S->evcap * 2 : 64;
        e = (struct pb_event *) realloc(S->out->events, sizeof(struct pb_event) * cap);
        if (!e) { S->oom = 1; return; }
        S->out->events = e; S->evcap = cap;
    }
    e = S->out->events + S->out->nevents++;
    e->t = t; e->kind = kind; e->a = a; e->b = b;
}

static void push_holed(struct sim *S, int id, int pocket, double t) {
    struct pb_holed *h;
    if (S->out->nholed >= S->holcap) {
        int cap = S->holcap ? S->holcap * 2 : 8;
        h = (struct pb_holed *) realloc(S->out->holed, sizeof(struct pb_holed) * cap);
        if (!h) { S->oom = 1; return; }
        S->out->holed = h; S->holcap = cap;
    }
    h = S->out->holed + S->out->nholed++;
    h->id = id; h->pocket = pocket; h->t = t;
}

static void push_energy(struct sim *S, double e) {
    double *p;
    if (S->out->nenergy >= S->encap) {
        int cap = S->encap ? S->encap * 2 : 64;
        p = (double *) realloc(S->out->energy, sizeof(double) * cap);
        if (!p) { S->oom = 1; return; }
        S->out->energy = p; S->encap = cap;
    }
    S->out->energy[S->out->nenergy++] = e;
}

/* Segments are recorded per ball in time order; a ball's segments are kept in a
 * per-ball chain of indexes so the flat list can be regrouped at the end. */
struct segnode { struct pb_segment s; int next; };
struct seglist { struct segnode *nodes; int count, cap; int *head, *tail; };

static void closeSeg(struct sim *S, struct seglist *L, int b, double at) {
    struct segnode *nd;
    int idx;
    if (L->count >= L->cap) {
        int cap = L->cap ? L->cap * 2 : 128;
        nd = (struct segnode *) realloc(L->nodes, sizeof(struct segnode) * cap);
        if (!nd) { S->oom = 1; return; }
        L->nodes = nd; L->cap = cap;
    }
    idx = L->count++;
    nd = L->nodes + idx;
    nd->s.id = S->ids[b];
    nd->s.t0 = S->t0[b]; nd->s.dur = at - S->t0[b];
    nd->s.px = S->px0[b]; nd->s.py = S->py0[b];
    nd->s.vx = S->vx0[b]; nd->s.vy = S->vy0[b];
    nd->s.ax = S->ax[b]; nd->s.ay = S->ay[b];
    nd->next = -1;
    if (L->head[b] < 0) { L->head[b] = idx; } else { L->nodes[L->tail[b]].next = idx; }
    L->tail[b] = idx;
}

static void begin(struct sim *S, struct seglist *L, int b, double at, double px, double py, double vx, double vy, double rx, double ry, double z) {
    double usx, usy, ul, vl, hx2, hy2;
    const struct pb_world *W = S->W;
    if (S->mode[b] == SLIDING || S->mode[b] == ROLLING) { closeSeg(S, L, b, at); }
    S->t0[b] = at; S->px0[b] = px; S->py0[b] = py; S->vx0[b] = vx; S->vy0[b] = vy; S->z0[b] = z;
    S->cx[b] = px; S->cy[b] = py; S->cvx[b] = vx; S->cvy[b] = vy; S->crx[b] = rx; S->cry[b] = ry; S->cz[b] = z;
    usx = vx - rx; usy = vy - ry;
    ul = sqrt(usx * usx + usy * usy);
    if (ul > EPS_V) {
        S->mode[b] = SLIDING;
        hx2 = usx / ul; hy2 = usy / ul;
        S->ax[b] = -W->mus * W->g * hx2; S->ay[b] = -W->mus * W->g * hy2;
        S->rx0[b] = rx; S->ry0[b] = ry;
        S->drx[b] = 2.5 * W->mus * W->g * hx2; S->dry[b] = 2.5 * W->mus * W->g * hy2;
        S->tEnd[b] = at + (2.0 / 7.0) * ul / (W->mus * W->g);
        return;
    }
    vl = sqrt(vx * vx + vy * vy);
    if (vl > EPS_V) {
        S->mode[b] = ROLLING;
        hx2 = vx / vl; hy2 = vy / vl;
        S->ax[b] = -W->mur * W->g * hx2; S->ay[b] = -W->mur * W->g * hy2;
        S->rx0[b] = vx; S->ry0[b] = vy;
        S->drx[b] = S->ax[b]; S->dry[b] = S->ay[b];
        S->tEnd[b] = at + vl / (W->mur * W->g);
        return;
    }
    S->mode[b] = STATIONARY;
    S->vx0[b] = 0; S->vy0[b] = 0; S->ax[b] = 0; S->ay[b] = 0;
    S->rx0[b] = 0; S->ry0[b] = 0; S->drx[b] = 0; S->dry[b] = 0; S->z0[b] = 0;
    S->cx[b] = px; S->cy[b] = py; S->cvx[b] = 0; S->cvy[b] = 0; S->crx[b] = 0; S->cry[b] = 0; S->cz[b] = 0;
    S->tEnd[b] = HUGE_VAL;
}

static void evalAt(struct sim *S, int b, double at) {
    double tt = at - S->t0[b], zz;
    S->cx[b] = S->px0[b] + S->vx0[b] * tt + 0.5 * S->ax[b] * tt * tt;
    S->cy[b] = S->py0[b] + S->vy0[b] * tt + 0.5 * S->ay[b] * tt * tt;
    S->cvx[b] = S->vx0[b] + S->ax[b] * tt;
    S->cvy[b] = S->vy0[b] + S->ay[b] * tt;
    S->crx[b] = S->rx0[b] + S->drx[b] * tt;
    S->cry[b] = S->ry0[b] + S->dry[b] * tt;
    zz = S->z0[b];
    if (zz > 0) { zz = zz - S->zrate * tt; if (zz < 0) { zz = 0; } }
    else if (zz < 0) { zz = zz + S->zrate * tt; if (zz > 0) { zz = 0; } }
    S->cz[b] = zz;
}

static void bounce(struct sim *S, struct seglist *L, int b, double nxx, double nyy) {
    const struct pb_world *W = S->W;
    double txx = -nyy, tyy = nxx;
    double vn = S->cvx[b] * nxx + S->cvy[b] * nyy;
    double vt = S->cvx[b] * txx + S->cvy[b] * tyy;
    double rn = S->crx[b] * nxx + S->cry[b] * nyy;
    double rt = S->crx[b] * txx + S->cry[b] * tyy;
    double z = S->cz[b], slip, pt, cap, vn2, vt2, z2, an, rn2;
    vn2 = -W->ec * vn;
    rn2 = -W->ec * W->erc * rn;
    slip = vt - z;
    pt = -(2.0 / 7.0) * slip;
    cap = W->ecf * (1 + W->ec) * (vn < 0 ? -vn : vn);
    if (pt > cap) { pt = cap; }
    if (pt < -cap) { pt = -cap; }
    vt2 = vt + pt;
    z2 = z - 2.5 * pt;
    if (vn2 < ZENO && vn2 > -ZENO) { vn2 = 0; }
    begin(S, L, b, S->tnow, S->cx[b], S->cy[b], vn2 * nxx + vt2 * txx, vn2 * nyy + vt2 * tyy, rn2 * nxx + rt * txx, rn2 * nyy + rt * tyy, z2);
    if (vn2 == 0) {
        an = S->ax[b] * nxx + S->ay[b] * nyy;
        if (an < 0) { S->ax[b] = S->ax[b] - an * nxx; S->ay[b] = S->ay[b] - an * nyy; }
    }
}

static void cluster(struct sim *S, struct seglist *L, int i, int j, double nx, double ny, double sv) {
    const struct pb_world *W = S->W;
    int n = S->n, nc;
    int prim[2];
    int iter, k, changed, a, b, p, q, pi, pass;
    double s, dj, jn, ddx, ddy, dd, s0, e, e0, e1;
    prim[0] = i; prim[1] = j;
    e = W->ebb;
    for (p = 0; p < n; p++) { S->ovx[p] = S->cvx[p]; S->ovy[p] = S->cvy[p]; S->touched[p] = 0; }
    nc = 0;
    for (pass = 0; pass < 8; pass++) {
        nc = 1; S->ca[0] = i; S->cb[0] = j; S->cnx[0] = nx; S->cny[0] = ny; S->cv0[0] = sv; S->cj[0] = 0;
        for (p = 0; p < n; p++) { if (S->touched[p]) { S->cvx[p] = S->ovx[p]; S->cvy[p] = S->ovy[p]; S->touched[p] = 0; } }
        S->touched[i] = 1; S->touched[j] = 1;
        for (iter = 0; iter < CLUSTER_ITER; iter++) {
            changed = 0;
            for (k = 0; k < nc; k++) {
                a = S->ca[k]; b = S->cb[k];
                s = (S->cvx[a] - S->cvx[b]) * S->cnx[k] + (S->cvy[a] - S->cvy[b]) * S->cny[k];
                dj = 0.5 * (s + e * S->cv0[k]);
                jn = S->cj[k] + dj;
                if (jn < 0) { jn = 0; }
                dj = jn - S->cj[k];
                if (dj > 1e-12 || dj < -1e-12) {
                    S->cj[k] = jn;
                    S->cvx[a] = S->cvx[a] - dj * S->cnx[k]; S->cvy[a] = S->cvy[a] - dj * S->cny[k];
                    S->cvx[b] = S->cvx[b] + dj * S->cnx[k]; S->cvy[b] = S->cvy[b] + dj * S->cny[k];
                    changed = 1;
                }
            }
            for (pi = 0; pi < 2; pi++) {
                p = prim[pi];
                for (q = 0; q < n; q++) {
                    if (q == p || S->mode[q] == POCKETED) { continue; }
                    ddx = S->cx[q] - S->cx[p]; ddy = S->cy[q] - S->cy[p];
                    dd = ddx * ddx + ddy * ddy;
                    if (dd - 4 * W->R * W->R > TOUCH) { continue; }
                    for (k = 0; k < nc; k++) { if ((S->ca[k] == p && S->cb[k] == q) || (S->ca[k] == q && S->cb[k] == p)) { break; } }
                    if (k < nc) { continue; }
                    dd = sqrt(dd);
                    s = (S->cvx[p] - S->cvx[q]) * (ddx / dd) + (S->cvy[p] - S->cvy[q]) * (ddy / dd);
                    if (s <= APPROACH) { continue; }
                    s0 = (S->ovx[p] - S->ovx[q]) * (ddx / dd) + (S->ovy[p] - S->ovy[q]) * (ddy / dd);
                    if (s0 < 0) { s0 = 0; }
                    if (nc >= S->ccap) { continue; }
                    S->ca[nc] = p; S->cb[nc] = q; S->cnx[nc] = ddx / dd; S->cny[nc] = ddy / dd; S->cv0[nc] = s0; S->cj[nc] = 0;
                    nc++;
                    S->touched[q] = 1;
                    changed = 1;
                }
            }
            if (!changed) { break; }
        }
        e0 = 0; e1 = 0;
        for (p = 0; p < n; p++) {
            if (S->touched[p]) {
                e0 = e0 + S->ovx[p] * S->ovx[p] + S->ovy[p] * S->ovy[p];
                e1 = e1 + S->cvx[p] * S->cvx[p] + S->cvy[p] * S->cvy[p];
            }
        }
        if (e1 <= e0 * (1 + 1e-12)) { break; }
        e = pass < 6 ? e * 0.5 : 0;
    }
    for (p = 0; p < n; p++) {
        if (S->touched[p]) { begin(S, L, p, S->tnow, S->cx[p], S->cy[p], S->cvx[p], S->cvy[p], S->crx[p], S->cry[p], S->cz[p]); }
    }
}

static double totalEnergy(struct sim *S) {
    double e = 0;
    int b;
    for (b = 0; b < S->n; b++) {
        if (S->mode[b] == SLIDING || S->mode[b] == ROLLING) {
            evalAt(S, b, S->tnow);
            e += 0.5 * (S->cvx[b] * S->cvx[b] + S->cvy[b] * S->cvy[b]) + 0.2 * (S->crx[b] * S->crx[b] + S->cry[b] * S->cry[b] + S->cz[b] * S->cz[b]);
        }
    }
    return e;
}

static double *dalloc(int n) { return (double *) calloc(n > 0 ? n : 1, sizeof(double)); }

void pb_outcome_free(struct pb_outcome *out) {
    if (!out) return;
    free(out->events); free(out->rest); free(out->holed); free(out->segments); free(out->energy);
    free(out);
}

struct pb_outcome *pb_strike(const struct pb_world *W, int n, const struct pb_ball_in *layout, const struct pb_shot *shot) {
    struct sim S;
    struct seglist L;
    struct pb_outcome *out;
    int i, j, k, cue, Tball, bestK, bestI, bestJ, nc, idx;
    double T, bestT, t, dx, dy, wx, wy, hx, hy, s0, sv, sa, lam, nx, ny, ux, uy, len, dl, p, speed, sxf, syf, sl;
    double R = W->R;

    out = (struct pb_outcome *) calloc(1, sizeof *out);
    if (!out) return NULL;
    S.W = W; S.n = n; S.out = out; S.nev = 0; S.tnow = 0; S.oom = 0;
    S.trace = shot->trace; S.evcap = S.segcap = S.encap = S.holcap = 0;
    S.zrate = 2.5 * W->musp * W->g;
    S.ids = (int *) calloc(n > 0 ? n : 1, sizeof(int));
    S.mode = (signed char *) calloc(n > 0 ? n : 1, 1);
    S.touched = (signed char *) calloc(n > 0 ? n : 1, 1);
    S.t0 = dalloc(n); S.tEnd = dalloc(n); S.px0 = dalloc(n); S.py0 = dalloc(n); S.vx0 = dalloc(n); S.vy0 = dalloc(n);
    S.ax = dalloc(n); S.ay = dalloc(n); S.rx0 = dalloc(n); S.ry0 = dalloc(n); S.drx = dalloc(n); S.dry = dalloc(n); S.z0 = dalloc(n);
    S.cx = dalloc(n); S.cy = dalloc(n); S.cvx = dalloc(n); S.cvy = dalloc(n); S.crx = dalloc(n); S.cry = dalloc(n); S.cz = dalloc(n);
    S.ovx = dalloc(n); S.ovy = dalloc(n);
    S.ccap = n * n + 1;
    S.ca = (int *) calloc(S.ccap, sizeof(int)); S.cb = (int *) calloc(S.ccap, sizeof(int));
    S.cnx = dalloc(S.ccap); S.cny = dalloc(S.ccap); S.cv0 = dalloc(S.ccap); S.cj = dalloc(S.ccap);
    L.nodes = NULL; L.count = 0; L.cap = 0;
    L.head = (int *) calloc(n > 0 ? n : 1, sizeof(int)); L.tail = (int *) calloc(n > 0 ? n : 1, sizeof(int));
    if (!S.ids || !S.mode || !S.touched || !S.t0 || !S.tEnd || !S.px0 || !S.py0 || !S.vx0 || !S.vy0 || !S.ax || !S.ay
        || !S.rx0 || !S.ry0 || !S.drx || !S.dry || !S.z0 || !S.cx || !S.cy || !S.cvx || !S.cvy || !S.crx || !S.cry || !S.cz
        || !S.ovx || !S.ovy || !S.ca || !S.cb || !S.cnx || !S.cny || !S.cv0 || !S.cj || !L.head || !L.tail) {
        S.oom = 1;
    }

    cue = -1;
    if (!S.oom) {
        for (i = 0; i < n; i++) {
            S.ids[i] = layout[i].id;
            S.px0[i] = layout[i].x * 1e-5;
            S.py0[i] = layout[i].y * 1e-5;
            S.mode[i] = STATIONARY;
            S.tEnd[i] = HUGE_VAL;
            S.cx[i] = S.px0[i]; S.cy[i] = S.py0[i];
            L.head[i] = -1; L.tail[i] = -1;
            if (S.ids[i] == shot->ball) { cue = i; }
        }
    }
    if (S.oom) { out->error = PB_ERR_MEMORY; goto done; }
    if (cue < 0) { out->error = PB_ERR_NO_BALL; goto done; }

    dl = sqrt((double) shot->dx * (double) shot->dx + (double) shot->dy * (double) shot->dy);
    ux = shot->dx / dl; uy = shot->dy / dl;
    p = shot->power / 1000.0;
    speed = 0.3 + p * p * (W->vmax - 0.3);
    sxf = shot->sx / 1000.0; syf = shot->sy / 1000.0;
    sl = sqrt(sxf * sxf + syf * syf);
    if (sl > 0.5) { sxf = sxf * 0.5 / sl; syf = syf * 0.5 / sl; }
    begin(&S, &L, cue, 0, S.px0[cue], S.py0[cue], ux * speed, uy * speed, 2.5 * syf * ux * speed, 2.5 * syf * uy * speed, 2.5 * sxf * speed);
    if (S.trace) { push_energy(&S, totalEnergy(&S)); }

    for (;;) {
        T = HUGE_VAL; Tball = -1;
        for (i = 0; i < n; i++) {
            if (S.mode[i] == SLIDING || S.mode[i] == ROLLING) {
                evalAt(&S, i, S.tnow);
                if (S.tEnd[i] - S.tnow < T) { T = S.tEnd[i] - S.tnow; Tball = i; }
            }
        }
        if (Tball < 0) { break; }
        if (T < 0) { T = 0; }
        bestT = T; bestK = K_MODE; bestI = Tball; bestJ = -1;

        for (i = 0; i < n; i++) {
            if (S.mode[i] == POCKETED) { continue; }
            for (j = i + 1; j < n; j++) {
                if (S.mode[j] == POCKETED) { continue; }
                if (S.mode[i] == STATIONARY && S.mode[j] == STATIONARY) { continue; }
                dx = S.cx[i] - S.cx[j]; dy = S.cy[i] - S.cy[j];
                wx = S.cvx[i] - S.cvx[j]; wy = S.cvy[i] - S.cvy[j];
                hx = 0.5 * (S.ax[i] - S.ax[j]); hy = 0.5 * (S.ay[i] - S.ay[j]);
                t = pairRoot(dx, dy, wx, wy, hx, hy, 2 * R, bestT);
                if (t >= 0 && t < bestT) { bestT = t; bestK = K_BALL; bestI = i; bestJ = j; }
            }
        }
        for (i = 0; i < n; i++) {
            if (S.mode[i] != SLIDING && S.mode[i] != ROLLING) { continue; }
            for (k = 0; k < W->nw; k++) {
                nx = W->walls[k * 7 + 5]; ny = W->walls[k * 7 + 6];
                s0 = nx * (S.cx[i] - W->walls[k * 7]) + ny * (S.cy[i] - W->walls[k * 7 + 1]) - R;
                sv = nx * S.cvx[i] + ny * S.cvy[i];
                sa = nx * S.ax[i] + ny * S.ay[i];
                t = lineRoot(s0, sv, sa, bestT);
                if (t < 0 || t >= bestT) { continue; }
                ux = W->walls[k * 7 + 2]; uy = W->walls[k * 7 + 3]; len = W->walls[k * 7 + 4];
                lam = ((S.cx[i] + S.cvx[i] * t + 0.5 * S.ax[i] * t * t - R * nx) - W->walls[k * 7]) * ux
                    + ((S.cy[i] + S.cvy[i] * t + 0.5 * S.ay[i] * t * t - R * ny) - W->walls[k * 7 + 1]) * uy;
                if (lam < 0 || lam > len) { continue; }
                bestT = t; bestK = K_WALL; bestI = i; bestJ = k;
            }
            for (k = 0; k < W->nn; k++) {
                dx = S.cx[i] - W->noses[k * 2]; dy = S.cy[i] - W->noses[k * 2 + 1];
                t = pairRoot(dx, dy, S.cvx[i], S.cvy[i], 0.5 * S.ax[i], 0.5 * S.ay[i], R, bestT);
                if (t >= 0 && t < bestT) { bestT = t; bestK = K_NOSE; bestI = i; bestJ = k; }
            }
            for (k = 0; k < W->ng; k++) {
                nx = W->gates[k * 8 + 5]; ny = W->gates[k * 8 + 6];
                s0 = -(nx * (S.cx[i] - W->gates[k * 8]) + ny * (S.cy[i] - W->gates[k * 8 + 1]));
                sv = -(nx * S.cvx[i] + ny * S.cvy[i]);
                sa = -(nx * S.ax[i] + ny * S.ay[i]);
                t = lineRoot(s0, sv, sa, bestT);
                if (t < 0 || t >= bestT) { continue; }
                ux = W->gates[k * 8 + 2]; uy = W->gates[k * 8 + 3]; len = W->gates[k * 8 + 4];
                lam = ((S.cx[i] + S.cvx[i] * t + 0.5 * S.ax[i] * t * t) - W->gates[k * 8]) * ux
                    + ((S.cy[i] + S.cvy[i] * t + 0.5 * S.ay[i] * t * t) - W->gates[k * 8 + 1]) * uy;
                if (lam < -R || lam > len + R) { continue; }
                bestT = t; bestK = K_GATE; bestI = i; bestJ = k;
            }
        }

        S.tnow = S.tnow + bestT;
        i = bestI; j = bestJ;
        if (bestK == K_MODE) {
            evalAt(&S, i, S.tnow);
            if (S.mode[i] == SLIDING) {
                begin(&S, &L, i, S.tnow, S.cx[i], S.cy[i], S.cvx[i], S.cvy[i], S.cvx[i], S.cvy[i], S.cz[i]);
                push_event(&S, S.tnow, PB_EV_ROLL, S.ids[i], -1);
            } else if (S.cvx[i] * S.cvx[i] + S.cvy[i] * S.cvy[i] > ZENO_BB * ZENO_BB) {
                begin(&S, &L, i, S.tnow, S.cx[i], S.cy[i], S.cvx[i], S.cvy[i], S.cvx[i], S.cvy[i], S.cz[i]);
            } else {
                closeSeg(&S, &L, i, S.tnow);
                S.mode[i] = STATIONARY;
                S.vx0[i] = 0; S.vy0[i] = 0; S.ax[i] = 0; S.ay[i] = 0; S.rx0[i] = 0; S.ry0[i] = 0; S.drx[i] = 0; S.dry[i] = 0; S.z0[i] = 0;
                S.cvx[i] = 0; S.cvy[i] = 0; S.crx[i] = 0; S.cry[i] = 0; S.cz[i] = 0;
                S.px0[i] = S.cx[i]; S.py0[i] = S.cy[i]; S.t0[i] = S.tnow; S.tEnd[i] = HUGE_VAL;
                push_event(&S, S.tnow, PB_EV_STOP, S.ids[i], -1);
            }
        } else if (bestK == K_BALL) {
            evalAt(&S, i, S.tnow); evalAt(&S, j, S.tnow);
            nx = S.cx[j] - S.cx[i]; ny = S.cy[j] - S.cy[i];
            dl = sqrt(nx * nx + ny * ny);
            nx = nx / dl; ny = ny / dl;
            if (dl < 2 * R) {
                lam = 2 * R - dl;
                if (S.mode[j] == STATIONARY) { S.cx[i] = S.cx[i] - lam * nx; S.cy[i] = S.cy[i] - lam * ny; }
                else if (S.mode[i] == STATIONARY) { S.cx[j] = S.cx[j] + lam * nx; S.cy[j] = S.cy[j] + lam * ny; }
                else { S.cx[i] = S.cx[i] - 0.5 * lam * nx; S.cy[i] = S.cy[i] - 0.5 * lam * ny; S.cx[j] = S.cx[j] + 0.5 * lam * nx; S.cy[j] = S.cy[j] + 0.5 * lam * ny; }
            }
            sv = (S.cvx[i] - S.cvx[j]) * nx + (S.cvy[i] - S.cvy[j]) * ny;
            if (sv > ZENO_BB) {
                cluster(&S, &L, i, j, nx, ny, sv);
            } else {
                lam = sv > 0 ? sv * 0.5 : 0;
                begin(&S, &L, i, S.tnow, S.cx[i], S.cy[i], S.cvx[i] - lam * nx, S.cvy[i] - lam * ny, S.crx[i] - lam * nx, S.cry[i] - lam * ny, S.cz[i]);
                begin(&S, &L, j, S.tnow, S.cx[j], S.cy[j], S.cvx[j] + lam * nx, S.cvy[j] + lam * ny, S.crx[j] + lam * nx, S.cry[j] + lam * ny, S.cz[j]);
                s0 = S.ax[i] * nx + S.ay[i] * ny;
                sa = S.ax[j] * nx + S.ay[j] * ny;
                if (S.mode[j] == STATIONARY) {
                    if (s0 > 0) { S.ax[i] = S.ax[i] - s0 * nx; S.ay[i] = S.ay[i] - s0 * ny; }
                } else if (S.mode[i] == STATIONARY) {
                    if (sa < 0) { S.ax[j] = S.ax[j] - sa * nx; S.ay[j] = S.ay[j] - sa * ny; }
                } else if (s0 > sa) {
                    lam = 0.5 * (s0 + sa);
                    S.ax[i] = S.ax[i] - (s0 - lam) * nx; S.ay[i] = S.ay[i] - (s0 - lam) * ny;
                    S.ax[j] = S.ax[j] - (sa - lam) * nx; S.ay[j] = S.ay[j] - (sa - lam) * ny;
                }
            }
            push_event(&S, S.tnow, PB_EV_BALL, S.ids[i], S.ids[j]);
        } else if (bestK == K_WALL) {
            evalAt(&S, i, S.tnow);
            bounce(&S, &L, i, W->walls[j * 7 + 5], W->walls[j * 7 + 6]);
            push_event(&S, S.tnow, PB_EV_WALL, S.ids[i], j);
        } else if (bestK == K_NOSE) {
            evalAt(&S, i, S.tnow);
            nx = S.cx[i] - W->noses[j * 2]; ny = S.cy[i] - W->noses[j * 2 + 1];
            dl = sqrt(nx * nx + ny * ny);
            bounce(&S, &L, i, nx / dl, ny / dl);
            push_event(&S, S.tnow, PB_EV_NOSE, S.ids[i], j);
        } else {
            evalAt(&S, i, S.tnow);
            closeSeg(&S, &L, i, S.tnow);
            S.mode[i] = POCKETED;
            S.px0[i] = S.cx[i]; S.py0[i] = S.cy[i]; S.t0[i] = S.tnow; S.tEnd[i] = HUGE_VAL;
            push_event(&S, S.tnow, PB_EV_POT, S.ids[i], (int) W->gates[j * 8 + 7]);
            push_holed(&S, S.ids[i], (int) W->gates[j * 8 + 7], S.tnow);
        }
        if (S.trace) { push_energy(&S, totalEnergy(&S)); }
        S.nev++;
        if (S.oom) { out->error = PB_ERR_MEMORY; break; }
        if (S.nev > PB_MAX_EVENTS) { out->error = PB_ERR_EVENTS; break; }
        if (S.tnow > PB_MAX_TIME) { out->error = PB_ERR_TIME; break; }
    }

    /* rest and the regrouped segments */
    out->t = S.tnow; out->n = S.nev;
    out->rest = (struct pb_rest *) calloc(n > 0 ? n : 1, sizeof(struct pb_rest));
    nc = 0;
    for (i = 0; i < n; i++) {
        if (S.mode[i] == SLIDING || S.mode[i] == ROLLING) { closeSeg(&S, &L, i, S.tnow); }
        if (S.mode[i] != POCKETED && out->rest) {
            out->rest[nc].id = S.ids[i];
            out->rest[nc].x = (long) floor(S.px0[i] * 1e5 + 0.5);
            out->rest[nc].y = (long) floor(S.py0[i] * 1e5 + 0.5);
            nc++;
        }
    }
    out->nrest = out->rest ? nc : 0;
    if (L.count) {
        out->segments = (struct pb_segment *) calloc(L.count, sizeof(struct pb_segment));
        if (out->segments) {
            k = 0;
            for (i = 0; i < n; i++) {
                for (idx = L.head[i]; idx >= 0; idx = L.nodes[idx].next) { out->segments[k++] = L.nodes[idx].s; }
            }
            out->nsegments = k;
        } else { out->error = PB_ERR_MEMORY; }
    }
    if (S.oom && !out->error) { out->error = PB_ERR_MEMORY; }

done:
    free(S.ids); free(S.mode); free(S.touched);
    free(S.t0); free(S.tEnd); free(S.px0); free(S.py0); free(S.vx0); free(S.vy0);
    free(S.ax); free(S.ay); free(S.rx0); free(S.ry0); free(S.drx); free(S.dry); free(S.z0);
    free(S.cx); free(S.cy); free(S.cvx); free(S.cvy); free(S.crx); free(S.cry); free(S.cz);
    free(S.ovx); free(S.ovy); free(S.ca); free(S.cb); free(S.cnx); free(S.cny); free(S.cv0); free(S.cj);
    free(L.nodes); free(L.head); free(L.tail);
    return out;
}

static const struct pb_abi PB_TABLE = { PB_ABI_VERSION, pb_world_new, pb_world_free, pb_strike, pb_outcome_free };

const struct pb_abi *pb_abi_table(void) { return &PB_TABLE; }
