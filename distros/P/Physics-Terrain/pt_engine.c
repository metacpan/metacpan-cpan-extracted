/* pt_engine.c - the field engine, a transliteration of the prototype's
 * fx.js, terrain.js and sim.js.
 *
 * Every expression here is in the same order as the JavaScript it came from
 * (plan_crater/prototype), because the fixtures recorded from those files are
 * the specification and t/03-bitwise.t asks for the same integers. Every
 * product, quotient, shift and modulo on a fixed-point value goes through one
 * of the fx_ helpers, which floor toward minus infinity as the JavaScript's
 * do; intermediates are int64_t so no product can overflow, and the state is
 * checked against a declared box every tick. No floating point, no libm, no
 * clock, no random beyond the engine's own xorshift32. C89: declarations at
 * the top of a block, no //, no variable-length arrays.
 *
 * The JavaScript's names are kept so the files can be read side by side:
 * noiseLayer, generate, walkCells, swept, carve, landing, stepBody, moveX,
 * moveY, land, stepProjectile, bounce, split, explode, hurt, advance.
 */

#include <stdlib.h>
#include <string.h>
#include "pt_abi.h"
#include "pt_sine.h"

typedef int64_t i64;
typedef uint32_t u32;

/* ---- fx.js ---------------------------------------------------------------- */

#define ONE 256
#define Q16 65536
#define BOX ((i64) 1073741824)

static i64 floordiv(i64 n, i64 d) {
    i64 q = n / d, r = n % d;
    if (r != 0 && ((r < 0) != (d < 0))) q -= 1;
    return q;
}
static i64 fx_from(i64 c) { return c * ONE; }
static i64 fx_shr(i64 p) { return floordiv(p, ONE); }
static i64 fx_mul(i64 a, i64 b) { return floordiv(a * b, ONE); }
static i64 fx_imul(i64 a, i64 b) { return a * b; }
static i64 fx_idiv(i64 a, i64 b) { return floordiv(a, b); }
static i64 fx_mod(i64 a, i64 m) { return a - m * floordiv(a, m); }
static i64 fx_abs(i64 a) { return a < 0 ? -a : a; }
static i64 fx_min(i64 a, i64 b) { return a < b ? a : b; }
static i64 fx_max(i64 a, i64 b) { return a > b ? a : b; }
static i64 fx_sign(i64 v) { return v < 0 ? -1 : (v > 0 ? 1 : 0); }
static i64 fx_scale16(i64 v, i64 q) { return floordiv(v * q, Q16); }

static i64 fx_isqrt(i64 n) {
    i64 bit, res = 0;
    if (n < 2) return n;
    bit = 1;
    while (bit * 4 <= n) bit = bit * 4;
    while (bit != 0) {
        if (n >= res + bit) { n = n - res - bit; res = floordiv(res, 2) + bit; }
        else res = floordiv(res, 2);
        bit = floordiv(bit, 4);
    }
    return res;
}

static i64 fx_sin(i64 a) { return pt_sine[fx_mod(a, 4096)]; }
static i64 fx_cos(i64 a) { return pt_sine[fx_mod(a + 1024, 4096)]; }

static u32 xs32(u32 s) {
    s ^= s << 13;
    s ^= s >> 17;
    s ^= s << 5;
    return s;
}
static u32 mix32(u32 h, u32 v) {
    h = h ^ v;
    h = h * 0x85ebca6bu;
    h = h ^ (h >> 13);
    h = h * 0xc2b2ae35u;
    h = h ^ (h >> 16);
    return h;
}
static u32 seed32(u32 seed) {
    u32 s = seed ? seed : 0x9e3779b9u;
    s = mix32(s, 0x2545f491u);
    return s == 0 ? 0x9e3779b9u : s;
}
static i64 rng_below(u32 *s, i64 n) { *s = xs32(*s); return fx_mod((i64) *s, n); }
static i64 rng_between(u32 *s, i64 lo, i64 hi) { *s = xs32(*s); return lo + fx_mod((i64) *s, hi - lo + 1); }

static u32 hash2(u32 seed, i64 x, i64 y, i64 k) {
    u32 h = mix32(seed, (u32) (x + 0x10000));
    h = mix32(h, (u32) (y + 0x10000));
    h = mix32(h, (u32) (k + 0x7f));
    return h & 0xffffu;
}

struct hasher { u32 a, b; };
static void hasher_init(struct hasher *h) { h->a = 0x811c9dc5u; h->b = 0x01000193u; }
static void hasher_add(struct hasher *h, i64 v) {
    u32 lo = (u32) v;
    u32 hi = (u32) floordiv(v, (i64) 4294967296LL);
    h->a = mix32(h->a, lo);
    h->b = mix32((u32) (h->b + 0x9e3779b9u), hi ^ lo);
}

/* ---- growable arrays ------------------------------------------------------ */

struct vec { void *p; int32_t n, cap; size_t sz; };

static int vec_push(struct vec *v, const void *item) {
    if (v->n == v->cap) {
        int32_t ncap = v->cap ? v->cap * 2 : 64;
        void *np = realloc(v->p, (size_t) ncap * v->sz);
        if (!np) return 0;
        v->p = np; v->cap = ncap;
    }
    memcpy((char *) v->p + (size_t) v->n * v->sz, item, v->sz);
    v->n++;
    return 1;
}
static void vec_init(struct vec *v, size_t sz) { v->p = NULL; v->n = 0; v->cap = 0; v->sz = sz; }
static void vec_clear(struct vec *v) { v->n = 0; }
static void vec_drop(struct vec *v) { free(v->p); v->p = NULL; v->n = 0; v->cap = 0; }
static int vec_copy(struct vec *dst, const struct vec *src) {
    vec_clear(dst);
    if (src->n == 0) return 1;
    if (dst->cap < src->n) {
        void *np = realloc(dst->p, (size_t) src->n * src->sz);
        if (!np) return 0;
        dst->p = np; dst->cap = src->n;
    }
    memcpy(dst->p, src->p, (size_t) src->n * src->sz);
    dst->n = src->n;
    return 1;
}

/* ---- weapons.js ------------------------------------------------------------ */

static const struct pt_weapon WEAPONS[] = {
    { "bazooka",  "Bazooka",  PT_KIND_SHELL,   2000, 1, 0,   0,   0,   22, 45, 900,  0,   0, 0,   0 },
    { "grenade",  "Grenade",  PT_KIND_BOUNCE,  1700, 0, 180, 128, 200, 18, 40, 800,  0,   0, 0,   0 },
    { "shotgun",  "Shotgun",  PT_KIND_HITSCAN, 0,    0, 0,   0,   0,   6,  30, 350,  900, 0, 0,   0 },
    { "cluster",  "Cluster",  PT_KIND_CLUSTER, 1900, 1, 55,  0,   0,   10, 12, 400,  0,   5, 200, 240 },
    { "dynamite", "Dynamite", PT_KIND_DROP,    0,    0, 180, 0,   0,   40, 75, 900,  0,   0, 0,   0 },
    { NULL,       "Bomblet",  PT_KIND_SHELL,   0,    1, 0,   0,   0,   9,  18, 450,  0,   0, 0,   0 },
    { NULL,       "Death",    PT_KIND_DEATH,   0,    0, 0,   0,   0,   14, 25, 600,  0,   0, 0,   0 }
};
#define N_WEAPONS 5
#define W_CHILD 5
#define W_DEATH 6

/* ---- the constants of sim.js ---------------------------------------------- */

#define C_G 12
#define C_TERM 2400
#define C_WALK 128
#define C_STEP 3
#define C_JUMP_VY (-300)
#define C_JUMP_VX 130
#define C_BODY_L 4
#define C_BODY_R 3
#define C_BODY_H 12
#define C_BODY_MID 6
#define C_FALL_HURT 700
#define C_FALL_DIV 20
#define C_BOUNCE 64
#define C_BOUNCE_MIN 400
#define C_FRICTION 179
#define C_STOP 24
#define C_KB_REACH 18
#define C_KB_LIFT 3
#define C_DIRECT_D 9
#define C_HP 100
#define C_WIND_MAX 20
#define C_WIND_DIV 16
#define C_OWNER_GRACE 6
#define C_MUZZLE 2560
#define C_REST_V 90
#define C_ROLL_FRICTION 236
#define C_ROLL_STOP 6
#define C_ROLL_NUDGE 24
#define C_MAX_BOUNCES 60
#define C_LADDER 64

/* ---- the state -------------------------------------------------------------- */

struct body { i64 seat, k, x, y, vx, vy, mode, hp, alive, facing, jump_latch, grace; };
struct proj { i64 id, w, x, y, vx, vy, owner, fuse, age, wacc, bounces, resting, alive; };

struct turn {
    i64 active, wind, phase, turn_tick, tick0, shot_tick, last_bits, settled_at;
    int32_t has_shot; struct pt_shot shot; int32_t error;
    struct vec inputs, events, craters, trace_bodies, trace_shots, ladder;
};

struct pt_state {
    struct pt_gen gen;
    int32_t W, H;
    uint8_t *mask, *scorch;
    uint32_t seed;
    u32 rng;
    int32_t teams, per_team;
    int32_t wind_set, wind_override;
    int32_t live_cap, settle_cap;
    int32_t nbodies; struct body bodies[PT_MAX_BODIES];
    int32_t nproj; struct proj proj[PT_MAX_PROJECTILES];
    struct vec craters, graves;
    i64 tick, next_pid;
    int32_t error, oom;
    struct turn turn;
};

struct pt_snapshot {
    int32_t W, H;
    uint8_t *mask, *scorch;
    int32_t nbodies; struct body bodies[PT_MAX_BODIES];
    struct vec craters, graves;
    u32 rng; i64 tick, next_pid;
};

static const struct pt_gen DEFAULT_GEN = { PT_GEN_NOISE, 1280, 640, 64, 16, 32, 44000, 196608, 98304, 31500, 34500, 56, 90, 9, 18, -1 };

/* ---- terrain.js ------------------------------------------------------------ */

static i64 idx(const struct pt_state *f, i64 x, i64 y) { return fx_imul(y, f->W) + x; }

static i64 solid(const struct pt_state *f, i64 x, i64 y) {
    if (x < 0 || y < 0 || x >= f->W || y >= f->H) return 0;
    return f->mask[fx_imul(y, f->W) + x];
}
static void set_cell(struct pt_state *f, i64 x, i64 y, uint8_t v) {
    if (x < 0 || y < 0 || x >= f->W || y >= f->H) return;
    f->mask[fx_imul(y, f->W) + x] = v;
}

static i64 smooth(i64 u, i64 S) {
    i64 uu = fx_imul(u, u);
    i64 t = fx_imul(uu, fx_imul(3, S) - fx_imul(2, u));
    return fx_idiv(t, fx_imul(S, S));
}

static int noise_layer(const struct pt_state *f, u32 seed, i64 S, i64 key, uint16_t *out) {
    i64 W = f->W, H = f->H, gw = fx_idiv(W, S) + 2, gh = fx_idiv(H, S) + 2;
    int32_t *lattice, *gx_of, *su, *sw, *gy_of;
    i64 x, y, gx, gy, u, w, i, row, v00, v10, v01, v11, top, bot, SS = fx_imul(S, S);
    lattice = (int32_t *) malloc(sizeof(int32_t) * (size_t) fx_imul(gw, gh));
    gx_of = (int32_t *) malloc(sizeof(int32_t) * (size_t) W);
    su = (int32_t *) malloc(sizeof(int32_t) * (size_t) W);
    sw = (int32_t *) malloc(sizeof(int32_t) * (size_t) H);
    gy_of = (int32_t *) malloc(sizeof(int32_t) * (size_t) H);
    if (!lattice || !gx_of || !su || !sw || !gy_of) { free(lattice); free(gx_of); free(su); free(sw); free(gy_of); return 0; }
    for (gy = 0; gy < gh; gy++) {
        for (gx = 0; gx < gw; gx++) lattice[fx_imul(gy, gw) + gx] = (int32_t) hash2(seed, gx, gy, key);
    }
    for (x = 0; x < W; x++) { gx_of[x] = (int32_t) fx_idiv(x, S); u = fx_mod(x, S); su[x] = (int32_t) smooth(u, S); }
    for (y = 0; y < H; y++) { gy_of[y] = (int32_t) fx_idiv(y, S); w = fx_mod(y, S); sw[y] = (int32_t) smooth(w, S); }
    for (y = 0; y < H; y++) {
        gy = gy_of[y]; w = sw[y]; row = fx_imul(gy, gw);
        i = fx_imul(y, W);
        for (x = 0; x < W; x++) {
            gx = gx_of[x]; u = su[x];
            v00 = lattice[row + gx]; v10 = lattice[row + gx + 1];
            v01 = lattice[row + gw + gx]; v11 = lattice[row + gw + gx + 1];
            top = fx_imul(v00, S - u) + fx_imul(v10, u);
            bot = fx_imul(v01, S - u) + fx_imul(v11, u);
            out[i + x] = (uint16_t) fx_idiv(fx_imul(top, S - w) + fx_imul(bot, w), SS);
        }
    }
    free(lattice); free(gx_of); free(su); free(sw); free(gy_of);
    return 1;
}

static void box_set(struct pt_state *f, i64 x0, i64 y0, i64 x1, i64 y1, uint8_t v) {
    i64 x, y, i;
    x0 = fx_max(x0, 0); y0 = fx_max(y0, 0); x1 = fx_min(x1, f->W - 1); y1 = fx_min(y1, f->H - 1);
    for (y = y0; y <= y1; y++) {
        i = fx_imul(y, f->W);
        for (x = x0; x <= x1; x++) f->mask[i + x] = v;
    }
}
static void fill_box(struct pt_state *f, i64 x0, i64 y0, i64 x1, i64 y1) { box_set(f, x0, y0, x1, y1, 1); }
static void clear_box(struct pt_state *f, i64 x0, i64 y0, i64 x1, i64 y1) { box_set(f, x0, y0, x1, y1, 0); }

static void slope(struct pt_state *f, i64 x0, i64 y0, i64 x1, i64 y1) {
    i64 x, y, dx = x1 - x0, dy = y1 - y0, top;
    if (dx == 0) { fill_box(f, x0, fx_min(y0, y1), x0, f->H - 1); return; }
    for (x = fx_min(x0, x1); x <= fx_max(x0, x1); x++) {
        top = y0 + fx_idiv(fx_imul(dy, x - x0), dx);
        for (y = fx_max(top, 0); y < f->H; y++) set_cell(f, x, y, 1);
    }
}

static void platform(struct pt_state *f, i64 x, i64 y, i64 half_w, i64 headroom) {
    clear_box(f, x - half_w, y - headroom, x + half_w, y - 1);
    fill_box(f, x - half_w, y, x + half_w, y + 4);
}

static i64 carve(struct pt_state *f, i64 cx, i64 cy, i64 r, int quiet) {
    i64 dx, dy, rr = fx_imul(r, r), cleared = 0, x, y, i, sr = fx_imul(r + 3, r + 3), d2;
    for (dy = -r - 3; dy <= r + 3; dy++) {
        y = cy + dy;
        if (y < 0 || y >= f->H) continue;
        i = fx_imul(y, f->W);
        for (dx = -r - 3; dx <= r + 3; dx++) {
            x = cx + dx;
            if (x < 0 || x >= f->W) continue;
            d2 = fx_imul(dx, dx) + fx_imul(dy, dy);
            if (d2 <= rr) {
                if (f->mask[i + x]) { cleared++; f->mask[i + x] = 0; }
            } else if (d2 <= sr && !quiet && f->mask[i + x]) {
                f->scorch[i + x] = 1;
            }
        }
    }
    return cleared;
}

static void sculpt(struct pt_state *f, int32_t n, const struct pt_sculpt *ops) {
    int32_t k;
    for (k = 0; k < n; k++) {
        const struct pt_sculpt *op = &ops[k];
        switch (op->op) {
            case PT_OP_FILL:     fill_box(f, op->a, op->b, op->c, op->d); break;
            case PT_OP_CLEAR:    clear_box(f, op->a, op->b, op->c, op->d); break;
            case PT_OP_SLOPE:    slope(f, op->a, op->b, op->c, op->d); break;
            case PT_OP_DISC:     carve(f, op->a, op->b, op->c, 1); break;
            case PT_OP_PLATFORM: platform(f, op->a, op->b, op->c, op->d); break;
            default: break;
        }
    }
}

/* walkCells: the cells of the segment, both ends included; a diagonal step
 * visits the two cells it cuts between first. visit returns nonzero to stop */
struct walk_ctx { const struct pt_state *s; i64 owner; int owner_counts; i64 hx, hy, hpx, hpy; int kind; i64 body; };

static int walk_cells(i64 x0, i64 y0, i64 x1, i64 y1, int (*visit)(struct walk_ctx *, i64, i64, i64, i64), struct walk_ctx *ctx) {
    i64 dx = fx_abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
    i64 dy = -fx_abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
    i64 err = dx + dy, e2, x = x0, y = y0, px = x0, py = y0;
    int r, step_x, step_y;
    for (;;) {
        r = visit(ctx, x, y, px, py);
        if (r) return r;
        if (x == x1 && y == y1) return 0;
        px = x; py = y;
        e2 = err + err;
        step_x = e2 >= dy; step_y = e2 <= dx;
        if (step_x && step_y) {
            r = visit(ctx, x + sx, y, px, py);
            if (r) return r;
            r = visit(ctx, x, y + sy, px, py);
            if (r) return r;
        }
        if (step_x) { err += dy; x += sx; }
        if (step_y) { err += dx; y += sy; }
    }
}

static int visit_solid(struct walk_ctx *c, i64 x, i64 y, i64 px, i64 py) {
    if (solid(c->s, x, y)) { c->hx = x; c->hy = y; c->hpx = px; c->hpy = py; return 1; }
    return 0;
}

/* swept: the first solid cell on the segment, or none; hpx,hpy the last free cell */
static int swept(const struct pt_state *s, i64 x0, i64 y0, i64 x1, i64 y1, struct walk_ctx *c) {
    memset(c, 0, sizeof *c);
    c->s = s;
    if (walk_cells(x0, y0, x1, y1, visit_solid, c)) return 1;
    c->hx = x1; c->hy = y1; c->hpx = x1; c->hpy = y1;
    return 0;
}

static int box_free(const struct pt_state *f, i64 x0, i64 y0, i64 x1, i64 y1) {
    i64 x, y, i;
    if (x1 < 0 || y1 < 0 || x0 >= f->W || y0 >= f->H) return 1;
    x0 = fx_max(x0, 0); y0 = fx_max(y0, 0); x1 = fx_min(x1, f->W - 1); y1 = fx_min(y1, f->H - 1);
    for (y = y0; y <= y1; y++) {
        i = fx_imul(y, f->W);
        for (x = x0; x <= x1; x++) if (f->mask[i + x]) return 0;
    }
    return 1;
}

static i64 surface_at(const struct pt_state *f, i64 x, i64 y_from) {
    i64 y;
    for (y = fx_max(y_from, 0); y < f->H; y++) if (solid(f, x, y)) return y;
    return -1;
}

/* landing: n spots spread across the field, each a flat stand; spots[k][0..1] = x, ground row */
static void landing(struct pt_state *f, u32 *rng, i64 n, i64 half_w, i64 headroom, int32_t *spots) {
    i64 k, lane, x = 0, y, tries, best, y_top;
    lane = fx_idiv(f->W - fx_imul(half_w, 4), n);
    for (k = 0; k < n; k++) {
        best = -1;
        for (tries = 0; tries < 6 && best < 0; tries++) {
            x = fx_imul(half_w, 2) + fx_imul(lane, k) + rng_below(rng, fx_max(lane - fx_imul(half_w, 2), 1));
            y_top = fx_idiv(fx_imul(f->H, 20), 100);
            y = surface_at(f, x, y_top);
            if (y >= 0 && y < fx_idiv(fx_imul(f->H, 92), 100)) best = y;
        }
        if (best < 0) best = fx_idiv(fx_imul(f->H, 60), 100);
        platform(f, x, best, half_w, headroom);
        spots[k * 2] = (int32_t) x; spots[k * 2 + 1] = (int32_t) best;
    }
}

static int generate(struct pt_state *f, uint32_t seed, const struct pt_gen *o) {
    i64 W, H, x, y, i, n, bias, cave_top, cave_bottom;
    uint16_t *n1, *n2, *n3;
    W = o->W; H = o->H;
    f->W = (int32_t) W; f->H = (int32_t) H;
    f->mask = (uint8_t *) calloc((size_t) fx_imul(W, H), 1);
    f->scorch = (uint8_t *) calloc((size_t) fx_imul(W, H), 1);
    if (!f->mask || !f->scorch) return 0;
    f->seed = seed; f->gen = *o;
    if (o->profile == PT_GEN_EMPTY) return 1;
    if (o->profile == PT_GEN_FLAT) {
        fill_box(f, 0, o->floor < 0 ? fx_idiv(fx_imul(H, 5), 8) : o->floor, W - 1, H - 1);
        return 1;
    }
    n1 = (uint16_t *) malloc(sizeof(uint16_t) * (size_t) fx_imul(W, H));
    n2 = (uint16_t *) malloc(sizeof(uint16_t) * (size_t) fx_imul(W, H));
    n3 = (uint16_t *) malloc(sizeof(uint16_t) * (size_t) fx_imul(W, H));
    if (!n1 || !n2 || !n3 || !noise_layer(f, seed, o->coarse, 1, n1) || !noise_layer(f, seed, o->fine, 2, n2) || !noise_layer(f, seed, o->cave, 3, n3)) {
        free(n1); free(n2); free(n3);
        return 0;
    }
    cave_top = fx_idiv(fx_imul(H, o->cave_top), 100);
    cave_bottom = fx_idiv(fx_imul(H, o->cave_bottom), 100);
    for (y = 0; y < H; y++) {
        bias = fx_idiv(fx_imul(y, o->bias_scale), H) - o->bias_offset;
        i = fx_imul(y, W);
        for (x = 0; x < W; x++) {
            n = fx_idiv(fx_imul(n1[i + x], 3) + n2[i + x], 4);
            if (n + bias >= o->threshold) {
                if (y >= cave_top && y < cave_bottom && n3[i + x] >= o->cave_lo && n3[i + x] <= o->cave_hi) f->mask[i + x] = 0;
                else f->mask[i + x] = 1;
            }
        }
    }
    free(n1); free(n2); free(n3);
    return 1;
}

/* ---- sim.js: bodies and the box ------------------------------------------- */

static i64 cell_x(const struct body *b) { return fx_shr(b->x); }
static i64 cell_y(const struct body *b) { return fx_shr(b->y); }
static i64 top_row(i64 y) { return fx_shr(y) - C_BODY_H; }
static i64 bottom_row(i64 y) { return fx_shr(y - 1); }

static int box_free_at(const struct pt_state *s, i64 cx, i64 y) {
    return box_free(s, cx - C_BODY_L, top_row(y), cx + C_BODY_R, bottom_row(y));
}
static int row_solid_at(const struct pt_state *s, i64 cx, i64 row) {
    return !box_free(s, cx - C_BODY_L, row, cx + C_BODY_R, row);
}
static int grounded(const struct pt_state *s, const struct body *b) { return row_solid_at(s, cell_x(b), fx_shr(b->y)); }

static int box_has(const struct body *b, i64 X, i64 Y) {
    i64 cx = cell_x(b);
    return X >= cx - C_BODY_L && X <= cx + C_BODY_R && Y >= top_row(b->y) && Y <= bottom_row(b->y);
}

static i64 add_body(struct pt_state *s, i64 seat, i64 cx, i64 cy) {
    struct body *b;
    int32_t i;
    if (s->nbodies >= PT_MAX_BODIES) { s->error = PT_ERR_BODIES; return -1; }
    b = &s->bodies[s->nbodies];
    memset(b, 0, sizeof *b);
    b->seat = seat; b->x = fx_from(cx) + 128; b->y = fx_from(cy); b->mode = PT_STANDING;
    b->hp = C_HP; b->alive = 1; b->facing = 1;
    for (i = 0; i < s->nbodies; i++) if (s->bodies[i].seat == seat) b->k++;
    s->nbodies++;
    return s->nbodies - 1;
}

static void place_bodies(struct pt_state *s, int32_t n, const struct pt_body_in *list) {
    int32_t k;
    i64 cy, i;
    for (k = 0; k < n; k++) {
        cy = surface_at(s, list[k].cx, list[k].cy_from);
        if (cy < 0) cy = s->H - 1;
        i = add_body(s, list[k].seat, list[k].cx, cy);
        if (i >= 0 && list[k].hp > 0) s->bodies[i].hp = list[k].hp;
    }
}

static int place_teams(struct pt_state *s) {
    i64 n = fx_imul(s->teams, s->per_team), i, j, t, k, tmp;
    int32_t *spots, *order;
    if (n > PT_MAX_BODIES) { s->error = PT_ERR_BODIES; return 0; }
    spots = (int32_t *) malloc(sizeof(int32_t) * (size_t) (n ? n * 2 : 1));
    order = (int32_t *) malloc(sizeof(int32_t) * (size_t) (n ? n : 1));
    if (!spots || !order) { free(spots); free(order); return 0; }
    landing(s, &s->rng, n, s->gen.platform, s->gen.headroom, spots);
    for (i = 0; i < n; i++) order[i] = (int32_t) i;
    for (i = n - 1; i > 0; i--) {
        j = rng_below(&s->rng, i + 1);
        tmp = order[i]; order[i] = order[j]; order[j] = (int32_t) tmp;
    }
    for (t = 0; t < s->teams; t++) {
        for (k = 0; k < s->per_team; k++) {
            i = order[fx_imul(t, s->per_team) + k];
            add_body(s, t, spots[i * 2], spots[i * 2 + 1]);
        }
    }
    free(spots); free(order);
    return 1;
}

