/*
 * Balls.xs - the XS door over pb_engine.c for Physics::Balls.
 *
 * At the top of the dist, not under lib/, for the reason Struct::Codec's
 * Codec.xs gives: an XSMULTI build's export list and Strawberry's import
 * library rule never agree on a name.
 *
 * The engine is perl-free; this file only turns a description hash into a
 * pb_desc2, a layout array into pb_ball_in2, and an outcome back into Perl
 * structures. Every SV built here is owned by the structure it goes into, and
 * the one returned is a fresh reference xsubpp mortalises itself. The Perl
 * always goes through the ABI 2 entry points; _strike_v1 exists so a test can
 * prove the v1 wrappers give the same doubles.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pb_abi.h"
#include <float.h>

/* How the compiler that built this file evaluates a double between operations,
 * as float.h says: 0 rounds every operation to a double, 2 is the x87 unit
 * holding 80 bits, negative is a header that does not say. pb_engine.c is
 * compiled with the same flags, so this is the engine's arithmetic too, and
 * the tests that compare against recorded doubles skip on anything but 0. */
static int pb_float_eval_method(void) {
#ifdef FLT_EVAL_METHOD
    return FLT_EVAL_METHOD;
#else
    return -1;
#endif
}

/* A flat array of doubles from an array of arrays of `width` numbers. The
 * caller frees. Rows that are short are padded with zero, never read past. */
static double *pb_flat(pTHX_ AV *rows, int width, int *count) {
    double *out;
    int n, i, k;
    n = rows ? av_len(rows) + 1 : 0;
    *count = n;
    Newxz(out, (n ? n : 1) * width, double);
    for (i = 0; i < n; i++) {
        SV **rp = av_fetch(rows, i, 0);
        AV *row;
        if (!rp || !SvROK(*rp) || SvTYPE(SvRV(*rp)) != SVt_PVAV) continue;
        row = (AV *) SvRV(*rp);
        for (k = 0; k < width; k++) {
            SV **v = av_fetch(row, k, 0);
            out[i * width + k] = v ? SvNV(*v) : 0;
        }
    }
    return out;
}

static double pb_num(pTHX_ HV *hv, const char *key, double dflt) {
    SV **v = hv_fetch(hv, key, (I32) strlen(key), 0);
    return v && SvOK(*v) ? SvNV(*v) : dflt;
}

static HV *pb_hash(pTHX_ HV *hv, const char *key) {
    SV **v = hv_fetch(hv, key, (I32) strlen(key), 0);
    if (v && SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVHV) return (HV *) SvRV(*v);
    return NULL;
}

static AV *pb_array(pTHX_ HV *hv, const char *key) {
    SV **v = hv_fetch(hv, key, (I32) strlen(key), 0);
    if (v && SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVAV) return (AV *) SvRV(*v);
    return NULL;
}

static const char *pb_kind_name(int kind) {
    switch (kind) {
        case PB_EV_ROLL: return "roll";
        case PB_EV_STOP: return "stop";
        case PB_EV_BALL: return "ball";
        case PB_EV_WALL: return "wall";
        case PB_EV_NOSE: return "nose";
        case PB_EV_POT:  return "pot";
        case PB_EV_ADJUST: return "adjust";
        case PB_EV_DOWN: return "down";
        default: return "unknown";
    }
}

static const char *pb_error_name(int err) {
    switch (err) {
        case PB_OK: return NULL;
        case PB_ERR_EVENTS: return "events";
        case PB_ERR_TIME: return "time";
        case PB_ERR_NO_BALL: return "no_ball";
        case PB_ERR_SIZE: return "size";
        case PB_ERR_KIND: return "kind";
        case PB_ERR_TURNS: return "turns";
        case PB_ERR_HORIZON: return "horizon";
        default: return "memory";
    }
}

/* The v1 fields of a shot hash into a pb_shot. */
static void pb_shot_from(pTHX_ HV *shot, struct pb_shot *s) {
    s->ball = (int) pb_num(aTHX_ shot, "ball", 0);
    s->dx = (long) pb_num(aTHX_ shot, "dx", 0);
    s->dy = (long) pb_num(aTHX_ shot, "dy", 0);
    s->power = (int) pb_num(aTHX_ shot, "power", 0);
    s->sx = (int) pb_num(aTHX_ shot, "sx", 0);
    s->sy = (int) pb_num(aTHX_ shot, "sy", 0);
    s->trace = (int) pb_num(aTHX_ shot, "trace", 0);
}

/* An outcome as the hash the prototype's fixtures use, freed here. A rest row
 * is [id, x, y] whatever the layout row carried: the 0.03 contract, and a
 * caller that gave kinds knows them. */
static SV *pb_outcome_sv(pTHX_ struct pb_outcome *out, int trace) {
    HV *hv, *segs, *peak;
    AV *events, *rest, *holed, *energy, *row, *list, *downs;
    int i, last_id;
    const char *err;
    char key[32];

    hv = newHV();
    (void) hv_stores(hv, "t", newSVnv(out->t));
    (void) hv_stores(hv, "n", newSViv(out->n));
    err = pb_error_name(out->error);
    (void) hv_stores(hv, "error", err ? newSVpv(err, 0) : newSV(0));

    events = newAV();
    for (i = 0; i < out->nevents; i++) {
        row = newAV();
        av_push(row, newSVnv(out->events[i].t));
        av_push(row, newSVpv(pb_kind_name(out->events[i].kind), 0));
        av_push(row, newSViv(out->events[i].a));
        if (out->events[i].kind == PB_EV_BALL || out->events[i].kind == PB_EV_WALL
            || out->events[i].kind == PB_EV_NOSE || out->events[i].kind == PB_EV_POT) {
            av_push(row, newSViv(out->events[i].b));
        }
        av_push(events, newRV_noinc((SV *) row));
    }
    (void) hv_stores(hv, "events", newRV_noinc((SV *) events));

    rest = newAV();
    for (i = 0; i < out->nrest; i++) {
        row = newAV();
        av_push(row, newSViv(out->rest[i].id));
        av_push(row, newSViv(out->rest[i].x));
        av_push(row, newSViv(out->rest[i].y));
        av_push(rest, newRV_noinc((SV *) row));
    }
    (void) hv_stores(hv, "rest", newRV_noinc((SV *) rest));

    downs = newAV();
    for (i = 0; i < out->ndowns; i++) {
        row = newAV();
        av_push(row, newSViv(out->downs[i].id));
        av_push(row, newSViv(out->downs[i].x));
        av_push(row, newSViv(out->downs[i].y));
        av_push(row, newSVnv(out->downs[i].t));
        av_push(downs, newRV_noinc((SV *) row));
    }
    (void) hv_stores(hv, "down", newRV_noinc((SV *) downs));

    peak = newHV();
    for (i = 0; i < out->npeaks; i++) {
        (void) snprintf(key, sizeof key, "%d", out->peaks[i].id);
        (void) hv_store(peak, key, (I32) strlen(key), newSVnv(out->peaks[i].v), 0);
    }
    (void) hv_stores(hv, "peak", newRV_noinc((SV *) peak));

    holed = newAV();
    for (i = 0; i < out->nholed; i++) {
        row = newAV();
        av_push(row, newSViv(out->holed[i].id));
        av_push(row, newSViv(out->holed[i].pocket));
        av_push(row, newSVnv(out->holed[i].t));
        av_push(holed, newRV_noinc((SV *) row));
    }
    (void) hv_stores(hv, "holed", newRV_noinc((SV *) holed));

    segs = newHV();
    list = NULL; last_id = 0;
    for (i = 0; i < out->nsegments; i++) {
        if (!list || out->segments[i].id != last_id) {
            last_id = out->segments[i].id;
            (void) snprintf(key, sizeof key, "%d", last_id);
            list = newAV();
            (void) hv_store(segs, key, (I32) strlen(key), newRV_noinc((SV *) list), 0);
        }
        row = newAV();
        av_push(row, newSVnv(out->segments[i].t0));
        av_push(row, newSVnv(out->segments[i].dur));
        av_push(row, newSVnv(out->segments[i].px));
        av_push(row, newSVnv(out->segments[i].py));
        av_push(row, newSVnv(out->segments[i].vx));
        av_push(row, newSVnv(out->segments[i].vy));
        av_push(row, newSVnv(out->segments[i].ax));
        av_push(row, newSVnv(out->segments[i].ay));
        av_push(list, newRV_noinc((SV *) row));
    }
    (void) hv_stores(hv, "segments", newRV_noinc((SV *) segs));

    /* ABI 4: the state at the horizon, only from an advance, so a strike's
     * hash is what it was */
    if (out->nstate > 0) {
        AV *state = newAV();
        for (i = 0; i < out->nstate; i++) {
            row = newAV();
            av_push(row, newSViv(out->state[i].id));
            av_push(row, newSViv(out->state[i].x));
            av_push(row, newSViv(out->state[i].y));
            av_push(row, newSViv(out->state[i].vx));
            av_push(row, newSViv(out->state[i].vy));
            av_push(row, newSViv(out->state[i].mode));
            av_push(state, newRV_noinc((SV *) row));
        }
        (void) hv_stores(hv, "state", newRV_noinc((SV *) state));
    }

    if (trace) {
        energy = newAV();
        for (i = 0; i < out->nenergy; i++) av_push(energy, newSVnv(out->energy[i]));
        (void) hv_stores(hv, "energy", newRV_noinc((SV *) energy));
    }
    pb_outcome_free(out);
    return newRV_noinc((SV *) hv);
}

MODULE = Physics::Balls    PACKAGE = Physics::Balls::Engine

PROTOTYPES: DISABLE

# A world from a description hash: L, W, R, g, vmax, mu => {s, r, sp},
# e => {bb, c, cf, rc}, walls => [[x1,y1,x2,y2]...], noses => [[x,y]...],
# gates => [[x1,y1,x2,y2,nx,ny,pocket]...], and since 0.03 an optional
# curve => {k, vref, vmin, kmax, p, cap, vfrac} and kinds => [{curve, follow,
# and since 0.04 r, m, mu, rs, vfall}...]; a kind member left out or 0 is the
# engine's default for it.
# Returns the address as an unsigned integer; Physics::Balls::Engine keeps it
# and frees it in DESTROY.
UV
_new_world(desc)
        HV *desc
    PREINIT:
        struct pb_desc2 d;
        struct pb_world *w;
        struct pb_kind *kinds;
        HV *mu, *e, *cv, *kh;
        AV *ka;
        SV **kp;
        double *walls, *noses, *gates;
        int nw, nn, ng, nk, i;
    CODE:
        memset(&d, 0, sizeof d);
        d.size = (unsigned int) sizeof d;
        mu = pb_hash(aTHX_ desc, "mu");
        e = pb_hash(aTHX_ desc, "e");
        cv = pb_hash(aTHX_ desc, "curve");
        d.base.L = pb_num(aTHX_ desc, "L", 0); d.base.W = pb_num(aTHX_ desc, "W", 0); d.base.R = pb_num(aTHX_ desc, "R", 0);
        d.base.g = pb_num(aTHX_ desc, "g", 9.81);
        d.base.vmax = pb_num(aTHX_ desc, "vmax", 8);
        d.base.mu_s = mu ? pb_num(aTHX_ mu, "s", 0.2) : 0.2;
        d.base.mu_r = mu ? pb_num(aTHX_ mu, "r", 0.02) : 0.02;
        d.base.mu_sp = mu ? pb_num(aTHX_ mu, "sp", 0.044) : 0.044;
        d.base.e_bb = e ? pb_num(aTHX_ e, "bb", 0.95) : 0.95;
        d.base.e_c = e ? pb_num(aTHX_ e, "c", 0.8) : 0.8;
        d.base.e_cf = e ? pb_num(aTHX_ e, "cf", 0.2) : 0.2;
        d.base.e_rc = e ? pb_num(aTHX_ e, "rc", 0.7) : 0.7;
        walls = pb_flat(aTHX_ pb_array(aTHX_ desc, "walls"), 4, &nw);
        noses = pb_flat(aTHX_ pb_array(aTHX_ desc, "noses"), 2, &nn);
        gates = pb_flat(aTHX_ pb_array(aTHX_ desc, "gates"), 7, &ng);
        d.base.nwalls = nw; d.base.walls = walls;
        d.base.nnoses = nn; d.base.noses = noses;
        d.base.ngates = ng; d.base.gates = gates;
        d.curve_k = cv ? pb_num(aTHX_ cv, "k", 0) : 0;
        d.curve_vref = cv ? pb_num(aTHX_ cv, "vref", 1) : 1;
        d.curve_vmin = cv ? pb_num(aTHX_ cv, "vmin", 0.1) : 0.1;
        d.curve_kmax = cv ? pb_num(aTHX_ cv, "kmax", 1) : 1;
        d.curve_p = cv ? (int) pb_num(aTHX_ cv, "p", 2) : 2;
        d.turn_cap = cv ? pb_num(aTHX_ cv, "cap", 0.002) : 0.002;
        d.turn_vfrac = cv ? pb_num(aTHX_ cv, "vfrac", 0.1) : 0.1;
        ka = pb_array(aTHX_ desc, "kinds");
        nk = ka ? av_len(ka) + 1 : 0;
        Newxz(kinds, nk ? nk : 1, struct pb_kind);
        for (i = 0; i < nk; i++) {
            kp = av_fetch(ka, i, 0);
            kh = (kp && SvROK(*kp) && SvTYPE(SvRV(*kp)) == SVt_PVHV) ? (HV *) SvRV(*kp) : NULL;
            kinds[i].curve = kh ? pb_num(aTHX_ kh, "curve", 0) : 0;
            kinds[i].follow = kh ? pb_num(aTHX_ kh, "follow", 1) : 1;
            kinds[i].r = kh ? pb_num(aTHX_ kh, "r", 0) : 0;
            kinds[i].m = kh ? pb_num(aTHX_ kh, "m", 0) : 0;
            kinds[i].mu = kh ? pb_num(aTHX_ kh, "mu", 0) : 0;
            kinds[i].rs = kh ? pb_num(aTHX_ kh, "rs", 0) : 0;
            kinds[i].vfall = kh ? pb_num(aTHX_ kh, "vfall", 0) : 0;
        }
        d.nkinds = nk; d.kinds = kinds; d.kind_stride = (int) sizeof(struct pb_kind);
        w = pb_world_new_ex(&d);
        Safefree(walls); Safefree(noses); Safefree(gates); Safefree(kinds);
        if (!w) croak("Physics::Balls::Engine: could not build a world");
        RETVAL = PTR2UV(w);
    OUTPUT:
        RETVAL

