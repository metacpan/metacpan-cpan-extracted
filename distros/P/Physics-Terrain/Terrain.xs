/*
 * Terrain.xs - the XS door over pt_engine.c for Physics::Terrain.
 *
 * At the top of the dist, not under lib/, for the reason Struct::Codec's
 * Codec.xs gives: an XSMULTI build's export list and Strawberry's import
 * library rule never agree on a name.
 *
 * The engine is perl-free and every method Perl sees is an XSUB here: an
 * object is a blessed scalar holding the state's address, and this file only
 * turns option hashes into pt_opts, input logs into pt_input arrays, and an
 * outcome back into the plain hashes and arrays the prototype's fixtures use.
 * Every SV built here is owned by the structure it goes into, and the one
 * returned is a fresh reference xsubpp mortalises itself.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pt_abi.h"

#define PT (pt_abi_table())

static struct pt_state *pt_self(pTHX_ SV *sv, const char *who) {
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Physics::Terrain"))
        croak("Physics::Terrain::%s: not a Physics::Terrain object", who);
    return INT2PTR(struct pt_state *, SvUV(SvRV(sv)));
}

static struct pt_snapshot *pt_snap(pTHX_ SV *sv, const char *who) {
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Physics::Terrain::Snapshot"))
        croak("Physics::Terrain::%s: not a Physics::Terrain::Snapshot object", who);
    return INT2PTR(struct pt_snapshot *, SvUV(SvRV(sv)));
}

static SV *pt_wrap(pTHX_ void *p, const char *class) {
    SV *inner = newSV(0);
    SV *rv;
    sv_setuv(inner, PTR2UV(p));
    rv = newRV_noinc(inner);
    sv_bless(rv, gv_stashpv(class, GV_ADD));
    return rv;
}

static SV **pt_fetch(pTHX_ HV *hv, const char *key) {
    return hv_fetch(hv, key, (I32) strlen(key), 0);
}
static IV pt_int(pTHX_ HV *hv, const char *key, IV dflt) {
    SV **v = pt_fetch(aTHX_ hv, key);
    return v && SvOK(*v) ? SvIV(*v) : dflt;
}
static AV *pt_array(pTHX_ HV *hv, const char *key) {
    SV **v = pt_fetch(aTHX_ hv, key);
    if (v && SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVAV) return (AV *) SvRV(*v);
    return NULL;
}
static HV *pt_hash(pTHX_ HV *hv, const char *key) {
    SV **v = pt_fetch(aTHX_ hv, key);
    if (v && SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVHV) return (HV *) SvRV(*v);
    return NULL;
}
static IV pt_row_int(pTHX_ AV *row, I32 i, IV dflt) {
    SV **v = av_fetch(row, i, 0);
    return v && SvOK(*v) ? SvIV(*v) : dflt;
}
static const char *pt_str(pTHX_ HV *hv, const char *key) {
    SV **v = pt_fetch(aTHX_ hv, key);
    return v && SvOK(*v) ? SvPV_nolen(*v) : NULL;
}

/* {tick, weapon, angle, power} into a pt_shot; returns the tick, or -1 for no shot */
static IV pt_read_shot(pTHX_ SV *sv, struct pt_shot *out) {
    HV *hv;
    if (!sv || !SvOK(sv)) return -1;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV) croak("Physics::Terrain: a shot is a hash of weapon, angle, power and tick");
    hv = (HV *) SvRV(sv);
    out->weapon = (int32_t) pt_int(aTHX_ hv, "weapon", 0);
    out->angle = (int32_t) pt_int(aTHX_ hv, "angle", 0);
    out->power = (int32_t) pt_int(aTHX_ hv, "power", 0);
    return pt_int(aTHX_ hv, "tick", 0);
}

static int pt_op_code(const char *name) {
    if (strEQ(name, "fill")) return PT_OP_FILL;
    if (strEQ(name, "clear")) return PT_OP_CLEAR;
    if (strEQ(name, "slope")) return PT_OP_SLOPE;
    if (strEQ(name, "disc")) return PT_OP_DISC;
    if (strEQ(name, "platform")) return PT_OP_PLATFORM;
    return -1;
}

