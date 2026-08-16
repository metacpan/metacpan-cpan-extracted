MODULE = PDF::Make  PACKAGE = PDF::Make::Markup::Style

PROTOTYPES: DISABLE

# Attributes, values and inheritance. Every decision - which properties exist,
# which tags accept them, how a value is read, what inherits - lives in
# src/pdfmake_markup_style.c. What is here is the SV walking needed to get
# bytes in and values out, and nothing else.

# Coerce one value. Croaks with the reason, which the caller decorates with a
# position when it has one.
double
length_pt(class, value, node = NULL, what = NULL)
    SV *class
    SV *value
    SV *node
    SV *what
    ALIAS:
        number = 1
    CODE:
    {
        STRLEN len;
        const char *v;
        char err[PDFMAKE_STYLE_ERR_LEN];
        double out = 0;
        int ok;

        PERL_UNUSED_VAR(class);
        v = pdfmake_markup_sv_bytes(aTHX_ value, &len);
        ok = ix ? pdfmake_style_number(v, len, &out, err, sizeof(err))
                : pdfmake_style_length(v, len, &out, err, sizeof(err));
        if (!ok)
            pdfmake_markup_croak_at(aTHX_ node, what, err);
        RETVAL = out;
    }
    OUTPUT:
        RETVAL

SV *
colour(class, value, node = NULL, what = NULL)
    SV *class
    SV *value
    SV *node
    SV *what
    CODE:
    {
        STRLEN len;
        const char *v;
        char err[PDFMAKE_STYLE_ERR_LEN];
        char out[8];

        PERL_UNUSED_VAR(class);
        v = pdfmake_markup_sv_bytes(aTHX_ value, &len);
        if (!pdfmake_style_colour(v, len, out, err, sizeof(err)))
            pdfmake_markup_croak_at(aTHX_ node, what, err);
        RETVAL = newSVpv(out, 0);
    }
    OUTPUT:
        RETVAL

IV
boolean(class, value, node = NULL, what = NULL)
    SV *class
    SV *value
    SV *node
    SV *what
    CODE:
    {
        STRLEN len;
        const char *v;
        char err[PDFMAKE_STYLE_ERR_LEN];
        int out = 0;

        PERL_UNUSED_VAR(class);
        v = pdfmake_markup_sv_bytes(aTHX_ value, &len);
        if (!pdfmake_style_bool(v, len, &out, err, sizeof(err)))
            pdfmake_markup_croak_at(aTHX_ node, what, err);
        RETVAL = out;
    }
    OUTPUT:
        RETVAL

# One element's own attributes, validated and coerced.
SV *
attrs(class, node)
    SV *class
    SV *node
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pdfmake_markup_style_attrs_sv(aTHX_ node);
    OUTPUT:
        RETVAL

# A <style> declaration list for one tag.
SV *
declarations(class, string, node, tag)
    SV *class
    SV *string
    SV *node
    SV *tag
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pdfmake_markup_style_decls_sv(aTHX_ string, node, tag);
    OUTPUT:
        RETVAL

# Parent's inheritable properties, with own on top.
SV *
inherit(class, parent, own)
    SV *class
    SV *parent
    SV *own
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pdfmake_markup_style_inherit_sv(aTHX_ parent, own);
    OUTPUT:
        RETVAL

# The font-shaped part of a style, named the way Builder::Font wants it.
SV *
font_args(class, style)
    SV *class
    SV *style
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pdfmake_markup_style_font_sv(aTHX_ style);
    OUTPUT:
        RETVAL

# The tables themselves, so documentation and tests read what the engine uses.
SV *
properties(class)
    SV *class
    CODE:
    {
        HV *out = newHV();
        int p;
        PERL_UNUSED_VAR(class);
        for (p = 1; p < PDFMAKE_P_MAX; p++) {
            const char *name = pdfmake_style_prop_name((pdfmake_prop_t)p);
            HV *spec;
            if (!name) continue;
            spec = newHV();
            (void)hv_stores(spec, "inherit",
                newSViv(pdfmake_style_inherits((pdfmake_prop_t)p)));
            (void)hv_store(out, name, (I32)strlen(name),
                newRV_noinc((SV *)spec), 0);
        }
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

SV *
allowed(class, tag)
    SV *class
    SV *tag
    CODE:
    {
        STRLEN len;
        const char *name;
        pdfmake_markup_tag_t t;
        AV *out;
        const char *list, *p;

        PERL_UNUSED_VAR(class);
        name = pdfmake_markup_sv_bytes(aTHX_ tag, &len);
        t = pdfmake_markup_tag_id(name, len);
        if (t == PDFMAKE_MK_INVALID) XSRETURN_UNDEF;

        out = newAV();
        list = pdfmake_style_tag_allowed(t);
        if (strcmp(list, "(none)") != 0) {
            for (p = list; *p; ) {
                const char *e = strstr(p, ", ");
                size_t l = e ? (size_t)(e - p) : strlen(p);
                av_push(out, newSVpvn(p, l));
                if (!e) break;
                p = e + 2;
            }
        }
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

SV *
colours(class)
    SV *class
    CODE:
    {
        static const char *NAMES[] = {
            "aqua","black","blue","fuchsia","gray","green","grey","lime",
            "maroon","navy","olive","purple","red","silver","teal","white",
            "yellow", NULL
        };
        HV *out = newHV();
        int i;
        PERL_UNUSED_VAR(class);
        for (i = 0; NAMES[i]; i++) {
            char hex[8];
            char err[PDFMAKE_STYLE_ERR_LEN];
            if (!pdfmake_style_colour(NAMES[i], strlen(NAMES[i]), hex,
                                      err, sizeof(err)))
                continue;
            (void)hv_store(out, NAMES[i], (I32)strlen(NAMES[i]),
                newSVpv(hex, 0), 0);
        }
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL
