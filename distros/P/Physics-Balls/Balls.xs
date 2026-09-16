/*
 * Balls.xs - the XS door over pb_engine.c for Physics::Balls.
 *
 * At the top of the dist, not under lib/, for the reason Struct::Codec's
 * Codec.xs gives: an XSMULTI build's export list and Strawberry's import
 * library rule never agree on a name.
 *
 * The engine is perl-free; this file only turns a description hash into a
 * pb_desc, a layout array into pb_ball_in, and an outcome back into Perl
 * structures. Every SV built here is owned by the structure it goes into, and
 * the one returned is a fresh reference xsubpp mortalises itself.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pb_abi.h"

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
        default: return "unknown";
    }
}

static const char *pb_error_name(int err) {
    switch (err) {
        case PB_OK: return NULL;
        case PB_ERR_EVENTS: return "events";
        case PB_ERR_TIME: return "time";
        case PB_ERR_NO_BALL: return "no_ball";
        default: return "memory";
    }
}

MODULE = Physics::Balls    PACKAGE = Physics::Balls::Engine

PROTOTYPES: DISABLE

# A world from a description hash: L, W, R, g, vmax, mu => {s, r, sp},
# e => {bb, c, cf, rc}, walls => [[x1,y1,x2,y2]...], noses => [[x,y]...],
# gates => [[x1,y1,x2,y2,nx,ny,pocket]...]. Returns the address as an unsigned
# integer; Physics::Balls::Engine keeps it and frees it in DESTROY.
UV
_new_world(desc)
        HV *desc
    PREINIT:
        struct pb_desc d;
        struct pb_world *w;
        HV *mu, *e;
        double *walls, *noses, *gates;
        int nw, nn, ng;
    CODE:
        mu = pb_hash(aTHX_ desc, "mu");
        e = pb_hash(aTHX_ desc, "e");
        d.L = pb_num(aTHX_ desc, "L", 0); d.W = pb_num(aTHX_ desc, "W", 0); d.R = pb_num(aTHX_ desc, "R", 0);
        d.g = pb_num(aTHX_ desc, "g", 9.81);
        d.vmax = pb_num(aTHX_ desc, "vmax", 8);
        d.mu_s = mu ? pb_num(aTHX_ mu, "s", 0.2) : 0.2;
        d.mu_r = mu ? pb_num(aTHX_ mu, "r", 0.02) : 0.02;
        d.mu_sp = mu ? pb_num(aTHX_ mu, "sp", 0.044) : 0.044;
        d.e_bb = e ? pb_num(aTHX_ e, "bb", 0.95) : 0.95;
        d.e_c = e ? pb_num(aTHX_ e, "c", 0.8) : 0.8;
        d.e_cf = e ? pb_num(aTHX_ e, "cf", 0.2) : 0.2;
        d.e_rc = e ? pb_num(aTHX_ e, "rc", 0.7) : 0.7;
        walls = pb_flat(aTHX_ pb_array(aTHX_ desc, "walls"), 4, &nw);
        noses = pb_flat(aTHX_ pb_array(aTHX_ desc, "noses"), 2, &nn);
        gates = pb_flat(aTHX_ pb_array(aTHX_ desc, "gates"), 7, &ng);
        d.nwalls = nw; d.walls = walls;
        d.nnoses = nn; d.noses = noses;
        d.ngates = ng; d.gates = gates;
        w = pb_world_new(&d);
        Safefree(walls); Safefree(noses); Safefree(gates);
        if (!w) croak("Physics::Balls::Engine: could not allocate a world");
        RETVAL = PTR2UV(w);
    OUTPUT:
        RETVAL

void
_free_world(ptr)
        UV ptr
    CODE:
        if (ptr) pb_world_free(INT2PTR(struct pb_world *, ptr));

# One shot. layout is [[id, x, y], ...] in hundredths of a millimetre; shot is
# {ball, dx, dy, power, sx, sy, trace}. Returns {t, n, error, events, rest,
# holed, segments, energy} in the shape the prototype's fixtures use, with
# event kinds as the same words.
SV *
_strike(ptr, layout, shot)
        UV ptr
        AV *layout
        HV *shot
    PREINIT:
        struct pb_world *w;
        struct pb_ball_in *balls;
        struct pb_shot s;
        struct pb_outcome *out;
        HV *hv, *segs;
        AV *events, *rest, *holed, *energy, *row, *list;
        int n, i, last_id;
        SV **rp, **v;
        const char *err;
        char key[32];
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
        s.ball = (int) pb_num(aTHX_ shot, "ball", 0);
        s.dx = (long) pb_num(aTHX_ shot, "dx", 0);
        s.dy = (long) pb_num(aTHX_ shot, "dy", 0);
        s.power = (int) pb_num(aTHX_ shot, "power", 0);
        s.sx = (int) pb_num(aTHX_ shot, "sx", 0);
        s.sy = (int) pb_num(aTHX_ shot, "sy", 0);
        s.trace = (int) pb_num(aTHX_ shot, "trace", 0);
        out = pb_strike(w, n, balls, &s);
        Safefree(balls);
        if (!out) croak("Physics::Balls::Engine: could not allocate an outcome");

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

        if (s.trace) {
            energy = newAV();
            for (i = 0; i < out->nenergy; i++) av_push(energy, newSVnv(out->energy[i]));
            (void) hv_stores(hv, "energy", newRV_noinc((SV *) energy));
        }
        pb_outcome_free(out);
        RETVAL = newRV_noinc((SV *) hv);
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