/* [['fill', x0, y0, x1, y1], ...] into pt_sculpt; the caller frees */
static struct pt_sculpt *pt_read_sculpt(pTHX_ AV *ops, int32_t *count) {
    struct pt_sculpt *out;
    I32 n, i;
    n = ops ? av_len(ops) + 1 : 0;
    *count = n;
    Newxz(out, n ? n : 1, struct pt_sculpt);
    for (i = 0; i < n; i++) {
        SV **rp = av_fetch(ops, i, 0);
        AV *row;
        SV **nm;
        int code;
        if (!rp || !SvROK(*rp) || SvTYPE(SvRV(*rp)) != SVt_PVAV) { Safefree(out); croak("Physics::Terrain: sculpt op %d is not an array", (int) i); }
        row = (AV *) SvRV(*rp);
        nm = av_fetch(row, 0, 0);
        code = nm && SvOK(*nm) ? pt_op_code(SvPV_nolen(*nm)) : -1;
        if (code < 0) { Safefree(out); croak("Physics::Terrain: sculpt op %d has no known name", (int) i); }
        out[i].op = code;
        out[i].a = (int32_t) pt_row_int(aTHX_ row, 1, 0);
        out[i].b = (int32_t) pt_row_int(aTHX_ row, 2, 0);
        out[i].c = (int32_t) pt_row_int(aTHX_ row, 3, 0);
        out[i].d = (int32_t) pt_row_int(aTHX_ row, 4, 0);
    }
    return out;
}

static void pt_read_gen(pTHX_ HV *gen, struct pt_gen *g) {
    const char *profile = pt_str(aTHX_ gen, "profile");
    g->profile = -1;
    if (profile) {
        if (strEQ(profile, "flat")) g->profile = PT_GEN_FLAT;
        else if (strEQ(profile, "empty")) g->profile = PT_GEN_EMPTY;
        else if (strEQ(profile, "noise")) g->profile = PT_GEN_NOISE;
        else croak("Physics::Terrain: unknown generator profile %s", profile);
    }
    g->W = (int32_t) pt_int(aTHX_ gen, "W", 0);
    g->H = (int32_t) pt_int(aTHX_ gen, "H", 0);
    g->coarse = (int32_t) pt_int(aTHX_ gen, "coarse", 0);
    g->fine = (int32_t) pt_int(aTHX_ gen, "fine", 0);
    g->cave = (int32_t) pt_int(aTHX_ gen, "cave", 0);
    g->threshold = (int32_t) pt_int(aTHX_ gen, "threshold", 0);
    g->bias_scale = (int32_t) pt_int(aTHX_ gen, "biasScale", 0);
    g->bias_offset = (int32_t) pt_int(aTHX_ gen, "biasOffset", 0);
    g->cave_lo = (int32_t) pt_int(aTHX_ gen, "caveLo", 0);
    g->cave_hi = (int32_t) pt_int(aTHX_ gen, "caveHi", 0);
    g->cave_top = (int32_t) pt_int(aTHX_ gen, "caveTop", 0);
    g->cave_bottom = (int32_t) pt_int(aTHX_ gen, "caveBottom", 0);
    g->platform = (int32_t) pt_int(aTHX_ gen, "platform", 0);
    g->headroom = (int32_t) pt_int(aTHX_ gen, "headroom", 0);
    g->floor = (int32_t) pt_int(aTHX_ gen, "floor", -1);
}

static AV *pt_body_av(pTHX_ const struct pt_body *b) {
    AV *row = newAV();
    av_push(row, newSViv(b->seat)); av_push(row, newSViv(b->x)); av_push(row, newSViv(b->y));
    av_push(row, newSViv(b->vx)); av_push(row, newSViv(b->vy)); av_push(row, newSViv(b->mode));
    av_push(row, newSViv(b->alive)); av_push(row, newSViv(b->facing));
    return row;
}

static HV *pt_body_hv(pTHX_ const struct pt_body *b, IV index) {
    HV *hv = newHV();
    (void) hv_stores(hv, "index", newSViv(index));
    (void) hv_stores(hv, "seat", newSViv(b->seat));
    (void) hv_stores(hv, "k", newSViv(b->k));
    (void) hv_stores(hv, "x", newSViv(b->x));
    (void) hv_stores(hv, "y", newSViv(b->y));
    (void) hv_stores(hv, "vx", newSViv(b->vx));
    (void) hv_stores(hv, "vy", newSViv(b->vy));
    (void) hv_stores(hv, "mode", newSViv(b->mode));
    (void) hv_stores(hv, "hp", newSViv(b->hp));
    (void) hv_stores(hv, "alive", newSViv(b->alive));
    (void) hv_stores(hv, "facing", newSViv(b->facing));
    return hv;
}

/* the trace rows for one side, grouped by who into a sparse array of lists */
static AV *pt_trace_av(pTHX_ const struct pt_trace *rows, int32_t n, int with_weapon) {
    AV *out = newAV();
    int32_t i;
    for (i = 0; i < n; i++) {
        SV **slot = av_fetch(out, rows[i].who, 1);
        AV *list, *row;
        if (!slot) continue;
        if (!SvROK(*slot)) { list = newAV(); sv_setsv(*slot, sv_2mortal(newRV_noinc((SV *) list))); }
        else list = (AV *) SvRV(*slot);
        row = newAV();
        av_push(row, newSViv(rows[i].tick)); av_push(row, newSViv(rows[i].x)); av_push(row, newSViv(rows[i].y));
        if (with_weapon && rows[i].weapon != -1) {
            const struct pt_weapon *w = rows[i].weapon >= 0 ? (PT->weapon_get)(rows[i].weapon) : NULL;
            av_push(row, w && w->id ? newSVpv(w->id, 0) : newSV(0));
        }
        av_push(list, newRV_noinc((SV *) row));
    }
    return out;
}

static SV *pt_outcome_sv(pTHX_ struct pt_outcome *o) {
    HV *hv = newHV(), *shot, *end;
    AV *list, *row, *health;
    int32_t i;
    const char *err;
    (void) hv_stores(hv, "engine", newSViv(1));
    (void) hv_stores(hv, "seed", newSVuv(o->seed));
    (void) hv_stores(hv, "active", newSViv(o->active));
    (void) hv_stores(hv, "wind", newSViv(o->wind));
    (void) hv_stores(hv, "ticks", newSViv(o->ticks));
    (void) hv_stores(hv, "settledAt", newSViv(o->settled_at));
    err = (PT->error_name)(o->error);
    (void) hv_stores(hv, "error", err ? newSVpv(err, 0) : newSV(0));
    if (o->has_shot) {
        shot = newHV();
        (void) hv_stores(shot, "tick", newSViv(o->shot_tick));
        (void) hv_stores(shot, "weapon", newSViv(o->shot.weapon));
        (void) hv_stores(shot, "angle", newSViv(o->shot.angle));
        (void) hv_stores(shot, "power", newSViv(o->shot.power));
        (void) hv_stores(hv, "shot", newRV_noinc((SV *) shot));
    } else (void) hv_stores(hv, "shot", newSV(0));
    list = newAV();
    for (i = 0; i < o->ninputs; i++) {
        row = newAV(); av_push(row, newSViv(o->inputs[i].tick)); av_push(row, newSViv(o->inputs[i].bits));
        av_push(list, newRV_noinc((SV *) row));
    }
    (void) hv_stores(hv, "inputs", newRV_noinc((SV *) list));
    list = newAV();
    for (i = 0; i < o->nevents; i++) {
        row = newAV();
        av_push(row, newSViv(o->events[i].tick)); av_push(row, newSVpv((PT->event_name)(o->events[i].kind), 0));
        av_push(row, newSViv(o->events[i].a)); av_push(row, newSViv(o->events[i].b));
        av_push(list, newRV_noinc((SV *) row));
    }
    (void) hv_stores(hv, "events", newRV_noinc((SV *) list));
    list = newAV();
    for (i = 0; i < o->ncraters; i++) {
        row = newAV(); av_push(row, newSViv(o->craters[i].x)); av_push(row, newSViv(o->craters[i].y)); av_push(row, newSViv(o->craters[i].r));
        av_push(list, newRV_noinc((SV *) row));
    }
    (void) hv_stores(hv, "craters", newRV_noinc((SV *) list));
    {
        HV *trace = newHV();
        (void) hv_stores(trace, "bodies", newRV_noinc((SV *) pt_trace_av(aTHX_ o->trace_bodies, o->ntrace_bodies, 0)));
        (void) hv_stores(trace, "shots", newRV_noinc((SV *) pt_trace_av(aTHX_ o->trace_shots, o->ntrace_shots, 1)));
        (void) hv_stores(hv, "trace", newRV_noinc((SV *) trace));
    }
    list = newAV();
    for (i = 0; i < o->nladder; i++) {
        row = newAV(); av_push(row, newSViv(o->ladder[i].tick)); av_push(row, newSVuv(o->ladder[i].h1)); av_push(row, newSVuv(o->ladder[i].h2));
        av_push(list, newRV_noinc((SV *) row));
    }
    (void) hv_stores(hv, "hashes", newRV_noinc((SV *) list));
    end = newHV();
    (void) hv_stores(end, "tick", newSViv(o->end_tick));
    list = newAV(); health = newAV();
    for (i = 0; i < o->nbodies; i++) {
        av_push(list, newRV_noinc((SV *) pt_body_av(aTHX_ &o->bodies[i])));
        av_push(health, newSViv(o->bodies[i].hp));
    }
    (void) hv_stores(end, "bodies", newRV_noinc((SV *) list));
    (void) hv_stores(end, "health", newRV_noinc((SV *) health));
    (void) hv_stores(end, "craters", newSViv(o->end_craters));
    (void) hv_stores(hv, "end", newRV_noinc((SV *) end));
    return newRV_noinc((SV *) hv);
}

