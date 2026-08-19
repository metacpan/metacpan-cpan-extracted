MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::GRPC

PROTOTYPES: DISABLE

# OTLP over gRPC: the parts that are protocol rather than transport.
#
# Everything here is pure and testable with no network. The transport half
# needs trailers out of HTTP/2, which Fetch does not yet expose - see the POD.

# The fixed service path for a signal. Part of the protocol, not
# configuration: a gRPC endpoint is a host and port, and the path is derived
# from the proto package and method.
SV *
path(signal)
        SV *signal
    CODE:
    {
        const char *p = otel_grpc_path(SvPV_nolen(signal));
        if (!p) XSRETURN_UNDEF;
        RETVAL = newSVpv(p, 0);
    }
    OUTPUT:
        RETVAL

# Wrap a message in the gRPC length prefix: one byte compressed flag, four
# bytes BIG-endian length, then the message. Big-endian, unlike every other
# length in this dist - getting the byte order wrong produces a length in the
# billions and a peer that closes the stream.
SV *
frame(msg, compressed = 0)
        SV *msg
        int compressed
    CODE:
        RETVAL = otel_grpc_frame(aTHX_ msg, compressed);
    OUTPUT:
        RETVAL

# Read one frame back. Returns (body, compressed, consumed), or an empty list
# when the buffer does not hold a whole frame yet - which means "not yet",
# and is not a failure. A length running past the buffer is treated the same
# way rather than trusted, because it arrived over a network.
void
unframe(buf)
        SV *buf
    PPCODE:
    {
        STRLEN len;
        const char *p = SvPV_const(buf, len);
        const char *body;
        STRLEN blen, consumed;
        int compressed;
        if (!otel_grpc_unframe(p, len, &body, &blen, &compressed, &consumed))
            XSRETURN_EMPTY;
        EXTEND(SP, 3);
        mPUSHp(body, blen);
        mPUSHi(compressed);
        mPUSHu((UV)consumed);
    }

# Is this status one the OTLP spec says to retry?
#
# RESOURCE_EXHAUSTED is the odd one: retryable ONLY with RetryInfo in the
# details. Without it the server is refusing a quota, and retrying a quota
# refusal on a timer is how a client turns its own rate limit into an outage.
IV
retryable(code, has_retry_info = 0)
        int code
        int has_retry_info
    CODE:
        RETVAL = otel_grpc_retryable(code, has_retry_info);
    OUTPUT:
        RETVAL

# The verdict a caller acts on: 0 ok, 1 retry, 2 permanent. Mirrors the HTTP
# transport's, so a caller branches once.
#
# A MISSING grpc-status is not success. It means the stream ended without the
# server saying how it went, which is a transport failure and is retryable.
# Treating it as OK is the specific bug that makes a broken gRPC client look
# perfectly healthy.
IV
verdict(have_status, code = 0, has_retry_info = 0)
        int have_status
        int code
        int has_retry_info
    CODE:
        RETVAL = otel_grpc_verdict(have_status, code, has_retry_info);
    OUTPUT:
        RETVAL

# The retry delay a server named in grpc-status-details-bin, in seconds.
# Undef when there is none. When the server names one it wins over any computed backoff:
# it knows when it will be ready and the client does not.
SV *
retry_after(details)
        SV *details
    CODE:
    {
        STRLEN l;
        const char *s = SvOK(details) ? SvPV_const(details, l) : (l = 0, NULL);
        double d = otel_grpc_retry_after(s, l);
        if (d < 0) XSRETURN_UNDEF;
        RETVAL = newSVnv(d);
    }
    OUTPUT:
        RETVAL

# The default port for a protocol. The single most common OTLP
# misconfiguration is sending gRPC to 4318 or HTTP to 4317, so this is stated
# rather than assumed, and the boot diagnostic prints which was chosen.
IV
default_port(protocol)
        SV *protocol
    CODE:
    {
        const char *p = SvPV_nolen(protocol);
        RETVAL = strEQ(p, "grpc") ? 4317 : 4318;
    }
    OUTPUT:
        RETVAL

# The headers a gRPC request must carry. `te: trailers` is not optional: it is
# how a client tells the server it will read the trailing metadata, and the
# status lives there.
void
headers(compressed = 0)
        int compressed
    PPCODE:
    {
        EXTEND(SP, 8);
        mPUSHp("content-type", 12);
        mPUSHp("application/grpc+proto", 22);
        mPUSHp("te", 2);
        mPUSHp("trailers", 8);
        if (compressed) {
            /* gzip lives in the FRAME flag and in grpc-encoding - NOT in
             * HTTP's content-encoding. Two mechanisms with similar names, and
             * using the HTTP one produces a request the collector rejects
             * with a confusing message. */
            mPUSHp("grpc-encoding", 13);
            mPUSHp("gzip", 4);
        }
    }

