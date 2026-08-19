#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::OpenTelemetry;

my $G = 'Punk::OpenTelemetry::GRPC';
*gpath    = \&Punk::OpenTelemetry::GRPC::path;
*frame    = \&Punk::OpenTelemetry::GRPC::frame;
*unframe  = \&Punk::OpenTelemetry::GRPC::unframe;
*retryable= \&Punk::OpenTelemetry::GRPC::retryable;
*verdict  = \&Punk::OpenTelemetry::GRPC::verdict;
*gheaders = \&Punk::OpenTelemetry::GRPC::headers;
*gport    = \&Punk::OpenTelemetry::GRPC::default_port;
*gretry   = \&Punk::OpenTelemetry::GRPC::retry_after;

# OTLP over gRPC: framing, status classification, paths, ports, and reading
# the status off a response.
#
# The status lives in the HTTP/2 TRAILERS, which Fetch 0.15 captures. Before
# it they were discarded, so there was no grpc-status to read at all and a
# client could only ever report success.

# ---- service paths ----------------------------------------------------------
{
    is(gpath('traces'),
       '/opentelemetry.proto.collector.trace.v1.TraceService/Export',
       'the traces service path');
    is(gpath('metrics'),
       '/opentelemetry.proto.collector.metrics.v1.MetricsService/Export',
       'the metrics service path');
    is(gpath('logs'),
       '/opentelemetry.proto.collector.logs.v1.LogsService/Export',
       'the logs service path');
    is(gpath('nonsense'), undef, 'an unknown signal has no path');
}

# ---- framing ----------------------------------------------------------------
# One byte compressed flag, four bytes BIG-endian length, then the message.
# Big-endian, unlike every other length in this dist.
{
    my $f = frame('hello');
    is(length $f, 10, 'a 5-byte message frames to 10 bytes');
    is(unpack('C', substr($f, 0, 1)), 0, 'the compressed flag is clear');
    is(unpack('N', substr($f, 1, 4)), 5, 'the length is BIG-endian');
    isnt(unpack('V', substr($f, 1, 4)), 5,
        'and specifically NOT little-endian, which would be a length of 83886080');
    is(substr($f, 5), 'hello', 'the message follows');

    is(unpack('C', substr(frame('x', 1), 0, 1)), 1,
        'the compressed flag is set when asked');

    my $empty = frame('');
    is(length $empty, 5, 'an empty message is still a valid frame');
    is(unpack('N', substr($empty, 1, 4)), 0, 'with a zero length');
}

# ---- round trip -------------------------------------------------------------
{
    my $msg = join '', map { chr($_ % 256) } 1 .. 1000;   # binary, not text
    my ($body, $comp, $used) = unframe(frame($msg));
    is($body, $msg, 'aframed message round-trips, bytes intact');
    is($comp, 0, 'with its flag');
    is($used, 1005, 'and the bytes consumed');

    ($body, $comp) = unframe(frame($msg, 1));
    is($comp, 1, 'a compressed frame reports its flag');
}

# ---- a partial frame is "not yet", not a failure ----------------------------
{
    my $f = frame('hello');
    is_deeply([ unframe(substr($f, 0, 3)) ], [],
        'fewer than 5 bytes is not a frame yet');
    is_deeply([ unframe(substr($f, 0, 7)) ], [],
        'a truncated body is not a frame yet either');
    is_deeply([ unframe('') ], [], 'and neither is nothing');

    # a length running past the buffer is treated the same way rather than
    # trusted: it arrived over a network
    my $lying = "\x00" . pack('N', 0xffffff) . 'short';
    is_deeply([ unframe($lying) ], [],
        'a length that overruns the buffer is refused, not trusted');
}

# ---- several frames in one buffer -------------------------------------------
{
    my $buf = frame('one') . frame('two');
    my ($b1, undef, $used1) = unframe($buf);
    is($b1, 'one', 'the first frame');
    my ($b2) = unframe(substr($buf, $used1));
    is($b2, 'two', 'and the second, after consuming the first');
}

# ---- retryable status codes -------------------------------------------------
{
    my %want = (
        1  => 1,   # CANCELLED
        4  => 1,   # DEADLINE_EXCEEDED
        10 => 1,   # ABORTED
        11 => 1,   # OUT_OF_RANGE
        14 => 1,   # UNAVAILABLE
        15 => 1,   # DATA_LOSS
        0  => 0,   # OK
        2  => 0,   # UNKNOWN
        3  => 0,   # INVALID_ARGUMENT
        5  => 0, 7 => 0, 9 => 0, 12 => 0, 13 => 0, 16 => 0,
    );
    for my $code (sort { $a <=> $b } keys %want) {
        is(retryable($code), $want{$code},
            "code $code is " . ($want{$code} ? 'retryable' : 'permanent'));
    }

    # RESOURCE_EXHAUSTED is the odd one: retryable ONLY with RetryInfo.
    # Without it the server is refusing a quota, and retrying a quota refusal
    # on a timer is how a client turns its own rate limit into an outage.
    is(retryable(8), 0, 'RESOURCE_EXHAUSTED alone is NOT retryable');
    is(retryable(8, 1), 1, 'but it is when the server sent RetryInfo');
}

# ---- the verdict ------------------------------------------------------------
{
    is(verdict(1, 0), 0, 'grpc-status 0 is success');
    is(verdict(1, 14), 1, 'UNAVAILABLE is a retry');
    is(verdict(1, 3), 2, 'INVALID_ARGUMENT is permanent');
    is(verdict(1, 8), 2, 'RESOURCE_EXHAUSTED without RetryInfo is permanent');
    is(verdict(1, 8, 1), 1, 'and a retry with it');

    # THE bug this exists to prevent: a gRPC call returns HTTP 200 even when
    # it fails, and a missing status means the stream ended without the server
    # saying how it went. Treating that as OK makes a broken client look
    # perfectly healthy.
    is(verdict(0), 1,
        'a MISSING grpc-status is a retryable transport failure, not success');
    isnt(verdict(0), 0, 'and is emphatically not reported as OK');
}

