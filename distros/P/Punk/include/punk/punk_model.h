/* punk_model.h - the storage-agnostic model tier.
 *
 * Two halves, both here. At boot: `use Punk::Model` installs the
 * table/field/database/validate keywords into the model class (magic CVs
 * carrying that class's metadata - the punk_static.h closure pattern), and
 * _instantiate resolves the backend and compiles the create/update
 * validators once per worker. Per call: the six-method contract, which is
 * a metadata read plus one method call into the backend, with no Perl
 * frame of its own.
 *
 * Metadata stays a Perl hash: the field specs come from user code and are
 * handed to JSON::Schema::Fast unchanged, so there is nothing to gain by
 * copying them into a C struct - only shapes to lose.
 */

#ifndef PUNK_MODEL_H
#define PUNK_MODEL_H

/* class name -> metadata HV. One entry per model class, for the life of
 * the process; model classes are declared at compile time and never go
 * away, so this is a registry rather than a cache. */
static HV *PM_META = NULL;

static HV *pm_registry(pTHX) {
    if (!PM_META) PM_META = newHV();
    return PM_META;
}

/* The JSON-Schema-relevant field keys, copied straight into the property
 * schema; type coercion and the rest are the validator's business. */
static const char *const PM_SCHEMA_KEYS[] = {
    "type", "format", "pattern", "enum",
    "minLength", "maxLength", "minimum", "maximum",
    "multipleOf", "minItems", "maxItems", NULL
};

static SV *pm_get(pTHX_ HV *hv, const char *k) {
    SV **e = hv_fetch(hv, k, (I32)strlen(k), 0);
    return (e && *e) ? *e : NULL;
}

/* The class's OWN metadata: an exact registry hit, no inheritance. This is
 * what `import` asks, so that a subclass gets its own entry to declare into
 * rather than being mistaken for one that has already been set up. */
static HV *pm_meta_own(pTHX_ SV *class_sv) {
    HE *he = hv_fetch_ent(pm_registry(aTHX), class_sv, 0, 0);
    if (!he) return NULL;
    {
        SV *v = HeVAL(he);
        return (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV)
             ? (HV *)SvRV(v) : NULL;
    }
}

/* The metadata a class reads: its own, else the nearest ancestor's.
 *
 * A subclass that only says `use parent 'Some::Model'` declares nothing of
 * its own and inherits the whole table, which is what a subclass of a model
 * is for. Depth-first over @ISA, the order method resolution uses, with a
 * depth bound so a cyclic @ISA cannot spin. */
static HV *pm_meta_isa(pTHX_ SV *class_sv, int depth) {
    HV *own = pm_meta_own(aTHX_ class_sv);
    AV *isa;
    SSize_t i, n;

    if (own) return own;
    if (depth >= 16) return NULL;

    isa = get_av(form("%s::ISA", SvPV_nolen(class_sv)), 0);
    if (!isa) return NULL;

    n = av_len(isa) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(isa, i, 0);
        HV *m;
        if (!(e && *e && SvOK(*e))) continue;
        m = pm_meta_isa(aTHX_ *e, depth + 1);
        if (m) return m;
    }
    return NULL;
}

/* The class and its ancestors that declared metadata, nearest first. */
static void pm_meta_chain(pTHX_ SV *class_sv, AV *out, int depth) {
    HV *own;
    AV *isa;
    SSize_t i, n;

    if (depth >= 16) return;
    own = pm_meta_own(aTHX_ class_sv);
    if (own) av_push(out, newRV_inc((SV *)own));

    isa = get_av(form("%s::ISA", SvPV_nolen(class_sv)), 0);
    if (!isa) return;
    n = av_len(isa) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(isa, i, 0);
        if (e && *e && SvOK(*e)) pm_meta_chain(aTHX_ *e, out, depth + 1);
    }
}

