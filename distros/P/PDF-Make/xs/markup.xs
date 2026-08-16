MODULE = PDF::Make  PACKAGE = PDF::Make::Markup::Parse

PROTOTYPES: DISABLE

# The parser's Perl face. The grammar, the entity table, the UTF-8 validation
# and every position live in src/pdfmake_markup.c; what is here names the
# interface and nothing else.

SV *
check(class, src)
    SV *class
    SV *src
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pdfmake_markup_parse_sv(aTHX_ src);
    OUTPUT:
        RETVAL

# The same parse, throwing with the position in the message - what an editor
# underlines and what a CI log needs in order to be useful.
SV *
parse(class, src)
    SV *class
    SV *src
    CODE:
    {
        SV *res;
        HV *h;
        SV **ok;

        PERL_UNUSED_VAR(class);
        res = sv_2mortal(pdfmake_markup_parse_sv(aTHX_ src));
        h = (HV *)SvRV(res);
        ok = hv_fetchs(h, "ok", 0);

        if (!ok || !SvTRUE(*ok)) {
            SV **msg  = hv_fetchs(h, "error", 0);
            SV **line = hv_fetchs(h, "line", 0);
            SV **col  = hv_fetchs(h, "col", 0);
            croak("markup error at line %" IVdf ", column %" IVdf ": %" SVf,
                  line ? (IV)SvIV(*line) : (IV)0,
                  col  ? (IV)SvIV(*col)  : (IV)0,
                  SVfARG(msg ? *msg : &PL_sv_undef));
        }
        {
            SV **root = hv_fetchs(h, "root", 0);
            RETVAL = root ? newSVsv(*root) : newSV(0);
        }
    }
    OUTPUT:
        RETVAL

# The tag set as the parser holds it, so the documentation and the tests read
# what the engine actually accepts.
void
tags(class = NULL)
    SV *class
    PPCODE:
    {
        int t;
        I32 pushed = 0;
        PERL_UNUSED_VAR(class);
        EXTEND(SP, (SSize_t)PDFMAKE_MK_MAX);
        for (t = 1; t < PDFMAKE_MK_MAX; t++) {
            const char *name = pdfmake_markup_tag_name((pdfmake_markup_tag_t)t);
            HV *h;
            uint32_t f;
            if (!name) continue;
            f = pdfmake_markup_tag_flags((pdfmake_markup_tag_t)t);
            h = newHV();
            (void)hv_stores(h, "name",      newSVpv(name, 0));
            (void)hv_stores(h, "void",      newSViv((f & PDFMAKE_MKF_VOID) ? 1 : 0));
            (void)hv_stores(h, "container", newSViv((f & PDFMAKE_MKF_CONTAINER) ? 1 : 0));
            (void)hv_stores(h, "inline",    newSViv((f & PDFMAKE_MKF_INLINE) ? 1 : 0));
            mPUSHs(newRV_noinc((SV *)h));
            pushed++;
        }
        XSRETURN(pushed);
    }

SV *
tag_info(class, name)
    SV *class
    SV *name
    CODE:
    {
        STRLEN len;
        const char *n;
        pdfmake_markup_tag_t t;
        HV *h;
        uint32_t f;

        PERL_UNUSED_VAR(class);
        n = pdfmake_markup_sv_bytes(aTHX_ name, &len);
        t = pdfmake_markup_tag_id(n, len);
        if (t == PDFMAKE_MK_INVALID) XSRETURN_UNDEF;

        f = pdfmake_markup_tag_flags(t);
        h = newHV();
        (void)hv_stores(h, "name",      newSVpv(pdfmake_markup_tag_name(t), 0));
        (void)hv_stores(h, "void",      newSViv((f & PDFMAKE_MKF_VOID) ? 1 : 0));
        (void)hv_stores(h, "container", newSViv((f & PDFMAKE_MKF_CONTAINER) ? 1 : 0));
        (void)hv_stores(h, "inline",    newSViv((f & PDFMAKE_MKF_INLINE) ? 1 : 0));
        RETVAL = newRV_noinc((SV *)h);
    }
    OUTPUT:
        RETVAL
