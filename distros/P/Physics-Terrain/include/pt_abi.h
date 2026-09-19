#ifndef PT_ABI_H
#define PT_ABI_H

#include <stdint.h>
#include <stddef.h>

/* Public C ABI for Physics::Terrain, the destructible-field engine, and
 * anything that wants to walk, fall, fly and carve without a Perl frame in
 * between.
 *
 * The engine is PERL-FREE. Nothing in this header or in pt_engine.c needs
 * perl.h, so the same C compiles into the XS, into a plain program, or to
 * wasm. The table is resolved at RUNTIME via Physics::Terrain::_abi_ptr, a
 * versioned function-pointer table in the shape of pb_abi.h, hm_abi.h and
 * sc_abi.h, so there is no link-time symbol coupling and each dist upgrades
 * on its own.
 *
 * The table only ever grows at the end. PT_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against,
 * NEVER ==.
 *
 * ---- what the engine is -----------------------------------------------------
 *
 * A field of cells, one bit each, generated from a seed; bodies of one size
 * that stand, walk (stepping up or down three cells), jump and fall on it;
 * projectiles that fly over it under gravity and wind, bounce, split or burst
 * on contact or on a fuse; explosions that carve a disc, hurt with a linear
 * falloff and launch every body in reach. It knows nothing about teams by
 * name, turn order, scores or seats: a game places its bodies with a seat
 * number, drives one turn a tick at a time or hands over a recorded input
 * log, and reads the outcome. Terrain does not collapse: a chunk cut free
 * floats.
 *
 * ---- units --------------------------------------------------------------------
 *
 * Everything is an integer. Positions and velocities are fixed point at
 * 1/256 of a cell (int32 in the ABI, int64 inside); a tick is 1/60 s; angles
 * are 12-bit brads, 0 right and 1024 up; power is 1 to 100; wind is -20 to
 * 20; a crater is a cell centre and a radius in cells. Every division floors
 * toward minus infinity, every product and quotient goes through one helper,
 * and the same inputs give the same integers on every platform, as the
 * JavaScript this engine was transliterated from (plan_crater/prototype)
 * produces, tick for tick. There is no floating point in the engine at all.
 *
 * ---- names ---------------------------------------------------------------------
 *
 * No member is called open, close, read, write, free or time, which XSUB.h
 * turns into function-like macros under PERL_IMPLICIT_SYS. Call through the
 * table with the member in parentheses anyway: (PT->advance)(s, ...).
 *
 * ---- ownership -----------------------------------------------------------------
 *
 * state_new returns a state the caller frees with state_free; it copies
 * everything it is given. outcome returns an outcome the caller frees with
 * outcome_free, and every array inside it is owned by the outcome.
 * snapshot_new returns a snapshot the caller frees with snapshot_free.
 * Pointers handed back by craters, graves and weapon_get are borrowed from
 * the state or from static data and are valid until the next call that
 * changes the state. Nothing is retained between calls.
 */

#define PT_ABI_VERSION 1

#define PT_STANDING 0
#define PT_WALKING  1
#define PT_FALLING  2
#define PT_FLYING   3

#define PT_LEFT  1
#define PT_RIGHT 2
#define PT_JUMP  4

#define PT_PHASE_IDLE   0
#define PT_PHASE_LIVE   1
#define PT_PHASE_SETTLE 2
#define PT_PHASE_DONE   3

#define PT_GEN_NOISE 0
#define PT_GEN_FLAT  1
#define PT_GEN_EMPTY 2

#define PT_PLACE_TEAMS    0
#define PT_PLACE_EXPLICIT 1
#define PT_PLACE_NONE     2

#define PT_OP_FILL     0   /* a, b, c, d = x0, y0, x1, y1 inclusive          */
#define PT_OP_CLEAR    1   /* the same box, cleared                          */
#define PT_OP_SLOPE    2   /* every cell on or below the segment (a,b)-(c,d) */
#define PT_OP_DISC     3   /* a, b, c = x, y, r cleared, no scorch           */
#define PT_OP_PLATFORM 4   /* a, b = x, ground row; c = half width; d = headroom */

