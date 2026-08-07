MODULE = Punk        PACKAGE = Punk::WebSocket

PROTOTYPES: DISABLE

# The upgrade handshake, in C (punk_wshandshake.h). Reached from the dispatcher
# once a websocket route's guards have passed: validate and answer the upgrade,
# then take the socket over and hand the connection to the handler. The codec
# and the connection object are already XS, so lib/Punk/WebSocket.pm is docs.
SV *
_dispatch(c, rec, env)
        SV *c
        SV *rec
        SV *env
    CODE:
        RETVAL = punk_ws_dispatch(aTHX_ c, rec, env);
    OUTPUT:
        RETVAL
