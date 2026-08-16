MODULE = PDF::Make  PACKAGE = PDF::Make::Markup::Render

PROTOTYPES: DISABLE

# Template, then markup, then PDF, through one function that every other entry
# point uses. One rendering path means one place where output can change,
# which is what makes the engine version promise checkable rather than
# aspirational.

# The engine version this build renders. A template pins the version it was
# written against and always renders on that one. It exists from the first
# release with exactly one version in it, because adding it later would mean
# the documents already in the world were rendered by "whatever was current",
# and there is then no answer to "why does this year's invoice not match last
# year's".
IV
engine_version(class = NULL)
    SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = PDFMAKE_ENGINE_VERSION;
    OUTPUT:
        RETVAL

void
supported(class = NULL)
    SV *class
    PPCODE:
    {
        int i;
        PERL_UNUSED_VAR(class);
        EXTEND(SP, PDFMAKE_ENGINE_VERSION);
        for (i = 1; i <= PDFMAKE_ENGINE_VERSION; i++)
            mPUSHi(i);
        XSRETURN(PDFMAKE_ENGINE_VERSION);
    }

SV *
render(class, template, data = &PL_sv_undef, ...)
    SV *class
    SV *template
    SV *data
    ALIAS:
        render_markup = 1
    CODE:
    {
        HV *opts = (HV *)sv_2mortal((SV *)newHV());
        SV *file_name = NULL;
        int i;

        PERL_UNUSED_VAR(class);

        /* render_markup takes no data, so its options begin one argument
         * earlier. Getting this wrong made render_markup($markup) - the
         * shortest possible call - look like an odd option list. */
        {
            int first = ix ? 2 : 3;
            if (items > first && ((items - first) % 2))
                croak("PDF::Make::Markup::Render->%s: odd number of options",
                      ix ? "render_markup" : "render");
            for (i = first; i + 1 < items; i += 2)
                (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);
        }

        {   /* the version gate, before anything is rendered */
            SV **want = hv_fetchs(opts, "engine_version", 0);
            if (want && SvOK(*want)) {
                STRLEN wlen;
                const char *w = SvPV(*want, wlen);
                STRLEN k;
                IV v;

                for (k = 0; k < wlen; k++)
                    if (w[k] < '0' || w[k] > '9')
                        croak("engine_version '%" SVf "' is not a version "
                              "number", SVfARG(*want));
                if (!wlen)
                    croak("engine_version '' is not a version number");

                v = SvIV(*want);
                if (v < 1 || v > PDFMAKE_ENGINE_VERSION)
                    croak("engine version %" IVdf " is not available in this "
                          "build (it renders 1..%d). %s",
                          v, PDFMAKE_ENGINE_VERSION,
                          v > PDFMAKE_ENGINE_VERSION
                            ? "The template was written for a newer engine "
                              "than this one."
                            : "That version has been retired.");
            }
        }

        file_name = hv_fetchs(opts, "file_name", 0)
                  ? *hv_fetchs(opts, "file_name", 0) : NULL;

        RETVAL = pdfmake_markup_render_sv(aTHX_ template,
                                          ix ? NULL : data,
                                          opts, file_name);
    }
    OUTPUT:
        RETVAL