#define PT_OK              0
#define PT_ERR_TICK_CAP    1   /* the settle phase ran past PT_SETTLE_CAP ticks: an error, not a stop */
#define PT_ERR_WEAPON      2   /* the shot names a weapon that does not exist        */
#define PT_ERR_BODIES      3   /* more than PT_MAX_BODIES                            */
#define PT_ERR_PROJECTILES 4   /* more than PT_MAX_PROJECTILES alive at once         */
#define PT_ERR_BOX         5   /* a state variable left the declared box (2^30)      */
#define PT_ERR_MEMORY      6
#define PT_ERR_STATE       7   /* no turn is running, or the active body is not alive */

#define PT_EV_JUMP    0   /* a = body                          */
#define PT_EV_FIRE    1   /* a = weapon, b = body              */
#define PT_EV_RAY     2   /* a, b = the cell the ray ended at  */
#define PT_EV_HIT     3   /* a = body, b = projectile id       */
#define PT_EV_EXPLODE 4   /* a, b = the crater's centre cell   */
#define PT_EV_BOUNCE  5   /* a, b = cell                       */
#define PT_EV_SPLIT   6   /* a, b = cell                       */
#define PT_EV_LOST    7   /* a = projectile id, or -1 for a ray */
#define PT_EV_HURT    8   /* a = body, b = damage              */
#define PT_EV_DIE     9   /* a = body, b = 1 out of the world, 0 killed */
#define PT_EV_OUT     10  /* a = body                          */
#define PT_EV_LAND    11  /* a = body, b = the landing speed   */
#define PT_EV_BLAST   12  /* a = body: its death explosion     */
#define PT_EV_EXPIRE  13  /* a = body: the live cap ran out    */
#define PT_EV_ERROR   14
#define PT_EV_COUNT   15

#define PT_KIND_SHELL   0
#define PT_KIND_BOUNCE  1
#define PT_KIND_HITSCAN 2
#define PT_KIND_CLUSTER 3
#define PT_KIND_DROP    4
#define PT_KIND_DEATH   5

#define PT_MAX_BODIES      32
#define PT_MAX_PROJECTILES 64
#define PT_LIVE_CAP        1800
#define PT_SETTLE_CAP      1800
#define PT_BODY_W          8
#define PT_BODY_H          12

struct pt_gen {
    int32_t profile;               /* PT_GEN_NOISE, PT_GEN_FLAT or PT_GEN_EMPTY; -1 for the defaults throughout */
    int32_t W, H;
    int32_t coarse, fine, cave;    /* lattice spacings in cells */
    int32_t threshold, bias_scale, bias_offset;
    int32_t cave_lo, cave_hi, cave_top, cave_bottom;
    int32_t platform, headroom;
    int32_t floor;                 /* PT_GEN_FLAT only; -1 for five eighths of H */
};

struct pt_sculpt  { int32_t op, a, b, c, d; };
struct pt_body_in { int32_t seat, cx, cy_from, hp; };   /* hp <= 0 means 100 */

struct pt_opts {
    uint32_t seed;
    int32_t  teams, per_team;
    int32_t  wind_set, wind;       /* wind_set 0: the turn's wind comes from the seed */
    int32_t  use_gen;              /* 0: the default generator; 1: gen below */
    struct pt_gen gen;
    int32_t  nsculpt; const struct pt_sculpt *sculpt;
    int32_t  place;                /* PT_PLACE_ */
    int32_t  nbodies; const struct pt_body_in *bodies;   /* PT_PLACE_EXPLICIT */
    int32_t  live_cap, settle_cap; /* 0 for PT_LIVE_CAP and PT_SETTLE_CAP */
};

struct pt_body    { int32_t seat, k, x, y, vx, vy, mode, hp, alive, facing; };
struct pt_shot    { int32_t weapon, angle, power; };
struct pt_event   { int32_t tick, kind, a, b; };
struct pt_crater  { int32_t x, y, r; };
struct pt_grave   { int32_t seat, x, y; };
struct pt_input   { int32_t tick, bits; };
struct pt_trace   { int32_t who, tick, x, y, weapon; };   /* weapon >= 0 only on a shot's first row; -2 for a cluster child */
struct pt_ladder  { int32_t tick; uint32_t h1, h2; };

struct pt_weapon {
    const char *id;                /* NULL for the cluster's child */
    const char *name;
    int32_t kind;
    int32_t speed_max, wind, fuse, bounce, friction, radius, damage, knock, range, count, spread, pop;
};

