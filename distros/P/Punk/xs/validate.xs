MODULE = Punk        PACKAGE = Punk::Validate

PROTOTYPES: DISABLE

# The boot half (punk_validate.h): called from Punk::App::compile_extras
# when any route carried a validate option. Compiles each schema once
# through the JSON::Schema::Fast C ABI, resolves on_invalid, and appends a
# C guard closure to the compiled record - after any auth guards.
void
_compile_routes(self)
        SV *self
    CODE:
        pv_compile_routes(aTHX_ self);

MODULE = Punk        PACKAGE = Punk::Validate::Result

PROTOTYPES: DISABLE

# The collected outcome of one validation: { errors, data, schema? },
# built in C (pv_result_new) and read through these accessors.

# has_errors: the error count - boolean in practice.
SV *
has_errors(self)
        SV *self
    CODE:
    {
        AV *errs = pv_result_errors(aTHX_ pv_result_hv(aTHX_ self));
        RETVAL = newSViv(errs ? av_len(errs) + 1 : 0);
    }
    OUTPUT:
        RETVAL

# errors: the arrayref, in the Open::API shape plus name.
SV *
errors(self)
        SV *self
    CODE:
    {
        HV *h = pv_result_hv(aTHX_ self);
        SV **e = hv_fetchs(h, "errors", 0);
        RETVAL = (e && *e) ? newSVsv(*e) : newRV_noinc((SV *)newAV());
    }
    OUTPUT:
        RETVAL

# The first message for one field - error($name) - or undef.
SV *
error(self, name)
        SV *self
        SV *name
    CODE:
    {
        AV *errs = pv_result_errors(aTHX_ pv_result_hv(aTHX_ self));
        SSize_t i, n = errs ? av_len(errs) + 1 : 0;
        STRLEN wl; const char *want = SvPV_const(name, wl);
        RETVAL = NULL;
        for (i = 0; i < n && !RETVAL; i++) {
            SV **ep = av_fetch(errs, i, 0);
            HV *e; SV **nm;
            if (!(ep && *ep && SvROK(*ep)
                  && SvTYPE(SvRV(*ep)) == SVt_PVHV)) continue;
            e = (HV *)SvRV(*ep);
            nm = hv_fetchs(e, "name", 0);
            if (nm && *nm && SvOK(*nm)) {
                STRLEN nl; const char *ns = SvPV_const(*nm, nl);
                if (nl == wl && memEQ(ns, want, wl)) {
                    SV **msg = hv_fetchs(e, "message", 0);
                    RETVAL = (msg && *msg) ? newSVsv(*msg) : newSV(0);
                }
            }
        }
        if (!RETVAL) RETVAL = newSV(0);
    }
    OUTPUT:
        RETVAL

# valid / valid($name): typed, filtered params (punk_validate.h).
SV *
valid(self, name = &PL_sv_undef)
        SV *self
        SV *name
    CODE:
        RETVAL = pv_result_valid(aTHX_ pv_result_hv(aTHX_ self), name);
    OUTPUT:
        RETVAL

# TO_JSON: { errors => [...] } - the Result encodes as the 400 body.
SV *
TO_JSON(self)
        SV *self
    CODE:
    {
        HV *h = pv_result_hv(aTHX_ self);
        SV **e = hv_fetchs(h, "errors", 0);
        HV *out = newHV();
        (void)hv_stores(out, "errors",
            (e && *e) ? newSVsv(*e) : newRV_noinc((SV *)newAV()));
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL
