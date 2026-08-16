MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2

# _flow_begin($c, $provider, $login, $return_to_or_undef) -> authorize
# URL. Mints state/nonce/PKCE, records the flow in the session, purges
# stale/overflow flows. All in C.
SV *
_flow_begin(c, provider, login, return_to)
        SV *c
        SV *provider
        SV *login
        SV *return_to
    CODE:
        RETVAL = pox_flow_begin(aTHX_ c, provider, login,
                                SvOK(return_to) ? return_to : NULL);
    OUTPUT:
        RETVAL

# _flow_complete($c, $provider, $login) -> ($identity, $tokens). Validates
# the returned state against the session (delete-on-use), the iss
# parameter, and the code, then exchanges and normalizes identity.
# Croaks with a short reason on any failure.
void
_flow_complete(c, provider, login)
        SV *c
        SV *provider
        SV *login
    PPCODE:
        SV *identity = NULL, *tokens = NULL;
        pox_flow_complete(aTHX_ c, provider, login, &identity, &tokens);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(identity));
        PUSHs(sv_2mortal(tokens));
