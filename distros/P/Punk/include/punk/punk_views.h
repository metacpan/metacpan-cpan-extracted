/* punk_views.h - the C view-engine registry (phase 6+).
 *
 * Punk::Views is entirely XS: the object is a blessed IV-ref to this struct.
 * new() resolves each `views Name => \%opts` to Punk::View::Name (or the
 * class as written for '+Full::Class'), loads and instantiates it (the boot
 * -time Perl calls), and stores the engine object keyed by name; the first is
 * the default. render() - the hot path - looks the engine up, calls its
 * render, and assembles the PSGI triplet in C, so a rendered page crosses the
 * Perl boundary only for the engine's own render (which is itself XS in
 * Template::Stencil). lib/Punk/Views.pm is documentation only.
 *
 * Perl headers and punk_response.h must be included before this file.
 */

#ifndef PUNK_VIEWS_H
#define PUNK_VIEWS_H

typedef struct {
    HV *engines;      /* engine name -> the engine object SV */
    SV *deflt;        /* the default engine's name (the first registered) */
} pv_views;

static pv_views *pv_of(pTHX_ SV *self) {
    if (!SvROK(self) || !SvIOK(SvRV(self)))
        croak("Punk::Views: not a view registry");
    return (pv_views *)INT2PTR(void *, SvIV(SvRV(self)));
}

static pv_views *pv_new(pTHX) {
    pv_views *v;
    Newxz(v, 1, pv_views);
    v->engines = newHV();
    v->deflt   = NULL;
    return v;
}

static void pv_free(pTHX_ pv_views *v) {
    if (!v) return;
    if (v->engines) SvREFCNT_dec((SV *)v->engines);
    if (v->deflt)   SvREFCNT_dec(v->deflt);
    Safefree(v);
}

/* Resolve, load and instantiate one engine, storing it under its name; the
 * first registered becomes the default. Mirrors the old Perl Punk::Views::new
 * exactly, including its croaks. */
static void pv_load_engine(pTHX_ pv_views *v, SV *name_sv, SV *opts) {
    STRLEN nl;
    const char *name = SvPV_const(name_sv, nl);
    int plus = (nl > 0 && name[0] == '+');
    const char *key = plus ? name + 1 : name;
    STRLEN keyl = plus ? nl - 1 : nl;
    SV  *classsv = plus ? sv_2mortal(newSVpvn(name + 1, nl - 1))
                        : sv_2mortal(newSVpvf("Punk::View::%.*s", (int)nl, name));
    STRLEN cl;
    const char *class = SvPV_const(classsv, cl);
    HV *stash = gv_stashpvn(class, cl, 0);
    SV *engine;

    if (!stash || !gv_fetchmethod_autoload(stash, "render", 0)) {
        SV *req = sv_2mortal(newSVpvf("require %s; 1;", class));
        eval_sv(req, G_SCALAR);
        if (SvTRUE(ERRSV))
            croak("Punk::Views: engine '%.*s' (%s) failed to load: %s",
                  (int)keyl, key, class, SvPV_nolen(ERRSV));
        stash = gv_stashpvn(class, cl, 0);
    }
    if (!stash || !gv_fetchmethod_autoload(stash, "new", 0))
        croak("Punk::Views: engine '%.*s' (%s) does not implement new",
              (int)keyl, key, class);
    if (!gv_fetchmethod_autoload(stash, "render", 0))
        croak("Punk::Views: engine '%.*s' (%s) does not implement render",
              (int)keyl, key, class);
    if (hv_exists(v->engines, key, (I32)keyl))
        croak("Punk::Views: engine '%.*s' registered twice", (int)keyl, key);

    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(classsv);
        PUSHs((opts && SvOK(opts)) ? opts
              : sv_2mortal(newRV_noinc((SV *)newHV())));
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        engine = count > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK;
        FREETMPS; LEAVE;
    }
    (void)hv_store(v->engines, key, (I32)keyl, engine, 0);
    if (!v->deflt) v->deflt = newSVpvn(key, keyl);
}

/* The named (or default) engine object; unknown names croak listing what is
 * registered. */
static SV *pv_engine(pTHX_ pv_views *v, SV *name_sv) {
    const char *name;
    STRLEN nl;
    SV **e;
    if (name_sv && SvOK(name_sv)) name = SvPV_const(name_sv, nl);
    else if (v->deflt)            name = SvPV_const(v->deflt, nl);
    else croak("Punk::Views: no view engine configured - add a views keyword");
    e = hv_fetch(v->engines, name, (I32)nl, 0);
    if (e && *e) return *e;
    {
        SV *have = sv_2mortal(newSVpvs(""));
        HE *he;
        int first = 1;
        hv_iterinit(v->engines);
        while ((he = hv_iternext(v->engines))) {
            if (!first) sv_catpvs(have, ", ");
            sv_catsv(have, hv_iterkeysv(he));
            first = 0;
        }
        croak("Punk::Views: no view engine '%.*s' registered (have: %s)",
              (int)nl, name, SvPV_nolen(have));
    }
    return NULL; /* not reached */
}

#endif /* PUNK_VIEWS_H */
