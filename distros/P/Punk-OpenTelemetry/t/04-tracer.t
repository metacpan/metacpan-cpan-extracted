#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::OpenTelemetry;

# The trace SDK: ids, clocks, sampling, span limits and the bounded queue.

sub tracer { Punk::OpenTelemetry::Tracer->new(sampler => 'always_on', @_) }

# ---- ids --------------------------------------------------------------------
{
    my $t = tracer();
    my (%tids, %sids);
    for (1 .. 200) {
        my $s = $t->start('x');
        $tids{ $s->trace_id }++;
        $sids{ $s->span_id }++;
    }
    is(scalar keys %tids, 200, '200 spans, 200 distinct trace ids');
    is(scalar keys %sids, 200, 'and 200 distinct span ids');

    my ($tid) = keys %tids;
    is(length $tid, 32, 'a trace id is 32 hex characters (16 bytes)');
    like($tid, qr/^[0-9a-f]{32}$/, 'lowercase hex');
    my ($sid) = keys %sids;
    is(length $sid, 16, 'a span id is 16 hex characters (8 bytes)');

    # all-zero is not a valid id in either direction: never generated, and
    # never accepted as a parent
    ok(!grep({ /^0+$/ } keys %tids), 'no trace id is all zero');
    ok(!grep({ /^0+$/ } keys %sids), 'no span id is all zero');
}

# ---- an all-zero or malformed parent is ABSENT, not a parent ---------------
# A span claiming a parent that cannot exist is worse than a root span: it
# hangs off nothing, for ever, in every UI.
{
    my $t = tracer();
    for my $bad ('0' x 32, 'nothex' . ('0' x 26), 'abc', '') {
        my $s = $t->start('x', parent => { trace_id => $bad,
                                           span_id  => '00f067aa0ba902b7',
                                           sampled  => 1 });
        my $h = $s->to_hash;
        ok(!exists $h->{parent_span_id},
            "a trace id of '" . substr($bad, 0, 12) . "' is not treated as a parent");
    }
    my $s = $t->start('x', parent => { trace_id => 'a' x 32,
                                       span_id  => '0' x 16, sampled => 1 });
    ok(!exists $s->to_hash->{parent_span_id},
        'an all-zero SPAN id is not a parent either');
}

# ---- a valid parent is inherited -------------------------------------------
{
    my $t = tracer();
    my $s = $t->start('child', parent => {
        trace_id => '4bf92f3577b34da6a3ce929d0e0e4736',
        span_id  => '00f067aa0ba902b7', sampled => 1 });
    is($s->trace_id, '4bf92f3577b34da6a3ce929d0e0e4736',
        'the child continues the parent trace id');
    is($s->to_hash->{parent_span_id}, '00f067aa0ba902b7',
        'and records the parent span id');
    isnt($s->span_id, '00f067aa0ba902b7', 'with a span id of its own');
}

# ---- sampling: deterministic in the trace id -------------------------------
# THE rule. With a coin flip per service, three services at 10% keep the same
# trace one time in a thousand, and a backend receives fragments with dangling
# parents while the dashboard claims 10% sampling.
{
    my $half = Punk::OpenTelemetry::Tracer->new(ratio => 0.5);

    # the same id decided twice gives the same answer - which is what makes it
    # the same answer in another process, with no coordination
    for my $trial (1 .. 20) {
        my $tid = sprintf '%032x', int(rand(2**32)) * 1000 + $trial;
        my @out = map {
            defined $half->start('x', parent => { trace_id => $tid,
                span_id => '00f067aa0ba902b7', sampled => 1 }) ? 1 : 0
        } 1 .. 3;
        is_deeply(\@out, [ @out[0,0,0] ],
            "trace $trial: the decision is the same every time");
    }

    # and the ratio is actually honoured over many ids
    my $on  = Punk::OpenTelemetry::Tracer->new(ratio => 1.0);
    my $off = Punk::OpenTelemetry::Tracer->new(ratio => 0.0);
    my $kept_on  = grep { defined $on->start('x') }  1 .. 200;
    my $kept_off = grep { defined $off->start('x') } 1 .. 200;
    is($kept_on, 200, 'ratio 1.0 keeps everything');
    is($kept_off, 0, 'ratio 0.0 keeps nothing');

    my $ten = Punk::OpenTelemetry::Tracer->new(ratio => 0.1);
    my $kept = grep { defined $ten->start('x') } 1 .. 4000;
    ok($kept > 250 && $kept < 550,
        "ratio 0.1 keeps roughly a tenth (kept $kept of 4000)");
}

