#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use OTelWire qw(pb_parse pb_field pb_fields pb_str);
use Punk::OpenTelemetry;

*mpb = \&Punk::OpenTelemetry::Encode::metrics_protobuf;
*lpb = \&Punk::OpenTelemetry::Encode::logs_protobuf;
*sev = \&Punk::OpenTelemetry::Logs::severity;

# The metrics and logs signals on the wire, checked against the independent
# reader in t/lib/OTelWire.pm - written from the wire spec alone, so it cannot
# agree with the encoder's own bugs.

# ---- metrics -----------------------------------------------------------------
{
    my $m = Punk::OpenTelemetry::Meter->new(
        scope_name => 'sc', resource => { 'service.name' => 'maat' });
    $m->record('hits', 1, 4, { r => '/x' });
    my $bytes = mpb($m->collect);
    ok(length $bytes, 'a metrics payload encodes');

    my $req = pb_parse($bytes);
    my $rm  = pb_parse(pb_field($req, 1));        # ResourceMetrics
    my $res = pb_parse(pb_field($rm, 1));         # Resource
    my $kv  = pb_parse((pb_fields($res, 1))[0]);
    is(pb_field($kv, 1), 'service.name', 'the resource survives');

    my $sm  = pb_parse(pb_field($rm, 2));         # ScopeMetrics
    is(pb_field(pb_parse(pb_field($sm, 1)), 1), 'sc', 'and the scope');

    my $met = pb_parse(pb_field($sm, 2));         # Metric
    is(pb_field($met, 1), 'hits', 'the metric name');
    ok(exists $met->{7}, 'a counter uses the Sum wrapper (field 7)');

    my $sum = pb_parse(pb_field($met, 7));
    is(pb_field($sum, 3), 1, 'and is marked monotonic');

    my $dp = pb_parse(pb_field($sum, 1));         # NumberDataPoint
    is(unpack('d<', pb_field($dp, 4)), 4, 'the value');
    ok(pb_str(pb_field($dp, 2)) > 0, 'with a start time');
    my $at = pb_parse((pb_fields($dp, 7))[0]);
    is(pb_field($at, 1), 'r', 'and its attributes');
}

# ---- the temporality trap ----------------------------------------------------
# The OTLP enum is DELTA=1, CUMULATIVE=2 - the REVERSE of the internal
# constants. Emitting the internal value would label every series as its
# opposite, which a backend accepts without complaint and then draws
# completely wrongly.
{
    for my $case ([ 'cumulative', 2 ], [ 'delta', 1 ]) {
        my ($name, $want) = @$case;
        my $m = Punk::OpenTelemetry::Meter->new(temporality => $name);
        $m->record('n', 1, 1, {});
        my $req = pb_parse(mpb($m->collect));
        my $sum = pb_parse(pb_field(pb_parse(pb_field(
                    pb_parse(pb_field(pb_parse(pb_field($req,1)),2)),2)), 7));
        is(pb_field($sum, 2), $want,
            "$name is emitted as the OTLP value $want, not the internal one");
    }
}

# ---- histogram on the wire ---------------------------------------------------
{
    my $m = Punk::OpenTelemetry::Meter->new;
    $m->record('d', 3, $_, {}) for (0.001, 0.2, 5);
    my $req = pb_parse(mpb($m->collect));
    my $met = pb_parse(pb_field(pb_parse(pb_field(
                pb_parse(pb_field($req, 1)), 2)), 2));
    ok(exists $met->{9}, 'a histogram uses the Histogram wrapper (field 9)');

    my $h  = pb_parse(pb_field($met, 9));
    my $dp = pb_parse(pb_field($h, 1));
    is(pb_str(pb_field($dp, 4)), 3, 'the count');
    cmp_ok(abs(unpack('d<', pb_field($dp, 5)) - 5.201), '<', 1e-9, 'the sum');

    # packed repeated fields: ONE length-delimited field holding the values
    # back to back, not a tag per value. The schema declares these packed and
    # strict consumers read them that way.
    my $bk = pb_field($dp, 6);
    is(length($bk) % 8, 0, 'bucket_counts is packed fixed64');
    is(length($bk) / 8, 15, 'with one bucket per boundary plus the overflow');
    my @counts = unpack 'Q<*', $bk;
    is(eval { my $t = 0; $t += $_ for @counts; $t }, 3,
        'and every observation is in exactly one bucket');

    my $bd = pb_field($dp, 7);
    is(length($bd) / 8, 14, 'explicit_bounds is packed double');
}

# ---- the exponential histogram on the wire -----------------------------------
{
    my $m = Punk::OpenTelemetry::Meter->new;
    $m->view(match => 'e', aggregation => 'exponential');
    $m->record('e', 3, $_, {}) for map { $_ / 3 } 1 .. 60;
    my $req = pb_parse(mpb($m->collect));
    my $met = pb_parse(pb_field(pb_parse(pb_field(
                pb_parse(pb_field($req, 1)), 2)), 2));
    ok(exists $met->{10},
        'an exponential histogram uses field 10, not the explicit one');

    my $eh = pb_parse(pb_field($met, 10));
    my $dp = pb_parse(pb_field($eh, 1));
    is(pb_str(pb_field($dp, 4)), 60, 'every value counted');
    ok(exists $dp->{8}, 'the positive buckets are present');
    my $pos = pb_parse(pb_field($dp, 8));
    my $bc  = pb_field($pos, 2);
    ok(defined $bc, 'with packed bucket counts');
}