struct pt_outcome {
    uint32_t seed;
    int32_t  active, wind, ticks, settled_at, error;
    int32_t  has_shot; int32_t shot_tick; struct pt_shot shot;
    int32_t ninputs;       struct pt_input  *inputs;
    int32_t nevents;       struct pt_event  *events;
    int32_t ncraters;      struct pt_crater *craters;
    int32_t ntrace_bodies; struct pt_trace  *trace_bodies;   /* in the order recorded */
    int32_t ntrace_shots;  struct pt_trace  *trace_shots;
    int32_t nladder;       struct pt_ladder *ladder;
    int32_t end_tick;      int32_t end_craters;
    int32_t nbodies;       struct pt_body   *bodies;         /* the end state */
};

struct pt_state;
struct pt_snapshot;

struct pt_abi {
    unsigned int abi_version;
    struct pt_state    *(*state_new)(const struct pt_opts *opts);
    void                (*state_free)(struct pt_state *s);
    int32_t             (*width)(const struct pt_state *s);
    int32_t             (*height)(const struct pt_state *s);
    uint32_t            (*seed)(const struct pt_state *s);
    int32_t             (*tick)(const struct pt_state *s);
    int32_t             (*teams)(const struct pt_state *s);
    int32_t             (*per_team)(const struct pt_state *s);
    int32_t             (*solid)(const struct pt_state *s, int32_t x, int32_t y);
    int32_t             (*swept)(const struct pt_state *s, int32_t x0, int32_t y0, int32_t x1, int32_t y1, int32_t out[4]);   /* returns hit; out = x, y, px, py */
    int32_t             (*carve)(struct pt_state *s, int32_t x, int32_t y, int32_t r);   /* cells cleared; scorches the rim */
    void                (*sculpt)(struct pt_state *s, int32_t n, const struct pt_sculpt *ops);
    int32_t             (*surface_at)(const struct pt_state *s, int32_t x, int32_t y_from);
    int32_t             (*count)(const struct pt_state *s);
    size_t              (*mask_bytes)(const struct pt_state *s);
    void                (*mask_pack)(const struct pt_state *s, uint8_t *buf);   /* row-major, eight cells a byte, leftmost in the low bit */
    int32_t             (*add_body)(struct pt_state *s, int32_t seat, int32_t cx, int32_t cy);   /* the index, or -1 over the cap */
    int32_t             (*body_count)(const struct pt_state *s);
    int32_t             (*body_get)(const struct pt_state *s, int32_t i, struct pt_body *out);
    int32_t             (*start_turn)(struct pt_state *s, int32_t active);   /* the wind, or PT_ERR_ negated */
    int32_t             (*advance)(struct pt_state *s, int32_t bits, const struct pt_shot *shot);   /* the phase after the tick */
    int32_t             (*phase)(const struct pt_state *s);
    int32_t             (*turn_tick)(const struct pt_state *s);
    int32_t             (*error)(const struct pt_state *s);
    struct pt_outcome  *(*outcome)(const struct pt_state *s);
    void                (*outcome_free)(struct pt_outcome *o);
    struct pt_outcome  *(*run_turn)(struct pt_state *s, int32_t active, int32_t ninputs, const struct pt_input *inputs, const struct pt_shot *shot, int32_t shot_tick);
    void                (*hash)(const struct pt_state *s, uint32_t out[2]);
    struct pt_snapshot *(*snapshot_new)(const struct pt_state *s);
    int32_t             (*snapshot_restore)(struct pt_state *s, const struct pt_snapshot *snap);
    void                (*snapshot_free)(struct pt_snapshot *snap);
    int32_t             (*launch)(int32_t weapon, int32_t angle, int32_t power, int32_t out[2]);
    int32_t             (*weapon_count)(void);
    const struct pt_weapon *(*weapon_get)(int32_t i);
    int32_t             (*craters)(const struct pt_state *s, const struct pt_crater **out);
    int32_t             (*graves)(const struct pt_state *s, const struct pt_grave **out);
    const char         *(*event_name)(int32_t kind);
    const char         *(*error_name)(int32_t error);
};

/* The linker names, for a program that links pt_engine.c directly. */
struct pt_state    *pt_state_new(const struct pt_opts *opts);
void                pt_state_free(struct pt_state *s);
struct pt_outcome  *pt_run_turn(struct pt_state *s, int32_t active, int32_t ninputs, const struct pt_input *inputs, const struct pt_shot *shot, int32_t shot_tick);
struct pt_outcome  *pt_outcome(const struct pt_state *s);
void                pt_outcome_free(struct pt_outcome *o);
const struct pt_abi *pt_abi_table(void);

#endif
