MODULE = Punk        PACKAGE = Punk

PROTOTYPES: DISABLE

# The request dispatcher (punk_serve.h). compile() freezes the routing state
# and returns sub { Punk::_serve($state, $env) }: static/dynamic routing, the
# API-mount route+dispatch, PSGI mounts, 404/405, and for a web route the
# before hooks, guards, controller (or websocket upgrade) and response finish -
# all in C. Only the hooks/guards/controllers/mounts are Perl frames.
SV *
# uncoverable statement
# uncoverable subroutine
_serve(state, env)
        SV *state
        SV *env
    CODE:
    {
        # uncoverable statement
        # uncoverable branch true
        # uncoverable branch false
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        # uncoverable condition left count:2
        # uncoverable condition right count:2
        if (!SvROK(state) || SvTYPE(SvRV(state)) != SVt_PVHV)
            croak("Punk::_serve: state must be a hashref"); /* # uncoverable statement */
        # uncoverable statement
        # uncoverable branch true
        # uncoverable branch false
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        # uncoverable condition left count:2
        # uncoverable condition right count:2
        if (!SvROK(env) || SvTYPE(SvRV(env)) != SVt_PVHV)
            croak("Punk::_serve: env must be a hashref"); /* # uncoverable statement */
        {   /* the struct the app closure carries, built for this one call */
            SV *holder = sv_2mortal(pk_state_build(aTHX_ (HV *)SvRV(state))); /* # uncoverable statement */
            RETVAL = punk_serve(aTHX_ pk_state_of(aTHX_ holder), (HV *)SvRV(env)); /* # uncoverable statement */
        }
    }
    OUTPUT:
        RETVAL
