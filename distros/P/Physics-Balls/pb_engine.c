/* pb_engine.c - the ball engine, a transliteration of the prototype's physics.js.
 *
 * Every expression here is written in the same order as the JavaScript it came
 * from (plan_pool_snooker/prototype/physics.js), because the fixtures recorded
 * from that file are the specification and t/03-bitwise.t asks for the same
 * doubles. Only + - * / and sqrt appear; no hypot, pow or trigonometry. C89:
 * declarations at the top of a block, no //, no variable-length arrays.
 *
 * The JavaScript's function names are kept so the two files can be read side
 * by side: lineRoot, quarticRoot, pairRoot, begin, evalAt, bounce, cluster,
 * since 0.03 scheduleTurn, and since 0.04 reach, stopBody and crawling.
 *
 * 0.04 (plan_bowling 02, from plan_bowling/prototype/physics.js, the fork of
 * pool's file): a kind has a radius, a mass, a friction multiplier, a sweep
 * radius it presents to its own kind and a peak speed above which a body is
 * down; a shot may carry a release roll; every body's peak speed is returned;
 * a down body leaves play when it stops or slows to a crawl; and a storm of
 * events inside ten milliseconds stops every down body and every body under
 * two centimetres a second. Every new factor is a multiplication by exactly
 * 1.0 or exactly 0.5 when every body is the default kind, no expression
 * divides by a sum of reciprocals, and the spin 0 branch is the 0.03 code, so
 * the 0.03 fixtures are bit-identical (t/03, t/09, t/10) and the lane fixtures
 * are bit-identical to the fork (t/11).
 *
 * 0.03 (plan_curling_bowls 01): a ball may curve, by its kind, as a chain of
 * parabolas turned at capped segment boundaries; a shot may carry an adjust
 * that scales the struck ball's friction and curve once it crosses a line.
 * With every curve zero and no adjust the scales are exactly 1.0 and the
 * doubles are the doubles of 0.02: the 21 table fixtures and the course
 * fixture are the proof. ABI 2 appends world_new_ex and strike_ex; the v1
 * entry points are wrappers that fill the v2 structs with the v1 defaults.
 */

#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <math.h>
#include "pb_abi.h"

#define STATIONARY 0
#define SLIDING    1
#define ROLLING    2
#define POCKETED   3

#define K_MODE   0
#define K_BALL   1
#define K_WALL   2
#define K_NOSE   3
#define K_GATE   4
#define K_TURN   5
#define K_ADJUST 6

static const double TOUCH    = 1e-5;
static const double TOUCH_S  = 1e-7;
static const double ZENO     = 0.01;
static const double ZENO_BB  = 1e-3;
static const double APPROACH = 1e-6;
static const double EPS_V    = 1e-6;
#define ITER 60
#define CLUSTER_ITER 200
#define STORM 100                 /* this many events inside one STORM_T window is a storm; pool's densest is 22 */
static const double STORM_T = 0.01;
static const double STALL   = 0.02;   /* a down body slower than this is lying, out of play; in a storm any body under it is stopped */

struct pb_world {
    double L, W, R, g, mus, mur, musp, ebb, ec, ecf, erc, vmax;
    int nw; double *walls;   /* x1, y1, ux, uy, len, nx, ny */
    int nn; double *noses;   /* x, y */
    int ng; double *gates;   /* x1, y1, ux, uy, len, nx, ny, pocket */
    /* the curve law and the kinds, ABI 2; a v1 world has curveK 0 and no kinds */
    double curveK, vref, vmin, kmax, cap, vfrac;
    int curveP;
    int nk; double *kcurve;  /* one curve strength per kind */
    double *kfollow;         /* one roll retention through contact per kind */
    /* ABI 3: per kind a radius, a sweep radius for its own kind, a mass, a
       friction multiplier and a down threshold; a v1 or v2 world has the
       defaults, R, R, 1, 1, 0 */
    double *kr, *krs, *km, *kmu, *kvf;
};

/* The v1 entry point: a v2 description with the v1 defaults, no curve and no kinds. */
struct pb_world *pb_world_new(const struct pb_desc *w) {
    struct pb_desc2 d;
    memset(&d, 0, sizeof d);
    d.size = (unsigned int) sizeof d;
    d.base = *w;
    d.curve_vref = 1; d.curve_vmin = 0.1; d.curve_kmax = 1; d.curve_p = 2; d.turn_cap = 0.002; d.turn_vfrac = 0.1;
    d.nkinds = 0; d.kinds = NULL; d.kind_stride = (int) sizeof(struct pb_kind);
    return pb_world_new_ex(&d);
}