MODULE = Physics::Terrain    PACKAGE = Physics::Terrain

PROTOTYPES: DISABLE

# A field and its bodies from an option hash: seed, teams, per_team, wind,
# gen => {profile, W, H, ...}, sculpt => [[op, ...], ...], place => 'teams' |
# 'explicit' | 'none', bodies => [[seat, cx, cy_from, hp], ...].
SV *
new(class, ...)
        const char *class
    PREINIT:
        HV *opts = NULL;
        struct pt_opts o;
        struct pt_sculpt *ops = NULL;
        struct pt_body_in *bodies = NULL;
        struct pt_state *s;
        AV *av;
        HV *gen;
        const char *place;
        I32 i, n;
        int32_t nops = 0;
    CODE:
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) opts = (HV *) SvRV(ST(1));
        else if (items > 1) {
            if ((items - 1) % 2) croak("Physics::Terrain::new: odd number of options");
            opts = (HV *) sv_2mortal((SV *) newHV());
            for (i = 1; i < items; i += 2) (void) hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);
        } else opts = (HV *) sv_2mortal((SV *) newHV());
        memset(&o, 0, sizeof o);
        o.seed = (uint32_t) pt_int(aTHX_ opts, "seed", 1);
        o.teams = (int32_t) pt_int(aTHX_ opts, "teams", 2);
        o.per_team = (int32_t) pt_int(aTHX_ opts, "per_team", pt_int(aTHX_ opts, "perTeam", 4));
        o.live_cap = (int32_t) pt_int(aTHX_ opts, "live_cap", 0);
        o.settle_cap = (int32_t) pt_int(aTHX_ opts, "settle_cap", 0);
        if (o.teams < 1 || o.teams > 4) croak("Physics::Terrain::new: teams is 1 to 4");
        if (o.per_team < 1 || o.per_team > 8) croak("Physics::Terrain::new: per_team is 1 to 8");
        {
            SV **w = pt_fetch(aTHX_ opts, "wind");
            if (w && SvOK(*w)) { o.wind_set = 1; o.wind = (int32_t) SvIV(*w); }
        }
        gen = pt_hash(aTHX_ opts, "gen");
        if (gen) { o.use_gen = 1; pt_read_gen(aTHX_ gen, &o.gen); }
        av = pt_array(aTHX_ opts, "sculpt");
        if (av) { ops = pt_read_sculpt(aTHX_ av, &nops); o.nsculpt = nops; o.sculpt = ops; }
        place = pt_str(aTHX_ opts, "place");
        av = pt_array(aTHX_ opts, "bodies");
        if (place && strEQ(place, "none")) o.place = PT_PLACE_NONE;
        else if ((place && strEQ(place, "explicit")) || (!place && av)) o.place = PT_PLACE_EXPLICIT;
        else if (!place || strEQ(place, "teams")) o.place = PT_PLACE_TEAMS;
        else { Safefree(ops); croak("Physics::Terrain::new: place is teams, explicit or none"); }
        if (o.place == PT_PLACE_EXPLICIT) {
            n = av ? av_len(av) + 1 : 0;
            if (n > PT_MAX_BODIES) { Safefree(ops); croak("Physics::Terrain::new: at most %d bodies", PT_MAX_BODIES); }
            Newxz(bodies, n ? n : 1, struct pt_body_in);
            for (i = 0; i < n; i++) {
                SV **rp = av_fetch(av, i, 0);
                AV *row;
                if (!rp || !SvROK(*rp) || SvTYPE(SvRV(*rp)) != SVt_PVAV) { Safefree(ops); Safefree(bodies); croak("Physics::Terrain::new: body %d is not [seat, x, y_from, hp]", (int) i); }
                row = (AV *) SvRV(*rp);
                bodies[i].seat = (int32_t) pt_row_int(aTHX_ row, 0, 0);
                bodies[i].cx = (int32_t) pt_row_int(aTHX_ row, 1, 0);
                bodies[i].cy_from = (int32_t) pt_row_int(aTHX_ row, 2, 0);
                bodies[i].hp = (int32_t) pt_row_int(aTHX_ row, 3, 0);
                if (bodies[i].seat < 0 || bodies[i].seat > 3) { Safefree(ops); Safefree(bodies); croak("Physics::Terrain::new: seat is 0 to 3"); }
            }
            o.nbodies = (int32_t) n; o.bodies = bodies;
        }
        if (o.place == PT_PLACE_TEAMS && o.teams * o.per_team > PT_MAX_BODIES) { Safefree(ops); croak("Physics::Terrain::new: at most %d bodies", PT_MAX_BODIES); }
        s = (PT->state_new)(&o);
        Safefree(ops); Safefree(bodies);
        if (!s) croak("Physics::Terrain::new: could not build the field");
        RETVAL = pt_wrap(aTHX_ s, class);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    PREINIT:
        struct pt_state *s;
    CODE:
        s = pt_self(aTHX_ self, "DESTROY");
        if (s) { (PT->state_free)(s); sv_setuv(SvRV(self), 0); }