void
_free_world(ptr)
        UV ptr
    CODE:
        if (ptr) pb_world_free(INT2PTR(struct pb_world *, ptr));

# One shot. layout is [[id, x, y], ...] or [[id, x, y, kind], ...] in
# hundredths of a millimetre; shot is {ball, dx, dy, power, sx, sy, trace} and
# optionally {adjust, adjust_at, adjust_axis, adjust_dir, adjust_mu,
# adjust_curve} and since 0.04 {tx, ty, spin}. Returns {t, n, error, events,
# rest, holed, down, peak, segments, energy} in the shape the prototype's
# fixtures use, with event kinds as the same words. A rest row is [id, x, y]
# whatever its layout row carried.
SV *
_strike(ptr, layout, shot)
        UV ptr
        AV *layout
        HV *shot
    PREINIT:
        struct pb_world *w;
        struct pb_ball_in2 *balls;
        struct pb_shot2 s;
        struct pb_outcome *out;
        AV *row;
        int n, i;
        SV **rp, **v;
    CODE:
        w = INT2PTR(struct pb_world *, ptr);
        if (!w) croak("Physics::Balls::Engine: no world");
        n = av_len(layout) + 1;
        Newxz(balls, n ? n : 1, struct pb_ball_in2);
        for (i = 0; i < n; i++) {
            rp = av_fetch(layout, i, 0);
            if (!rp || !SvROK(*rp) || SvTYPE(SvRV(*rp)) != SVt_PVAV) {
                Safefree(balls);
                croak("Physics::Balls::Engine: layout entry %d is not [id, x, y] or [id, x, y, kind]", i);
            }
            row = (AV *) SvRV(*rp);
            v = av_fetch(row, 0, 0); balls[i].id = v ? (int) SvIV(*v) : 0;
            v = av_fetch(row, 1, 0); balls[i].x = v ? (long) SvIV(*v) : 0;
            v = av_fetch(row, 2, 0); balls[i].y = v ? (long) SvIV(*v) : 0;
            v = av_fetch(row, 3, 0); balls[i].kind = v && SvOK(*v) ? (int) SvIV(*v) : 0;
        }
        memset(&s, 0, sizeof s);
        s.size = (unsigned int) sizeof s;
        pb_shot_from(aTHX_ shot, &s.base);
        s.adjust = (int) pb_num(aTHX_ shot, "adjust", 0) ? 1 : 0;
        s.adjust_at = (long) pb_num(aTHX_ shot, "adjust_at", 0);
        s.adjust_axis = (int) pb_num(aTHX_ shot, "adjust_axis", 1);
        s.adjust_dir = (int) pb_num(aTHX_ shot, "adjust_dir", 1);
        s.adjust_mu = (int) pb_num(aTHX_ shot, "adjust_mu", 1000);
        s.adjust_curve = (int) pb_num(aTHX_ shot, "adjust_curve", 1000);
        s.tx = (long) pb_num(aTHX_ shot, "tx", 0);
        s.ty = (long) pb_num(aTHX_ shot, "ty", 0);
        s.spin = (int) pb_num(aTHX_ shot, "spin", 0);
        out = pb_strike_ex(w, n, balls, (int) sizeof(struct pb_ball_in2), &s);
        Safefree(balls);
        if (!out) croak("Physics::Balls::Engine: could not allocate an outcome");
        RETVAL = pb_outcome_sv(aTHX_ out, s.base.trace);
    OUTPUT:
        RETVAL

