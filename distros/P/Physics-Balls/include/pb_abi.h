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
 * ---- versioning -----------------------------------------------------------------
 *
 * ABI 3 (0.04) appends no function: it appends members to struct pb_kind and
 * struct pb_shot2 (read through kind_stride and size, so an ABI 2 consumer's
 * structs are read exactly as before) and to struct pb_outcome, which the
 * engine allocates and an ABI 2 consumer reads as its own prefix.
 *
 * The table only ever grows at the end. PB_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against,
 * NEVER ==.
 *
 * That covers appended function pointers. It does not cover widening a struct
 * a v1 function takes, and 0.01 and 0.02 are on CPAN, so struct pb_desc,
 * struct pb_ball_in and struct pb_shot are FROZEN: they are what world_new and
 * strike take and they never change. Anything new goes through world_new_ex
 * and strike_ex, which take struct pb_desc2, struct pb_ball_in2 and
 * struct pb_shot2. The two "2" structs with a `size` member grow by append:
 * a later version adds members at the end and bumps nothing but the version,
 * a consumer sets size to the sizeof it was compiled against, and the engine
 * reads no member past the size it was given, taking the default for it. A
 * size smaller than the members this version needs is refused. A layout row
 * has no size word, because one per array element is a real cost; the
 * consumer passes layout_stride, the sizeof of its own row, once for the
 * array, and the engine reads no member past it (a row of struct pb_ball_in
 * with its own sizeof as the stride is a valid v2 layout of kind 0). The v1
 * entry points are thin wrappers that fill a v2 struct with the v1 defaults.
 *
 * ABI 4 (0.07, plan_air_hockey 02a) appends ONE function, advance: the same
 * loop run from a layout whose rows may each carry a starting velocity
 * (struct pb_ball_in3, read through layout_stride as ever) to a HORIZON,
 * struct pb_tick's dt microseconds, and stopped there: every body's position,
 * velocity and mode at the horizon come back in the outcome's appended state
 * rows. That is what a live game ticking at 50 Hz needs and what strike, which
 * releases one ball and runs to rest, cannot give. Every difference from the
 * strike path is behind a test of the tick argument, so a strike executes the
 * 0.06 instructions and its fixtures are the same doubles.
 *
 * ---- what the engine is -----------------------------------------------------
 *
 * Balls on a flat surface with friction (since ABI 3 of more than one radius
 * and mass, by kind: a bowling ball and its pins), walls as line
 * segments, nose points a ball can rattle off, and gates a ball drops through
 * (a pocket). It knows nothing about reds, stripes, fouls or frames; a game
 * describes its table and reads the outcome. Event-based and analytic: a
 * sliding ball is a parabola, a rolling ball a straight line, and every
 * contact time is the first downward zero of a polynomial found by a fixed
 * number of bisections in a fixed order, so the same inputs give the same
 * outcome bit for bit on every platform that keeps IEEE doubles honest (the
 * build must not contract multiply-adds: see Makefile.PL).
 *
 * Since ABI 2 a ball may curve. A ball's kind names a curve strength, and a
 * ball whose kind has one runs as a chain of parabolas that bends: its
 * segment is capped and at the cap the velocity and the roll vector are
 * rotated together through a small angle, with no trigonometry (the Cayley
 * form from the half-angle tangent), and the segment begins again. The
 * rotation does no work and creates no slip; a turn is not an event and does
 * not count against PB_MAX_EVENTS. The turn rate is a house law of the speed,
 *
 *     k_per_second = curve_k * kind.curve * (curve_vref / max(|v|, curve_vmin)) ^ curve_p
 *
 * clamped to curve_kmax, with curve_p an integer 0 to 4; the constants are
 * fitted by whoever describes the surface and are not a model of ice or of a
 * green. A shot may also carry an adjust: once the struck ball's centre
 * crosses a line, in the named direction, its friction and its curve are
 * multiplied by two factors, once, for the rest of the run. That is a change
 * in the surface partway down a run, which is equally a swept path, a fast
 * strip or a damp patch. With every kind's curve zero and no adjust, none of
 * this is reached and the outcome is bit-identical to ABI 1's.
 *
 * ---- units --------------------------------------------------------------------
 *
 * The description is in metres, seconds and metres per second. A layout and
 * a rest position are INTEGERS in hundredths of a millimetre, a shot is
 * integers (a direction in plus or minus 1,000,000, power 0 to 1000, a tip
 * offset in thousandths of the radius from -500 to 500, an adjust line in
 * hundredths of a millimetre and its factors in thousandths), so that a
 * client cannot send a float two encoders would spell differently. Segments
 * are doubles in metres and seconds.
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
 * between calls. Nothing is retained between calls. A world copies the kinds
 * it is given; the caller's array may go.
 */

