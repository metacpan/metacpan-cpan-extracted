MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Encode

PROTOTYPES: DISABLE

# ExportTraceServiceRequest as protobuf bytes. Takes the payload hashref
# documented in Punk::OpenTelemetry::OTLP and returns a byte string.
SV *
traces_protobuf(payload)
        SV *payload
    CODE:
    {
        if (!(payload && SvROK(payload) && SvTYPE(SvRV(payload)) == SVt_PVHV))
            croak("Punk::OpenTelemetry::Encode::traces_protobuf: "
                  "expected a hashref payload");
        RETVAL = otel_encode_traces(aTHX_ (HV *)SvRV(payload));
    }
    OUTPUT:
        RETVAL

# The size the encoder MEASURED for the same payload, without writing it.
# Every message is length-delimited, so the encoder walks twice - once to
# measure, once to write - and the two must agree exactly. This exposes the
# measuring half so a test can assert that agreement directly rather than
# inferring it from bytes that happen to parse.
UV
traces_protobuf_size(payload)
        SV *payload
    CODE:
    {
        HV *h;
        AV *rss;
        SSize_t i, cnt;
        UV total = 0;
        if (!(payload && SvROK(payload) && SvTYPE(SvRV(payload)) == SVt_PVHV))
            croak("Punk::OpenTelemetry::Encode::traces_protobuf_size: "
                  "expected a hashref payload");
        h = (HV *)SvRV(payload);
        rss = otel_h_av(aTHX_ h, "resource_spans");
        cnt = rss ? av_len(rss) + 1 : 0;
        for (i = 0; i < cnt; i++) {
            SV **e = av_fetch(rss, i, 0);
            total += otel_pb_msg_size(PB_EXPORT_TRACE_RESOURCE_SPANS,
                         otel_resourcespans_size(aTHX_
                             otel_hv_of(aTHX_ (e ? *e : NULL))));
        }
        RETVAL = total;
    }
    OUTPUT:
        RETVAL

# The same request as OTLP/JSON bytes. A supported transport, and the one
# people paste into a bug report - so it is not a naive rendering of the
# protobuf tree: field names are lowerCamelCase, trace and span ids are hex
# rather than base64, 64-bit integers are strings, and enums are names. See
# otel_json.h for why each of those is load-bearing.
SV *
traces_json(payload)
        SV *payload
    CODE:
    {
        SV *tree;
        if (!(payload && SvROK(payload) && SvTYPE(SvRV(payload)) == SVt_PVHV))
            croak("Punk::OpenTelemetry::Encode::traces_json: "
                  "expected a hashref payload");
        frj_opts o;
        Zero(&o, 1, frj_opts);
        /* sorted keys: JSON object order carries no meaning to a collector,
         * but it carries a great deal to a person diffing two payloads, a
         * golden vector, and anything that caches or fingerprints a body.
         * The protobuf side is byte-reproducible for the same reason. */
        o.sort_keys = 1;
        tree = sv_2mortal(otel_json_traces_sv(aTHX_ (HV *)SvRV(payload)));
        RETVAL = otel_frj(aTHX)->encode(aTHX_ tree, &o);
    }
    OUTPUT:
        RETVAL

# The OTLP/JSON tree as Perl data, before it is serialised. The tests assert
# the mapping rules against this rather than against parsed JSON, so a failure
# names the field that is wrong instead of a diff of two long strings.
SV *
traces_json_tree(payload)
        SV *payload
    CODE:
    {
        if (!(payload && SvROK(payload) && SvTYPE(SvRV(payload)) == SVt_PVHV))
            croak("Punk::OpenTelemetry::Encode::traces_json_tree: "
                  "expected a hashref payload");
        RETVAL = otel_json_traces_sv(aTHX_ (HV *)SvRV(payload));
    }
    OUTPUT:
        RETVAL

# ---- the primitives, exposed for the golden vectors -------------------------
# Not public API. A varint is the whole of protobuf that can be wrong in a way
# every higher level inherits, so it is tested directly rather than only
# through a message that happens to decode.

SV *
_varint(v)
        UV v
    CODE:
    {
        otel_buf b;
        otel_buf_init(&b, 16);
        otel_pb_varint(&b, v);
        RETVAL = newSVpvn(b.buf, b.len);
        otel_buf_free(&b);
    }
    OUTPUT:
        RETVAL

UV
_varint_size(v)
        UV v
    CODE:
        RETVAL = (UV)otel_pb_varint_size(v);
    OUTPUT:
        RETVAL

# One AnyValue body, for the scalar-shape tests: the same code every attribute
# in every signal goes through, reachable without building a whole span.
SV *
_anyvalue(v)
        SV *v
    CODE:
    {
        otel_buf b;
        size_t want = otel_anyvalue_body_size(aTHX_ v);
        otel_buf_init(&b, want ? want : 16);
        otel_anyvalue_body_write(aTHX_ &b, v);
        if (b.len != want)
            croak("Punk::OpenTelemetry: AnyValue wrote %lu bytes, measured "
                  "%lu", (unsigned long)b.len, (unsigned long)want);
        RETVAL = newSVpvn(b.buf, b.len);
        otel_buf_free(&b);
    }
    OUTPUT:
        RETVAL