# ---- the transport half ------------------------------------------------------
# Made possible by Fetch 0.15, which captures HTTP/2 trailers. Before it, the
# grpc-status could not be read at all.

# classify($res) -> (verdict, code, message, retry_after)
#
# Looks for grpc-status in the TRAILERS first, then in the response HEADERS -
# and both are normal. An ordinary call puts it in the trailers; a
# TRAILERS-ONLY response, which is what a server sends when it fails before
# producing a body, puts it in the one and only HEADERS frame. A client that
# looked only at trailers would find no status on exactly the responses that
# failed fastest.
void
classify(res)
        SV *res
    PPCODE:
    {
        SV *st = otel_grpc_field(aTHX_ res, "grpc-status", 11);
        SV *msg = otel_grpc_field(aTHX_ res, "grpc-message", 12);
        SV *det = otel_grpc_field(aTHX_ res, "grpc-status-details-bin", 23);
        int have = st && SvOK(st) ? 1 : 0;
        int code = have ? (int)SvIV(st) : 0;
        double after = -1;
        int has_ri = 0;
        if (det && SvOK(det)) {
            STRLEN dl;
            const char *ds = SvPV_const(det, dl);
            after = otel_grpc_retry_after(ds, dl);
            has_ri = after >= 0;
        }
        EXTEND(SP, 4);
        mPUSHi(otel_grpc_verdict(have, code, has_ri));
        mPUSHi(have ? code : -1);
        if (msg && SvOK(msg)) mPUSHs(newSVsv(msg));
        else                  PUSHs(&PL_sv_undef);
        if (after >= 0) mPUSHn(after);
        else            PUSHs(&PL_sv_undef);
    }

# send($ua, $endpoint, $signal, $bytes, $timeout) -> the ua's future.
#
# The same protobuf the HTTP transport sends, in a gRPC frame, over HTTP/2 to
# the fixed service path. The endpoint is a scheme://host:port with NO path -
# the path is protocol, not configuration.
SV *
send(ua, endpoint, signal, bytes, timeout = 10)
        SV *ua
        SV *endpoint
        SV *signal
        SV *bytes
        double timeout
    CODE:
    {
        const char *path = otel_grpc_path(SvPV_nolen(signal));
        SV *url, *body;
        AV *hdrs;
        if (!path)
            croak("Punk::OpenTelemetry::GRPC::send: unknown signal '%s'",
                  SvPV_nolen(signal));
        {
            STRLEN el;
            const char *es = SvPV_const(endpoint, el);
            while (el && es[el - 1] == '/') el--;   /* no double slash */
            url = sv_2mortal(newSVpvn(es, el));
            sv_catpv(url, path);
        }
        body = sv_2mortal(otel_grpc_frame(aTHX_ bytes, 0));

        hdrs = (AV *)sv_2mortal((SV *)newAV());
        av_push(hdrs, newSVpvs("content-type"));
        av_push(hdrs, newSVpvs("application/grpc+proto"));
        /* te: trailers is how a client says it will read the trailing
         * metadata, and the status lives there */
        av_push(hdrs, newSVpvs("te"));
        av_push(hdrs, newSVpvs("trailers"));

        {
            dSP; int count; SV *f = NULL;
            ENTER; SAVETMPS;
            PUSHMARK(SP); EXTEND(SP, 9);
            PUSHs(ua);
            PUSHs(sv_2mortal(newSVpvs("POST")));
            PUSHs(url);
            PUSHs(sv_2mortal(newSVpvs("headers")));
            PUSHs(sv_2mortal(newRV_inc((SV *)hdrs)));
            PUSHs(sv_2mortal(newSVpvs("body")));
            PUSHs(body);
            PUSHs(sv_2mortal(newSVpvs("timeout")));
            PUSHs(sv_2mortal(newSVnv(timeout)));
            PUTBACK;
            count = call_method("request", G_SCALAR);
            SPAGAIN;
            if (count > 0) f = newSVsv(POPs);
            PUTBACK; FREETMPS; LEAVE;
            RETVAL = f ? f : &PL_sv_undef;
        }
    }
    OUTPUT:
        RETVAL