struct pb_world *pb_world_new_ex(const struct pb_desc2 *d) {
    struct pb_world *W;
    const struct pb_desc *w;
    int i;
    double dx, dy, len;
    const double *s;
    const char *kp;
    if (!d || d->size < sizeof(struct pb_desc2)) return NULL;
    if (d->curve_p < 0 || d->curve_p > 4) return NULL;
    if (d->nkinds > 0 && (!d->kinds || d->kind_stride < (int) sizeof(struct pb_kind))) return NULL;
    w = &d->base;
    W = (struct pb_world *) malloc(sizeof *W);
    if (!W) return NULL;
    W->L = w->L; W->W = w->W; W->R = w->R; W->g = w->g;
    W->mus = w->mu_s; W->mur = w->mu_r; W->musp = w->mu_sp;
    W->ebb = w->e_bb; W->ec = w->e_c; W->ecf = w->e_cf; W->erc = w->e_rc;
    W->vmax = w->vmax;
    W->curveK = d->curve_k; W->vref = d->curve_vref; W->vmin = d->curve_vmin; W->kmax = d->curve_kmax;
    W->curveP = d->curve_p; W->cap = d->turn_cap; W->vfrac = d->turn_vfrac;
    W->nk = d->nkinds > 0 ? d->nkinds : 0;
    W->nw = w->nwalls; W->nn = w->nnoses; W->ng = w->ngates;
    W->walls = (double *) malloc(sizeof(double) * (W->nw ? W->nw * 7 : 1));
    W->noses = (double *) malloc(sizeof(double) * (W->nn ? W->nn * 2 : 1));
    W->gates = (double *) malloc(sizeof(double) * (W->ng ? W->ng * 8 : 1));
    W->kcurve = (double *) malloc(sizeof(double) * (W->nk ? W->nk : 1));
    W->kfollow = (double *) malloc(sizeof(double) * (W->nk ? W->nk : 1));
    W->kr = (double *) malloc(sizeof(double) * (W->nk ? W->nk : 1));
    W->krs = (double *) malloc(sizeof(double) * (W->nk ? W->nk : 1));
    W->km = (double *) malloc(sizeof(double) * (W->nk ? W->nk : 1));
    W->kmu = (double *) malloc(sizeof(double) * (W->nk ? W->nk : 1));
    W->kvf = (double *) malloc(sizeof(double) * (W->nk ? W->nk : 1));
    if (!W->walls || !W->noses || !W->gates || !W->kcurve || !W->kfollow || !W->kr || !W->krs || !W->km || !W->kmu || !W->kvf) { pb_world_free(W); return NULL; }
    for (i = 0; i < W->nk; i++) {
        kp = (const char *) d->kinds + (size_t) i * (size_t) d->kind_stride;
        W->kcurve[i] = ((const struct pb_kind *) kp)->curve;
        W->kfollow[i] = ((const struct pb_kind *) kp)->follow;
        /* the ABI 3 members, only when the consumer's stride covers them; a
           value of zero or less is the default, which is the ABI 2 arithmetic */
        W->kr[i] = W->R; W->km[i] = 1; W->kmu[i] = 1; W->krs[i] = W->R; W->kvf[i] = 0;
        if (d->kind_stride >= (int) sizeof(struct pb_kind)) {
            const struct pb_kind *kk = (const struct pb_kind *) kp;
            if (kk->r > 0) { W->kr[i] = kk->r; }
            if (kk->m > 0) { W->km[i] = kk->m; }
            if (kk->mu > 0) { W->kmu[i] = kk->mu; }
            W->krs[i] = kk->rs > 0 ? kk->rs : W->kr[i];
            if (kk->vfall > 0) { W->kvf[i] = kk->vfall; }
        }
    }
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
    free(W->walls); free(W->noses); free(W->gates); free(W->kcurve); free(W->kfollow);
    free(W->kr); free(W->krs); free(W->km); free(W->kmu); free(W->kvf);
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
    /* the curve: per ball its kind's curve, the two scales the adjust changes
       (1 until it does), the turn rate at the segment start, the next turn */
    double *curve, *muscale, *curvescale, *kps, *tTurn, *follow;
    int nturns;
    /* ABI 3: per body its radius, sweep radius, mass, friction multiplier, the
       down threshold squared and the peak speed squared; the cluster's per
       contact mass shares; the storm counter and its window */
    double *rad, *rsw, *mass, *ms, *vf2, *peak2;
    double *cki, *ckj;
    int storm; double stormT0;
    int downcap;
};

/* the radius two bodies meet at: the sweep radii between bodies of one kind */
static double reach(const struct sim *S, int a, int b) {
    return S->rad[a] == S->rad[b] && S->rsw[a] == S->rsw[b] && S->mass[a] == S->mass[b] && S->vf2[a] == S->vf2[b] && S->ms[a] == S->ms[b]
        ? S->rsw[a] + S->rsw[b] : S->rad[a] + S->rad[b];
}

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