#define PB_ABI_VERSION 4

#define PB_EV_ROLL   0   /* a sliding ball began to roll            a = ball        */
#define PB_EV_STOP   1   /* a ball came to rest                     a = ball        */
#define PB_EV_BALL   2   /* two balls met                           a, b = balls    */
#define PB_EV_WALL   3   /* a ball met a wall                       a = ball, b = wall index */
#define PB_EV_NOSE   4   /* a ball met a nose point                 a = ball, b = nose index */
#define PB_EV_POT    5   /* a ball crossed a gate                   a = ball, b = the gate's pocket number */
#define PB_EV_ADJUST 6   /* the struck ball crossed the adjust line a = ball        */
#define PB_EV_DOWN   7   /* a body past its kind's vfall came to rest and left play (ABI 3)  a = ball */

#define PB_OK          0
#define PB_ERR_EVENTS  1   /* more than PB_MAX_EVENTS: the engine gave up, not a silent stop */
#define PB_ERR_TIME    2   /* more than PB_MAX_TIME seconds of simulated time             */
#define PB_ERR_NO_BALL 3   /* the shot names a ball that is not in the layout             */
#define PB_ERR_MEMORY  4
#define PB_ERR_SIZE    5   /* a v2 struct's size is smaller than this version needs        */
#define PB_ERR_KIND    6   /* a layout row names a kind the world does not declare         */
#define PB_ERR_TURNS   7   /* more than PB_MAX_TURNS turns of curving balls in one shot    */
#define PB_ERR_HORIZON 8   /* ABI 4: an advance whose dt is not positive                   */

#define PB_MAX_EVENTS 5000
#define PB_MAX_TIME   40.0
#define PB_MAX_TURNS  20000

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

/* ---- ABI 2 ------------------------------------------------------------------ */

/* A kind of ball. Grows by append with the version; a consumer passes
 * kind_stride, the sizeof it was compiled against, and the engine reads no
 * member past it. curve is the signed strength, -1 to 1 by convention, that
 * the law multiplies; 0 is a ball that never turns. follow is how much of
 * its roll a body keeps through a contact with another body: 1 is a ball,
 * which keeps all of it and so follows through after a full hit the way a
 * rolling cue ball does; 0 is a body with no spin to keep, which rolls at
 * whatever velocity the contact left it, the way a curling stone slides off.
 * At 1 the contact code is the ABI 1 code, untouched. */
/* ABI 3 (0.04, plan_bowling 02) appends five members, read only when the
 * consumer's kind_stride covers them: r, the body's radius in metres (0 or
 * less means the world's R); m, its mass (0 or less means 1; only ratios
 * matter); mu, a multiplier on the world's sliding and rolling friction for
 * this body (0 or less means 1); rs, the radius the body presents to bodies
 * of its OWN kind (0 or less means r: a toppling pin sweeps other pins wider
 * than its belly, and it is other pins it sweeps); and vfall, a peak speed
 * above which the body is down (0 means never). A down body leaves play when
 * it stops or slows under 2 cm/s, as a potted ball does, and is reported in
 * the outcome's downs. Every default is exactly the ABI 2 arithmetic: a mass
 * of 1 enters every contact as a multiplier of exactly 1.0 or 0.5, and the
 * 0.03 fixtures are bit-identical through a world that declares none of it. */
struct pb_kind { double curve; double follow; double r; double m; double mu; double rs; double vfall; };

struct pb_desc2 {
    unsigned int size;           /* sizeof(struct pb_desc2) as compiled by the consumer */
    struct pb_desc base;         /* every v1 constant, unchanged */
    double curve_k, curve_vref, curve_vmin, curve_kmax;
    int    curve_p;              /* 0 to 4, multiplied out: pow is banned */
    double turn_cap;             /* the half-angle tangent turned in one step */
    double turn_vfrac;           /* the largest fraction of its speed a ball may lose in one step */
    int nkinds; const struct pb_kind *kinds; int kind_stride;
};

struct pb_ball_in2 { int id; long x, y; int kind; };   /* the v1 row, then the kind: index into the world's kinds */

struct pb_shot2 {
    unsigned int size;           /* sizeof(struct pb_shot2) as compiled by the consumer */
    struct pb_shot base;         /* every v1 field, unchanged */
    int  adjust;                 /* 0 = none */
    long adjust_at;              /* the line, in hundredths of a millimetre */
    int  adjust_axis;            /* 0 = a line of constant x, 1 = of constant y */
    int  adjust_dir;             /* +1 = on the centre crossing with the coordinate increasing, -1 = decreasing */
    int  adjust_mu, adjust_curve;/* multipliers in thousandths, 1000 = unchanged */
    /* ABI 3: the release roll. The struck ball's roll velocity at release is
       spin/1000 of its speed along the direction tx, ty (integers in plus or
       minus 1,000,000), instead of the ABI 1 tip offset's roll along the line
       of the shot; a roll off the line slides on a parabola, which is a hook.
       spin 0, or a size that stops short of these, is the ABI 1 path. */
    long tx, ty;
    int  spin;
};