IV
width(self)
        SV *self
    CODE:
        RETVAL = (PT->width)(pt_self(aTHX_ self, "width"));
    OUTPUT:
        RETVAL

IV
height(self)
        SV *self
    CODE:
        RETVAL = (PT->height)(pt_self(aTHX_ self, "height"));
    OUTPUT:
        RETVAL

UV
seed(self)
        SV *self
    CODE:
        RETVAL = (PT->seed)(pt_self(aTHX_ self, "seed"));
    OUTPUT:
        RETVAL

IV
tick(self)
        SV *self
    CODE:
        RETVAL = (PT->tick)(pt_self(aTHX_ self, "tick"));
    OUTPUT:
        RETVAL

IV
teams(self)
        SV *self
    CODE:
        RETVAL = (PT->teams)(pt_self(aTHX_ self, "teams"));
    OUTPUT:
        RETVAL

IV
per_team(self)
        SV *self
    CODE:
        RETVAL = (PT->per_team)(pt_self(aTHX_ self, "per_team"));
    OUTPUT:
        RETVAL

IV
solid(self, x, y)
        SV *self
        IV x
        IV y
    CODE:
        RETVAL = (PT->solid)(pt_self(aTHX_ self, "solid"), (int32_t) x, (int32_t) y);
    OUTPUT:
        RETVAL

# The first solid cell on the segment, both ends included: returns (hit, x, y,
# px, py) where px, py is the last free cell before the hit.
void
swept(self, x0, y0, x1, y1)
        SV *self
        IV x0
        IV y0
        IV x1
        IV y1
    PREINIT:
        int32_t out[4];
        int32_t hit;
    PPCODE:
        hit = (PT->swept)(pt_self(aTHX_ self, "swept"), (int32_t) x0, (int32_t) y0, (int32_t) x1, (int32_t) y1, out);
        EXTEND(SP, 5);
        mPUSHi(hit); mPUSHi(out[0]); mPUSHi(out[1]); mPUSHi(out[2]); mPUSHi(out[3]);

IV
carve(self, x, y, r)
        SV *self
        IV x
        IV y
        IV r
    CODE:
        RETVAL = (PT->carve)(pt_self(aTHX_ self, "carve"), (int32_t) x, (int32_t) y, (int32_t) r);
    OUTPUT:
        RETVAL

void
sculpt(self, ops)
        SV *self
        AV *ops
    PREINIT:
        struct pt_sculpt *list;
        int32_t n;
        struct pt_state *s;
    CODE:
        s = pt_self(aTHX_ self, "sculpt");
        list = pt_read_sculpt(aTHX_ ops, &n);
        (PT->sculpt)(s, n, list);
        Safefree(list);

IV
surface_at(self, x, y_from = 0)
        SV *self
        IV x
        IV y_from
    CODE:
        RETVAL = (PT->surface_at)(pt_self(aTHX_ self, "surface_at"), (int32_t) x, (int32_t) y_from);
    OUTPUT:
        RETVAL

IV
count(self)
        SV *self
    CODE:
        RETVAL = (PT->count)(pt_self(aTHX_ self, "count"));
    OUTPUT:
        RETVAL

