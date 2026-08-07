MODULE = Punk        PACKAGE = Punk::Model

PROTOTYPES: DISABLE

# use Punk::Model - push the base class onto the caller's @ISA and install
# its declaration keywords, each a magic CV carrying that class's metadata.
void
import(class, ...)
        SV *class
    CODE:
    {
        const char *caller = CopSTASHPV(PL_curcop);
        SV *caller_sv;
        HV *meta;
        SV *meta_rv;
        PERL_UNUSED_VAR(class);
        PERL_UNUSED_VAR(items);
        if (!caller || strEQ(caller, "main")) XSRETURN_EMPTY;
        caller_sv = sv_2mortal(newSVpv(caller, 0));

        /* already a model (a second `use`, or a subclass): nothing to do */
        if (pm_meta_hv(aTHX_ caller_sv)) XSRETURN_EMPTY;

        meta = newHV();
        (void)hv_stores(meta, "table",    newSV(0));
        (void)hv_stores(meta, "fields",   newRV_noinc((SV *)newAV()));
        (void)hv_stores(meta, "field",    newRV_noinc((SV *)newHV()));
        (void)hv_stores(meta, "primary",  newSV(0));
        (void)hv_stores(meta, "validate", newSV(0));
        (void)hv_stores(meta, "database", newSVpvs("default"));
        meta_rv = newRV_noinc((SV *)meta);
        (void)hv_store_ent(pm_registry(aTHX), caller_sv, meta_rv, 0);

        {   /* @Caller::ISA = ('Punk::Model') */
            AV *isa = get_av(form("%s::ISA", caller), GV_ADD);
            av_push(isa, newSVpvs("Punk::Model"));
        }

        {   /* the keywords, each carrying [ $meta ] */
            static const struct { const char *name; XSUBADDR_t body; } kw[] = {
                { "table",    pm_kw_table    },
                { "field",    pm_kw_field    },
                { "database", pm_kw_database },
                { "validate", pm_kw_validate },
                { NULL, NULL }
            };
            int i;
            for (i = 0; kw[i].name; i++) {
                AV *cap = newAV();
                SV *code;
                av_push(cap, newSVsv(meta_rv));
                code = punk_closure(aTHX_ kw[i].body, cap);
                {
                    GV *gv = gv_fetchpv(form("%s::%s", caller, kw[i].name),
                                        GV_ADD, SVt_PVCV);
                    sv_setsv((SV *)gv, code);
                    SvREFCNT_dec(code);
                }
            }
        }
        XSRETURN_EMPTY;
    }

# The finalised metadata hashref, or undef when the class declared no
# table. Punk::App calls _punk_model_meta at compile to test a class.
SV *
_meta(class, ...)
        SV *class
    ALIAS:
        _punk_model_meta = 1
    CODE:
    {
        SV *pkg = (items > 1 && SvOK(ST(1))) ? ST(1) : class;
        HV *m;
        PERL_UNUSED_VAR(ix);
        if (SvROK(pkg)) pkg = sv_2mortal(newSVpv(sv_reftype(SvRV(pkg), 1), 0));
        m = pm_meta_hv(aTHX_ pkg);
        RETVAL = (m && pm_meta_finalize(aTHX_ m))
               ? newRV_inc((SV *)m) : newSV(0);
    }
    OUTPUT:
        RETVAL

