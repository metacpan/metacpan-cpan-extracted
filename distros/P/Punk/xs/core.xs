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

