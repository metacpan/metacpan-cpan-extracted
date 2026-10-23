MODULE = Punk        PACKAGE = Punk::Model::Computed

PROTOTYPES: DISABLE

# A base for read-only backends whose rows are worked out from the question
# (punk_computed.h). Punk::Model::Computed.pm is the documentation.

void
answers(class, ...)
        SV *class
    PPCODE:
    {
        const char *cls = pmc_cls(aTHX_ class);
        I32 i;
        if (items == 1) {
            AV *t = pmc_tables(aTHX_ cls);
            SSize_t j, n = av_len(t) + 1;
            EXTEND(SP, n);
            for (j = 0; j < n; j++) PUSHs(*av_fetch(t, j, 0));
            XSRETURN(n);
        }
        if (items % 2 == 0)
            croak("%s: answers takes table => { ... } pairs", cls);
        for (i = 1; i + 1 < items; i += 2)
            pmc_declare(aTHX_ cls, ST(i), ST(i + 1));
        XSRETURN_EMPTY;
    }

SV *
new(class, ...)
        SV *class
    CODE:
        RETVAL = pmc_build(aTHX_ class, &ST(0), items);
    OUTPUT:
        RETVAL

SV *
table(self)
        SV *self
    CODE:
        RETVAL = newSVsv(pdbi_get(aTHX_ pmc_self(aTHX_ self), "table"));
    OUTPUT:
        RETVAL

SV *
app(self)
        SV *self
    CODE:
    {
        SV *a = pdbi_get(aTHX_ pmc_self(aTHX_ self), "app");
        RETVAL = a ? newSVsv(a) : newSV(0);
    }
    OUTPUT:
        RETVAL

SV *
filter(self, filter = &PL_sv_undef)
        SV *self
        SV *filter
    CODE:
        RETVAL = newSVsv(pmc_filter(aTHX_ self, filter));
    OUTPUT:
        RETVAL

SV *
options(self, opts = &PL_sv_undef)
        SV *self
        SV *opts
    CODE:
        RETVAL = newSVsv(pmc_options(aTHX_ self, opts));
    OUTPUT:
        RETVAL

SV *
get(self, ...)
        SV *self
    CODE:
    {
        HV *key = (HV *)sv_2mortal((SV *)newHV());
        I32 i;
        if (items % 2 == 0)
            croak("%s: get takes field => value pairs", pmc_cls(aTHX_ self));
        for (i = 1; i + 1 < items; i += 2)
            (void)hv_store_ent(key, ST(i), newSVsv(ST(i + 1)), 0);
        RETVAL = pmc_call(aTHX_ self, 0,
            pmc_filter(aTHX_ self, sv_2mortal(newRV_inc((SV *)key))), NULL);
    }
    OUTPUT:
        RETVAL

SV *
search(self, filter = &PL_sv_undef, opts = &PL_sv_undef)
        SV *self
        SV *filter
        SV *opts
    CODE:
        RETVAL = pmc_search(aTHX_ self, filter, opts);
    OUTPUT:
        RETVAL

SV *
count(self, filter = &PL_sv_undef)
        SV *self
        SV *filter
    CODE:
        RETVAL = pmc_call(aTHX_ self, 2, pmc_filter(aTHX_ self, filter), NULL);
    OUTPUT:
        RETVAL

SV *
all(self)
        SV *self
    CODE:
        RETVAL = pmc_search(aTHX_ self, NULL, NULL);
    OUTPUT:
        RETVAL

void
create(self, ...)
        SV *self
    ALIAS:
        update = 1
        delete = 2
    CODE:
    {
        static const char *const what[] = { "create", "update", "delete" };
        croak("%s: %s - the %s rows are worked out, not stored", pmc_cls(aTHX_ self),
              what[ix], SvPV_nolen(pdbi_get(aTHX_ pmc_self(aTHX_ self), "table")));
    }

IV
limit(self, opts, dflt, max, what = &PL_sv_undef)
        SV *self
        SV *opts
        SV *dflt
        IV max
        SV *what
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = pmc_limit(aTHX_ opts, dflt, max, what);
    OUTPUT:
        RETVAL

SV *
cache_key(self, ...)
        SV *self
    CODE:
    {
        I32 i;
        RETVAL = newSVsv(pdbi_get(aTHX_ pmc_self(aTHX_ self), "table"));
        for (i = 1; i < items; i++) {
            sv_catpvs(RETVAL, "\t");
            pmc_key_part(aTHX_ RETVAL, ST(i), 0);
        }
    }
    OUTPUT:
        RETVAL

SV *
cached(self, key, code)
        SV *self
        SV *key
        SV *code
    CODE:
        RETVAL = pmc_cached(aTHX_ self, key, code);
    OUTPUT:
        RETVAL

void
cache_clear(self)
        SV *self
    CODE:
    {
        SV *c = pdbi_get(aTHX_ pmc_self(aTHX_ self), "cache");
        if (c && SvROK(c)) hv_clear((HV *)SvRV(c));
    }

IV
cache_size(self)
        SV *self
    CODE:
    {
        SV *c = pdbi_get(aTHX_ pmc_self(aTHX_ self), "cache");
        RETVAL = c && SvROK(c) ? (IV)HvUSEDKEYS((HV *)SvRV(c)) : 0;
    }
    OUTPUT:
        RETVAL

void
error(self, field, message)
        SV *self
        SV *field
        SV *message
    CODE:
        PERL_UNUSED_VAR(self);
        pmce_throw(aTHX_ NULL, field, message);

void
wrap(self, field, code)
        SV *self
        SV *field
        SV *code
    PPCODE:
    {
        I32 gimme = GIMME_V;
        I32 count;
        SV *f = sv_2mortal(newSVsv(field));
        PERL_UNUSED_VAR(self);
        if (!(SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV))
            croak("%s: wrap takes a field and a code reference", pmc_cls(aTHX_ self));
        PUSHMARK(SP);
        PUTBACK;
        count = call_sv(code, gimme | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            SV *e = sv_2mortal(newSVsv(ERRSV));
            SP -= count;
            PUTBACK;
            croak_sv(pmce_from(aTHX_ NULL, f, e));
        }
        PUTBACK;
        XSRETURN(count);
    }

MODULE = Punk        PACKAGE = Punk::Model::Computed::Error

PROTOTYPES: DISABLE

SV *
new(class, field, message)
        SV *class
        SV *field
        SV *message
    CODE:
        RETVAL = pmce_new(aTHX_ class, field, message);
    OUTPUT:
        RETVAL

void
throw(class, field, message)
        SV *class
        SV *field
        SV *message
    CODE:
        pmce_throw(aTHX_ class, field, message);

SV *
from(class, field, error)
        SV *class
        SV *field
        SV *error
    CODE:
        RETVAL = newSVsv(pmce_from(aTHX_ class, field, error));
    OUTPUT:
        RETVAL

SV *
said(class, error)
        SV *class
        SV *error
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = newSVsv(pmce_said(aTHX_ error));
    OUTPUT:
        RETVAL

SV *
field(self, ...)
        SV *self
    ALIAS:
        message = 1
    CODE:
    {
        SV *v = pdbi_get(aTHX_ pmce_hv(aTHX_ self), ix ? "message" : "field");
        RETVAL = v ? newSVsv(v) : newSV(0);
    }
    OUTPUT:
        RETVAL

SV *
TO_JSON(self, ...)
        SV *self
    CODE:
    {
        HV *h = pmce_hv(aTHX_ self), *out = newHV();
        SV *f = pdbi_get(aTHX_ h, "field"), *m = pdbi_get(aTHX_ h, "message");
        (void)hv_stores(out, "field",   f ? newSVsv(f) : newSV(0));
        (void)hv_stores(out, "message", m ? newSVsv(m) : newSV(0));
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL
