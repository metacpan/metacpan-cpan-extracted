MODULE = Punk        PACKAGE = Punk::CSRF

PROTOTYPES: DISABLE

# The two hooks the `csrf` keyword makes the compiler install (punk_csrf.h).
# lib/Punk/CSRF.pm is documentation.

# before_dispatch: a reference return short-circuits the request, so a refusal
# answers 403 before any guard or handler runs. Returning nothing lets the
# request through - and, on the way, spends the token it arrived with.
void
_check(c)
        SV *c
    PPCODE:
    {
        SV *refused = pcf_check(aTHX_ c);
        if (refused) {
            EXTEND(SP, 1);
            mPUSHs(refused);
            XSRETURN(1);
        }
        XSRETURN_EMPTY;
    }

# after_dispatch: mirror the token into a script-readable cookie when it
# changed. Pushed after the session write-back, so both cookies go out on the
# same response.
SV *
_writeback(c, resp)
        SV *c
        SV *resp
    CODE:
        pcf_writeback(aTHX_ c, resp);
        RETVAL = newSVsv(resp);
    OUTPUT:
        RETVAL