# ---- ParentBased: an existing decision is inherited -------------------------
# A service that re-decides mid-trace produces a trace with holes in the
# middle, which is harder to read than no trace at all.
{
    my $off = Punk::OpenTelemetry::Tracer->new(ratio => 0.0);
    my $s = $off->start('child', parent => {
        trace_id => '4bf92f3577b34da6a3ce929d0e0e4736',
        span_id  => '00f067aa0ba902b7', sampled => 1 });
    ok(defined $s,
        'a sampled parent is honoured even at ratio 0: the decision is inherited');

    my $on = Punk::OpenTelemetry::Tracer->new(ratio => 1.0);
    my $u = $on->start('child', parent => {
        trace_id => '4bf92f3577b34da6a3ce929d0e0e4736',
        span_id  => '00f067aa0ba902b7', sampled => 0 });
    ok(!defined $u,
        'and an UNsampled parent is honoured even at ratio 1');

    for my $k ([ 'always_on', 1 ], [ 'always_off', 0 ]) {
        my $t = Punk::OpenTelemetry::Tracer->new(sampler => $k->[0]);
        my $got = defined $t->start('x', parent => {
            trace_id => 'a' x 32, span_id => 'b' x 16, sampled => !$k->[1] });
        is($got ? 1 : 0, $k->[1], "$k->[0] overrides the parent, as it must");
    }
}

# ---- an unsampled span allocates nothing -----------------------------------
{
    my $off = Punk::OpenTelemetry::Tracer->new(sampler => 'always_off');
    my $s = $off->start('x');
    is($s, undef, 'an unsampled start returns undef, not a null-object');
    my %st = $off->stats;
    is($st{started}, 0, 'and is not counted as started');
    is($st{sampled_out}, 1, 'it is counted as sampled out');
    is($off->queued, 0, 'nothing was queued');
}

# ---- the clock --------------------------------------------------------------
# Two wall-clock reads can go backwards across an NTP step; the duration is
# measured on a monotonic clock and the end derived from it.
{
    my $t = tracer();
    my $s = $t->start('x');
    select undef, undef, undef, 0.02;
    $s->end;
    my $h = $s->to_hash;
    ok($h->{end_time_unix_nano} >= $h->{start_time_unix_nano},
        'a span never ends before it starts');
    ok($h->{end_time_unix_nano} - $h->{start_time_unix_nano} >= 10_000_000,
        'and the measured duration is real (>= 10ms for a 20ms sleep)');
    ok($h->{start_time_unix_nano} > 1_600_000_000_000_000_000,
        'the start is a plausible unix nanosecond timestamp, not uptime');
}

# ---- span limits, and the counts -------------------------------------------
# A span that quietly loses its 129th attribute looks complete, and somebody
# spends an afternoon on it. One that says "1 dropped" answers first.
{
    my $t = tracer();
    my $s = $t->start('x');
    $s->attr("k$_" => $_) for 1 .. 200;
    my ($attrs, $dropped) = $s->counts;
    is($attrs, 128, 'attributes are capped at 128');
    is($dropped, 72, 'and the 72 that did not fit are counted');
    is($s->to_hash->{dropped_attributes_count}, 72,
        'the count reaches the payload, where a reader will see it');

    # overwriting is not adding: a loop that updates one attribute must not
    # look like a span with a hundred dropped ones
    my $u = $t->start('x');
    $u->attr(same => $_) for 1 .. 300;
    my ($ua, $ud) = $u->counts;
    is($ua, 1, 'overwriting one key leaves one attribute');
    is($ud, 0, 'and drops nothing');

    my $e = $t->start('x');
    $e->event("e$_") for 1 .. 200;
    my (undef, undef, $ev, $evd) = $e->counts;
    is($ev, 128, 'events are capped at 128');
    is($evd, 72, 'and the rest counted');
    is($e->to_hash->{dropped_events_count}, 72, 'in the payload too');

    my $l = $t->start('x');
    $l->link('a' x 32, 'b' x 16) for 1 .. 200;
    my (undef, undef, undef, undef, $ln, $lnd) = $l->counts;
    is($ln, 128, 'links are capped at 128');
    is($lnd, 72, 'and the rest counted');
}

# ---- status -----------------------------------------------------------------
{
    my $t = tracer();
    my $unset = $t->start('x');
    ok(!exists $unset->to_hash->{status},
        'a span with no opinion carries no status at all');

    my $err = $t->start('x')->status(2, 'upstream refused');
    is($err->to_hash->{status}{code}, 2, 'an error status is recorded');
    is($err->to_hash->{status}{message}, 'upstream refused', 'with its message');
}

# ---- the bounded queue ------------------------------------------------------
# Unbounded in front of an unreachable collector is not a queue, it is a
# memory leak with a schedule.
{
    my $t = tracer();
    for (1 .. 2500) {
        my $s = $t->start("s$_");
        $t->enqueue($s);
    }
    is($t->queued, 2048, 'the queue is bounded at 2048');
    my %st = $t->stats;
    is($st{dropped}, 452, 'and what overflowed is counted, not silently lost');
    is($st{ended}, 2500, 'every span was still accounted for');

    # drop-OLDEST: when a system is in trouble the recent spans are the
    # interesting ones
    my $p = $t->drain(1);
    is($p->{resource_spans}[0]{scope_spans}[0]{spans}[0]{name}, 's453',
        'the oldest surviving span is s453: the OLDEST were dropped');
}