static void push_down(struct sim *S, int id, long x, long y, double t) {
    struct pb_down *d;
    if (S->out->ndowns >= S->downcap) {
        int cap = S->downcap ? S->downcap * 2 : 8;
        d = (struct pb_down *) realloc(S->out->downs, sizeof(struct pb_down) * cap);
        if (!d) { S->oom = 1; return; }
        S->out->downs = d; S->downcap = cap;
    }
    d = S->out->downs + S->out->ndowns++;
    d->id = id; d->x = x; d->y = y; d->t = t;
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

/* When a curving ball next turns: the law at the segment's start speed, then
   the sooner of the heading cap and the speed-fraction cap. The speed-fraction
   cap exists to bound how far the law at the step's end runs from the law at
   its start, and below vmin the law does not change with speed, so there it
   does not apply: otherwise the steps shrink with the speed for ever and the
   ball never reaches its stop. A ball with no curve never turns and nothing
   here touches its state. */
static void scheduleTurn(struct sim *S, int b, double at, double vl, double dec) {
    const struct pb_world *W = S->W;
    double c = S->curve[b] * S->curvescale[b], ratio, q, kk, dt, dt2;
    int m;
    S->kps[b] = 0; S->tTurn[b] = HUGE_VAL;
    if (c == 0 || W->curveK == 0) { return; }
    ratio = W->vref / (vl > W->vmin ? vl : W->vmin);
    q = 1;
    for (m = 0; m < W->curveP; m++) { q = q * ratio; }
    kk = W->curveK * c * q;
    if (kk > W->kmax) { kk = W->kmax; } else if (kk < -W->kmax) { kk = -W->kmax; }
    if (kk == 0) { return; }
    S->kps[b] = kk;
    dt = W->cap / (kk < 0 ? -kk : kk);
    if (dec > 0 && vl > W->vmin) { dt2 = W->vfrac * vl / dec; if (dt2 < dt) { dt = dt2; } }
    S->tTurn[b] = at + dt;
}

static void begin(struct sim *S, struct seglist *L, int b, double at, double px, double py, double vx, double vy, double rx, double ry, double z) {
    double usx, usy, ul, vl, hx2, hy2, musb, murb, s2;
    const struct pb_world *W = S->W;
    if (S->mode[b] == SLIDING || S->mode[b] == ROLLING) { closeSeg(S, L, b, at); }
    S->t0[b] = at; S->px0[b] = px; S->py0[b] = py; S->vx0[b] = vx; S->vy0[b] = vy; S->z0[b] = z;
    S->cx[b] = px; S->cy[b] = py; S->cvx[b] = vx; S->cvy[b] = vy; S->crx[b] = rx; S->cry[b] = ry; S->cz[b] = z;
    /* the friction under this ball: the world's, times a scale that is exactly
       1.0 until an adjust changes it, times its kind's multiplier, which is
       exactly 1.0 for every pool and minigolf body, so the product is exact */
    musb = W->mus * S->muscale[b] * S->ms[b]; murb = W->mur * S->muscale[b] * S->ms[b];
    /* the peak: one comparison per segment start, for a pinfall rule */
    s2 = vx * vx + vy * vy;
    if (s2 > S->peak2[b]) { S->peak2[b] = s2; }
    usx = vx - rx; usy = vy - ry;
    ul = sqrt(usx * usx + usy * usy);
    if (ul > EPS_V) {
        S->mode[b] = SLIDING;
        hx2 = usx / ul; hy2 = usy / ul;
        S->ax[b] = -musb * W->g * hx2; S->ay[b] = -musb * W->g * hy2;
        S->rx0[b] = rx; S->ry0[b] = ry;
        S->drx[b] = 2.5 * musb * W->g * hx2; S->dry[b] = 2.5 * musb * W->g * hy2;
        S->tEnd[b] = at + (2.0 / 7.0) * ul / (musb * W->g);
        scheduleTurn(S, b, at, sqrt(vx * vx + vy * vy), musb * W->g);
        return;
    }
    vl = sqrt(vx * vx + vy * vy);
    if (vl > EPS_V) {
        S->mode[b] = ROLLING;
        hx2 = vx / vl; hy2 = vy / vl;
        S->ax[b] = -murb * W->g * hx2; S->ay[b] = -murb * W->g * hy2;
        S->rx0[b] = vx; S->ry0[b] = vy;
        S->drx[b] = S->ax[b]; S->dry[b] = S->ay[b];
        S->tEnd[b] = at + vl / (murb * W->g);
        scheduleTurn(S, b, at, vl, murb * W->g);
        return;
    }
    S->mode[b] = STATIONARY;
    S->vx0[b] = 0; S->vy0[b] = 0; S->ax[b] = 0; S->ay[b] = 0;
    S->rx0[b] = 0; S->ry0[b] = 0; S->drx[b] = 0; S->dry[b] = 0; S->z0[b] = 0;
    S->cx[b] = px; S->cy[b] = py; S->cvx[b] = 0; S->cvy[b] = 0; S->crx[b] = 0; S->cry[b] = 0; S->cz[b] = 0;
    S->tEnd[b] = HUGE_VAL;
    S->kps[b] = 0; S->tTurn[b] = HUGE_VAL;
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
    double s, dj, jn, ddx, ddy, dd, s0, e, e0, e1, rho;
    prim[0] = i; prim[1] = j;
    e = W->ebb;
    for (p = 0; p < n; p++) { S->ovx[p] = S->cvx[p]; S->ovy[p] = S->cvy[p]; S->touched[p] = 0; }
    nc = 0;
    for (pass = 0; pass < 8; pass++) {
        /* dj stays the equal-mass half impulse per unit mass, in the units the
           1e-12 convergence test was tuned for; the mass ratio enters as a
           multiplier on its application, 2 mb / (ma + mb), which is exactly
           1.0 when the masses are equal. Never 1 / (1/ma + 1/mb). */
        nc = 1; S->ca[0] = i; S->cb[0] = j; S->cnx[0] = nx; S->cny[0] = ny; S->cv0[0] = sv; S->cj[0] = 0;
        S->cki[0] = 2 * S->mass[j] / (S->mass[i] + S->mass[j]); S->ckj[0] = 2 * S->mass[i] / (S->mass[i] + S->mass[j]);
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
                    S->cvx[a] = S->cvx[a] - (dj * S->cki[k]) * S->cnx[k]; S->cvy[a] = S->cvy[a] - (dj * S->cki[k]) * S->cny[k];
                    S->cvx[b] = S->cvx[b] + (dj * S->ckj[k]) * S->cnx[k]; S->cvy[b] = S->cvy[b] + (dj * S->ckj[k]) * S->cny[k];
                    changed = 1;
                }
            }
            for (pi = 0; pi < 2; pi++) {
                p = prim[pi];
                for (q = 0; q < n; q++) {
                    if (q == p || S->mode[q] == POCKETED) { continue; }
                    ddx = S->cx[q] - S->cx[p]; ddy = S->cy[q] - S->cy[p];
                    dd = ddx * ddx + ddy * ddy;
                    rho = reach(S, p, q);
                    if (dd - rho * rho > TOUCH) { continue; }
                    for (k = 0; k < nc; k++) { if ((S->ca[k] == p && S->cb[k] == q) || (S->ca[k] == q && S->cb[k] == p)) { break; } }
                    if (k < nc) { continue; }
                    dd = sqrt(dd);
                    s = (S->cvx[p] - S->cvx[q]) * (ddx / dd) + (S->cvy[p] - S->cvy[q]) * (ddy / dd);
                    if (s <= APPROACH) { continue; }
                    s0 = (S->ovx[p] - S->ovx[q]) * (ddx / dd) + (S->ovy[p] - S->ovy[q]) * (ddy / dd);
                    if (s0 < 0) { s0 = 0; }
                    if (nc >= S->ccap) { continue; }
                    S->ca[nc] = p; S->cb[nc] = q; S->cnx[nc] = ddx / dd; S->cny[nc] = ddy / dd; S->cv0[nc] = s0; S->cj[nc] = 0;
                    S->cki[nc] = 2 * S->mass[q] / (S->mass[p] + S->mass[q]); S->ckj[nc] = 2 * S->mass[p] / (S->mass[p] + S->mass[q]);
                    nc++;
                    S->touched[q] = 1;
                    changed = 1;
                }
            }
            if (!changed) { break; }
        }
        /* mass-weighted, associated as the JavaScript is: ((e0 + m vx vx) + m vy vy) */
        e0 = 0; e1 = 0;
        for (p = 0; p < n; p++) {
            if (S->touched[p]) {
                e0 = e0 + S->mass[p] * S->ovx[p] * S->ovx[p] + S->mass[p] * S->ovy[p] * S->ovy[p];
                e1 = e1 + S->mass[p] * S->cvx[p] * S->cvx[p] + S->mass[p] * S->cvy[p] * S->cvy[p];
            }
        }
        if (e1 <= e0 * (1 + 1e-12)) { break; }
        e = pass < 6 ? e * 0.5 : 0;
    }
    for (p = 0; p < n; p++) {
        if (!S->touched[p]) { continue; }
        /* a body that keeps less than all of its roll through a contact: the
           roll it leaves with is its new velocity plus that share of the
           difference. At 1 this is not reached and the roll is what it was. */
        if (S->follow[p] != 1) {
            S->crx[p] = S->cvx[p] + S->follow[p] * (S->crx[p] - S->cvx[p]);
            S->cry[p] = S->cvy[p] + S->follow[p] * (S->cry[p] - S->cvy[p]);
        }
        begin(S, L, p, S->tnow, S->cx[p], S->cy[p], S->cvx[p], S->cvy[p], S->crx[p], S->cry[p], S->cz[p]);
    }
}