/* ---- the turn ---------------------------------------------------------------- */

static void turn_init(struct turn *t) {
    memset(t, 0, sizeof *t);
    vec_init(&t->inputs, sizeof(struct pt_input));
    vec_init(&t->events, sizeof(struct pt_event));
    vec_init(&t->craters, sizeof(struct pt_crater));
    vec_init(&t->trace_bodies, sizeof(struct pt_trace));
    vec_init(&t->trace_shots, sizeof(struct pt_trace));
    vec_init(&t->ladder, sizeof(struct pt_ladder));
    t->phase = PT_PHASE_IDLE;
}
static void turn_drop(struct turn *t) {
    vec_drop(&t->inputs); vec_drop(&t->events); vec_drop(&t->craters);
    vec_drop(&t->trace_bodies); vec_drop(&t->trace_shots); vec_drop(&t->ladder);
}

static void event(struct pt_state *s, i64 kind, i64 a, i64 b) {
    struct pt_event e;
    e.tick = (int32_t) s->turn.turn_tick; e.kind = (int32_t) kind; e.a = (int32_t) a; e.b = (int32_t) b;
    if (!vec_push(&s->turn.events, &e)) s->oom = 1;
}
static void trace_row(struct pt_state *s, struct vec *v, i64 who, i64 x, i64 y, i64 weapon) {
    struct pt_trace r;
    r.who = (int32_t) who; r.tick = (int32_t) s->turn.turn_tick; r.x = (int32_t) x; r.y = (int32_t) y; r.weapon = (int32_t) weapon;
    if (!vec_push(v, &r)) s->oom = 1;
}

static void hash_state(const struct pt_state *s, uint32_t out[2]) {
    struct hasher h;
    int32_t i;
    const struct body *b;
    const struct proj *p;
    hasher_init(&h);
    hasher_add(&h, s->tick); hasher_add(&h, s->turn.phase == PT_PHASE_IDLE ? 0 : s->turn.wind); hasher_add(&h, s->craters.n);
    for (i = 0; i < s->nbodies; i++) {
        b = &s->bodies[i];
        hasher_add(&h, b->x); hasher_add(&h, b->y); hasher_add(&h, b->vx); hasher_add(&h, b->vy);
        hasher_add(&h, b->mode); hasher_add(&h, b->hp); hasher_add(&h, b->alive); hasher_add(&h, b->facing);
    }
    for (i = 0; i < s->nproj; i++) {
        p = &s->proj[i];
        if (!p->alive) continue;
        hasher_add(&h, p->x); hasher_add(&h, p->y); hasher_add(&h, p->vx); hasher_add(&h, p->vy); hasher_add(&h, p->fuse); hasher_add(&h, p->wacc);
    }
    out[0] = h.a; out[1] = h.b;
}

static int32_t start_turn(struct pt_state *s, i64 active) {
    struct turn *t = &s->turn;
    if (active < 0 || active >= s->nbodies) return -PT_ERR_STATE;
    vec_clear(&t->inputs); vec_clear(&t->events); vec_clear(&t->craters);
    vec_clear(&t->trace_bodies); vec_clear(&t->trace_shots); vec_clear(&t->ladder);
    t->active = active;
    t->wind = s->wind_set ? s->wind_override : rng_between(&s->rng, -C_WIND_MAX, C_WIND_MAX);
    t->phase = PT_PHASE_LIVE; t->turn_tick = 0; t->tick0 = s->tick; t->has_shot = 0; t->shot_tick = -1;
    t->error = PT_OK; t->settled_at = -1; t->last_bits = 0;
    s->nproj = 0;
    s->bodies[active].grace = 0;
    return (int32_t) t->wind;
}

static int settled(const struct pt_state *s) {
    int32_t i;
    for (i = 0; i < s->nproj; i++) if (s->proj[i].alive) return 0;
    for (i = 0; i < s->nbodies; i++) {
        if (s->bodies[i].alive && (s->bodies[i].mode == PT_FALLING || s->bodies[i].mode == PT_FLYING)) return 0;
    }
    return 1;
}

/* ---- firing ------------------------------------------------------------------ */

static struct proj *spawn(struct pt_state *s, i64 w, i64 x, i64 y, i64 vx, i64 vy, i64 owner, i64 fuse) {
    struct proj *p;
    if (s->nproj >= PT_MAX_PROJECTILES) { s->turn.error = PT_ERR_PROJECTILES; return NULL; }
    p = &s->proj[s->nproj++];
    memset(p, 0, sizeof *p);
    p->id = s->next_pid++; p->w = w; p->x = x; p->y = y; p->vx = vx; p->vy = vy; p->owner = owner; p->fuse = fuse; p->alive = 1;
    trace_row(s, &s->turn.trace_shots, p->id, x, y, w == W_CHILD ? -2 : w);
    return p;
}

static int visit_cast(struct walk_ctx *c, i64 x, i64 y, i64 px, i64 py) {
    int32_t i;
    const struct body *b;
    (void) px; (void) py;
    if (c->kind == 1 && x == c->hx && y == c->hy) { c->kind = 3; return 1; }
    for (i = 0; i < c->s->nbodies; i++) {
        b = &c->s->bodies[i];
        if (!b->alive) continue;
        if (i == c->owner && !c->owner_counts) continue;
        if (box_has(b, x, y)) { c->kind = 2; c->body = i; c->hx = x; c->hy = y; return 1; }
    }
    return 0;
}

/* cast: kind 0 none, 2 a body at hx,hy, 3 terrain at hx,hy with hpx,hpy the last free cell */
static void cast(const struct pt_state *s, i64 x0, i64 y0, i64 x1, i64 y1, i64 owner, int owner_counts, struct walk_ctx *c) {
    struct walk_ctx sw;
    int hit = swept(s, x0, y0, x1, y1, &sw);
    memset(c, 0, sizeof *c);
    c->s = s; c->owner = owner; c->owner_counts = owner_counts;
    c->kind = hit ? 1 : 0;
    c->hx = sw.hx; c->hy = sw.hy; c->hpx = sw.hpx; c->hpy = sw.hpy;
    if (walk_cells(x0, y0, x1, y1, visit_cast, c)) return;
    c->kind = 0; c->hx = x1; c->hy = y1;
}

static void explode(struct pt_state *s, i64 x, i64 y, i64 w, i64 owner, i64 hx, i64 hy);

static void hitscan(struct pt_state *s, i64 w, i64 cx, i64 cy, i64 angle, i64 owner) {
    const struct pt_weapon *wp = &WEAPONS[w];
    i64 ex = cx + fx_scale16(fx_from(wp->range), fx_cos(angle));
    i64 ey = cy + fx_scale16(fx_from(wp->range), -fx_sin(angle));
    i64 hx, hy, pid = 0, i;
    struct walk_ctx r;
    const struct pt_trace *rows;
    cast(s, fx_shr(cx), fx_shr(cy), fx_shr(ex), fx_shr(ey), owner, 0, &r);
    if (r.kind == 2) { hx = fx_from(r.hx) + 128; hy = fx_from(r.hy) + 128; }
    else if (r.kind == 3) { hx = fx_from(r.hpx) + 128; hy = fx_from(r.hpy) + 128; }
    else { hx = ex; hy = ey; }
    event(s, PT_EV_RAY, fx_shr(hx), fx_shr(hy));
    rows = (const struct pt_trace *) s->turn.trace_shots.p;
    for (i = 0; i < s->turn.trace_shots.n; i++) if (rows[i].who + 1 > pid) pid = rows[i].who + 1;
    trace_row(s, &s->turn.trace_shots, pid, cx, cy, w);
    trace_row(s, &s->turn.trace_shots, pid, hx, hy, w);
    if (r.kind == 2) event(s, PT_EV_HIT, r.body, -1);
    if (r.kind != 0) explode(s, hx, hy, w, owner, ex - cx, ey - cy);
    else event(s, PT_EV_LOST, -1, 0);
}