# The mask as packed bytes: row-major, eight cells a byte, the leftmost cell
# in the low bit. Digest it with Digest::SHA for the mask digest.
SV *
mask(self)
        SV *self
    PREINIT:
        struct pt_state *s;
        size_t n;
    CODE:
        s = pt_self(aTHX_ self, "mask");
        n = (PT->mask_bytes)(s);
        RETVAL = newSV(n + 1);
        SvPOK_on(RETVAL);
        (PT->mask_pack)(s, (uint8_t *) SvPVX(RETVAL));
        SvCUR_set(RETVAL, n);
        *SvEND(RETVAL) = 0;
    OUTPUT:
        RETVAL

# The index of the new body, or undef over the cap (error says why).
SV *
add_body(self, seat, cx, cy)
        SV *self
        IV seat
        IV cx
        IV cy
    PREINIT:
        int32_t i;
    CODE:
        if (seat < 0 || seat > 3) croak("Physics::Terrain::add_body: seat is 0 to 3");
        i = (PT->add_body)(pt_self(aTHX_ self, "add_body"), (int32_t) seat, (int32_t) cx, (int32_t) cy);
        RETVAL = i < 0 ? newSV(0) : newSViv(i);
    OUTPUT:
        RETVAL

IV
body_count(self)
        SV *self
    CODE:
        RETVAL = (PT->body_count)(pt_self(aTHX_ self, "body_count"));
    OUTPUT:
        RETVAL

SV *
body(self, i)
        SV *self
        IV i
    PREINIT:
        struct pt_body b;
    CODE:
        if ((PT->body_get)(pt_self(aTHX_ self, "body"), (int32_t) i, &b) < 0) RETVAL = newSV(0);
        else RETVAL = newRV_noinc((SV *) pt_body_hv(aTHX_ &b, i));
    OUTPUT:
        RETVAL

SV *
bodies(self)
        SV *self
    PREINIT:
        struct pt_state *s;
        struct pt_body b;
        AV *list;
        int32_t i, n;
    CODE:
        s = pt_self(aTHX_ self, "bodies");
        n = (PT->body_count)(s);
        list = newAV();
        for (i = 0; i < n; i++) {
            (PT->body_get)(s, i, &b);
            av_push(list, newRV_noinc((SV *) pt_body_hv(aTHX_ &b, i)));
        }
        RETVAL = newRV_noinc((SV *) list);
    OUTPUT:
        RETVAL

IV
alive(self, seat = -1)
        SV *self
        IV seat
    PREINIT:
        struct pt_state *s;
        struct pt_body b;
        int32_t i, n;
    CODE:
        s = pt_self(aTHX_ self, "alive");
        n = (PT->body_count)(s);
        RETVAL = 0;
        for (i = 0; i < n; i++) {
            (PT->body_get)(s, i, &b);
            if (b.alive && (seat < 0 || b.seat == seat)) RETVAL++;
        }
    OUTPUT:
        RETVAL

# Starts a turn for body $active and returns the wind; undef when there is
# no such body (error says 'state').
SV *
start_turn(self, active)
        SV *self
        IV active
    PREINIT:
        int32_t r;
    CODE:
        r = (PT->start_turn)(pt_self(aTHX_ self, "start_turn"), (int32_t) active);
        RETVAL = r == -PT_ERR_STATE ? newSV(0) : newSViv(r);
    OUTPUT:
        RETVAL

# One tick: the held bits, and the shot when this is the tick it fires.
# Returns the phase after the tick: live, settle or done.
const char *
advance(self, bits = 0, shot = NULL)
        SV *self
        IV bits
        SV *shot
    PREINIT:
        struct pt_shot sh;
        int32_t phase;
        int has = 0;
    CODE:
        if (shot && SvOK(shot)) { (void) pt_read_shot(aTHX_ shot, &sh); has = 1; }
        phase = (PT->advance)(pt_self(aTHX_ self, "advance"), (int32_t) bits, has ? &sh : NULL);
        RETVAL = phase == PT_PHASE_LIVE ? "live" : phase == PT_PHASE_SETTLE ? "settle" : phase == PT_PHASE_DONE ? "done" : "idle";
    OUTPUT:
        RETVAL

const char *
phase(self)
        SV *self
    PREINIT:
        int32_t phase;
    CODE:
        phase = (PT->phase)(pt_self(aTHX_ self, "phase"));
        RETVAL = phase == PT_PHASE_LIVE ? "live" : phase == PT_PHASE_SETTLE ? "settle" : phase == PT_PHASE_DONE ? "done" : "idle";
    OUTPUT:
        RETVAL

