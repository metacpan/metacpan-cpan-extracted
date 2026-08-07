MODULE = Punk        PACKAGE = Punk::CORS

PROTOTYPES: DISABLE

# The one piece of the CORS path that cannot be C: a nonblocking handler hands
# back a Future, and chaining onto it needs ->then. Punk::CORS::_chain does the
# chaining and calls this to do the work (punk_cors.h). Everything else -
# preflight and the triplet and streaming shapes - happens in pc_app_cb without
# a Perl frame.
void
_decorate(resp, cfg, allow)
        SV *resp
        SV *cfg
        SV *allow
    CODE:
    {
        AV *headers = pco_headers_of(aTHX_ resp);
        if (headers && cfg && SvROK(cfg) && SvTYPE(SvRV(cfg)) == SVt_PVHV)
            pco_add(aTHX_ headers, (HV *)SvRV(cfg), allow);
    }