/* The metadata a class reads, with its ancestors' merged in.
 *
 * This is done at LOOKUP and not at `use Punk::Model`, because `table` and
 * `field` are statements in the package body: they run when the class is
 * loaded, long after import decided what the class knew. A subclass seeded at
 * import time would copy an empty parent.
 *
 * Nearest wins: a subclass may add fields, or redeclare one to change its
 * spec, and names it does not mention keep the parent's. The merged hash is
 * cached under its own registry key, so the merge happens once per class and
 * the parent's own entry is never disturbed.
 */
static HV *pm_meta_merged(pTHX_ SV *class_sv) {
    AV *chain = (AV *)sv_2mortal((SV *)newAV());
    HV *m;
    AV *fields;
    HV *field;
    SSize_t i, n;

    pm_meta_chain(aTHX_ class_sv, chain, 0);
    n = av_len(chain) + 1;
    if (n == 0) return NULL;
    /* the common case: nothing inherited, so nothing to merge */
    if (n == 1) return (HV *)SvRV(*av_fetch(chain, 0, 0));

    {   /* already merged for this class? */
        SV *key = sv_2mortal(newSVsv(class_sv));
        HE *he;
        sv_catpvn(key, "\0merged", 7);
        he = hv_fetch_ent(pm_registry(aTHX), key, 0, 0);
        if (he) {
            SV *v = HeVAL(he);
            if (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV)
                return (HV *)SvRV(v);
        }
    }

    m      = newHV();
    fields = newAV();
    field  = newHV();
    (void)hv_stores(m, "database", newSVpvs("default"));

    /* furthest ancestor first, so the nearest overwrites */
    for (i = n - 1; i >= 0; i--) {
        HV *src = (HV *)SvRV(*av_fetch(chain, i, 0));
        SV *t = pm_get(aTHX_ src, "table");
        SV *p = pm_get(aTHX_ src, "primary");
        SV *v = pm_get(aTHX_ src, "validate");
        SV *d = pm_get(aTHX_ src, "database");
        SV *f = pm_get(aTHX_ src, "fields");
        SV *h = pm_get(aTHX_ src, "field");

        if (t && SvOK(t)) (void)hv_stores(m, "table",    newSVsv(t));
        if (p && SvOK(p)) (void)hv_stores(m, "primary",  newSVsv(p));
        if (v && SvOK(v)) (void)hv_stores(m, "validate", newSVsv(v));
        if (d && SvOK(d)) (void)hv_stores(m, "database", newSVsv(d));

        if (h && SvROK(h) && SvTYPE(SvRV(h)) == SVt_PVHV) {
            HV *sh = (HV *)SvRV(h);
            HE *he;
            hv_iterinit(sh);
            while ((he = hv_iternext(sh))) {
                STRLEN kl;
                const char *k = HePV(he, kl);
                (void)hv_store(field, k, (I32)kl, newSVsv(HeVAL(he)), 0);
            }
        }
        /* declaration order, each name once: a redeclared field keeps the
         * position the parent gave it rather than moving to the end */
        if (f && SvROK(f) && SvTYPE(SvRV(f)) == SVt_PVAV) {
            AV *sf = (AV *)SvRV(f);
            SSize_t j, fn = av_len(sf) + 1;
            for (j = 0; j < fn; j++) {
                SV **e = av_fetch(sf, j, 0);
                SSize_t k, kn = av_len(fields) + 1;
                int seen = 0;
                if (!(e && *e && SvOK(*e))) continue;
                for (k = 0; k < kn; k++) {
                    SV **g = av_fetch(fields, k, 0);
                    if (g && *g && sv_eq(*g, *e)) { seen = 1; break; }
                }
                if (!seen) av_push(fields, newSVsv(*e));
            }
        }
    }

    (void)hv_stores(m, "fields", newRV_noinc((SV *)fields));
    (void)hv_stores(m, "field",  newRV_noinc((SV *)field));

    {
        SV *key = sv_2mortal(newSVsv(class_sv));
        sv_catpvn(key, "\0merged", 7);
        (void)hv_store_ent(pm_registry(aTHX), key,
                           newRV_noinc((SV *)m), 0);
    }
    return m;
}

static HV *pm_meta_hv(pTHX_ SV *class_sv) {
    return pm_meta_merged(aTHX_ class_sv);
}


/* ---- the declaration keywords -------------------------------------------- *
 * Each is a magic CV carrying [ $meta_hashref ], installed into the model
 * class by import. */

XS_INTERNAL(pm_kw_table);
XS_INTERNAL(pm_kw_table) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    HV *m;
    if (!cap) XSRETURN_EMPTY;
    m = (HV *)SvRV(*av_fetch(cap, 0, 0));
    if (items > 0) (void)hv_stores(m, "table", newSVsv(ST(0)));
    XSRETURN_EMPTY;
}

/* Which configured database this model lives in (see the app's
 * `database $name => \%opts`); the unnamed default when unset. */
XS_INTERNAL(pm_kw_database);
XS_INTERNAL(pm_kw_database) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    HV *m;
    if (!cap) XSRETURN_EMPTY;
    m = (HV *)SvRV(*av_fetch(cap, 0, 0));
    (void)hv_stores(m, "database",
        (items > 0 && SvOK(ST(0))) ? newSVsv(ST(0)) : newSVpvs("default"));
    XSRETURN_EMPTY;
}

/* field $name => \%spec  |  field $name => (k => v, ...) */
XS_INTERNAL(pm_kw_field);
XS_INTERNAL(pm_kw_field) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    HV *m, *spec, *fields;
    AV *order;
    SV *name;
    int i;
    if (!cap || items < 1) XSRETURN_EMPTY;
    m = (HV *)SvRV(*av_fetch(cap, 0, 0));
    name = ST(0);

    spec = newHV();
    if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
        HV *src = (HV *)SvRV(ST(1));
        HE *he;
        hv_iterinit(src);
        while ((he = hv_iternext(src)))
            (void)hv_store_ent(spec, HeSVKEY_force(he), newSVsv(HeVAL(he)), 0);
    }
    else {
        for (i = 1; i + 1 < items; i += 2)
            (void)hv_store_ent(spec, ST(i), newSVsv(ST(i + 1)), 0);
    }

    order  = (AV *)SvRV(pm_get(aTHX_ m, "fields"));
    fields = (HV *)SvRV(pm_get(aTHX_ m, "field"));
    if (!hv_exists_ent(fields, name, 0))
        av_push(order, newSVsv(name));            /* declaration order */
    (void)hv_store_ent(fields, name, newRV_noinc((SV *)spec), 0);
    {
        SV *pk = pm_get(aTHX_ spec, "primary");
        if (pk && SvTRUE(pk)) (void)hv_stores(m, "primary", newSVsv(name));
    }
    XSRETURN_EMPTY;
}

/* Opt in or out of create/update validation explicitly; the default is to
 * validate when any field carries a constraint (see pm_meta_finalize). */
XS_INTERNAL(pm_kw_validate);
XS_INTERNAL(pm_kw_validate) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    HV *m;
    if (!cap) XSRETURN_EMPTY;
    m = (HV *)SvRV(*av_fetch(cap, 0, 0));
    (void)hv_stores(m, "validate",
        newSViv(items > 0 ? (SvTRUE(ST(0)) ? 1 : 0) : 1));
    XSRETURN_EMPTY;
}

/* ---- metadata ------------------------------------------------------------ */

/* Finalise once: default the primary key, decide whether to validate.
 * Returns 0 when the class declared no table (not a usable model). */