IV
turn_tick(self)
        SV *self
    CODE:
        RETVAL = (PT->turn_tick)(pt_self(aTHX_ self, "turn_tick"));
    OUTPUT:
        RETVAL

SV *
error(self)
        SV *self
    PREINIT:
        const char *e;
    CODE:
        e = (PT->error_name)((PT->error)(pt_self(aTHX_ self, "error")));
        RETVAL = e ? newSVpv(e, 0) : newSV(0);
    OUTPUT:
        RETVAL

SV *
outcome(self)
        SV *self
    PREINIT:
        struct pt_outcome *o;
    CODE:
        o = (PT->outcome)(pt_self(aTHX_ self, "outcome"));
        if (!o) croak("Physics::Terrain::outcome: could not allocate an outcome");
        RETVAL = pt_outcome_sv(aTHX_ o);
        (PT->outcome_free)(o);
    OUTPUT:
        RETVAL

# A whole turn from a recorded input log [[tick, bits], ...] and a shot
# {tick, weapon, angle, power} or undef. Returns the outcome.
SV *
run_turn(self, active, inputs, shot = NULL)
        SV *self
        IV active
        AV *inputs
        SV *shot
    PREINIT:
        struct pt_input *list;
        struct pt_shot sh;
        struct pt_outcome *o;
        IV shot_tick = -1;
        I32 n, i;
        struct pt_state *s;
    CODE:
        s = pt_self(aTHX_ self, "run_turn");
        n = av_len(inputs) + 1;
        Newxz(list, n ? n : 1, struct pt_input);
        for (i = 0; i < n; i++) {
            SV **rp = av_fetch(inputs, i, 0);
            AV *row;
            if (!rp || !SvROK(*rp) || SvTYPE(SvRV(*rp)) != SVt_PVAV) { Safefree(list); croak("Physics::Terrain::run_turn: input %d is not [tick, bits]", (int) i); }
            row = (AV *) SvRV(*rp);
            list[i].tick = (int32_t) pt_row_int(aTHX_ row, 0, 0);
            list[i].bits = (int32_t) pt_row_int(aTHX_ row, 1, 0);
        }
        if (shot && SvOK(shot)) shot_tick = pt_read_shot(aTHX_ shot, &sh);
        o = (PT->run_turn)(s, (int32_t) active, (int32_t) n, list, shot_tick >= 0 ? &sh : NULL, (int32_t) shot_tick);
        Safefree(list);
        if (!o) croak("Physics::Terrain::run_turn: could not allocate an outcome");
        RETVAL = pt_outcome_sv(aTHX_ o);
        (PT->outcome_free)(o);
    OUTPUT:
        RETVAL

# The per-tick state hash as two unsigned 32-bit halves.
void
hash(self)
        SV *self
    PREINIT:
        uint32_t h[2];
    PPCODE:
        (PT->hash)(pt_self(aTHX_ self, "hash"), h);
        EXTEND(SP, 2);
        mPUSHu(h[0]); mPUSHu(h[1]);

SV *
snapshot(self)
        SV *self
    PREINIT:
        struct pt_snapshot *n;
    CODE:
        n = (PT->snapshot_new)(pt_self(aTHX_ self, "snapshot"));
        if (!n) croak("Physics::Terrain::snapshot: could not allocate a snapshot");
        RETVAL = pt_wrap(aTHX_ n, "Physics::Terrain::Snapshot");
    OUTPUT:
        RETVAL

IV
restore(self, snap)
        SV *self
        SV *snap
    PREINIT:
        int32_t r;
    CODE:
        r = (PT->snapshot_restore)(pt_self(aTHX_ self, "restore"), pt_snap(aTHX_ snap, "restore"));
        if (r == -PT_ERR_STATE) croak("Physics::Terrain::restore: the snapshot is of a field of another size");
        if (r < 0) croak("Physics::Terrain::restore: could not restore");
        RETVAL = 1;
    OUTPUT:
        RETVAL

SV *
craters(self)
        SV *self
    PREINIT:
        const struct pt_crater *c;
        int32_t n, i;
        AV *list, *row;
    CODE:
        n = (PT->craters)(pt_self(aTHX_ self, "craters"), &c);
        list = newAV();
        for (i = 0; i < n; i++) {
            row = newAV(); av_push(row, newSViv(c[i].x)); av_push(row, newSViv(c[i].y)); av_push(row, newSViv(c[i].r));
            av_push(list, newRV_noinc((SV *) row));
        }
        RETVAL = newRV_noinc((SV *) list);
    OUTPUT:
        RETVAL

