#ifndef PB_ABI_H
#define PB_ABI_H

/* Public C ABI for Physics::Balls, the ball engine, and anything that wants to
 * roll balls without a Perl frame in between.
 *
 * The engine is PERL-FREE. Nothing in this header or in pb_engine.c needs
 * perl.h, so the same C compiles into the XS, into a plain program, or to
 * wasm. The table is resolved at RUNTIME via Physics::Balls::_abi_ptr, a
 * versioned function-pointer table in the shape of hm_abi.h and sc_abi.h, so
 * there is no link-time symbol coupling and each dist upgrades on its own.
 *
 * The table only ever grows at the end. PB_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against,
 * NEVER ==.
 *
 * ---- what the engine is -----------------------------------------------------
 *
 * Balls of one radius on a flat surface with friction, walls as line
 * segments, nose points a ball can rattle off, and gates a ball drops through
 * (a pocket). It knows nothing about reds, stripes, fouls or frames; a game
 * describes its table and reads the outcome. Event-based and analytic: a
 * sliding ball is a parabola, a rolling ball a straight line, and every
 * contact time is the first downward zero of a polynomial found by a fixed
 * number of bisections in a fixed order, so the same inputs give the same
 * outcome bit for bit on every platform that keeps IEEE doubles honest (the
 * build must not contract multiply-adds: see Makefile.PL).
 *
 * ---- units --------------------------------------------------------------------
 *
 * The description is in metres, seconds and metres per second. A layout and
 * a rest position are INTEGERS in hundredths of a millimetre, a shot is
 * integers (a direction in plus or minus 1,000,000, power 0 to 1000, a tip
 * offset in thousandths of the radius from -500 to 500), so that a client
 * cannot send a float two encoders would spell differently. Segments are
 * doubles in metres and seconds.
 *
 * ---- names ---------------------------------------------------------------------
 *
 * No member is called open, close, read, write, free or time, which XSUB.h
 * turns into function-like macros under PERL_IMPLICIT_SYS. Call through the
 * table with the member in parentheses anyway: (PB->strike)(w, ...).
 *
 * ---- ownership -----------------------------------------------------------------
 *
 * world_new returns a world the caller frees with world_free. strike returns
 * an outcome the caller frees with outcome_free; every array inside it is
 * owned by the outcome. A world is not modified by strike and may be shared
 * between calls. Nothing is retained between calls.
 */

#define PB_ABI_VERSION 1

#define PB_EV_ROLL 0   /* a sliding ball began to roll            a = ball        */
#define PB_EV_STOP 1   /* a ball came to rest                     a = ball        */
#define PB_EV_BALL 2   /* two balls met                           a, b = balls    */
#define PB_EV_WALL 3   /* a ball met a wall                       a = ball, b = wall index */
#define PB_EV_NOSE 4   /* a ball met a nose point                 a = ball, b = nose index */
#define PB_EV_POT  5   /* a ball crossed a gate                   a = ball, b = the gate's pocket number */

#define PB_OK          0
#define PB_ERR_EVENTS  1   /* more than PB_MAX_EVENTS: the engine gave up, not a silent stop */
#define PB_ERR_TIME    2   /* more than PB_MAX_TIME seconds of simulated time             */
#define PB_ERR_NO_BALL 3   /* the shot names a ball that is not in the layout             */
#define PB_ERR_MEMORY  4

#define PB_MAX_EVENTS 5000
#define PB_MAX_TIME   40.0

struct pb_desc {
    double L, W, R;              /* the playing area between the noses, the ball radius */
    double g;                    /* 9.81 */
    double mu_s, mu_r, mu_sp;    /* sliding, rolling, spinning friction */
    double e_bb, e_c, e_cf, e_rc;/* ball-ball restitution, cushion restitution, cushion friction, roll retention */
    double vmax;                 /* the speed of a full-power strike */
    int nwalls;  const double *walls;   /* x1, y1, x2, y2 per wall, cloth on the LEFT of x1->x2 */
    int nnoses;  const double *noses;   /* x, y per nose point */
    int ngates;  const double *gates;   /* x1, y1, x2, y2, nx, ny, pocket per gate; n points into the pocket */
};

struct pb_ball_in { int id; long x, y; };
struct pb_shot    { int ball; long dx, dy; int power, sx, sy; int trace; };

struct pb_event   { double t; int kind; int a; int b; };
struct pb_segment { int id; double t0, dur, px, py, vx, vy, ax, ay; };
struct pb_rest    { int id; long x, y; };
struct pb_holed   { int id; int pocket; double t; };

struct pb_outcome {
    double t;                 /* simulated seconds until the last ball stopped */
    int    n;                 /* events processed */
    int    error;             /* PB_OK or a PB_ERR_ */
    int nevents;   struct pb_event   *events;     /* in time order */
    int nrest;     struct pb_rest    *rest;       /* every ball still in play */
    int nholed;    struct pb_holed   *holed;      /* in time order */
    int nsegments; struct pb_segment *segments;   /* grouped by ball, each ball's in time order */
    int nenergy;   double            *energy;     /* per unit mass after the strike and after each event, when traced */
};

struct pb_world;

struct pb_abi {
    unsigned int abi_version;
    struct pb_world   *(*world_new)(const struct pb_desc *desc);
    void               (*world_free)(struct pb_world *world);
    struct pb_outcome *(*strike)(const struct pb_world *world, int n, const struct pb_ball_in *layout, const struct pb_shot *shot);
    void               (*outcome_free)(struct pb_outcome *out);
};

/* The linker names, for a program that links pb_engine.c directly. */
struct pb_world   *pb_world_new(const struct pb_desc *desc);
void               pb_world_free(struct pb_world *world);
struct pb_outcome *pb_strike(const struct pb_world *world, int n, const struct pb_ball_in *layout, const struct pb_shot *shot);
void               pb_outcome_free(struct pb_outcome *out);
const struct pb_abi *pb_abi_table(void);

#endif