static int pm_meta_finalize(pTHX_ HV *m) {
    SV *table = pm_get(aTHX_ m, "table");
    SV *fin;
    if (!(table && SvOK(table))) return 0;
    fin = pm_get(aTHX_ m, "finalized");
    if (fin && SvTRUE(fin)) return 1;

    {   /* primary defaults to `id` when a field of that name exists */
        SV *pk = pm_get(aTHX_ m, "primary");
        HV *fields = (HV *)SvRV(pm_get(aTHX_ m, "field"));
        if (!(pk && SvOK(pk)) && hv_exists(fields, "id", 2))
            (void)hv_stores(m, "primary", newSVpvs("id"));
    }
    {   /* validate by default when any field carries a constraint */
        AV *order   = (AV *)SvRV(pm_get(aTHX_ m, "fields"));
        HV *fields  = (HV *)SvRV(pm_get(aTHX_ m, "field"));
        SV *want    = pm_get(aTHX_ m, "validate");
        int constrained = 0;
        SSize_t i, n = av_len(order) + 1;
        for (i = 0; i < n && !constrained; i++) {
            SV **nm = av_fetch(order, i, 0);
            HE *he  = nm ? hv_fetch_ent(fields, *nm, 0, 0) : NULL;
            HV *spec;
            int k;
            if (!he || !SvROK(HeVAL(he))) continue;
            spec = (HV *)SvRV(HeVAL(he));
            {
                SV *req = pm_get(aTHX_ spec, "required");
                if (req && SvTRUE(req)) { constrained = 1; break; }
            }
            /* every schema key but `type`: a bare type is not a constraint
             * worth compiling a validator for */
            for (k = 1; PM_SCHEMA_KEYS[k]; k++) {
                SV *v = pm_get(aTHX_ spec, PM_SCHEMA_KEYS[k]);
                if (v && SvOK(v)) { constrained = 1; break; }
            }
        }
        (void)hv_stores(m, "should_validate",
            newSViv((want && SvOK(want)) ? (SvTRUE(want) ? 1 : 0)
                                         : (constrained ? 1 : 0)));
    }
    (void)hv_stores(m, "finalized", newSViv(1));
    return 1;
}

/* The JSON Schema for create (with required) or update (without). */
static SV *pm_object_schema(pTHX_ HV *m, int partial) {
    AV *order  = (AV *)SvRV(pm_get(aTHX_ m, "fields"));
    HV *fields = (HV *)SvRV(pm_get(aTHX_ m, "field"));
    HV *schema = newHV(), *props = newHV();
    AV *required = newAV();
    SSize_t i, n = av_len(order) + 1;

    for (i = 0; i < n; i++) {
        SV **nm = av_fetch(order, i, 0);
        HE *he  = nm ? hv_fetch_ent(fields, *nm, 0, 0) : NULL;
        HV *spec, *p;
        int k;
        if (!he || !SvROK(HeVAL(he))) continue;
        spec = (HV *)SvRV(HeVAL(he));
        p = newHV();
        for (k = 0; PM_SCHEMA_KEYS[k]; k++) {
            SV *v = pm_get(aTHX_ spec, PM_SCHEMA_KEYS[k]);
            if (v && SvOK(v))
                (void)hv_store(p, PM_SCHEMA_KEYS[k],
                               (I32)strlen(PM_SCHEMA_KEYS[k]), newSVsv(v), 0);
        }
        (void)hv_store_ent(props, *nm, newRV_noinc((SV *)p), 0);
        if (!partial) {
            SV *req = pm_get(aTHX_ spec, "required");
            if (req && SvTRUE(req)) av_push(required, newSVsv(*nm));
        }
    }
    (void)hv_stores(schema, "type", newSVpvs("object"));
    (void)hv_stores(schema, "properties", newRV_noinc((SV *)props));
    if (av_len(required) >= 0)
        (void)hv_stores(schema, "required", newRV_noinc((SV *)required));
    else
        SvREFCNT_dec((SV *)required);
    return newRV_noinc((SV *)schema);
}

/* ---- validation ----------------------------------------------------------- */

/* Run a compiled validator; croak with the first error's location and
 * message. A validation failure is the application's bug, so it stops the
 * request the way any other croak does. */