# ABI 4: one advance. layout is [[id, x, y, kind, vx, vy], ...], the velocity
# in hundredths of a millimetre a second (a row of three or four is
# stationary); tick is {t, trace}, t the horizon in microseconds. Returns the
# strike's hash plus `state`, [[id, x, y, vx, vy, mode], ...] at the horizon.
SV *
_advance(ptr, layout, tick)
        UV ptr
        AV *layout
        HV *tick
    PREINIT:
        struct pb_world *w;
        struct pb_ball_in3 *balls;
        struct pb_tick tk;
        struct pb_outcome *out;
        AV *row;
        int n, i;
        SV **rp, **v;
    CODE:
        w = INT2PTR(struct pb_world *, ptr);
        if (!w) croak("Physics::Balls::Engine: no world");
        n = av_len(layout) + 1;
        Newxz(balls, n ? n : 1, struct pb_ball_in3);
        for (i = 0; i < n; i++) {
            rp = av_fetch(layout, i, 0);
            if (!rp || !SvROK(*rp) || SvTYPE(SvRV(*rp)) != SVt_PVAV) {
                Safefree(balls);
                croak("Physics::Balls::Engine: layout entry %d is not [id, x, y, kind, vx, vy]", i);
            }
            row = (AV *) SvRV(*rp);
            v = av_fetch(row, 0, 0); balls[i].id = v ? (int) SvIV(*v) : 0;
            v = av_fetch(row, 1, 0); balls[i].x = v ? (long) SvIV(*v) : 0;
            v = av_fetch(row, 2, 0); balls[i].y = v ? (long) SvIV(*v) : 0;
            v = av_fetch(row, 3, 0); balls[i].kind = v && SvOK(*v) ? (int) SvIV(*v) : 0;
            v = av_fetch(row, 4, 0); balls[i].vx = v && SvOK(*v) ? (long) SvIV(*v) : 0;
            v = av_fetch(row, 5, 0); balls[i].vy = v && SvOK(*v) ? (long) SvIV(*v) : 0;
        }
        memset(&tk, 0, sizeof tk);
        tk.size = (unsigned int) sizeof tk;
        tk.dt = (long) pb_num(aTHX_ tick, "t", 20000);
        tk.trace = (int) pb_num(aTHX_ tick, "trace", 0);
        out = pb_advance(w, n, (const struct pb_ball_in2 *) (const void *) balls, (int) sizeof(struct pb_ball_in3), &tk);
        Safefree(balls);
        if (!out) croak("Physics::Balls::Engine: could not allocate an outcome");
        RETVAL = pb_outcome_sv(aTHX_ out, tk.trace);
    OUTPUT:
        RETVAL

