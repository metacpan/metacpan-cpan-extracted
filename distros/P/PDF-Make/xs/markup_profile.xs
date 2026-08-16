MODULE = PDF::Make  PACKAGE = PDF::Make::Markup::Profile

PROTOTYPES: DISABLE

# The template boundary. What a template may not do is decided in
# src/pdfmake_markup_profile.c; the engine is still built by calling
# Template::Stencil's constructor, because that is its interface, but the
# arguments it is built with are fixed here and cannot be passed in.
#
# The filters are XSUBs. Stencil takes filters as Perl coderefs, so the only
# way to offer formatting without offering a way back to arbitrary code is for
# the coderefs to be C.

# money: 1240.5 -> 1,240.50
SV *
_filter_money(value)
    SV *value
    ALIAS:
        _filter_number = 1
    CODE:
    {
        STRLEN len;
        const char *v;
        char out[128];
        size_t n;

        if (!value || !SvOK(value)) XSRETURN_PV("");
        v = pdfmake_markup_sv_bytes(aTHX_ value, &len);
        n = ix ? pdfmake_profile_number(v, len, out, sizeof(out))
               : pdfmake_profile_money(v, len, out, sizeof(out));
        RETVAL = newSVpvn(out, n);
    }
    OUTPUT:
        RETVAL

# Refuse {% raw %}, with the line it is on.
IV
check_source(class, src)
    SV *class
    SV *src
    CODE:
    {
        STRLEN len;
        const char *bytes;
        char err[PDFMAKE_PROFILE_ERR_LEN];
        uint32_t line = 0;

        PERL_UNUSED_VAR(class);
        bytes = pdfmake_markup_sv_bytes(aTHX_ src, &len);
        if (!pdfmake_profile_check_source(bytes, len, &line, err, sizeof(err)))
            croak("template error at line %" UVuf ": %s", (UV)line, err);
        RETVAL = 1;
    }
    OUTPUT:
        RETVAL

# The filter map, as coderefs onto the XSUBs above. A copy each time: handing
# out the engine's own map would let a caller replace an entry in it.
SV *
filters(class = NULL)
    SV *class
    CODE:
    {
        HV *out = newHV();
        CV *money  = get_cv("PDF::Make::Markup::Profile::_filter_money", 0);
        CV *number = get_cv("PDF::Make::Markup::Profile::_filter_number", 0);
        PERL_UNUSED_VAR(class);
        if (money)  (void)hv_stores(out, "money",  newRV_inc((SV *)money));
        if (number) (void)hv_stores(out, "number", newRV_inc((SV *)number));
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

void
filter_names(class = NULL)
    SV *class
    PPCODE:
        PERL_UNUSED_VAR(class);
        EXTEND(SP, 2);
        mPUSHp("money", 5);
        mPUSHp("number", 6);
        XSRETURN(2);

# A Template::Stencil configured for untrusted templates. The settings that
# matter are not options: escaping is on, strictness is on, and the filter map
# is this module's.
SV *
engine(class, ...)
    SV *class
    CODE:
    {
        HV *args;
        int i;

        PERL_UNUSED_VAR(class);
        if ((items - 1) % 2)
            croak("PDF::Make::Markup::Profile->engine: odd number of options");

        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k = SvPV(ST(i), klen);
            if ((klen == 7 && memcmp(k, "filters", 7) == 0) ||
                (klen == 11 && memcmp(k, "auto_escape", 11) == 0))
                croak("PDF::Make::Markup::Profile: '%.*s' cannot be set. "
                      "The profile exists to fix it.", (int)klen, k);
        }

        args = newHV();
        /* A value can never become markup. */
        (void)hv_stores(args, "auto_escape", newSViv(1));
        /* A missing field is an error, not a blank space. */
        (void)hv_stores(args, "strict", newSViv(1));
        /* Iteration order must not depend on the hash seed. */
        (void)hv_stores(args, "sort_keys", newSViv(1));
        (void)hv_stores(args, "cache", newSViv(1));
        (void)hv_stores(args, "filters",
            pdfmake_markup_profile_filters(aTHX));

        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k = SvPV(ST(i), klen);
            (void)hv_store(args, k, (I32)klen, newSVsv(ST(i + 1)), 0);
        }

        RETVAL = pdfmake_markup_profile_engine(aTHX_ args);
    }
    OUTPUT:
        RETVAL

# Check the source, render it, and enforce the output cap. The result is
# markup and nothing more: it has not been parsed and nothing is trusted yet.
SV *
render(class, src, data = &PL_sv_undef, ...)
    SV *class
    SV *src
    SV *data
    CODE:
    {
        SV *engine = NULL;
        UV max = 4 * 1024 * 1024;
        HV *opts = newHV();
        int i;

        PERL_UNUSED_VAR(class);
        sv_2mortal((SV *)opts);

        if ((items - 3) % 2)
            croak("PDF::Make::Markup::Profile->render: odd number of options");

        for (i = 3; i < items; i += 2) {
            STRLEN klen;
            const char *k = SvPV(ST(i), klen);
            if (klen == 6 && memcmp(k, "engine", 6) == 0) {
                engine = ST(i + 1);
            } else if (klen == 10 && memcmp(k, "max_output", 10) == 0) {
                max = SvUV(ST(i + 1));
            } else {
                (void)hv_store(opts, k, (I32)klen, newSVsv(ST(i + 1)), 0);
            }
        }

        RETVAL = pdfmake_markup_profile_render(aTHX_ src, data, engine,
                                               opts, max);
    }
    OUTPUT:
        RETVAL
