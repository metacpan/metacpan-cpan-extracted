#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::OpenTelemetry;
use Punk::OpenTelemetry::Exporter;

# The OTLP/HTTP transport: endpoint resolution, response classification,
# partial success, and the backoff policy. Each of these fails silently in
# production if it is wrong - a payload posted to the wrong path is accepted
# by nothing, a partial success counted as a success loses data while the
# dashboard stays green - so each is asserted directly.

my $PAYLOAD = { resource_spans => [ { scope_spans => [ { spans => [
    { trace_id => 'a' x 32, span_id => 'b' x 16, name => 'x' } ] } ] } ] };

# ---- endpoint resolution ----------------------------------------------------
# The asymmetry is in the spec: a GENERAL endpoint has the signal path
# appended, a PER-SIGNAL endpoint is used exactly as given. Appending to a
# per-signal endpoint breaks every collector behind a path prefix.
{
    my $e = Punk::OpenTelemetry::Exporter->new(
        endpoint => 'http://collector:4318');
    is($e->_endpoint_for('traces'),  'http://collector:4318/v1/traces',
        'a general endpoint has /v1/traces appended');
    is($e->_endpoint_for('metrics'), 'http://collector:4318/v1/metrics',
        'and /v1/metrics for metrics');
    is($e->_endpoint_for('logs'),    'http://collector:4318/v1/logs',
        'and /v1/logs for logs');

    my $slash = Punk::OpenTelemetry::Exporter->new(
        endpoint => 'http://collector:4318/');
    is($slash->_endpoint_for('traces'), 'http://collector:4318/v1/traces',
        'a trailing slash does not produce a double slash');

    my $per = Punk::OpenTelemetry::Exporter->new(
        endpoint  => 'http://collector:4318',
        endpoints => { traces => 'https://vendor.example/otlp/ingest' });
    is($per->_endpoint_for('traces'), 'https://vendor.example/otlp/ingest',
        'a per-signal endpoint is used EXACTLY as given, path and all');
    is($per->_endpoint_for('metrics'), 'http://collector:4318/v1/metrics',
        'while the other signals still use the general one');

    my $none = Punk::OpenTelemetry::Exporter->new;
    is($none->_endpoint_for('traces'), undef,
        'with no endpoint configured there is nowhere to send');
}