/* ---- ABI 4 ------------------------------------------------------------------ */

/* A layout row for advance: the v2 row, then a starting velocity in hundredths
   of a millimetre a second. INTEGERS, for the reason positions are: a tick's
   state is the next tick's row and every encoder must spell it identically. A
   pb_ball_in2 array at its own stride is a valid all-stationary layout; the
   velocity is read only when layout_stride reaches it. A body with a velocity
   is released ROLLING with its roll equal to its velocity, and no speed floor
   applies: 0.05 m/s is legal. */
struct pb_ball_in3 { int id; long x, y; int kind; long vx, vy; };

/* The horizon: dt in microseconds, an integer so a fixture carries the exact
   value (20000 is the double nearest 0.02, by a correctly rounded division). */
struct pb_tick { unsigned int size; long dt; int trace; };

/* One row per layout row, in layout order, at the horizon: position and
   velocity in hundredths of a millimetre (a second), and the body's mode
   (0 stationary, 1 sliding, 2 rolling, 3 pocketed). A pocketed body carries a
   zero velocity. Integers, so no negative zero exists on any wire. */
struct pb_state   { int id; long x, y, vx, vy; int mode; };

struct pb_event   { double t; int kind; int a; int b; };
struct pb_segment { int id; double t0, dur, px, py, vx, vy, ax, ay; };
struct pb_rest    { int id; long x, y; };
struct pb_holed   { int id; int pocket; double t; };
struct pb_peak    { int id; double v; };              /* ABI 3: a body's peak speed over the shot, m/s */
struct pb_down    { int id; long x, y; double t; };   /* ABI 3: a down body, where it lay and when it left play */

struct pb_outcome {
    double t;                 /* simulated seconds until the last ball stopped */
    int    n;                 /* events processed */
    int    error;             /* PB_OK or a PB_ERR_ */
    int nevents;   struct pb_event   *events;     /* in time order */
    int nrest;     struct pb_rest    *rest;       /* every ball still in play */
    int nholed;    struct pb_holed   *holed;      /* in time order */
    int nsegments; struct pb_segment *segments;   /* grouped by ball, each ball's in time order */
    int nenergy;   double            *energy;     /* mass-weighted, after the strike and after each event, when traced */
    /* ABI 3, appended: a consumer compiled against ABI 2 reads its own prefix */
    int npeaks;    struct pb_peak    *peaks;      /* one per body in the layout, in layout order */
    int ndowns;    struct pb_down    *downs;      /* in time order; a down body is in neither rest nor holed */
    /* ABI 4, appended: filled by advance only; a strike leaves nstate 0 */
    int nstate;    struct pb_state   *state;      /* every body at the horizon, in layout order */
};

struct pb_world;

struct pb_abi {
    unsigned int abi_version;
    struct pb_world   *(*world_new)(const struct pb_desc *desc);
    void               (*world_free)(struct pb_world *world);
    struct pb_outcome *(*strike)(const struct pb_world *world, int n, const struct pb_ball_in *layout, const struct pb_shot *shot);
    void               (*outcome_free)(struct pb_outcome *out);
    /* ABI 2 */
    struct pb_world   *(*world_new_ex)(const struct pb_desc2 *desc);
    struct pb_outcome *(*strike_ex)(const struct pb_world *world, int n, const struct pb_ball_in2 *layout, int layout_stride, const struct pb_shot2 *shot);
    /* ABI 4 */
    struct pb_outcome *(*advance)(const struct pb_world *world, int n, const struct pb_ball_in2 *layout, int layout_stride, const struct pb_tick *tick);
};

/* The linker names, for a program that links pb_engine.c directly. */
struct pb_world   *pb_world_new(const struct pb_desc *desc);
struct pb_world   *pb_world_new_ex(const struct pb_desc2 *desc);
void               pb_world_free(struct pb_world *world);
struct pb_outcome *pb_strike(const struct pb_world *world, int n, const struct pb_ball_in *layout, const struct pb_shot *shot);
struct pb_outcome *pb_strike_ex(const struct pb_world *world, int n, const struct pb_ball_in2 *layout, int layout_stride, const struct pb_shot2 *shot);
struct pb_outcome *pb_advance(const struct pb_world *world, int n, const struct pb_ball_in2 *layout, int layout_stride, const struct pb_tick *tick);
void               pb_outcome_free(struct pb_outcome *out);
const struct pb_abi *pb_abi_table(void);

#endif