static double totalEnergy(struct sim *S) {
    double e = 0;
    int b;
    for (b = 0; b < S->n; b++) {
        if (S->mode[b] == SLIDING || S->mode[b] == ROLLING) {
            evalAt(S, b, S->tnow);
            e += S->mass[b] * (0.5 * (S->cvx[b] * S->cvx[b] + S->cvy[b] * S->cvy[b]) + 0.2 * (S->crx[b] * S->crx[b] + S->cry[b] * S->cry[b] + S->cz[b] * S->cz[b]));
        }
    }
    return e;
}

/* A body comes to rest. A body of a kind with a down threshold that ever
   passed it is lying, not standing: it leaves play at once, as a potted ball
   does, so nothing rests against a pin that is flat on the deck. */
static void stopBody(struct sim *S, struct seglist *L, int i) {
    closeSeg(S, L, i, S->tnow);
    S->vx0[i] = 0; S->vy0[i] = 0; S->ax[i] = 0; S->ay[i] = 0; S->rx0[i] = 0; S->ry0[i] = 0; S->drx[i] = 0; S->dry[i] = 0; S->z0[i] = 0;
    S->cvx[i] = 0; S->cvy[i] = 0; S->crx[i] = 0; S->cry[i] = 0; S->cz[i] = 0;
    S->px0[i] = S->cx[i]; S->py0[i] = S->cy[i]; S->t0[i] = S->tnow; S->tEnd[i] = HUGE_VAL;
    S->kps[i] = 0; S->tTurn[i] = HUGE_VAL;
    if (S->vf2[i] > 0 && S->peak2[i] > S->vf2[i]) {
        S->mode[i] = POCKETED;
        push_event(S, S->tnow, PB_EV_DOWN, S->ids[i], -1);
        push_down(S, S->ids[i], (long) floor(S->px0[i] * 1e5 + 0.5), (long) floor(S->py0[i] * 1e5 + 0.5), S->tnow);
    } else {
        S->mode[i] = STATIONARY;
        push_event(S, S->tnow, PB_EV_STOP, S->ids[i], -1);
    }
}

/* a down body slowed to a crawl: lying on the deck, out of play now */
static int crawling(const struct sim *S, int b) {
    return (S->mode[b] == SLIDING || S->mode[b] == ROLLING) && S->vf2[b] > 0 && S->peak2[b] > S->vf2[b]
        && S->cvx[b] * S->cvx[b] + S->cvy[b] * S->cvy[b] < STALL * STALL;
}

static double *dalloc(int n) { return (double *) calloc(n > 0 ? n : 1, sizeof(double)); }

void pb_outcome_free(struct pb_outcome *out) {
    if (!out) return;
    free(out->events); free(out->rest); free(out->holed); free(out->segments); free(out->energy);
    free(out->peaks); free(out->downs);
    free(out);
}

/* The v1 entry point: the v1 rows are a v2 layout of kind 0 at their own
   stride, and the shot is a v2 shot with no adjust. */
struct pb_outcome *pb_strike(const struct pb_world *W, int n, const struct pb_ball_in *layout, const struct pb_shot *shot) {
    struct pb_shot2 s2;
    memset(&s2, 0, sizeof s2);
    s2.size = (unsigned int) sizeof s2;
    s2.base = *shot;
    s2.adjust = 0; s2.adjust_mu = 1000; s2.adjust_curve = 1000; s2.adjust_axis = 1; s2.adjust_dir = 1;
    return pb_strike_ex(W, n, (const struct pb_ball_in2 *) (const void *) layout, (int) sizeof(struct pb_ball_in), &s2);
}

struct pb_outcome *pb_strike_ex(const struct pb_world *W, int n, const struct pb_ball_in2 *layout, int layout_stride, const struct pb_shot2 *shot2) {
    struct sim S;
    struct seglist L;
    struct pb_outcome *out;
    const struct pb_shot *shot;
    const char *rowp;
    struct pb_ball_in row;
    int i, j, k, cue, Tball, Tkind, bestK, bestI, bestJ, nc, idx, pass, moved, kind, badkind;
    double T, bestT, t, dx, dy, wx, wy, hx, hy, s0, sv, sa, lam, nx, ny, ux, uy, len, dl, p, speed, sxf, syf, sl;
    int adj = 0, adjusted = 0, adjAxis = 1, adjDir = 1, roll = 0;
    double adjAt = 0, adjMu = 1, adjCurve = 1, rk, rc, rs, rd, rho, wi, wj;