# ---- exemplars on the wire ---------------------------------------------------
{
    my $t = Punk::OpenTelemetry::Tracer->new(sampler => 'always_on');
    my $span = $t->start('op');
    my $m = Punk::OpenTelemetry::Meter->new;
    $m->record('d', 3, 0.5, {}, $span);
    my $req = pb_parse(mpb($m->collect));
    my $met = pb_parse(pb_field(pb_parse(pb_field(
                pb_parse(pb_field($req, 1)), 2)), 2));
    my $dp  = pb_parse(pb_field(pb_parse(pb_field($met, 9)), 1));
    ok(exists $dp->{8}, 'the data point carries an exemplar');
    my $ex = pb_parse((pb_fields($dp, 8))[0]);
    is(unpack('H*', pb_field($ex, 5)), $span->trace_id,
        'carrying the trace id, which is what makes it clickable');
    is(length(pb_field($ex, 5)), 16, 'as 16 raw bytes');
}

# ---- logs --------------------------------------------------------------------
{
    my $t = Punk::OpenTelemetry::Tracer->new(sampler => 'always_on');
    my $span = $t->start('op');
    my $lg = Punk::OpenTelemetry::Logs->new(
        scope_name => 'sc', resource => { 'service.name' => 'maat' });

    $lg->emit('error', 'db down', { dsn => 'pg' }, $span);
    $lg->emit('info',  'fine');

    my $p = $lg->drain;
    is(scalar @{ $p->{resource_logs}[0]{scope_logs}[0]{log_records} }, 2,
        'both records drained');

    my $bytes = lpb($p);
    ok(length $bytes, 'and encode');

    my $req = pb_parse($bytes);
    my $rl  = pb_parse(pb_field($req, 1));
    my $sl  = pb_parse(pb_field($rl, 2));
    my @recs = pb_fields($sl, 2);
    is(scalar @recs, 2, 'two LogRecords on the wire');

    my $r = pb_parse($recs[0]);
    is(pb_field($r, 2), 17, 'severity_number for error');
    is(pb_field($r, 3), 'error', 'severity_text');
    is(pb_field(pb_parse(pb_field($r, 5)), 1), 'db down',
        'the body is an AnyValue, so a structured body stays possible');
    is(unpack('H*', pb_field($r, 9)), $span->trace_id,
        'the trace id correlates the line with a trace');
    is(unpack('H*', pb_field($r, 10)), $span->span_id, 'and the span id');
    ok(pb_str(pb_field($r, 11)) > 0, 'observed_time is set');

    my $second = pb_parse($recs[1]);
    ok(!exists $second->{9},
        'a line logged outside a span carries no trace id rather than a fake one');
}

# ---- severity mapping --------------------------------------------------------
# The bands are four wide; this picks the FIRST of each, which is what a
# threshold written as ">= 13" compares against.
{
    is(sev('trace'), 1,  'trace');
    is(sev('debug'), 5,  'debug');
    is(sev('info'),  9,  'info');
    is(sev('warn'),  13, 'warn');
    is(sev('error'), 17, 'error');
    is(sev('fatal'), 21, 'fatal');
    is(sev('nonsense'), 9, 'an unknown level falls back to info, not to zero');
    is(sev(undef), 9, 'and so does undef');
}

# ---- the log queue -----------------------------------------------------------
{
    my $lg = Punk::OpenTelemetry::Logs->new;
    $lg->emit('info', "m$_") for 1 .. 5000;
    my %s = $lg->stats;
    is($s{emitted}, 5000, 'every line was accounted for');
    ok($s{queued} <= 4096, 'the queue is bounded');
    ok($s{dropped} > 0, 'and what overflowed is COUNTED, not silently lost');

    my $p = $lg->drain(3);
    is(scalar @{ $p->{resource_logs}[0]{scope_logs}[0]{log_records} }, 3,
        'drain takes at most the batch asked for');
}

# ---- the recursion guard -----------------------------------------------------
# The exporter's own diagnostics must not come back round through the logger
# that ships them to the collector that is failing.
{
    my $lg = Punk::OpenTelemetry::Logs->new;
    Punk::OpenTelemetry::Instrument::suppress_begin();
    $lg->emit('error', 'export failed');
    Punk::OpenTelemetry::Instrument::suppress_end();
    my %s = $lg->stats;
    is($s{emitted}, 0,
        'a line emitted while suppressed is not queued for export');

    $lg->emit('error', 'a real one');
    %s = $lg->stats;
    is($s{emitted}, 1, 'and ordinary lines are unaffected');
}

# ---- empty ------------------------------------------------------------------
{
    my $lg = Punk::OpenTelemetry::Logs->new;
    is($lg->drain, undef, 'draining nothing returns undef, not an empty payload');
    my $m = Punk::OpenTelemetry::Meter->new;
    is($m->collect, undef, 'and so does collecting nothing');
}

# ---- fork --------------------------------------------------------------------
SKIP: {
    skip 'fork', 1 if $^O =~ /Win32/;
    my $lg = Punk::OpenTelemetry::Logs->new;
    $lg->emit('info', "m$_") for 1 .. 5;
    pipe my ($r, $w) or skip 'pipe', 1;
    my $pid = fork;
    skip 'fork failed', 1 unless defined $pid;
    if (!$pid) {
        close $r;
        my %s = $lg->stats;
        print {$w} $s{queued}, "\n";
        close $w;
        exit 0;
    }
    close $w;
    chomp(my $child = <$r> // '');
    waitpid $pid, 0;
    is($child, 0, 'a forked child does not inherit the parent log queue');
}

done_testing;