# ---- drain ------------------------------------------------------------------
{
    my $t = tracer(resource => { 'service.name' => 'maat' },
                   scope_name => 'sc', scope_version => '9');
    is($t->drain, undef, 'draining an empty queue returns undef, not an empty payload');

    $t->enqueue($t->start("s$_")) for 1 .. 10;
    my $p = $t->drain(4);
    is(scalar @{ $p->{resource_spans}[0]{scope_spans}[0]{spans} }, 4,
        'drain takes at most the batch size asked for');
    is($t->queued, 6, 'and leaves the rest queued');

    is($p->{resource_spans}[0]{resource}{attributes}{'service.name'}, 'maat',
        'the payload carries the resource');
    is($p->{resource_spans}[0]{scope_spans}[0]{scope}{name}, 'sc',
        'and the scope');

    # it is the shape the phase-2 encoders take
    my $bytes = Punk::OpenTelemetry::Encode::traces_protobuf($p);
    ok(length($bytes) > 0, 'and encodes as protobuf without further shaping');
    is(length($bytes), Punk::OpenTelemetry::Encode::traces_protobuf_size($p),
        'with the two encoder passes still agreeing');
}

# ---- fork -------------------------------------------------------------------
# A worker inheriting a queue would export the parent's spans as its own, once
# per worker.
SKIP: {
    skip 'fork', 2 unless $Config::Config{d_fork} || $^O !~ /Win32/;
    my $t = tracer();
    $t->enqueue($t->start("s$_")) for 1 .. 5;
    is($t->queued, 5, 'the parent has five queued');

    pipe my ($r, $w) or skip 'pipe', 1;
    my $pid = fork;
    skip 'fork failed', 1 unless defined $pid;
    if (!$pid) {
        close $r;
        print {$w} $t->queued, "\n";
        close $w;
        POSIX::_exit(0) if eval { require POSIX; 1 };
        exit 0;
    }
    close $w;
    chomp(my $child = <$r> // '');
    waitpid $pid, 0;
    is($child, 0, 'a forked child starts with an EMPTY queue, not a copy');
}

# ---- the resource -----------------------------------------------------------
{
    require Punk::OpenTelemetry::Resource;
    my $r = Punk::OpenTelemetry::Resource::detect(service_name => 'maat');
    is($r->{'service.name'}, 'maat', 'the service name is set');
    is($r->{'telemetry.sdk.language'}, 'perl', 'the sdk language');
    is($r->{'telemetry.sdk.name'}, 'punk-opentelemetry', 'the sdk name');
    is($r->{'process.pid'}, $$, 'the pid');
    like($r->{'service.instance.id'}, qr/^[0-9a-f-]{36}$/,
        'the instance id is uuid-shaped');

    # THE rule: two calls must never agree. Prefork workers sharing an
    # instance id make a collector see several contradictory cumulative
    # series claiming to be one, and it resolves that wrongly and invisibly.
    my %seen = map {
        Punk::OpenTelemetry::Resource::detect(service_name => 'x')
            ->{'service.instance.id'} => 1
    } 1 .. 50;
    is(scalar keys %seen, 50,
        'every detect() gives a DIFFERENT service.instance.id');

    {
        local $ENV{OTEL_SERVICE_NAME} = 'from-env';
        is(Punk::OpenTelemetry::Resource::detect()->{'service.name'},
            'from-env', 'OTEL_SERVICE_NAME is read');
        is(Punk::OpenTelemetry::Resource::detect(service_name => 'explicit')
             ->{'service.name'}, 'explicit',
            'and an explicit name wins over it');
    }
    {
        local $ENV{OTEL_SERVICE_NAME} = 'x';
        local $ENV{OTEL_RESOURCE_ATTRIBUTES}
            = 'a=1,deployment.environment=prod';
        my $e = Punk::OpenTelemetry::Resource::detect();
        is($e->{a}, 1, 'OTEL_RESOURCE_ATTRIBUTES is parsed');
        is($e->{'deployment.environment'}, 'prod', 'including dotted keys');
    }

    # an unnamed service warns once, loudly: it is indistinguishable from
    # every other unnamed service in the fleet
    {
        local $ENV{OTEL_SERVICE_NAME};
        local $ENV{OTEL_RESOURCE_ATTRIBUTES};
        my @warn;
        local $SIG{__WARN__} = sub { push @warn, "@_" };
        my $u = Punk::OpenTelemetry::Resource::detect();
        is($u->{'service.name'}, 'unknown_service', 'the spec default is used');
        ok(scalar(grep { /unknown_service/ } @warn),
            'and it warns, where somebody can still act on it');
    }

    # a worker refreshes its instance id after a fork
    my $t = tracer(resource => $r);
    $t->resource_attr('service.instance.id' => 'fresh');
    $t->enqueue($t->start('s'));
    is($t->drain->{resource_spans}[0]{resource}{attributes}
         {'service.instance.id'},
       'fresh', 'resource_attr updates what the payload carries');
}

done_testing;
