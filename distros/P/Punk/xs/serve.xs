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
        {   /* the struct the app closure carries, built for this one call */
            SV *holder = sv_2mortal(pk_state_build(aTHX_ (HV *)SvRV(state)));
            RETVAL = punk_serve(aTHX_ pk_state_of(aTHX_ holder), (HV *)SvRV(env));
        }
    }
    OUTPUT:
        RETVAL