# The per-worker instance: resolve the backend, hand it the table shape,
# compile the create/update validators. Called once per model per worker.
SV *
_instantiate(class, ...)
        SV *class
    CODE:
    {
        HV *dbopts = (items > 1 && SvROK(ST(1))
                      && SvTYPE(SvRV(ST(1))) == SVt_PVHV)
                   ? (HV *)SvRV(ST(1)) : NULL;
        HV *m = pm_meta_hv(aTHX_ class);
        HV *self;
        SV *backend_class, *backend;
        SV *should;

        if (!(m && pm_meta_finalize(aTHX_ m)))
            croak("Punk::Model: '%s' declares no table", SvPV_nolen(class));

        {   /* backend => 'Class', defaulting to the shipped DBI one */
            SV *b = dbopts ? pm_get(aTHX_ dbopts, "backend") : NULL;
            backend_class = (b && SvOK(b)) ? sv_2mortal(newSVsv(b))
                          : sv_2mortal(newSVpvs("Punk::Model::DBI"));
        }
        {   /* load it unless it is already there */
            HV *stash = gv_stashsv(backend_class, 0);
            if (!(stash && gv_fetchmethod_autoload(stash, "new", 0))) {
                SV *err;
                eval_pv(form("require %s;", SvPV_nolen(backend_class)), FALSE);
                err = ERRSV;
                if (SvTRUE(err))
                    croak("Punk::Model: backend '%s' failed to load: %s",
                          SvPV_nolen(backend_class), SvPV_nolen(err));
            }
        }

        {   /* $backend_class->new(database => \%conn, table, primary,
             * columns) - the connection options minus our own key */
            HV *conn = newHV();
            dSP;
            int count;
            if (dbopts) {
                HE *he;
                hv_iterinit(dbopts);
                while ((he = hv_iternext(dbopts))) {
                    SV *k = HeSVKEY_force(he);
                    if (SvCUR(k) == 7 && memEQ(SvPVX(k), "backend", 7))
                        continue;
                    (void)hv_store_ent(conn, k, newSVsv(HeVAL(he)), 0);
                }
            }
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 9);
            PUSHs(backend_class);
            mPUSHs(newSVpvs("database"));
            mPUSHs(newRV_noinc((SV *)conn));
            mPUSHs(newSVpvs("table"));
            mPUSHs(newSVsv(pm_get(aTHX_ m, "table")));
            mPUSHs(newSVpvs("primary"));
            mPUSHs(newSVsv(pm_get(aTHX_ m, "primary")));
            mPUSHs(newSVpvs("columns"));
            mPUSHs(newSVsv(pm_get(aTHX_ m, "fields")));
            PUTBACK;
            count = call_method("new", G_SCALAR);
            SPAGAIN;
            backend = count > 0 ? newSVsv(POPs) : &PL_sv_undef;
            PUTBACK; FREETMPS; LEAVE;
        }

        self = newHV();
        (void)hv_stores(self, "backend", backend);
        (void)hv_stores(self, "meta", newRV_inc((SV *)m));

        should = pm_get(aTHX_ m, "should_validate");
        if (should && SvTRUE(should)) {
            static const char *const which[] = { "cv_create", "cv_update" };
            int partial;
            eval_pv("require JSON::Schema::Fast;", TRUE);
            for (partial = 0; partial < 2; partial++) {
                SV *schema = sv_2mortal(pm_object_schema(aTHX_ m, partial));
                dSP;
                int count;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                EXTEND(SP, 2);
                mPUSHs(newSVpvs("JSON::Schema::Fast"));
                PUSHs(schema);
                PUTBACK;
                count = call_method("compile", G_SCALAR);
                SPAGAIN;
                if (count > 0)
                    (void)hv_store(self, which[partial],
                                   (I32)strlen(which[partial]),
                                   newSVsv(POPs), 0);
                PUTBACK; FREETMPS; LEAVE;
            }
        }
        RETVAL = sv_bless(newRV_noinc((SV *)self), gv_stashsv(class, GV_ADD));
    }
    OUTPUT:
        RETVAL

SV *
backend(self)
        SV *self
    ALIAS:
        meta = 1
    CODE:
    {
        SV *v = pm_slot(aTHX_ self, ix ? "meta" : "backend");
        RETVAL = v ? newSVsv(v) : newSV(0);
    }
    OUTPUT:
        RETVAL

# get / search / delete: straight through to the backend, keeping the
# caller's context so a list-returning backend stays a list.
void
get(self, ...)
        SV *self
    ALIAS:
        search = 1
        delete = 2
    PPCODE:
    {
        static const char *const m[] = { "get", "search", "delete" };
        PERL_UNUSED_VAR(self);
        pm_delegate(aTHX_ &ST(0), items, m[ix], GIMME_V);
        return;   /* whatever the backend left on the stack */
    }

# all: search with no filter and no options.
void
all(self)
        SV *self
    PPCODE:
    {
        SV *backend = pm_slot(aTHX_ self, "backend");
        if (!backend) croak("Punk::Model: this model has no backend");
        PUSHMARK(SP);
        EXTEND(SP, 3);
        PUSHs(backend);
        mPUSHs(newRV_noinc((SV *)newHV()));
        mPUSHs(newRV_noinc((SV *)newHV()));
        PUTBACK;
        call_method("search", GIMME_V);
        SPAGAIN;
        return;
    }

void
create(self, data)
        SV *self
        SV *data
    PPCODE:
    {
        SV *cv_sv = pm_slot(aTHX_ self, "cv_create");
        if (cv_sv && SvOK(cv_sv)) pm_validate(aTHX_ self, cv_sv, data);
        pm_delegate(aTHX_ &ST(0), items, "create", GIMME_V);
        return;
    }

# update validates the changes only: the primary key identifies the row
# rather than being part of what is being set, so a partial schema without
# it is what the payload has to satisfy.
void
update(self, data)
        SV *self
        SV *data
    PPCODE:
    {
        SV *cv_sv = pm_slot(aTHX_ self, "cv_update");
        if (cv_sv && SvOK(cv_sv)) {
            SV *meta = pm_slot(aTHX_ self, "meta");
            SV *pk   = (meta && SvROK(meta))
                     ? pm_get(aTHX_ (HV *)SvRV(meta), "primary") : NULL;
            HV *changes = newHV();
            if (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV) {
                HV *src = (HV *)SvRV(data);
                HE *he;
                hv_iterinit(src);
                while ((he = hv_iternext(src))) {
                    SV *k = HeSVKEY_force(he);
                    if (pk && SvOK(pk) && sv_eq(k, pk)) continue;
                    (void)hv_store_ent(changes, k, newSVsv(HeVAL(he)), 0);
                }
            }
            pm_validate(aTHX_ self, cv_sv,
                        sv_2mortal(newRV_noinc((SV *)changes)));
        }
        pm_delegate(aTHX_ &ST(0), items, "update", GIMME_V);
        return;
    }