static void pm_validate(pTHX_ SV *self, SV *cv_sv, SV *data) {
    dSP;
    int count, ok = 0;
    SV *errors = NULL;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(cv_sv);
    PUSHs(data);
    PUTBACK;
    count = call_method("validate", G_ARRAY);
    SPAGAIN;
    /* Pop into locals before testing. SvTRUE is a macro that evaluates its
     * argument more than once on perls before 5.30 - that is what SvTRUEx
     * exists for - so SvTRUE(POPs) popped repeatedly, walked off the stack
     * and handed sv_2bool garbage, segfaulting the model tier on 5.10 to
     * 5.28. Modern perls make it an inline function, which is why it had
     * never shown up. */
    if (count >= 2) {
        SV *e = POPs;
        SV *o = POPs;
        errors = e;
        ok = SvTRUE(o);
    }
    else if (count == 1) {
        SV *o = POPs;
        ok = SvTRUE(o);
    }
    /* NOT sv_2mortal here. SAVETMPS saved the temps floor above, so the
     * FREETMPS on the next line frees anything mortalised inside this
     * scope - including this copy, which is then read below. A freed SV
     * fails SvROK, the location and message are skipped, and EVERY
     * validation failure reports the fallback "does not match the field
     * schema" with no field named. Take a plain reference, leave the
     * scope, and mortalise into the CALLER's temps where it survives long
     * enough to be read. */
    if (errors) errors = newSVsv(errors);
    PUTBACK; FREETMPS; LEAVE;
    if (errors) sv_2mortal(errors);
    if (ok) return;
    {
        const char *cls = sv_reftype(SvRV(self), 1);
        SV *at = NULL, *msg = NULL;
        if (errors && SvROK(errors) && SvTYPE(SvRV(errors)) == SVt_PVAV) {
            AV *ea = (AV *)SvRV(errors);
            SV **first = av_fetch(ea, 0, 0);
            if (first && *first && SvROK(*first)
                && SvTYPE(SvRV(*first)) == SVt_PVHV) {
                HV *e = (HV *)SvRV(*first);
                at  = pm_get(aTHX_ e, "instanceLocation");
                msg = pm_get(aTHX_ e, "message");
            }
        }
        croak("Punk::Model: %s validation failed%s%s: %s", cls,
              (at && SvOK(at) && SvCUR(at)) ? " at " : "",
              (at && SvOK(at) && SvCUR(at)) ? SvPV_nolen(at) : "",
              (msg && SvOK(msg)) ? SvPV_nolen(msg)
                                 : "does not match the field schema");
    }
}

/* ---- the contract --------------------------------------------------------- */

static SV *pm_slot(pTHX_ SV *self, const char *k) {
    HV *hv;
    if (!(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV))
        croak("Punk::Model: not a model instance");
    hv = (HV *)SvRV(self);
    return pm_get(aTHX_ hv, k);
}

/* Forward @_ to the backend's method of the same name, returning whatever
 * it returns. The results land above the caller's own arguments, so they
 * are copied down over them before the caller returns - without that, list
 * context handed back ($self, @args, @results), which scalar context
 * masked by taking the last value. */
static void pm_delegate(pTHX_ SV **sp_base, I32 items, const char *method,
                        I32 gimme) {
    dSP;
    SV *self = sp_base[0];
    SV *backend = pm_slot(aTHX_ self, "backend");
    /* the callee can grow (and so move) the stack, so remember where the
     * caller's frame starts as an offset, never as a pointer */
    SSize_t base = sp_base - PL_stack_base;
    I32 i;
    if (!backend) croak("Punk::Model: this model has no backend");
    PUSHMARK(SP);
    EXTEND(SP, items);
    PUSHs(backend);
    for (i = 1; i < items; i++) PUSHs(sp_base[i]);
    PUTBACK;
    call_method(method, gimme);
    SPAGAIN;
    {   /* results sit above the caller's own arguments; slide them down over
         * them so list context returns @results, not ($self, @args,
         * @results) - which scalar context masked by taking the last value.
         * They are call_method's mortals, and dest stays below source, so an
         * ascending alias copy is safe. */
        SV **b = PL_stack_base + base;
        SSize_t count = SP - (b + items - 1);
        SSize_t j;
        if (count < 0) count = 0;
        for (j = 0; j < count; j++) b[j] = b[items + j];
        SP = b + count - 1;
    }
    PUTBACK;
}

#endif /* PUNK_MODEL_H */