SV *
graves(self)
        SV *self
    PREINIT:
        const struct pt_grave *g;
        int32_t n, i;
        AV *list, *row;
    CODE:
        n = (PT->graves)(pt_self(aTHX_ self, "graves"), &g);
        list = newAV();
        for (i = 0; i < n; i++) {
            row = newAV(); av_push(row, newSViv(g[i].seat)); av_push(row, newSViv(g[i].x)); av_push(row, newSViv(g[i].y));
            av_push(list, newRV_noinc((SV *) row));
        }
        RETVAL = newRV_noinc((SV *) list);
    OUTPUT:
        RETVAL

# The launch vector (vx, vy) a weapon fires with at an angle and a power,
# without firing. A class method.
void
launch(class, weapon, angle, power)
        SV *class
        IV weapon
        IV angle
        IV power
    PREINIT:
        int32_t out[2];
    PPCODE:
        PERL_UNUSED_VAR(class);
        if ((PT->launch)((int32_t) weapon, (int32_t) angle, (int32_t) power, out) < 0) croak("Physics::Terrain::launch: no weapon %d", (int) weapon);
        EXTEND(SP, 2);
        mPUSHi(out[0]); mPUSHi(out[1]);

# The weapon table, as a list of hashes. A class method.
SV *
weapons(class)
        SV *class
    PREINIT:
        AV *list;
        HV *hv;
        int32_t i, n;
        const struct pt_weapon *w;
        static const char *const KINDS[] = { "shell", "bounce", "hitscan", "cluster", "drop", "death" };
    CODE:
        PERL_UNUSED_VAR(class);
        n = (PT->weapon_count)();
        list = newAV();
        for (i = 0; i < n; i++) {
            w = (PT->weapon_get)(i);
            hv = newHV();
            (void) hv_stores(hv, "id", newSVpv(w->id, 0));
            (void) hv_stores(hv, "name", newSVpv(w->name, 0));
            (void) hv_stores(hv, "kind", newSVpv(KINDS[w->kind], 0));
            (void) hv_stores(hv, "speedMax", newSViv(w->speed_max));
            (void) hv_stores(hv, "wind", newSViv(w->wind));
            (void) hv_stores(hv, "fuse", newSViv(w->fuse));
            (void) hv_stores(hv, "radius", newSViv(w->radius));
            (void) hv_stores(hv, "damage", newSViv(w->damage));
            (void) hv_stores(hv, "knock", newSViv(w->knock));
            if (w->bounce) (void) hv_stores(hv, "bounce", newSViv(w->bounce));
            if (w->friction) (void) hv_stores(hv, "friction", newSViv(w->friction));
            if (w->range) (void) hv_stores(hv, "range", newSViv(w->range));
            if (w->count) { (void) hv_stores(hv, "count", newSViv(w->count)); (void) hv_stores(hv, "spread", newSViv(w->spread)); (void) hv_stores(hv, "pop", newSViv(w->pop)); }
            av_push(list, newRV_noinc((SV *) hv));
        }
        RETVAL = newRV_noinc((SV *) list);
    OUTPUT:
        RETVAL

IV
abi_version(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = PT_ABI_VERSION;
    OUTPUT:
        RETVAL

IV
LEFT(...)
    ALIAS:
        RIGHT = 1
        JUMP = 2
        STANDING = 3
        WALKING = 4
        FALLING = 5
        FLYING = 6
    CODE:
        PERL_UNUSED_VAR(items);
        switch (ix) {
            case 0: RETVAL = PT_LEFT; break;
            case 1: RETVAL = PT_RIGHT; break;
            case 2: RETVAL = PT_JUMP; break;
            case 3: RETVAL = PT_STANDING; break;
            case 4: RETVAL = PT_WALKING; break;
            case 5: RETVAL = PT_FALLING; break;
            default: RETVAL = PT_FLYING; break;
        }
    OUTPUT:
        RETVAL

UV
_abi_ptr(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = PTR2UV(pt_abi_table());
    OUTPUT:
        RETVAL

MODULE = Physics::Terrain    PACKAGE = Physics::Terrain::Snapshot

void
DESTROY(self)
        SV *self
    PREINIT:
        struct pt_snapshot *n;
    CODE:
        n = pt_snap(aTHX_ self, "Snapshot::DESTROY");
        if (n) { (PT->snapshot_free)(n); sv_setuv(SvRV(self), 0); }