    out = (struct pb_outcome *) calloc(1, sizeof *out);
    if (!out) return NULL;
    /* an ABI 2 consumer's shot stops at adjust_curve and is read as it was */
    if (!shot2 || shot2->size < offsetof(struct pb_shot2, tx) || layout_stride < (int) sizeof(struct pb_ball_in)) { out->error = PB_ERR_SIZE; return out; }
    shot = &shot2->base;
    if (shot2->size >= offsetof(struct pb_shot2, spin) + sizeof(int) && shot2->spin) { roll = 1; }
    if (shot2->adjust) {
        adj = 1;
        adjAt = shot2->adjust_at * 1e-5;
        adjAxis = shot2->adjust_axis ? 1 : 0;
        adjDir = shot2->adjust_dir < 0 ? -1 : 1;
        adjMu = shot2->adjust_mu / 1000.0;
        adjCurve = shot2->adjust_curve / 1000.0;
    }
    S.W = W; S.n = n; S.out = out; S.nev = 0; S.tnow = 0; S.oom = 0; S.nturns = 0;
    S.trace = shot->trace; S.evcap = S.segcap = S.encap = S.holcap = 0;
    S.zrate = 2.5 * W->musp * W->g;
    S.ids = (int *) calloc(n > 0 ? n : 1, sizeof(int));
    S.mode = (signed char *) calloc(n > 0 ? n : 1, 1);
    S.touched = (signed char *) calloc(n > 0 ? n : 1, 1);
    S.t0 = dalloc(n); S.tEnd = dalloc(n); S.px0 = dalloc(n); S.py0 = dalloc(n); S.vx0 = dalloc(n); S.vy0 = dalloc(n);
    S.ax = dalloc(n); S.ay = dalloc(n); S.rx0 = dalloc(n); S.ry0 = dalloc(n); S.drx = dalloc(n); S.dry = dalloc(n); S.z0 = dalloc(n);
    S.cx = dalloc(n); S.cy = dalloc(n); S.cvx = dalloc(n); S.cvy = dalloc(n); S.crx = dalloc(n); S.cry = dalloc(n); S.cz = dalloc(n);
    S.ovx = dalloc(n); S.ovy = dalloc(n);
    S.curve = dalloc(n); S.muscale = dalloc(n); S.curvescale = dalloc(n); S.kps = dalloc(n); S.tTurn = dalloc(n); S.follow = dalloc(n);
    S.rad = dalloc(n); S.rsw = dalloc(n); S.mass = dalloc(n); S.ms = dalloc(n); S.vf2 = dalloc(n); S.peak2 = dalloc(n);
    S.storm = 0; S.stormT0 = 0; S.downcap = 0;
    S.ccap = n * n + 1;
    S.ca = (int *) calloc(S.ccap, sizeof(int)); S.cb = (int *) calloc(S.ccap, sizeof(int));
    S.cnx = dalloc(S.ccap); S.cny = dalloc(S.ccap); S.cv0 = dalloc(S.ccap); S.cj = dalloc(S.ccap);
    S.cki = dalloc(S.ccap); S.ckj = dalloc(S.ccap);
    L.nodes = NULL; L.count = 0; L.cap = 0;
    L.head = (int *) calloc(n > 0 ? n : 1, sizeof(int)); L.tail = (int *) calloc(n > 0 ? n : 1, sizeof(int));
    if (!S.ids || !S.mode || !S.touched || !S.t0 || !S.tEnd || !S.px0 || !S.py0 || !S.vx0 || !S.vy0 || !S.ax || !S.ay
        || !S.rx0 || !S.ry0 || !S.drx || !S.dry || !S.z0 || !S.cx || !S.cy || !S.cvx || !S.cvy || !S.crx || !S.cry || !S.cz
        || !S.ovx || !S.ovy || !S.ca || !S.cb || !S.cnx || !S.cny || !S.cv0 || !S.cj || !L.head || !L.tail
        || !S.curve || !S.muscale || !S.curvescale || !S.kps || !S.tTurn || !S.follow
        || !S.rad || !S.rsw || !S.mass || !S.ms || !S.vf2 || !S.peak2 || !S.cki || !S.ckj) {
        S.oom = 1;
    }

    cue = -1; badkind = 0;
    if (!S.oom) {
        for (i = 0; i < n; i++) {
            /* a row is read through its stride: the v1 prefix always, the
               kind only when the consumer's row is wide enough to hold one */
            rowp = (const char *) layout + (size_t) i * (size_t) layout_stride;
            memcpy(&row, rowp, sizeof row);
            kind = 0;
            if (layout_stride >= (int) (offsetof(struct pb_ball_in2, kind) + sizeof(int))) {
                memcpy(&kind, rowp + offsetof(struct pb_ball_in2, kind), sizeof kind);
            }
            S.ids[i] = row.id;
            S.px0[i] = row.x * 1e-5;
            S.py0[i] = row.y * 1e-5;
            S.mode[i] = STATIONARY;
            S.tEnd[i] = HUGE_VAL;
            S.cx[i] = S.px0[i]; S.cy[i] = S.py0[i];
            L.head[i] = -1; L.tail[i] = -1;
            if (S.ids[i] == shot->ball) { cue = i; }
            if (kind != 0 && (kind < 0 || kind >= W->nk)) { badkind = 1; }
            S.curve[i] = kind < W->nk ? W->kcurve[kind] : 0;
            S.follow[i] = kind < W->nk ? W->kfollow[kind] : 1;
            S.rad[i] = kind < W->nk ? W->kr[kind] : W->R;
            S.rsw[i] = kind < W->nk ? W->krs[kind] : W->R;
            S.mass[i] = kind < W->nk ? W->km[kind] : 1;
            S.ms[i] = kind < W->nk ? W->kmu[kind] : 1;
            S.vf2[i] = kind < W->nk ? W->kvf[kind] * W->kvf[kind] : 0;
            S.peak2[i] = 0;
            S.muscale[i] = 1; S.curvescale[i] = 1; S.kps[i] = 0; S.tTurn[i] = HUGE_VAL;
        }
    }
    if (S.oom) { out->error = PB_ERR_MEMORY; goto done; }
    if (badkind) { out->error = PB_ERR_KIND; goto done; }
    if (cue < 0) { out->error = PB_ERR_NO_BALL; goto done; }

