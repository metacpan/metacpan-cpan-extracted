MODULE = Punk        PACKAGE = Punk::Model::JSONFile

PROTOTYPES: DISABLE

# A model backend over a JSON file (punk_mrows.h): the file is an object and
# the model's table names an array of rows in it. Reads are cached until the
# file changes; writes lock, re-read, and rename a new file into place.
# Punk::Model::JSONFile.pm is the documentation.

SV *
new(class, ...)
        SV *class
    CODE:
        RETVAL = pdbi_build_self(aTHX_ class, &ST(0), items, PMJ);
        (void)pmj_file(aTHX_ (HV *)SvRV(RETVAL));
    OUTPUT:
        RETVAL

SV *
file(self)
        SV *self
    CODE:
        RETVAL = newSVsv(pmj_file(aTHX_ pmr_self(aTHX_ self, PMJ)));
    OUTPUT:
        RETVAL

# The whole decoded file, copied, or undef when there is no usable file:
# for values kept beside the tables.
SV *
document(self)
        SV *self
    CODE:
    {
        HV *doc = pmj_document(aTHX_ self);
        RETVAL = doc ? pmr_deep(aTHX_ sv_2mortal(newRV_inc((SV *)doc)))
                     : newSV(0);
    }
    OUTPUT:
        RETVAL

SV *
get(self, ...)
        SV *self
    CODE:
        RETVAL = pmr_get(aTHX_ self, pmj_rows(aTHX_ self), &ST(0), items, PMJ);
    OUTPUT:
        RETVAL

SV *
search(self, filter = &PL_sv_undef, opts = &PL_sv_undef)
        SV *self
        SV *filter
        SV *opts
    CODE:
        RETVAL = pmr_search(aTHX_ self, pmj_rows(aTHX_ self), filter, opts, PMJ);
    OUTPUT:
        RETVAL

IV
count(self, filter = &PL_sv_undef)
        SV *self
        SV *filter
    CODE:
        RETVAL = pmr_count(aTHX_ self, pmj_rows(aTHX_ self), filter, PMJ);
    OUTPUT:
        RETVAL

SV *
all(self)
        SV *self
    CODE:
        RETVAL = pmr_search(aTHX_ self, pmj_rows(aTHX_ self), NULL, NULL, PMJ);
    OUTPUT:
        RETVAL

SV *
create(self, data)
        SV *self
        SV *data
    CODE:
        RETVAL = pmj_create(aTHX_ self, data);
    OUTPUT:
        RETVAL

SV *
update(self, data)
        SV *self
        SV *data
    CODE:
        RETVAL = pmj_update(aTHX_ self, data);
    OUTPUT:
        RETVAL

IV
delete(self, ...)
        SV *self
    CODE:
        RETVAL = pmj_delete(aTHX_ self, &ST(0), items);
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::Model::Markdown

PROTOTYPES: DISABLE

# A read-only model backend over a `markdown` mount (punk_mrows.h): one row
# per page, as $app->markdown_pages gives them. Punk passes the application
# when it builds a backend; the mount is found by the database's prefix.

SV *
new(class, ...)
        SV *class
    CODE:
    {
        SV *app = NULL, *o, *prefix;
        HV *h;
        I32 i;
        RETVAL = pdbi_build_self(aTHX_ class, &ST(0), items, PMM);
        h = (HV *)SvRV(RETVAL);
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            if (kl == 3 && memEQ(k, "app", 3)) app = ST(i + 1);
        }
        if (!(app && SvROK(app))) {
            SvREFCNT_dec(RETVAL);
            croak(PMM ": needs the application - it is built by Punk::Model, "
                  "which passes it");
        }
        o = pdbi_get(aTHX_ h, "opts");
        prefix = (o && SvROK(o)) ? pdbi_get(aTHX_ (HV *)SvRV(o), "prefix") : NULL;
        if (!(prefix && SvOK(prefix) && SvCUR(prefix))) {
            SvREFCNT_dec(RETVAL);
            croak(PMM ": the database needs a `prefix`, the markdown mount's "
                  "(database name => { backend => '" PMM "', prefix => '/blog' })");
        }
        {   /* weak: the application holds its models, which hold this */
            SV *w = newSVsv(app);
            sv_rvweaken(w);
            (void)hv_stores(h, "app", w);
        }
    }
    OUTPUT:
        RETVAL

SV *
get(self, ...)
        SV *self
    CODE:
        RETVAL = pmr_get(aTHX_ self, pmm_rows(aTHX_ self), &ST(0), items, PMM);
    OUTPUT:
        RETVAL

SV *
search(self, filter = &PL_sv_undef, opts = &PL_sv_undef)
        SV *self
        SV *filter
        SV *opts
    CODE:
        RETVAL = pmr_search(aTHX_ self, pmm_rows(aTHX_ self), filter, opts, PMM);
    OUTPUT:
        RETVAL

IV
count(self, filter = &PL_sv_undef)
        SV *self
        SV *filter
    CODE:
        RETVAL = pmr_count(aTHX_ self, pmm_rows(aTHX_ self), filter, PMM);
    OUTPUT:
        RETVAL

SV *
all(self)
        SV *self
    CODE:
        RETVAL = pmr_search(aTHX_ self, pmm_rows(aTHX_ self), NULL, NULL, PMM);
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
        HV *h = pmr_self(aTHX_ self, PMM);
        SV *o = pdbi_get(aTHX_ h, "opts");
        SV *prefix = (o && SvROK(o)) ? pdbi_get(aTHX_ (HV *)SvRV(o), "prefix") : NULL;
        croak(PMM ": %s - the pages at %s are the markdown files, which this "
              "backend reads and does not write", what[ix],
              prefix ? SvPV_nolen(prefix) : "?");
    }
