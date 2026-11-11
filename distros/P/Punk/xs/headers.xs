MODULE = Punk        PACKAGE = Punk::Headers

PROTOTYPES: DISABLE

# The one piece of the headers path that cannot be C: a nonblocking handler
# hands back a Future, and chaining onto it needs ->then. Punk::Headers::_chain
# does the chaining and calls this to do the work (punk_headers.h). The
# triplet and streaming shapes happen in pc_app_cb without a Perl frame.
void
_decorate(resp, pairs)
        SV *resp
        SV *pairs
    CODE:
    {
        AV *headers = pco_headers_of(aTHX_ resp);
        # uncoverable branch false
        # uncoverable condition right count:1 class:ignore_covered_err
        # uncoverable condition right count:2 class:ignore_covered_err
        # uncoverable condition right count:3 class:ignore_covered_err
        # uncoverable condition right count:4 class:ignore_covered_err
        if (headers && pairs && SvROK(pairs)
            && SvTYPE(SvRV(pairs)) == SVt_PVAV)
            phd_add_absent(aTHX_ headers, (AV *)SvRV(pairs));
    }
