MODULE = Punk        PACKAGE = Punk::Session

PROTOTYPES: DISABLE

# The after-dispatch write-back installed when the `session` keyword is used
# (punk_session.h). It adds a signed Set-Cookie to the finished triplet when the
# session changed, or a deletion cookie when it was expired. lib/Punk/Session.pm
# is documentation.
SV *
_writeback(c, resp)
        SV *c
        SV *resp
    CODE:
        ps_writeback(aTHX_ c, resp);
        RETVAL = newSVsv(resp);
    OUTPUT:
        RETVAL
