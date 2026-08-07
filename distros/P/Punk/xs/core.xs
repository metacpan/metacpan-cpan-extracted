MODULE = Punk        PACKAGE = Punk

PROTOTYPES: DISABLE

# `use Punk` (punk_import.h): turn on strict and warnings in the caller, get or
# make that class's registrar, and install the DSL - every keyword a magic CV
# carrying the registrar, from one table. lib/Punk.pm keeps the documentation.
void
import(class, ...)
        SV *class
    CODE:
    {
        const char *caller = CopSTASHPV(PL_curcop);
        PERL_UNUSED_VAR(class);
        PERL_UNUSED_VAR(items);
        if (!caller) XSRETURN_EMPTY;
        pki_pragma(aTHX_ "strict");
        pki_pragma(aTHX_ "warnings");
        pki_export(aTHX_ sv_2mortal(newSVpv(caller, 0)));
        XSRETURN_EMPTY;
    }

PROTOTYPES: DISABLE

int
_xs_ok()
    CODE:
        RETVAL = 1;
    OUTPUT:
        RETVAL

# status, content type, body bytes, optional extra header pair arrayref.
SV *
_text_response(status, ct, body, ...)
        IV  status
        SV *ct
        SV *body
    CODE:
    {
        AV *extra = NULL;
        if (items > 3 && SvOK(ST(3))) {
            if (!SvROK(ST(3)) || SvTYPE(SvRV(ST(3))) != SVt_PVAV)
                croak("Punk::_text_response: headers must be an arrayref");
            extra = (AV *)SvRV(ST(3));
        }
        RETVAL = punk_triplet(aTHX_ status, ct, newSVsv(body), extra);
    }
    OUTPUT:
        RETVAL

# status, any Perl data, optional extra header pairs -> application/json
# triplet, encoded through frj's C ABI into an owned body SV.
SV *
_json_response(status, data, ...)
        IV  status
        SV *data
    CODE:
    {
        const frj_abi *J = punk_frj(aTHX);
        SV *bytes = J->encode(aTHX_ data, NULL);
        SV *ct    = sv_2mortal(newSVpvs("application/json"));
        AV *extra = NULL;
        if (items > 2 && SvOK(ST(2))) {
            if (!SvROK(ST(2)) || SvTYPE(SvRV(ST(2))) != SVt_PVAV)
                croak("Punk::_json_response: headers must be an arrayref");
            extra = (AV *)SvRV(ST(2));
        }
        RETVAL = punk_triplet(aTHX_ status, ct, bytes, extra);
    }
    OUTPUT:
        RETVAL