# ---- ports ------------------------------------------------------------------
# The single most common OTLP misconfiguration.
{
    is(gport('grpc'), 4317, 'gRPC defaults to 4317');
    is(gport('http/protobuf'), 4318, 'and HTTP to 4318');
    is(gport('http/json'), 4318, 'both HTTP encodings share a port');
}

# ---- headers ----------------------------------------------------------------
{
    my %h = gheaders();
    is($h{'content-type'}, 'application/grpc+proto', 'the content type');
    is($h{te}, 'trailers',
        'te: trailers is sent - it is how a client says it will read the '
      . 'trailing metadata, and the status lives there');
    ok(!exists $h{'grpc-encoding'}, 'no encoding header when uncompressed');

    my %c = gheaders(1);
    is($c{'grpc-encoding'}, 'gzip',
        'gzip is declared in grpc-encoding');
    ok(!exists $c{'content-encoding'},
        'and NOT in content-encoding: two mechanisms with similar names, and '
      . 'the HTTP one produces a request the collector rejects');
}

# ---- RetryInfo --------------------------------------------------------------
{
    is(gretry(undef), undef, 'no details means no named delay');
    is(gretry(''), undef, 'nor does an empty value');
    is(gretry('not base64 !!!'), undef, 'nor does something unparseable');

    # a google.rpc.Status whose details name RetryInfo with a 7 second delay
    my $inner = "RetryInfo" . "\x08\x07";
    my $b64 = do {
        my $s = $inner;
        my $out = '';
        require MIME::Base64;
        $out = MIME::Base64::encode_base64($s, '');
        $out;
    };
    SKIP: {
        skip 'MIME::Base64', 2 unless defined $b64 && length $b64;
        my $d = gretry($b64);
        ok(defined $d, 'a RetryInfo in the details is found');
        is($d, 7, 'with the delay the server named');
    }
}

# ---- the payloads are the same ones the HTTP transport sends ----------------
# gRPC changes the framing and the status channel, not the message.
{
    my $t = Punk::OpenTelemetry::Tracer->new(sampler => 'always_on',
                                             scope_name => 's');
    $t->enqueue($t->start('op'));
    my $bytes = Punk::OpenTelemetry::Encode::traces_protobuf($t->drain);

    my $f = frame($bytes);
    my ($back) = unframe($f);
    is($back, $bytes,
        'the same protobuf the HTTP transport sends, inside a gRPC frame');
    is(length($f) - length($bytes), 5, 'with exactly five bytes of overhead');
}

# ---- reading the status off a response --------------------------------------
# Fetch 0.15 captures HTTP/2 trailers, which is what makes this possible at
# all. Two places to look, and both are normal.
{
    *classify = \&Punk::OpenTelemetry::GRPC::classify;

    # an ordinary call: HEADERS, DATA, then a second HEADERS with the status
    my $ok = bless { status => 200, headers => ['content-type','application/grpc+proto'],
                     trailers => ['grpc-status','0'] }, 'Fetch::Response';
    my ($v, $code) = classify($ok);
    is($v, 0, 'grpc-status 0 in the trailers is success');
    is($code, 0, 'with the code reported');

    my $fail = bless { status => 200, headers => [],
                       trailers => ['grpc-status','14','grpc-message','down'] },
                     'Fetch::Response';
    my ($fv, $fc, $fm) = classify($fail);
    is($fv, 1, 'UNAVAILABLE in the trailers is a retry');
    is($fc, 14, 'the code');
    is($fm, 'down', 'and the message');

    # note the HTTP status was 200 on BOTH. That is the whole point: reading
    # the HTTP status and stopping would call the failure a success.
    is($fail->{status}, 200, 'a failed gRPC call still returns HTTP 200');
}

# ---- Trailers-Only -----------------------------------------------------------
# A server that fails before producing a body sends ONE HEADERS frame with
# :status, the grpc-status and END_STREAM - no DATA, no second HEADERS. So the
# status arrives in the ordinary header list, and a client that looked only at
# trailers would find no status on exactly the responses that failed fastest.
{
    my $to = bless { status => 200,
                     headers => ['grpc-status','12','grpc-message','no such method'] },
                   'Fetch::Response';
    my ($v, $code, $msg) = classify($to);
    is($v, 2, 'a Trailers-Only response is classified');
    is($code, 12, 'UNIMPLEMENTED, read from the response HEADERS');
    is($msg, 'no such method', 'with its message');
}

# ---- no status at all --------------------------------------------------------
{
    my $none = bless { status => 200, headers => [] }, 'Fetch::Response';
    my ($v, $code) = classify($none);
    is($v, 1, 'a response with NO grpc-status is a retryable failure');
    is($code, -1, 'and reports no code rather than pretending to zero');
    isnt($v, 0, 'it is emphatically not success');
}

# ---- the trailer wins over a header of the same name ------------------------
{
    my $both = bless { status => 200,
                       headers  => ['grpc-status','0'],
                       trailers => ['grpc-status','14'] }, 'Fetch::Response';
    my ($v, $code) = classify($both);
    is($code, 14,
        'the TRAILER wins: it is the real end-of-call status, the header is stale');
    is($v, 1, 'and the verdict follows it');
}

# ---- Fetch must be new enough ------------------------------------------------
{
    require Fetch;
    ok(Fetch::Response->can('trailers'),
        'Fetch exposes trailers - without it there is no grpc-status at all');
}

done_testing;