static int fire(struct pt_state *s, const struct pt_shot *shot) {
    struct turn *t = &s->turn;
    struct body *b = &s->bodies[t->active];
    i64 w = shot->weapon, angle, power, speed, cx, cy, sx, sy, px, py;
    const struct pt_weapon *wp;
    struct walk_ctx sw;
    if (w < 0 || w >= N_WEAPONS) { t->error = PT_ERR_WEAPON; t->phase = PT_PHASE_DONE; event(s, PT_EV_ERROR, 0, 0); return 0; }
    wp = &WEAPONS[w];
    angle = fx_mod(shot->angle, 4096);
    power = fx_max(1, fx_min(100, shot->power));
    t->has_shot = 1; t->shot.weapon = (int32_t) w; t->shot.angle = (int32_t) angle; t->shot.power = (int32_t) power;
    t->shot_tick = t->turn_tick;
    t->phase = PT_PHASE_SETTLE;
    if (fx_cos(angle) < 0) b->facing = -1; else if (fx_cos(angle) > 0) b->facing = 1;
    event(s, PT_EV_FIRE, w, t->active);
    cx = b->x; cy = b->y - fx_from(C_BODY_MID);
    if (wp->kind == PT_KIND_DROP) {
        spawn(s, w, b->x, b->y - fx_from(2), fx_imul(b->facing, 20), -40, t->active, wp->fuse);
        return 1;
    }
    if (wp->kind == PT_KIND_HITSCAN) {
        hitscan(s, w, cx, cy, angle, t->active);
        return 1;
    }
    speed = fx_idiv(fx_imul(wp->speed_max, power), 100);
    sx = fx_scale16(speed, fx_cos(angle));
    sy = fx_scale16(speed, -fx_sin(angle));
    px = cx + fx_scale16(C_MUZZLE, fx_cos(angle));
    py = cy + fx_scale16(C_MUZZLE, -fx_sin(angle));
    if (swept(s, fx_shr(cx), fx_shr(cy), fx_shr(px), fx_shr(py), &sw)) { px = fx_from(sw.hpx) + 128; py = fx_from(sw.hpy) + 128; }
    spawn(s, w, px, py, sx, sy, t->active, wp->fuse);
    return 1;
}

/* ---- the tick ------------------------------------------------------------------ */

static void hurt(struct pt_state *s, struct body *b, i64 idx_, i64 dmg, int32_t *dead, int32_t *ndead);
static void death_blast(struct pt_state *s, i64 idx_);

static void land(struct pt_state *s, struct body *b, i64 idx_, i64 vy) {
    if (vy > C_FALL_HURT) {
        event(s, PT_EV_LAND, idx_, vy);
        hurt(s, b, idx_, fx_idiv(vy - C_FALL_HURT, C_FALL_DIV), NULL, NULL);
        if (!b->alive) return;
    }
    if (b->mode == PT_FLYING && vy > C_BOUNCE_MIN) {
        b->vy = -fx_mul(vy, C_BOUNCE);
        b->vx = fx_mul(b->vx, C_FRICTION);
        return;
    }
    b->vy = 0;
    b->vx = fx_mul(b->vx, C_FRICTION);
    if (fx_abs(b->vx) < C_STOP) { b->vx = 0; b->mode = PT_STANDING; }
}

static void move_x(struct pt_state *s, struct body *b) {
    i64 nx = b->x + b->vx, cx = cell_x(b), ncx = fx_shr(nx), dir = fx_sign(ncx - cx), c;
    if (b->vx == 0) return;
    if (ncx == cx) { b->x = nx; return; }
    for (c = cx + dir; c != ncx + dir; c += dir) {
        if (!box_free_at(s, c, b->y)) {
            b->x = dir > 0 ? fx_from(c - 1) + 255 : fx_from(c);
            b->vx = b->mode == PT_FLYING ? -fx_mul(b->vx, C_BOUNCE) : 0;
            return;
        }
    }
    b->x = nx;
}

static void move_y(struct pt_state *s, struct body *b, i64 idx_) {
    i64 ny = b->y + b->vy, cx = cell_x(b), r, vy = b->vy;
    if (b->vy > 0) {
        for (r = bottom_row(b->y) + 1; r <= fx_shr(ny); r++) {
            if (row_solid_at(s, cx, r)) { b->y = fx_from(r); land(s, b, idx_, vy); return; }
        }
        b->y = ny;
        return;
    }
    if (b->vy < 0) {
        for (r = top_row(b->y) - 1; r >= top_row(ny); r--) {
            if (row_solid_at(s, cx, r)) { b->y = fx_from(r + 1 + C_BODY_H); b->vy = 0; return; }
        }
        b->y = ny;
        return;
    }
    if (grounded(s, b)) land(s, b, idx_, 0);
}

static void die_out(struct pt_state *s, struct body *b, i64 idx_) {
    if (!b->alive) return;
    b->alive = 0; b->hp = 0;
    event(s, PT_EV_DIE, idx_, 1);
    event(s, PT_EV_OUT, idx_, 0);
}

static void step_body(struct pt_state *s, struct body *b, i64 idx_, i64 bits) {
    i64 dx, cx, cy, ncx, k, moved, before = b->mode, was_y = b->y, was_x = b->x;
    if (b->mode == PT_STANDING || b->mode == PT_WALKING) {
        b->mode = PT_STANDING;
        if (bits & (PT_LEFT | PT_RIGHT)) {
            dx = (bits & PT_LEFT) ? -C_WALK : C_WALK;
            b->facing = dx < 0 ? -1 : 1;
            cx = cell_x(b); ncx = fx_shr(b->x + dx);
            moved = 0;
            if (ncx == cx) { b->x += dx; moved = 1; }
            else {
                for (k = 0; k <= C_STEP; k++) {
                    if (box_free_at(s, ncx, b->y - fx_from(k))) { b->x += dx; b->y -= fx_from(k); moved = 1; break; }
                }
            }
            if (moved) {
                b->mode = PT_WALKING;
                cx = cell_x(b); cy = cell_y(b);
                if (!row_solid_at(s, cx, cy)) {
                    for (k = 1; k <= C_STEP; k++) {
                        if (row_solid_at(s, cx, cy + k)) { b->y += fx_from(k); break; }
                    }
                }
            }
        }
        if (bits & PT_JUMP) {
            if (!b->jump_latch) {
                b->jump_latch = 1;
                b->vy = C_JUMP_VY; b->vx = fx_imul(b->facing, C_JUMP_VX); b->mode = PT_FLYING;
                event(s, PT_EV_JUMP, idx_, 0);
            }
        } else b->jump_latch = 0;
        if (b->mode != PT_FLYING && !grounded(s, b)) { b->mode = PT_FALLING; b->vy = 0; b->vx = 0; }
    }
    if (b->mode == PT_FALLING || b->mode == PT_FLYING) {
        b->vy = fx_min(b->vy + C_G, C_TERM);
        move_x(s, b);
        move_y(s, b, idx_);
    }
    if (b->alive && b->y >= fx_from(s->H)) { die_out(s, b, idx_); return; }
    if (b->alive && (cell_x(b) + C_BODY_R < 0 || cell_x(b) - C_BODY_L >= s->W)) { die_out(s, b, idx_); return; }
    if (b->mode != PT_STANDING || before != PT_STANDING || b->x != was_x || b->y != was_y) {
        trace_row(s, &s->turn.trace_bodies, idx_, b->x, b->y, -1);
    }
}

static void detonate(struct pt_state *s, struct proj *p) {
    p->alive = 0;
    explode(s, p->x, p->y, p->w, p->owner, p->vx, p->vy);
}

static void bounce(struct pt_state *s, struct proj *p, const struct walk_ctx *r) {
    const struct pt_weapon *w = &WEAPONS[p->w];
    int across_x = r->hx != r->hpx, across_y = r->hy != r->hpy, flip_x = 0, flip_y = 0;
    i64 bnc = w->bounce ? w->bounce : 128, fr = w->friction ? w->friction : 200;
    if (across_x && !across_y) flip_x = 1;
    else if (across_y && !across_x) flip_y = 1;
    else {
        if (solid(s, r->hx, r->hpy)) flip_x = 1;
        if (solid(s, r->hpx, r->hy)) flip_y = 1;
        if (!flip_x && !flip_y) { flip_x = 1; flip_y = 1; }
    }
    if (flip_x) { p->vx = -fx_mul(p->vx, bnc); p->vy = fx_mul(p->vy, fr); }
    if (flip_y) {
        if (p->vy > 0 && p->vy < C_REST_V) { p->vy = 0; p->resting = 1; }
        else { p->vy = -fx_mul(p->vy, bnc); p->vx = fx_mul(p->vx, fr); }
    }
    p->bounces++;
    if (!p->resting || flip_x) event(s, PT_EV_BOUNCE, fx_shr(p->x), fx_shr(p->y));
    if (p->bounces > C_MAX_BOUNCES && !p->resting) detonate(s, p);
}

static void split(struct pt_state *s, struct proj *p) {
    const struct pt_weapon *w = &WEAPONS[p->w];
    i64 k, n = w->count, mid, px = p->x, py = p->y, pvx = p->vx, pvy = p->vy, owner = p->owner;
    struct proj *c;
    p->alive = 0;
    event(s, PT_EV_SPLIT, fx_shr(p->x), fx_shr(p->y));
    mid = fx_idiv(n, 2);
    for (k = 0; k < n; k++) {
        c = spawn(s, W_CHILD, px, py, pvx + fx_imul(k - mid, w->spread), pvy - w->pop, owner, 0);
        if (!c) return;
        c->age = C_OWNER_GRACE + 1;
    }
}