# ---- protocol ---------------------------------------------------------------
{
    my $pb = Punk::OpenTelemetry::Exporter->new(endpoint => 'http://x');
    my $js = Punk::OpenTelemetry::Exporter->new(endpoint => 'http://x',
                                                protocol => 'http/json');
    is($pb->{protocol}, 'http/protobuf', 'protobuf is the default protocol');

    my $b1 = $pb->encode(traces => $PAYLOAD);
    my $b2 = $js->encode(traces => $PAYLOAD);
    isnt($b1, $b2, 'the two protocols produce different bytes');
    like($b2, qr/^\{/, 'the json one is JSON');
    ok(length($b1) < length($b2),
        'and protobuf is the smaller, which is why it is the default');

    ok(!eval { Punk::OpenTelemetry::Exporter->new(protocol => 'grpc'); 1 },
        'an unimplemented protocol is refused at construction');
}

# ---- classification ---------------------------------------------------------
{
    my $e = Punk::OpenTelemetry::Exporter->new(endpoint => 'http://x');

    is(($e->_classify(200, [], ''))[0], 'ok', '200 with an empty body is ok');
    is(($e->_classify(204, [], undef))[0], 'ok', 'so is 204');

    for my $s (429, 502, 503, 504) {
        is(($e->_classify($s, [], ''))[0], 'retry', "$s is retryable");
    }
    for my $s (400, 401, 403, 404, 413, 422, 500, 501) {
        is(($e->_classify($s, [], ''))[0], 'permanent',
            "$s is permanent: repeating it will not help");
    }
    is(($e->_classify(undef, undef, undef))[0], 'retry',
        'a transport failure with no status at all is retryable');
}

# ---- Retry-After ------------------------------------------------------------
{
    my $e = Punk::OpenTelemetry::Exporter->new(endpoint => 'http://x');
    my (undef, $after) = $e->_classify(503, [ 'Retry-After' => '7' ], '');
    is($after, 7, 'a numeric Retry-After is taken as seconds');

    (undef, $after) = $e->_classify(429, [ 'retry-after' => '3' ], '');
    is($after, 3, 'the header match is case-insensitive');

    (undef, $after) = $e->_classify(503, { 'retry-after' => '5' }, '');
    is($after, 5, 'a hashref of headers works too');

    (undef, $after) = $e->_classify(503, [], '');
    is($after, undef, 'and its absence is undef, not zero');
}

# ---- partial success --------------------------------------------------------
# A 200 that rejected some spans is NOT a failure and NOT retryable. Counting
# it as a plain success is how data disappears while every dashboard is green.
{
    my $e = Punk::OpenTelemetry::Exporter->new(endpoint => 'http://x');

    # ExportTraceServiceResponse { partial_success { rejected_spans: 3,
    #                                                error_message: "nope" } }
    my $inner = "\x08\x03"                        # field 1 varint 3
              . "\x12\x04" . 'nope';              # field 2 bytes "nope"
    my $body  = "\x0a" . chr(length $inner) . $inner;   # field 1, len-delim

    my ($verdict, $detail) = $e->_classify(200, [], $body);
    is($verdict, 'partial', 'a 200 naming rejected spans is a partial success');
    is($detail->{rejected}, 3, 'with the rejected count');
    is($detail->{message}, 'nope', 'and the error message');

    is(($e->_classify(200, [], "\x0a\x00"))[0], 'ok',
        'a partial_success with nothing rejected is a plain success');

    # the same thing over OTLP/JSON
    my $js = Punk::OpenTelemetry::Exporter->new(endpoint => 'http://x',
                                                protocol => 'http/json');
    SKIP: {
        eval { require File::Raw::JSON; 1 } or skip 'File::Raw::JSON', 2;
        my ($v, $d) = $js->_classify(200, [],
            '{"partialSuccess":{"rejectedSpans":2,"errorMessage":"some"}}');
        is($v, 'partial', 'json: a partial success is recognised');
        is($d->{rejected}, 2, 'json: with its count');
    }

    # garbage in the body must not take anything down: an export response we
    # cannot read is an export that worked as far as we can tell
    is(($e->_classify(200, [], "\xff\xff\xff"))[0], 'ok',
        'an unparseable body is treated as success, not as a crash');
    is(($e->_classify(200, [], "\x0a\xff"))[0], 'ok',
        'and so is a truncated one');
}

# ---- backoff ----------------------------------------------------------------
{
    my $e = Punk::OpenTelemetry::Exporter->new(endpoint => 'http://x');

    is($e->backoff(1, 12), 12, 'a Retry-After from the server wins outright');
    is($e->backoff(9, 0), 0, 'including one that says come back immediately');

    for my $attempt (1 .. 8) {
        my $ceiling = 2 ** ($attempt - 1);
        $ceiling = 30 if $ceiling > 30;
        my @s = map { $e->backoff($attempt) } 1 .. 50;
        ok((grep { $_ < 0 } @s) == 0, "attempt $attempt: never negative");
        ok((grep { $_ > $ceiling + 1e-9 } @s) == 0,
            "attempt $attempt: never over the $ceiling second ceiling");
    }

    my @s = map { $e->backoff(6) } 1 .. 200;
    ok((grep { $_ > 30 } @s) == 0, 'the ceiling holds however many attempts');
    my %seen = map { sprintf('%.4f', $_) => 1 } @s;
    ok(scalar(keys %seen) > 100,
        'full jitter really is jittered: a fleet does not retry in lockstep');
}

# ---- the counters -----------------------------------------------------------
{
    my $e = Punk::OpenTelemetry::Exporter->new(endpoint => 'http://x');
    my $s = $e->stats;
    is_deeply([ sort keys %$s ],
        [ qw(dropped exported failures partial rejected retries) ],
        'the exporter reports its own losses');
    is($s->{dropped}, 0, 'and starts at zero');

    $e->{stats}{dropped}++;
    is($e->stats->{dropped}, 1, 'the counters move');
    is($s->{dropped}, 0, 'and stats() hands back a copy, not the live hash');
}

# ---- the request itself -----------------------------------------------------
# _attempt was never asserted while this was Perl. It is the half that actually
# talks to a collector, so it is the half where a wrong header or a dropped
# timeout is invisible until nothing arrives.
{
    package MockUA;
    sub new  { bless { calls => [] }, shift }
    sub request { my ($s, @a) = @_; push @{ $s->{calls} }, \@a; return 'FUTURE' }
    sub loop { undef }
    package main;

    my $ua = MockUA->new;
    my $e  = Punk::OpenTelemetry::Exporter->new(
        endpoint => 'http://collector:4318', ua => $ua,
        headers  => { 'x-api-key' => 'k' }, timeout => 3);

    is($e->_attempt('traces', 'BYTES'), 'FUTURE', '_attempt returns the ua future');
    my ($method, $url, %opt) = @{ $ua->{calls}[0] };
    is($method, 'POST', 'OTLP/HTTP is a POST');
    is($url, 'http://collector:4318/v1/traces', 'to the resolved endpoint');
    is($opt{body}, 'BYTES', 'carrying the encoded bytes');
    is($opt{timeout}, 3, 'under the configured timeout');

    my %h = @{ $opt{headers} };
    is($h{'Content-Type'}, 'application/x-protobuf',
        'the content type matches the protocol');
    is($h{'x-api-key'}, 'k', 'and the configured headers are merged in');

    my $js = Punk::OpenTelemetry::Exporter->new(
        endpoint => 'http://x', ua => MockUA->new, protocol => 'http/json');
    $js->_attempt('traces', '{}');
    my (undef, undef, %jo) = @{ $js->{ua}{calls}[0] };
    my %jh = @{ $jo{headers} };
    is($jh{'Content-Type'}, 'application/json', 'http/json says so too');

    my $none = Punk::OpenTelemetry::Exporter->new(ua => MockUA->new);
    is($none->_attempt('traces', 'x'), undef,
        'no endpoint configured is undef, not a request to nowhere');
}

# gzip when asked for it - and, when the compressor is missing, the payload
# still goes out uncompressed rather than not at all
SKIP: {
    skip 'IO::Compress::Gzip required', 3
        unless eval { require IO::Compress::Gzip; 1 };
    my $e = Punk::OpenTelemetry::Exporter->new(
        endpoint => 'http://x', ua => MockUA->new, compression => 'gzip');
    $e->_attempt('traces', 'hello world ' x 20);
    my (undef, undef, %opt) = @{ $e->{ua}{calls}[0] };
    my %h = @{ $opt{headers} };
    is($h{'Content-Encoding'}, 'gzip', 'the encoding is declared');
    is(substr($opt{body}, 0, 2), "\x1f\x8b", 'and the body really is gzip');
    cmp_ok(length $opt{body}, '<', 240, 'and smaller than what went in');
}

# ---- encode dispatches on the protocol --------------------------------------
{
    require Punk::OpenTelemetry::Encode;
    my $pb = Punk::OpenTelemetry::Exporter->new(endpoint => 'http://x');
    is($pb->encode(traces => $PAYLOAD),
        Punk::OpenTelemetry::Encode::traces_protobuf($PAYLOAD),
        'encode is byte-identical to the protobuf encoder');

    my $js = Punk::OpenTelemetry::Exporter->new(
        endpoint => 'http://x', protocol => 'http/json');
    is($js->encode(traces => $PAYLOAD),
        Punk::OpenTelemetry::Encode::traces_json($PAYLOAD),
        'and to the JSON one under http/json');

    my $err = '';
    eval { $pb->encode(metrics => $PAYLOAD) } or $err = $@;
    like($err, qr/only traces are implemented/, 'another signal is refused');

    $err = '';
    eval { Punk::OpenTelemetry::Exporter->new(protocol => 'grpc') } or $err = $@;
    like($err, qr/unknown protocol 'grpc'/, 'and so is an unknown protocol');
}

# ---- _sleep -----------------------------------------------------------------
# With no loop it blocks and then calls back, which is the honest thing for a
# retry in a script; the return says which of the two happened.
{
    my $e = Punk::OpenTelemetry::Exporter->new(
        endpoint => 'http://x', ua => MockUA->new);
    my $called = 0;
    my $parked = $e->_sleep(0.05, sub { $called++ });
    is($parked, 0, 'with no loop to park on, _sleep blocked');
    is($called, 1, 'and called back exactly once');

    package TimerLoop;
    sub new { bless {}, shift }
    sub _ft_timer { my ($s, $secs, $cb) = @_; $s->{secs} = $secs; return 1 }
    package MockUAL;
    our $LOOP = TimerLoop->new;
    sub new { bless {}, shift }
    sub request { 'F' }
    sub loop { $LOOP }
    package main;

    my $l = Punk::OpenTelemetry::Exporter->new(
        endpoint => 'http://x', ua => MockUAL->new);
    my $ran = 0;
    is($l->_sleep(1.5, sub { $ran++ }), 1, 'a loop that can time parks instead');
    is($MockUAL::LOOP->{secs}, 1.5, 'handing the delay to the loop');
    is($ran, 0, 'without calling back yet - the loop owns that now');
}

# ---- Retry-After, on its own ------------------------------------------------
{
    is(Punk::OpenTelemetry::Exporter::_retry_after([ 'Retry-After' => ' 12 ' ]), 12,
        'a delta in seconds, whitespace and all');
    is(Punk::OpenTelemetry::Exporter::_retry_after([ 'x' => 'y' ]), undef,
        'no Retry-After is undef');
    is(Punk::OpenTelemetry::Exporter::_retry_after(undef), undef,
        'and so are no headers at all');
    is(Punk::OpenTelemetry::Exporter::_retry_after([ 'Retry-After' => 'soon' ]),
        undef, 'an unparseable value is undef, not zero');

    SKIP: {
        skip 'HTTP::Date required', 2 unless eval { require HTTP::Date; 1 };
        my $in30 = HTTP::Date::time2str(time + 30);
        my $d = Punk::OpenTelemetry::Exporter::_retry_after(
            [ 'Retry-After' => $in30 ]);
        cmp_ok($d, '>', 25, 'an HTTP date becomes a delta');
        cmp_ok($d, '<=', 31, 'of about the right size');

        my $past = HTTP::Date::time2str(time - 300);
        is(Punk::OpenTelemetry::Exporter::_retry_after([ 'Retry-After' => $past ]),
            0, 'a date already gone is 0, never negative');
    }
}

done_testing;
