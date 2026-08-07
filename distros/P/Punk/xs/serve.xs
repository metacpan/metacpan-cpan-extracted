MODULE = Punk        PACKAGE = Punk

PROTOTYPES: DISABLE

# The request dispatcher (punk_serve.h). compile() freezes the routing state
# and returns sub { Punk::_serve($state, $env) }: static/dynamic routing, the
# API-mount route+dispatch, PSGI mounts, 404/405, and for a web route the
# before hooks, guards, controller (or websocket upgrade) and response finish -
# all in C. Only the hooks/guards/controllers/mounts are Perl frames.
SV *
_serve(state, env)
        SV *state
        SV *env
    CODE:
    {
        if (!SvROK(state) || SvTYPE(SvRV(state)) != SVt_PVHV)
            croak("Punk::_serve: state must be a hashref");
        if (!SvROK(env) || SvTYPE(SvRV(env)) != SVt_PVHV)
            croak("Punk::_serve: env must be a hashref");
        RETVAL = punk_serve(aTHX_ (HV *)SvRV(state), (HV *)SvRV(env));
    }
    OUTPUT:
        RETVAL