static void step_projectile(struct pt_state *s, int32_t pi) {
    struct proj *p = &s->proj[pi];
    const struct pt_weapon *w = &WEAPONS[p->w];
    i64 nx, ny, cx, cy;
    struct walk_ctx r;
    p->age++;
    cx = fx_shr(p->x); cy = fx_shr(p->y);
    if (p->resting) {
        if (solid(s, cx, cy + 1)) {
            p->vx = fx_mul(p->vx, C_ROLL_FRICTION);
            if (fx_abs(p->vx) < C_ROLL_STOP) p->vx = 0;
            p->vy = 0;
            if (p->vx <= 0 && !solid(s, cx - 1, cy + 1) && !solid(s, cx - 1, cy)) { p->vx -= C_ROLL_NUDGE; p->resting = 0; }
            else if (p->vx >= 0 && !solid(s, cx + 1, cy + 1) && !solid(s, cx + 1, cy)) { p->vx += C_ROLL_NUDGE; p->resting = 0; }
        } else p->resting = 0;
    }
    if (!p->resting) p->vy = fx_min(p->vy + C_G, C_TERM);
    if (w->wind) {
        p->wacc += s->turn.wind;
        p->vx += fx_idiv(p->wacc, C_WIND_DIV);
        p->wacc = fx_mod(p->wacc, C_WIND_DIV);
    }
    nx = p->x + p->vx; ny = p->y + p->vy;
    cast(s, cx, cy, fx_shr(nx), fx_shr(ny), p->owner, w->kind != PT_KIND_DROP && p->age > C_OWNER_GRACE, &r);
    if (r.kind == 2) {
        p->x = fx_from(r.hx) + 128; p->y = fx_from(r.hy) + 128;
        event(s, PT_EV_HIT, r.body, p->id);
        detonate(s, p);
        return;
    }
    if (r.kind == 3) {
        p->x = fx_from(r.hpx) + 128; p->y = fx_from(r.hpy) + 128;
        if (w->kind == PT_KIND_BOUNCE || w->kind == PT_KIND_DROP) {
            bounce(s, p, &r);
            if (!p->alive) return;
        } else {
            detonate(s, p);
            return;
        }
    } else {
        p->x = nx; p->y = ny;
    }
    if (fx_shr(p->x) < -64 || fx_shr(p->x) >= s->W + 64 || fx_shr(p->y) >= s->H) {
        p->alive = 0; event(s, PT_EV_LOST, p->id, 0); return;
    }
    trace_row(s, &s->turn.trace_shots, p->id, p->x, p->y, -1);
    if (w->kind == PT_KIND_CLUSTER && p->age > 8 && p->vy >= 0) { split(s, p); return; }
    if (p->fuse > 0) {
        p->fuse--;
        if (p->fuse == 0) {
            if (w->kind == PT_KIND_CLUSTER) split(s, p); else detonate(s, p);
        }
    }
}

static void explode(struct pt_state *s, i64 x, i64 y, i64 w, i64 owner, i64 hx, i64 hy) {
    const struct pt_weapon *wp = &WEAPONS[w];
    i64 cx = fx_shr(x), cy = fx_shr(y), R = wp->radius + C_KB_REACH, RR = fx_imul(R, R);
    i64 i, bx, by, dx, dy, d2, d, dmg, kv, kx, ky, hl = 0;
    struct body *b;
    struct pt_crater cr;
    int32_t dead[PT_MAX_BODIES], ndead = 0;
    (void) owner;
    if (hx || hy) hl = fx_isqrt(fx_imul(hx, hx) + fx_imul(hy, hy));
    carve(s, cx, cy, wp->radius, 0);
    cr.x = (int32_t) cx; cr.y = (int32_t) cy; cr.r = wp->radius;
    if (!vec_push(&s->craters, &cr) || !vec_push(&s->turn.craters, &cr)) s->oom = 1;
    event(s, PT_EV_EXPLODE, cx, cy);
    for (i = 0; i < s->nbodies; i++) {
        b = &s->bodies[i];
        if (!b->alive) continue;
        bx = fx_shr(b->x); by = fx_shr(b->y) - C_BODY_MID;
        dx = bx - cx; dy = by - cy;
        d2 = fx_imul(dx, dx) + fx_imul(dy, dy);
        if (d2 > RR) continue;
        d = fx_isqrt(d2);
        dmg = fx_idiv(fx_imul(wp->damage, R - d), R);
        kv = fx_idiv(fx_imul(wp->knock, R - d), R);
        if (d < C_DIRECT_D && hl > 0) {
            kx = fx_idiv(fx_imul(hx, kv), hl);
            ky = -fx_idiv(kv, 2);
        } else if (d == 0) { kx = 0; ky = -kv; }
        else {
            kx = fx_idiv(fx_imul(dx, kv), d);
            ky = fx_idiv(fx_imul(dy, kv), d) - fx_idiv(kv, C_KB_LIFT);
        }
        b->vx += kx; b->vy += ky;
        if (b->mode != PT_FLYING) b->mode = PT_FLYING;
        if (dmg > 0) hurt(s, b, i, dmg, dead, &ndead);
    }
    for (i = 0; i < ndead; i++) death_blast(s, dead[i]);
}

static void hurt(struct pt_state *s, struct body *b, i64 idx_, i64 dmg, int32_t *dead, int32_t *ndead) {
    struct pt_grave g;
    if (dmg <= 0 || !b->alive) return;
    b->hp = fx_max(0, b->hp - dmg);
    event(s, PT_EV_HURT, idx_, dmg);
    if (b->hp == 0) {
        b->alive = 0;
        event(s, PT_EV_DIE, idx_, 0);
        g.seat = (int32_t) b->seat; g.x = (int32_t) fx_shr(b->x); g.y = (int32_t) fx_shr(b->y);
        if (!vec_push(&s->graves, &g)) s->oom = 1;
        if (dead) dead[(*ndead)++] = (int32_t) idx_; else death_blast(s, idx_);
    }
}

static void death_blast(struct pt_state *s, i64 idx_) {
    struct body *b = &s->bodies[idx_];
    event(s, PT_EV_BLAST, idx_, 0);
    explode(s, b->x, b->y - fx_from(C_BODY_MID), W_DEATH, idx_, 0, 0);
}

static void step(struct pt_state *s, i64 bits) {
    int32_t i;
    for (i = 0; i < s->nproj; i++) if (s->proj[i].alive) step_projectile(s, i);
    for (i = 0; i < s->nbodies; i++) {
        if (!s->bodies[i].alive) continue;
        step_body(s, &s->bodies[i], i, i == s->turn.active && s->turn.phase == PT_PHASE_LIVE ? bits : 0);
    }
}

static int in_box(i64 v) { return v > -BOX && v < BOX; }

static int box_ok(const struct pt_state *s) {
    int32_t i;
    for (i = 0; i < s->nbodies; i++) {
        const struct body *b = &s->bodies[i];
        if (!in_box(b->x) || !in_box(b->y) || !in_box(b->vx) || !in_box(b->vy)) return 0;
    }
    for (i = 0; i < s->nproj; i++) {
        const struct proj *p = &s->proj[i];
        if (!p->alive) continue;
        if (!in_box(p->x) || !in_box(p->y) || !in_box(p->vx) || !in_box(p->vy)) return 0;
    }
    return 1;
}

static int32_t advance(struct pt_state *s, i64 bits, const struct pt_shot *shot) {
    struct turn *t = &s->turn;
    struct body *b;
    struct pt_input in;
    struct pt_ladder l;
    uint32_t h[2];
    if (t->phase == PT_PHASE_DONE || t->phase == PT_PHASE_IDLE) return (int32_t) t->phase;
    b = &s->bodies[t->active];
    bits = bits & 7;
    if (t->phase == PT_PHASE_LIVE) {
        if (!b->alive) { t->phase = PT_PHASE_SETTLE; t->shot_tick = t->turn_tick; }
        else {
            if (shot) { if (!fire(s, shot)) return (int32_t) t->phase; }
            else if (t->turn_tick >= s->live_cap) { t->phase = PT_PHASE_SETTLE; t->shot_tick = t->turn_tick; event(s, PT_EV_EXPIRE, t->active, 0); }
        }
    }
    if (t->phase == PT_PHASE_LIVE) {
        if (bits != t->last_bits) {
            in.tick = (int32_t) t->turn_tick; in.bits = (int32_t) bits;
            if (!vec_push(&t->inputs, &in)) s->oom = 1;
            t->last_bits = bits;
        }
    } else bits = 0;
    step(s, bits);
    if (fx_mod(t->turn_tick, C_LADDER) == 0) {
        hash_state(s, h);
        l.tick = (int32_t) t->turn_tick; l.h1 = h[0]; l.h2 = h[1];
        if (!vec_push(&t->ladder, &l)) s->oom = 1;
    }
    t->turn_tick++;
    s->tick++;
    if (!box_ok(s)) { t->phase = PT_PHASE_DONE; t->error = PT_ERR_BOX; event(s, PT_EV_ERROR, 0, 0); return (int32_t) t->phase; }
    if (t->error == PT_ERR_PROJECTILES) { t->phase = PT_PHASE_DONE; event(s, PT_EV_ERROR, 0, 0); return (int32_t) t->phase; }
    if (s->oom) { t->phase = PT_PHASE_DONE; t->error = PT_ERR_MEMORY; return (int32_t) t->phase; }
    if (t->phase == PT_PHASE_SETTLE) {
        if (settled(s)) { t->phase = PT_PHASE_DONE; t->settled_at = t->turn_tick; }
        else if (t->turn_tick - t->shot_tick > s->settle_cap) { t->phase = PT_PHASE_DONE; t->error = PT_ERR_TICK_CAP; event(s, PT_EV_ERROR, 0, 0); }
    }
    return (int32_t) t->phase;
}