# The same shot through the ABI 1 entry point, rows of three, no kind and no
# adjust: for the test that the v1 wrappers are the v2 path with the v1
# defaults, bit for bit.
SV *
_strike_v1(ptr, layout, shot)
        UV ptr
        AV *layout
        HV *shot
    PREINIT:
        struct pb_world *w;
        struct pb_ball_in *balls;
        struct pb_shot s;
        struct pb_outcome *out;
        AV *row;
        int n, i;
        SV **rp, **v;
    CODE:
        w = INT2PTR(struct pb_world *, ptr);
        if (!w) croak("Physics::Balls::Engine: no world");
        n = av_len(layout) + 1;
        Newxz(balls, n ? n : 1, struct pb_ball_in);
        for (i = 0; i < n; i++) {
            rp = av_fetch(layout, i, 0);
            if (!rp || !SvROK(*rp) || SvTYPE(SvRV(*rp)) != SVt_PVAV) {
                Safefree(balls);
                croak("Physics::Balls::Engine: layout entry %d is not [id, x, y]", i);
            }
            row = (AV *) SvRV(*rp);
            v = av_fetch(row, 0, 0); balls[i].id = v ? (int) SvIV(*v) : 0;
            v = av_fetch(row, 1, 0); balls[i].x = v ? (long) SvIV(*v) : 0;
            v = av_fetch(row, 2, 0); balls[i].y = v ? (long) SvIV(*v) : 0;
        }
        pb_shot_from(aTHX_ shot, &s);
        out = pb_strike(w, n, balls, &s);
        Safefree(balls);
        if (!out) croak("Physics::Balls::Engine: could not allocate an outcome");
        RETVAL = pb_outcome_sv(aTHX_ out, s.trace);
    OUTPUT:
        RETVAL

# A v2 struct whose size is smaller than this version needs is refused: the
# world is not built, the strike returns the size error, and since ABI 4 so
# does an advance with a short tick. For t/10 and t/13.
IV
_bad_size_refused(ptr)
        UV ptr
    PREINIT:
        struct pb_desc2 d;
        struct pb_shot2 s;
        struct pb_ball_in2 one;
        struct pb_ball_in3 three;
        struct pb_tick tk;
        struct pb_world *w;
        struct pb_outcome *out;
        int refused = 0;
    CODE:
        memset(&tk, 0, sizeof tk);
        tk.size = 1; tk.dt = 20000;
        three.id = 0; three.x = 0; three.y = 0; three.kind = 0; three.vx = 0; three.vy = 0;
        out = pb_advance(INT2PTR(struct pb_world *, ptr), 1, (const struct pb_ball_in2 *) (const void *) &three, (int) sizeof three, &tk);
        if (out) { if (out->error == PB_ERR_SIZE) refused++; pb_outcome_free(out); }
        memset(&d, 0, sizeof d);
        d.size = 1;
        d.base.L = 1; d.base.W = 1; d.base.R = 0.01; d.base.g = 9.81; d.base.vmax = 1;
        w = pb_world_new_ex(&d);
        if (!w) refused++;
        else pb_world_free(w);
        memset(&s, 0, sizeof s);
        s.size = 1;
        s.base.dx = 1000000; s.base.power = 100;
        one.id = 0; one.x = 0; one.y = 0; one.kind = 0;
        out = pb_strike_ex(INT2PTR(struct pb_world *, ptr), 1, &one, (int) sizeof one, &s);
        if (out) { if (out->error == PB_ERR_SIZE) refused++; pb_outcome_free(out); }
        RETVAL = refused == 3;
    OUTPUT:
        RETVAL

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(pb_abi_table());
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = PB_ABI_VERSION;
    OUTPUT:
        RETVAL

IV
_float_eval_method()
    CODE:
        RETVAL = pb_float_eval_method();
    OUTPUT:
        RETVAL