    dl = sqrt((double) shot->dx * (double) shot->dx + (double) shot->dy * (double) shot->dy);
    ux = shot->dx / dl; uy = shot->dy / dl;
    p = shot->power / 1000.0;
    speed = 0.3 + p * p * (W->vmax - 0.3);
    sxf = shot->sx / 1000.0; syf = shot->sy / 1000.0;
    sl = sqrt(sxf * sxf + syf * syf);
    if (sl > 0.5) { sxf = sxf * 0.5 / sl; syf = syf * 0.5 / sl; }
    if (roll) {
        /* the release roll: a direction and a size, so a ball whose roll is not
           along its line slides on a parabola, which is the hook. Not an angle. */
        dl = sqrt((double) shot2->tx * (double) shot2->tx + (double) shot2->ty * (double) shot2->ty);
        sl = shot2->spin / 1000.0 * speed;
        begin(&S, &L, cue, 0, S.px0[cue], S.py0[cue], ux * speed, uy * speed, sl * (double) shot2->tx / dl, sl * (double) shot2->ty / dl, 2.5 * sxf * speed);
    } else {
        begin(&S, &L, cue, 0, S.px0[cue], S.py0[cue], ux * speed, uy * speed, 2.5 * syf * ux * speed, 2.5 * syf * uy * speed, 2.5 * sxf * speed);
    }
    if (S.trace) { push_energy(&S, totalEnergy(&S)); }

