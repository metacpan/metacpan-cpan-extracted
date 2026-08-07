MODULE = Punk        PACKAGE = Punk::SSE

PROTOTYPES: DISABLE

# Server-Sent Events, in C (punk_sse.h). The `sse` route kind hands the socket
# to a stream the handler pushes text/event-stream events onto; lib/Punk/SSE.pm
# is documentation. _dispatch is reached from punk_serve.h once guards pass.
SV *
_dispatch(c, rec, env)
        SV *c
        SV *rec
        SV *env
    CODE:
        RETVAL = punk_sse_dispatch(aTHX_ c, rec, env);
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::SSE

# send($data): one event ($data a ref is JSON-encoded; a multi-line string
# becomes multiple data: lines). event($name, $data): a named event. Both chain.
SV *
send(self, data = &PL_sv_undef)
        SV *self
        SV *data
    CODE:
        se_send(aTHX_ se_of(aTHX_ self), data);
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

SV *
event(self, name, data = &PL_sv_undef)
        SV *self
        SV *name
        SV *data
    CODE:
        se_event(aTHX_ se_of(aTHX_ self), name, data);
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

# comment($text) (: text), id($id) and retry($ms) write a single SSE field.
# id/retry are their own line, so send them just before the event they stamp.
SV *
comment(self, text = &PL_sv_undef)
        SV *self
        SV *text
    CODE:
        se_field(aTHX_ se_of(aTHX_ self), ": ", text);
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

SV *
id(self, id)
        SV *self
        SV *id
    CODE:
        se_field(aTHX_ se_of(aTHX_ self), "id: ", id);
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

SV *
retry(self, ms)
        SV *self
        SV *ms
    CODE:
        se_field(aTHX_ se_of(aTHX_ self), "retry: ", ms);
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

# on(close => $cb): the only event, fired once when the stream ends (client
# gone, close, or a write error). Chains.
SV *
on(self, event, cb)
        SV *self
        SV *event
        SV *cb
    CODE:
    {
        punk_sse *sse = se_of(aTHX_ self);
        STRLEN el; const char *ev = SvPV_const(event, el);
        if (!(el == 5 && memEQ(ev, "close", 5)))
            croak("Punk::SSE::Stream: unknown event '%s' (only 'close')", ev);
        if (!sse->cbs) sse->cbs = newHV();
        (void)hv_store(sse->cbs, ev, (I32)el, newSVsv(cb), 0);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# close: end the stream now.
SV *
close(self)
        SV *self
    CODE:
        se_teardown(aTHX_ se_of(aTHX_ self));
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

IV
is_open(self)
        SV *self
    CODE:
        RETVAL = se_of(aTHX_ self)->state == SSE_OPEN ? 1 : 0;
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        se_free(aTHX_ se_of(aTHX_ self));