/* ---- the outcome ------------------------------------------------------------- */

static void *dup_vec(const struct vec *v) {
    void *p = malloc(v->n ? (size_t) v->n * v->sz : 1);
    if (p && v->n) memcpy(p, v->p, (size_t) v->n * v->sz);
    return p;
}

struct pt_outcome *pt_outcome(const struct pt_state *s) {
    const struct turn *t = &s->turn;
    struct pt_outcome *o = (struct pt_outcome *) calloc(1, sizeof *o);
    int32_t i;
    if (!o) return NULL;
    o->seed = s->seed; o->active = (int32_t) t->active; o->wind = (int32_t) t->wind;
    o->ticks = (int32_t) t->turn_tick; o->settled_at = (int32_t) t->settled_at;
    o->error = s->oom ? PT_ERR_MEMORY : t->error;
    o->has_shot = t->has_shot; o->shot_tick = (int32_t) t->shot_tick; o->shot = t->shot;
    o->ninputs = t->inputs.n; o->inputs = (struct pt_input *) dup_vec(&t->inputs);
    o->nevents = t->events.n; o->events = (struct pt_event *) dup_vec(&t->events);
    o->ncraters = t->craters.n; o->craters = (struct pt_crater *) dup_vec(&t->craters);
    o->ntrace_bodies = t->trace_bodies.n; o->trace_bodies = (struct pt_trace *) dup_vec(&t->trace_bodies);
    o->ntrace_shots = t->trace_shots.n; o->trace_shots = (struct pt_trace *) dup_vec(&t->trace_shots);
    o->nladder = t->ladder.n; o->ladder = (struct pt_ladder *) dup_vec(&t->ladder);
    o->end_tick = (int32_t) s->tick; o->end_craters = s->craters.n;
    o->nbodies = s->nbodies;
    o->bodies = (struct pt_body *) malloc(sizeof(struct pt_body) * (size_t) (s->nbodies ? s->nbodies : 1));
    if (!o->inputs || !o->events || !o->craters || !o->trace_bodies || !o->trace_shots || !o->ladder || !o->bodies) { pt_outcome_free(o); return NULL; }
    for (i = 0; i < s->nbodies; i++) {
        const struct body *b = &s->bodies[i];
        struct pt_body *ob = &o->bodies[i];
        ob->seat = (int32_t) b->seat; ob->k = (int32_t) b->k; ob->x = (int32_t) b->x; ob->y = (int32_t) b->y;
        ob->vx = (int32_t) b->vx; ob->vy = (int32_t) b->vy; ob->mode = (int32_t) b->mode; ob->hp = (int32_t) b->hp;
        ob->alive = (int32_t) b->alive; ob->facing = (int32_t) b->facing;
    }
    return o;
}

void pt_outcome_free(struct pt_outcome *o) {
    if (!o) return;
    free(o->inputs); free(o->events); free(o->craters); free(o->trace_bodies); free(o->trace_shots); free(o->ladder); free(o->bodies);
    free(o);
}

struct pt_outcome *pt_run_turn(struct pt_state *s, int32_t active, int32_t ninputs, const struct pt_input *inputs, const struct pt_shot *shot, int32_t shot_tick) {
    int32_t cursor = 0, bits = 0, fired = 0, guard = s->live_cap + s->settle_cap + 8;
    const struct pt_shot *now;
    if (start_turn(s, active) < 0 && s->turn.phase != PT_PHASE_LIVE) {
        s->turn.error = PT_ERR_STATE;
        return pt_outcome(s);
    }
    while (s->turn.phase != PT_PHASE_DONE) {
        while (cursor < ninputs && inputs[cursor].tick <= s->turn.turn_tick) { bits = inputs[cursor].bits; cursor++; }
        now = NULL;
        if (!fired && shot && shot_tick == s->turn.turn_tick) { fired = 1; now = shot; }
        advance(s, bits, now);
        if (--guard < 0) { s->turn.error = PT_ERR_TICK_CAP; s->turn.phase = PT_PHASE_DONE; break; }
    }
    return pt_outcome(s);
}

/* ---- the state's life ---------------------------------------------------------- */

struct pt_state *pt_state_new(const struct pt_opts *opts) {
    struct pt_state *s = (struct pt_state *) calloc(1, sizeof *s);
    struct pt_gen g;
    if (!s) return NULL;
    vec_init(&s->craters, sizeof(struct pt_crater));
    vec_init(&s->graves, sizeof(struct pt_grave));
    turn_init(&s->turn);
    s->seed = opts->seed;
    s->teams = opts->teams > 0 ? opts->teams : 2;
    s->per_team = opts->per_team > 0 ? opts->per_team : 4;
    s->wind_set = opts->wind_set; s->wind_override = opts->wind;
    s->live_cap = opts->live_cap > 0 ? opts->live_cap : PT_LIVE_CAP;
    s->settle_cap = opts->settle_cap > 0 ? opts->settle_cap : PT_SETTLE_CAP;
    g = DEFAULT_GEN;
    if (opts->use_gen) {
        if (opts->gen.profile >= 0) g.profile = opts->gen.profile;
        if (opts->gen.W > 0) g.W = opts->gen.W;
        if (opts->gen.H > 0) g.H = opts->gen.H;
        if (opts->gen.coarse > 0) g.coarse = opts->gen.coarse;
        if (opts->gen.fine > 0) g.fine = opts->gen.fine;
        if (opts->gen.cave > 0) g.cave = opts->gen.cave;
        if (opts->gen.threshold > 0) g.threshold = opts->gen.threshold;
        if (opts->gen.bias_scale > 0) g.bias_scale = opts->gen.bias_scale;
        if (opts->gen.bias_offset > 0) g.bias_offset = opts->gen.bias_offset;
        if (opts->gen.cave_lo > 0) g.cave_lo = opts->gen.cave_lo;
        if (opts->gen.cave_hi > 0) g.cave_hi = opts->gen.cave_hi;
        if (opts->gen.cave_top > 0) g.cave_top = opts->gen.cave_top;
        if (opts->gen.cave_bottom > 0) g.cave_bottom = opts->gen.cave_bottom;
        if (opts->gen.platform > 0) g.platform = opts->gen.platform;
        if (opts->gen.headroom > 0) g.headroom = opts->gen.headroom;
        g.floor = opts->gen.floor;
    }
    if (g.W < 16 || g.H < 16 || g.W > 8192 || g.H > 8192) { pt_state_free(s); return NULL; }
    if (!generate(s, opts->seed, &g)) { pt_state_free(s); return NULL; }
    if (opts->nsculpt > 0 && opts->sculpt) sculpt(s, opts->nsculpt, opts->sculpt);
    s->rng = seed32(mix32(s->seed, 0x5bd1e995u));
    if (opts->place == PT_PLACE_EXPLICIT) place_bodies(s, opts->nbodies, opts->bodies);
    else if (opts->place == PT_PLACE_TEAMS) { if (!place_teams(s) && s->error != PT_ERR_BODIES) { pt_state_free(s); return NULL; } }
    return s;
}

void pt_state_free(struct pt_state *s) {
    if (!s) return;
    free(s->mask); free(s->scorch);
    vec_drop(&s->craters); vec_drop(&s->graves);
    turn_drop(&s->turn);
    free(s);
}

/* ---- snapshots ------------------------------------------------------------------ */