    for (;;) {
        T = HUGE_VAL; Tball = -1; Tkind = K_MODE;
        for (i = 0; i < n; i++) {
            if (S.mode[i] == SLIDING || S.mode[i] == ROLLING) {
                evalAt(&S, i, S.tnow);
                if (S.tEnd[i] - S.tnow < T) { T = S.tEnd[i] - S.tnow; Tball = i; Tkind = K_MODE; }
                if (S.tTurn[i] - S.tnow < T) { T = S.tTurn[i] - S.tnow; Tball = i; Tkind = K_TURN; }
            }
        }
        if (Tball < 0) { break; }
        if (T < 0) { T = 0; }
        bestT = T; bestK = Tkind; bestI = Tball; bestJ = -1;

        for (i = 0; i < n; i++) {
            if (S.mode[i] == POCKETED) { continue; }
            for (j = i + 1; j < n; j++) {
                if (S.mode[j] == POCKETED) { continue; }
                if (S.mode[i] == STATIONARY && S.mode[j] == STATIONARY) { continue; }
                dx = S.cx[i] - S.cx[j]; dy = S.cy[i] - S.cy[j];
                wx = S.cvx[i] - S.cvx[j]; wy = S.cvy[i] - S.cvy[j];
                hx = 0.5 * (S.ax[i] - S.ax[j]); hy = 0.5 * (S.ay[i] - S.ay[j]);
                t = pairRoot(dx, dy, wx, wy, hx, hy, reach(&S, i, j), bestT);
                if (t >= 0 && t < bestT) { bestT = t; bestK = K_BALL; bestI = i; bestJ = j; }
            }
        }
        for (i = 0; i < n; i++) {
            if (S.mode[i] != SLIDING && S.mode[i] != ROLLING) { continue; }
            for (k = 0; k < W->nw; k++) {
                nx = W->walls[k * 7 + 5]; ny = W->walls[k * 7 + 6];
                s0 = nx * (S.cx[i] - W->walls[k * 7]) + ny * (S.cy[i] - W->walls[k * 7 + 1]) - S.rad[i];
                /* more than a radius beyond the wall's line is its far side, not
                   inside it: a course has far sides (physics.js says why) */
                if (s0 < -S.rad[i]) { continue; }
                sv = nx * S.cvx[i] + ny * S.cvy[i];
                sa = nx * S.ax[i] + ny * S.ay[i];
                t = lineRoot(s0, sv, sa, bestT);
                if (t < 0 || t >= bestT) { continue; }
                ux = W->walls[k * 7 + 2]; uy = W->walls[k * 7 + 3]; len = W->walls[k * 7 + 4];
                lam = ((S.cx[i] + S.cvx[i] * t + 0.5 * S.ax[i] * t * t - S.rad[i] * nx) - W->walls[k * 7]) * ux
                    + ((S.cy[i] + S.cvy[i] * t + 0.5 * S.ay[i] * t * t - S.rad[i] * ny) - W->walls[k * 7 + 1]) * uy;
                if (lam < 0 || lam > len) { continue; }
                bestT = t; bestK = K_WALL; bestI = i; bestJ = k;
            }
            for (k = 0; k < W->nn; k++) {
                dx = S.cx[i] - W->noses[k * 2]; dy = S.cy[i] - W->noses[k * 2 + 1];
                t = pairRoot(dx, dy, S.cvx[i], S.cvy[i], 0.5 * S.ax[i], 0.5 * S.ay[i], S.rad[i], bestT);
                if (t >= 0 && t < bestT) { bestT = t; bestK = K_NOSE; bestI = i; bestJ = k; }
            }
            for (k = 0; k < W->ng; k++) {
                nx = W->gates[k * 8 + 5]; ny = W->gates[k * 8 + 6];
                s0 = -(nx * (S.cx[i] - W->gates[k * 8]) + ny * (S.cy[i] - W->gates[k * 8 + 1]));
                /* more than a radius beyond a gate's line is not its ball: it
                   crossed already, or it is across a ring of gates */
                if (s0 < -S.rad[i]) { continue; }
                sv = -(nx * S.cvx[i] + ny * S.cvy[i]);
                sa = -(nx * S.ax[i] + ny * S.ay[i]);
                t = lineRoot(s0, sv, sa, bestT);
                if (t < 0 || t >= bestT) { continue; }
                ux = W->gates[k * 8 + 2]; uy = W->gates[k * 8 + 3]; len = W->gates[k * 8 + 4];
                lam = ((S.cx[i] + S.cvx[i] * t + 0.5 * S.ax[i] * t * t) - W->gates[k * 8]) * ux
                    + ((S.cy[i] + S.cvy[i] * t + 0.5 * S.ay[i] * t * t) - W->gates[k * 8 + 1]) * uy;
                if (lam < -S.rad[i] || lam > len + S.rad[i]) { continue; }
                bestT = t; bestK = K_GATE; bestI = i; bestJ = k;
            }
        }
        /* the adjust: the struck ball's centre crossing the line, in the named
           direction, once. A ball already beyond the line never crosses it.
           lineRoot finds only the downward zero, so a crossing the other way
           is not a candidate. */
        if (adj && !adjusted && (S.mode[cue] == SLIDING || S.mode[cue] == ROLLING)) {
            if (adjAxis == 0) { s0 = S.cx[cue]; sv = S.cvx[cue]; sa = S.ax[cue]; }
            else { s0 = S.cy[cue]; sv = S.cvy[cue]; sa = S.ay[cue]; }
            if (adjDir > 0) { s0 = adjAt - s0; sv = -sv; sa = -sa; }
            else { s0 = s0 - adjAt; }
            if (s0 >= 0) {
                t = lineRoot(s0, sv, sa, bestT);
                if (t >= 0 && t < bestT) { bestT = t; bestK = K_ADJUST; bestI = cue; bestJ = -1; }
            }
        }

        S.tnow = S.tnow + bestT;
        i = bestI; j = bestJ;
        if (bestK == K_TURN) {
            /* the rotation: v and r together, through the half-angle tangent
               the law accrued over this segment, in the Cayley form. It does
               no work, creates no slip, and is not an event. */
            evalAt(&S, i, S.tnow);
            rk = S.kps[i] * (S.tnow - S.t0[i]);
            rd = 1 + rk * rk;
            rc = (1 - rk * rk) / rd;
            rs = (2 * rk) / rd;
            begin(&S, &L, i, S.tnow, S.cx[i], S.cy[i], rc * S.cvx[i] - rs * S.cvy[i], rs * S.cvx[i] + rc * S.cvy[i], rc * S.crx[i] - rs * S.cry[i], rs * S.crx[i] + rc * S.cry[i], S.cz[i]);
            S.nturns++;
            if (S.oom) { out->error = PB_ERR_MEMORY; break; }
            if (S.nturns > PB_MAX_TURNS) { out->error = PB_ERR_TURNS; break; }
            if (S.tnow > PB_MAX_TIME) { out->error = PB_ERR_TIME; break; }
            continue;
        }
        /* A down body that has slowed to a crawl is lying on the deck: out of
           play now, not at its eventual stop, or a chain of down pins creeping
           against a standing one costs two thousand resting-contact events.
           Bodies with no down threshold, pool's, never qualify. */
        k = 0;
        if (crawling(&S, i)) { evalAt(&S, i, S.tnow); stopBody(&S, &L, i); k = 1; }
        if (bestK == K_BALL && crawling(&S, j)) { evalAt(&S, j, S.tnow); stopBody(&S, &L, j); k = 1; }
        if (k) {
            if (S.trace) { push_energy(&S, totalEnergy(&S)); }
            S.nev++;
            if (S.oom) { out->error = PB_ERR_MEMORY; break; }
            if (S.nev > PB_MAX_EVENTS) { out->error = PB_ERR_EVENTS; break; }
            continue;
        }
        /* A storm: a hundred events inside ten milliseconds are bodies rattling
           or resting on each other pairwise and undoing each other's fixes (a
           ball wedged between two stopped pins at one instant; a down pin
           rattling between two standing ones, 535 events in ten milliseconds).
           Stop every down body and every body slower than STALL, and carry on.
           Pool's densest window over the fixtures and two hundred full breaks
           is 22 events, so pool never reaches the count. */
        if (S.tnow - S.stormT0 > STORM_T) { S.stormT0 = S.tnow; S.storm = 0; } else { S.storm++; }
        if (S.storm > STORM) {
            for (k = 0; k < n; k++) {
                if (S.mode[k] != SLIDING && S.mode[k] != ROLLING) { continue; }
                if ((S.vf2[k] > 0 && S.peak2[k] > S.vf2[k]) || S.cvx[k] * S.cvx[k] + S.cvy[k] * S.cvy[k] < STALL * STALL) { evalAt(&S, k, S.tnow); stopBody(&S, &L, k); }
            }
            S.storm = 0;
            S.nev++;
            if (S.oom) { out->error = PB_ERR_MEMORY; break; }
            if (S.nev > PB_MAX_EVENTS) { out->error = PB_ERR_EVENTS; break; }
            continue;
        }
        if (bestK == K_ADJUST) {
            evalAt(&S, i, S.tnow);
            S.muscale[i] = adjMu; S.curvescale[i] = adjCurve; adjusted = 1;
            begin(&S, &L, i, S.tnow, S.cx[i], S.cy[i], S.cvx[i], S.cvy[i], S.crx[i], S.cry[i], S.cz[i]);
            push_event(&S, S.tnow, PB_EV_ADJUST, S.ids[i], -1);
        } else if (bestK == K_MODE) {
            evalAt(&S, i, S.tnow);
            if (S.mode[i] == SLIDING) {
                begin(&S, &L, i, S.tnow, S.cx[i], S.cy[i], S.cvx[i], S.cvy[i], S.cvx[i], S.cvy[i], S.cz[i]);
                push_event(&S, S.tnow, PB_EV_ROLL, S.ids[i], -1);
            } else if (S.cvx[i] * S.cvx[i] + S.cvy[i] * S.cvy[i] > ZENO_BB * ZENO_BB) {
                begin(&S, &L, i, S.tnow, S.cx[i], S.cy[i], S.cvx[i], S.cvy[i], S.cvx[i], S.cvy[i], S.cz[i]);
            } else {
                stopBody(&S, &L, i);
            }
        } else if (bestK == K_BALL) {
            evalAt(&S, i, S.tnow); evalAt(&S, j, S.tnow);
            nx = S.cx[j] - S.cx[i]; ny = S.cy[j] - S.cy[i];
            dl = sqrt(nx * nx + ny * ny);
            nx = nx / dl; ny = ny / dl;
            /* contact is at exactly Ri + Rj: a pair that crept inside is set
               apart, the stationary one never moved, a moving pair each by the
               other's share of the mass, exactly a half at equal mass */
            rho = reach(&S, i, j);
            wi = S.mass[j] / (S.mass[i] + S.mass[j]); wj = S.mass[i] / (S.mass[i] + S.mass[j]);
            if (dl < rho) {
                lam = rho - dl;
                if (S.mode[j] == STATIONARY) { S.cx[i] = S.cx[i] - lam * nx; S.cy[i] = S.cy[i] - lam * ny; }
                else if (S.mode[i] == STATIONARY) { S.cx[j] = S.cx[j] + lam * nx; S.cy[j] = S.cy[j] + lam * ny; }
                else { S.cx[i] = S.cx[i] - (lam * wi) * nx; S.cy[i] = S.cy[i] - (lam * wi) * ny; S.cx[j] = S.cx[j] + (lam * wj) * nx; S.cy[j] = S.cy[j] + (lam * wj) * ny; }
            }
            sv = (S.cvx[i] - S.cvx[j]) * nx + (S.cvy[i] - S.cvy[j]) * ny;
            if (sv > ZENO_BB) {
                cluster(&S, &L, i, j, nx, ny, sv);
            } else {
                /* each takes the other's share of the closing speed; the common
                   deceleration is the momentum-weighted one */
                lam = sv > 0 ? sv * wi : 0;
                sl = sv > 0 ? sv * wj : 0;
                begin(&S, &L, i, S.tnow, S.cx[i], S.cy[i], S.cvx[i] - lam * nx, S.cvy[i] - lam * ny, S.crx[i] - lam * nx, S.cry[i] - lam * ny, S.cz[i]);
                begin(&S, &L, j, S.tnow, S.cx[j], S.cy[j], S.cvx[j] + sl * nx, S.cvy[j] + sl * ny, S.crx[j] + sl * nx, S.cry[j] + sl * ny, S.cz[j]);
                s0 = S.ax[i] * nx + S.ay[i] * ny;
                sa = S.ax[j] * nx + S.ay[j] * ny;
                if (S.mode[j] == STATIONARY) {
                    if (s0 > 0) { S.ax[i] = S.ax[i] - s0 * nx; S.ay[i] = S.ay[i] - s0 * ny; }
                } else if (S.mode[i] == STATIONARY) {
                    if (sa < 0) { S.ax[j] = S.ax[j] - sa * nx; S.ay[j] = S.ay[j] - sa * ny; }
                } else if (s0 > sa) {
                    lam = (S.mass[i] * s0 + S.mass[j] * sa) / (S.mass[i] + S.mass[j]);
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
            S.kps[i] = 0; S.tTurn[i] = HUGE_VAL;
            push_event(&S, S.tnow, PB_EV_POT, S.ids[i], (int) W->gates[j * 8 + 7]);
            push_holed(&S, S.ids[i], (int) W->gates[j * 8 + 7], S.tnow);
        }
        if (S.trace) { push_energy(&S, totalEnergy(&S)); }
        S.nev++;
        if (S.oom) { out->error = PB_ERR_MEMORY; break; }
        if (S.nev > PB_MAX_EVENTS) { out->error = PB_ERR_EVENTS; break; }
        if (S.tnow > PB_MAX_TIME) { out->error = PB_ERR_TIME; break; }
    }

    for (i = 0; i < n; i++) {
        if (S.mode[i] == SLIDING || S.mode[i] == ROLLING) { closeSeg(&S, &L, i, S.tnow); }
    }
    /* a down body still moving when the run was cut short leaves play too */
    for (i = 0; i < n; i++) {
        if ((S.mode[i] == SLIDING || S.mode[i] == ROLLING) && S.vf2[i] > 0 && S.peak2[i] > S.vf2[i]) {
            evalAt(&S, i, S.tnow);
            S.mode[i] = POCKETED;
            push_down(&S, S.ids[i], (long) floor(S.cx[i] * 1e5 + 0.5), (long) floor(S.cy[i] * 1e5 + 0.5), S.tnow);
        }
    }
    /* settle: a resting pair that crept inside each other is set apart to
       Ri + Rj, each moved by the other's share of the mass (exactly a half at
       equal mass), in a few passes; physics.js says why */
    for (pass = 0; pass < 8; pass++) {
        moved = 0;
        for (i = 0; i < n; i++) {
            if (S.mode[i] == POCKETED) { continue; }
            for (j = i + 1; j < n; j++) {
                if (S.mode[j] == POCKETED) { continue; }
                dx = S.px0[j] - S.px0[i]; dy = S.py0[j] - S.py0[i];
                dl = sqrt(dx * dx + dy * dy);
                rho = reach(&S, i, j);
                if (dl >= rho || dl == 0) { continue; }
                lam = rho - dl;
                wi = S.mass[j] / (S.mass[i] + S.mass[j]); wj = S.mass[i] / (S.mass[i] + S.mass[j]);
                S.px0[i] = S.px0[i] - (lam * wi) * dx / dl; S.py0[i] = S.py0[i] - (lam * wi) * dy / dl;
                S.px0[j] = S.px0[j] + (lam * wj) * dx / dl; S.py0[j] = S.py0[j] + (lam * wj) * dy / dl;
                moved = 1;
            }
        }
        if (!moved) { break; }
    }

    /* rest and the regrouped segments */
    out->t = S.tnow; out->n = S.nev;
    out->rest = (struct pb_rest *) calloc(n > 0 ? n : 1, sizeof(struct pb_rest));
    nc = 0;
    for (i = 0; i < n; i++) {
        if (S.mode[i] != POCKETED && out->rest) {
            out->rest[nc].id = S.ids[i];
            out->rest[nc].x = (long) floor(S.px0[i] * 1e5 + 0.5);
            out->rest[nc].y = (long) floor(S.py0[i] * 1e5 + 0.5);
            nc++;
        }
    }
    out->nrest = out->rest ? nc : 0;
    out->peaks = (struct pb_peak *) calloc(n > 0 ? n : 1, sizeof(struct pb_peak));
    if (out->peaks) {
        for (i = 0; i < n; i++) { out->peaks[i].id = S.ids[i]; out->peaks[i].v = sqrt(S.peak2[i]); }
        out->npeaks = n;
    } else { out->error = PB_ERR_MEMORY; }
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
    free(S.curve); free(S.muscale); free(S.curvescale); free(S.kps); free(S.tTurn); free(S.follow);
    free(S.rad); free(S.rsw); free(S.mass); free(S.ms); free(S.vf2); free(S.peak2); free(S.cki); free(S.ckj);
    free(L.nodes); free(L.head); free(L.tail);
    return out;
}

static const struct pb_abi PB_TABLE = { PB_ABI_VERSION, pb_world_new, pb_world_free, pb_strike, pb_outcome_free, pb_world_new_ex, pb_strike_ex };

const struct pb_abi *pb_abi_table(void) { return &PB_TABLE; }