static struct pt_snapshot *snapshot_new(const struct pt_state *s) {
    struct pt_snapshot *n = (struct pt_snapshot *) calloc(1, sizeof *n);
    size_t cells;
    if (!n) return NULL;
    cells = (size_t) fx_imul(s->W, s->H);
    n->W = s->W; n->H = s->H;
    n->mask = (uint8_t *) malloc(cells); n->scorch = (uint8_t *) malloc(cells);
    vec_init(&n->craters, sizeof(struct pt_crater)); vec_init(&n->graves, sizeof(struct pt_grave));
    if (!n->mask || !n->scorch || !vec_copy(&n->craters, &s->craters) || !vec_copy(&n->graves, &s->graves)) {
        free(n->mask); free(n->scorch); vec_drop(&n->craters); vec_drop(&n->graves); free(n);
        return NULL;
    }
    memcpy(n->mask, s->mask, cells); memcpy(n->scorch, s->scorch, cells);
    n->nbodies = s->nbodies; memcpy(n->bodies, s->bodies, sizeof s->bodies);
    n->rng = s->rng; n->tick = s->tick; n->next_pid = s->next_pid;
    return n;
}

static int32_t snapshot_restore(struct pt_state *s, const struct pt_snapshot *n) {
    size_t cells;
    if (n->W != s->W || n->H != s->H) return -PT_ERR_STATE;
    cells = (size_t) fx_imul(s->W, s->H);
    memcpy(s->mask, n->mask, cells); memcpy(s->scorch, n->scorch, cells);
    s->nbodies = n->nbodies; memcpy(s->bodies, n->bodies, sizeof s->bodies);
    if (!vec_copy(&s->craters, &n->craters) || !vec_copy(&s->graves, &n->graves)) return -PT_ERR_MEMORY;
    s->rng = n->rng; s->tick = n->tick; s->next_pid = n->next_pid;
    s->nproj = 0;
    s->turn.phase = PT_PHASE_IDLE;
    s->error = PT_OK; s->oom = 0;
    return 0;
}

static void snapshot_free(struct pt_snapshot *n) {
    if (!n) return;
    free(n->mask); free(n->scorch); vec_drop(&n->craters); vec_drop(&n->graves); free(n);
}

/* ---- the table -------------------------------------------------------------------- */

static int32_t abi_width(const struct pt_state *s) { return s->W; }
static int32_t abi_height(const struct pt_state *s) { return s->H; }
static uint32_t abi_seed(const struct pt_state *s) { return s->seed; }
static int32_t abi_tick(const struct pt_state *s) { return (int32_t) s->tick; }
static int32_t abi_teams(const struct pt_state *s) { return s->teams; }
static int32_t abi_per_team(const struct pt_state *s) { return s->per_team; }
static int32_t abi_solid(const struct pt_state *s, int32_t x, int32_t y) { return (int32_t) solid(s, x, y); }
static int32_t abi_swept(const struct pt_state *s, int32_t x0, int32_t y0, int32_t x1, int32_t y1, int32_t out[4]) {
    struct walk_ctx c;
    int hit = swept(s, x0, y0, x1, y1, &c);
    out[0] = (int32_t) c.hx; out[1] = (int32_t) c.hy; out[2] = (int32_t) c.hpx; out[3] = (int32_t) c.hpy;
    return hit;
}
static int32_t abi_carve(struct pt_state *s, int32_t x, int32_t y, int32_t r) { return r < 0 ? 0 : (int32_t) carve(s, x, y, r, 0); }
static void abi_sculpt(struct pt_state *s, int32_t n, const struct pt_sculpt *ops) { sculpt(s, n, ops); }
static int32_t abi_surface_at(const struct pt_state *s, int32_t x, int32_t y_from) { return (int32_t) surface_at(s, x, y_from); }
static int32_t abi_count(const struct pt_state *s) {
    i64 n = fx_imul(s->W, s->H), i, c = 0;
    for (i = 0; i < n; i++) if (s->mask[i]) c++;
    return (int32_t) c;
}
static size_t abi_mask_bytes(const struct pt_state *s) { return (size_t) fx_idiv(fx_imul(s->W, s->H) + 7, 8); }
static void abi_mask_pack(const struct pt_state *s, uint8_t *buf) {
    i64 n = fx_imul(s->W, s->H), i, bit = 0, o = 0;
    uint8_t byte = 0;
    for (i = 0; i < n; i++) {
        if (s->mask[i]) byte |= (uint8_t) (1 << bit);
        bit++;
        if (bit == 8) { buf[o++] = byte; byte = 0; bit = 0; }
    }
    if (bit) buf[o] = byte;
}
static int32_t abi_add_body(struct pt_state *s, int32_t seat, int32_t cx, int32_t cy) { return (int32_t) add_body(s, seat, cx, cy); }
static int32_t abi_body_count(const struct pt_state *s) { return s->nbodies; }
static int32_t abi_body_get(const struct pt_state *s, int32_t i, struct pt_body *out) {
    const struct body *b;
    if (i < 0 || i >= s->nbodies) return -1;
    b = &s->bodies[i];
    out->seat = (int32_t) b->seat; out->k = (int32_t) b->k; out->x = (int32_t) b->x; out->y = (int32_t) b->y;
    out->vx = (int32_t) b->vx; out->vy = (int32_t) b->vy; out->mode = (int32_t) b->mode; out->hp = (int32_t) b->hp;
    out->alive = (int32_t) b->alive; out->facing = (int32_t) b->facing;
    return 0;
}
static int32_t abi_start_turn(struct pt_state *s, int32_t active) { return start_turn(s, active); }
static int32_t abi_advance(struct pt_state *s, int32_t bits, const struct pt_shot *shot) { return advance(s, bits, shot); }
static int32_t abi_phase(const struct pt_state *s) { return (int32_t) s->turn.phase; }
static int32_t abi_turn_tick(const struct pt_state *s) { return (int32_t) s->turn.turn_tick; }
static int32_t abi_error(const struct pt_state *s) { return s->oom ? PT_ERR_MEMORY : (s->turn.error ? s->turn.error : s->error); }
static void abi_hash(const struct pt_state *s, uint32_t out[2]) { hash_state(s, out); }
static int32_t abi_launch(int32_t weapon, int32_t angle, int32_t power, int32_t out[2]) {
    const struct pt_weapon *w;
    i64 a, p, speed;
    if (weapon < 0 || weapon >= N_WEAPONS) return -1;
    w = &WEAPONS[weapon];
    a = fx_mod(angle, 4096);
    p = fx_max(1, fx_min(100, power));
    speed = fx_idiv(fx_imul(w->speed_max, p), 100);
    out[0] = (int32_t) fx_scale16(speed, fx_cos(a));
    out[1] = (int32_t) fx_scale16(speed, -fx_sin(a));
    return 0;
}
static int32_t abi_weapon_count(void) { return N_WEAPONS; }
static const struct pt_weapon *abi_weapon_get(int32_t i) { return (i >= 0 && i < (int32_t) (sizeof WEAPONS / sizeof WEAPONS[0])) ? &WEAPONS[i] : NULL; }
static int32_t abi_craters(const struct pt_state *s, const struct pt_crater **out) { *out = (const struct pt_crater *) s->craters.p; return s->craters.n; }
static int32_t abi_graves(const struct pt_state *s, const struct pt_grave **out) { *out = (const struct pt_grave *) s->graves.p; return s->graves.n; }

static const char *const EVENT_NAMES[PT_EV_COUNT] = {
    "jump", "fire", "ray", "hit", "explode", "bounce", "split", "lost", "hurt", "die", "out", "land", "blast", "expire", "error"
};
static const char *abi_event_name(int32_t kind) { return (kind >= 0 && kind < PT_EV_COUNT) ? EVENT_NAMES[kind] : "unknown"; }
static const char *abi_error_name(int32_t err) {
    switch (err) {
        case PT_OK: return NULL;
        case PT_ERR_TICK_CAP: return "tick cap";
        case PT_ERR_WEAPON: return "weapon";
        case PT_ERR_BODIES: return "bodies";
        case PT_ERR_PROJECTILES: return "projectiles";
        case PT_ERR_BOX: return "box";
        case PT_ERR_MEMORY: return "memory";
        case PT_ERR_STATE: return "state";
        default: return "unknown";
    }
}

static const struct pt_abi PT_ABI = {
    PT_ABI_VERSION,
    pt_state_new, pt_state_free,
    abi_width, abi_height, abi_seed, abi_tick, abi_teams, abi_per_team,
    abi_solid, abi_swept, abi_carve, abi_sculpt, abi_surface_at, abi_count, abi_mask_bytes, abi_mask_pack,
    abi_add_body, abi_body_count, abi_body_get,
    abi_start_turn, abi_advance, abi_phase, abi_turn_tick, abi_error,
    pt_outcome, pt_outcome_free, pt_run_turn,
    abi_hash,
    snapshot_new, snapshot_restore, snapshot_free,
    abi_launch, abi_weapon_count, abi_weapon_get,
    abi_craters, abi_graves, abi_event_name, abi_error_name
};

const struct pt_abi *pt_abi_table(void) { return &PT_ABI; }
