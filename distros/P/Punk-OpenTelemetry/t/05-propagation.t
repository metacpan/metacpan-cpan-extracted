#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::OpenTelemetry;

*extract  = \&Punk::OpenTelemetry::Propagate::extract;
*inject   = \&Punk::OpenTelemetry::Propagate::inject;
*tracestate = \&Punk::OpenTelemetry::Propagate::tracestate;
*bag_in   = \&Punk::OpenTelemetry::Propagate::baggage_extract;
*bag_out  = \&Punk::OpenTelemetry::Propagate::baggage_inject;

my $TID = '4bf92f3577b34da6a3ce929d0e0e4736';
my $SID = '00f067aa0ba902b7';

# Context propagation. Every input here is a request header, which means
# attacker-controlled bytes on the hot path of every request: nothing may
# croak, nothing may allocate on a client-supplied length, and a malformed
# header must be ABSENT rather than an error.

# ---- W3C traceparent --------------------------------------------------------
{
    my $c = extract({ traceparent => "00-$TID-$SID-01" });
    is($c->{trace_id}, $TID, 'the trace id');
    is($c->{span_id}, $SID, 'the span id');
    is($c->{sampled}, 1, 'the sampled flag');
    is($c->{format}, 'tracecontext', 'and which format it came from');

    is(extract({ traceparent => "00-$TID-$SID-00" })->{sampled}, 0,
        'flags 00 is not sampled');

    # every flag bit is preserved, not just the one we understand: a bit we
    # do not know the meaning of is still somebody's information
    my $f = extract({ traceparent => "00-$TID-$SID-05" });
    is($f->{flags}, 5, 'unknown flag bits are preserved');
    is($f->{sampled}, 1, 'while bit 0 is still read as sampled');
}

# ---- version tolerance ------------------------------------------------------
# Rejecting an unknown version is how a service becomes the one that breaks
# every trace the day the ecosystem moves to 01.
{
    my $c = extract({ traceparent => "01-$TID-$SID-01-extrafield" });
    ok($c, 'a FUTURE version is parsed, not rejected');
    is($c->{trace_id}, $TID, 'taking the part we understand');

    ok(!extract({ traceparent => "ff-$TID-$SID-01" }),
        'version ff is the one explicit invalid');
    ok(!extract({ traceparent => "01-$TID-$SID-01extra" }),
        'a future version without the separator is still malformed');
}

# ---- malformed traceparent is ABSENT, never an error ------------------------
{
    my @bad = (
        "00-$TID-$SID",              'no flags',
        "00-$TID-$SID-",             'empty flags',
        "00-$TID-$SID-0",            'one flag character',
        "00-" . ('0' x 32) . "-$SID-01", 'an all-zero trace id',
        "00-$TID-" . ('0' x 16) . "-01", 'an all-zero span id',
        "00-" . ('z' x 32) . "-$SID-01", 'a non-hex trace id',
        "00-abc-$SID-01",            'a short trace id',
        "",                          'an empty header',
        "garbage",                   'plain garbage',
        ("x" x 4096),                'a very long header',
        "00_${TID}_${SID}_01",       'the wrong separator',
    );
    while (my ($h, $why) = splice @bad, 0, 2) {
        my $got = eval { extract({ traceparent => $h }) };
        ok(!$@, "$why does not croak");
        is($got, undef, "$why yields no context");
    }
}

# ---- tracestate -------------------------------------------------------------
# The changed member moves to the FRONT; that ordering tells a downstream
# vendor which system touched the trace most recently.
{
    is(tracestate('', 'punk', 'x1'), 'punk=x1', 'a member is added');
    is(tracestate('vendor=abc', 'punk', 'x1'), 'punk=x1,vendor=abc',
        'and goes to the FRONT of the existing state');
    is(tracestate('a=1,punk=old,b=2', 'punk', 'new'), 'punk=new,a=1,b=2',
        'an existing member moves to the front, others keep their order');

    # a malformed member invalidates THAT MEMBER, not the whole header:
    # dropping everyone else's state because one vendor sent something odd is
    # both rude and lossy
    is(tracestate('good=1,BADKEY=2,also=3', 'punk', 'x'),
        'punk=x,good=1,also=3',
        'one malformed member is dropped and the rest survive');
    is(tracestate('nonsense,good=1', 'punk', 'x'), 'punk=x,good=1',
        'a member with no = is dropped in isolation');

    my $many = join ',', map { "k$_=v$_" } 1 .. 40;
    my @m = split /,/, tracestate($many, 'punk', 'x');
    is(scalar @m, 32, 'the list is capped at 32 members');
    is($m[0], 'punk=x', 'with ours at the front');
    is($m[1], 'k1=v1', 'and the OLDEST dropped from the right');
}

# ---- B3 ---------------------------------------------------------------------
{
    my $c = extract({ b3 => "$TID-$SID-1" }, 'b3');
    is($c->{trace_id}, $TID, 'b3 single: the trace id');
    is($c->{span_id}, $SID, 'b3 single: the span id');
    is($c->{sampled}, 1, 'b3 single: sampled');

    # a 64-bit id is LEFT-padded. Getting the side wrong makes a well-formed
    # id of a different value, which looks fine and joins to nothing.
    my $short = extract({ b3 => "a3ce929d0e0e4736-$SID-1" }, 'b3');
    is($short->{trace_id}, '0000000000000000a3ce929d0e0e4736',
        'a 64-bit trace id is padded on the LEFT');
    isnt($short->{trace_id}, 'a3ce929d0e0e47360000000000000000',
        'and specifically NOT on the right');

    for my $s (['1',1], ['0',0], ['true',1], ['false',0]) {
        is(extract({ b3 => "$TID-$SID-$s->[0]" }, 'b3')->{sampled}, $s->[1],
            "b3 sampled '$s->[0]' reads as $s->[1]");
    }

    # debug is a DISTINCT state that implies sampled, not a synonym for it
    my $d = extract({ b3 => "$TID-$SID-d" }, 'b3');
    is($d->{debug}, 1, 'b3 "d" is debug');
    is($d->{sampled}, 1, 'and debug implies sampled');

    ok(!extract({ b3 => "$TID-$SID-1" }), 'b3 is not read unless configured');
}

# ---- B3 multi ---------------------------------------------------------------
{
    my $c = extract({ 'x-b3-traceid' => $TID, 'x-b3-spanid' => $SID,
                      'x-b3-sampled' => '1' }, 'b3');
    is($c->{trace_id}, $TID, 'b3 multi: the trace id');
    is($c->{sampled}, 1, 'b3 multi: sampled');

    # X-B3-Flags: 1 is the multi-header spelling of debug, and debug implies
    # sampled even when X-B3-Sampled says otherwise
    my $d = extract({ 'x-b3-traceid' => $TID, 'x-b3-spanid' => $SID,
                      'x-b3-flags' => '1', 'x-b3-sampled' => '0' }, 'b3');
    is($d->{debug}, 1, 'X-B3-Flags: 1 is debug');
    is($d->{sampled}, 1, 'which overrides an X-B3-Sampled of 0');

    # single wins when both are present
    my $both = extract({ b3 => "$TID-$SID-1",
                         'x-b3-traceid' => 'b' x 32,
                         'x-b3-spanid'  => 'c' x 16 }, 'b3');
    is($both->{trace_id}, $TID, 'the single header wins over the multi form');
}

# ---- Jaeger -----------------------------------------------------------------
{
    my $c = extract({ 'uber-trace-id' => "$TID:$SID:0:1" }, 'jaeger');
    is($c->{trace_id}, $TID, 'jaeger: the trace id');
    is($c->{span_id}, $SID, 'jaeger: the span id');
    is($c->{sampled}, 1, 'jaeger: flag bit 1 is sampled');

    my $d = extract({ 'uber-trace-id' => "$TID:$SID:0:3" }, 'jaeger');
    is($d->{debug}, 1, 'jaeger: flag bit 2 is debug');
    is($d->{sampled}, 1, 'and debug implies sampled');

    # Jaeger trims leading zeroes without regard for byte boundaries
    my $short = extract({ 'uber-trace-id' => "abc:def:0:1" }, 'jaeger');
    is($short->{trace_id}, '0' x 29 . 'abc', 'a short trace id is left-padded');
    is($short->{span_id}, '0' x 13 . 'def', 'and so is a short span id');

    # proxies percent-encode the whole value, treating it as a URL component.
    # A parser that only accepts the raw form drops context from every request
    # that passed through one, which looks like an intermittent tracing bug.
    my $enc = extract({ 'uber-trace-id' => "$TID%3A$SID%3A0%3A1" }, 'jaeger');
    ok($enc, 'a percent-encoded uber-trace-id is decoded');
    is($enc->{trace_id}, $TID, 'and yields the same context');

    ok(!extract({ 'uber-trace-id' => 'garbage' }, 'jaeger'),
        'garbage yields no context');
    ok(!extract({ 'uber-trace-id' => 'x' x 4096 }, 'jaeger'),
        'and an over-long value is bounded, not parsed');
}

# ---- the composite ----------------------------------------------------------
{
    # inject emits EVERY configured format, which is what makes a mixed-fleet
    # migration possible without a flag day
    my $h = inject($TID, $SID, 1, 'tracecontext,b3,jaeger');
    is($h->{traceparent}, "00-$TID-$SID-01", 'traceparent is injected');
    is($h->{b3}, "$TID-$SID-1", 'and b3');
    is($h->{'uber-trace-id'}, "$TID:$SID:0:1", 'and uber-trace-id');

    my $one = inject($TID, $SID, 0, 'tracecontext');
    is_deeply([sort keys %$one], ['traceparent'],
        'only the configured formats are emitted');
    is($one->{traceparent}, "00-$TID-$SID-00", 'an unsampled flag round-trips');

    # extract order matters, and both orders are reasonable to configure
    my %mixed = ( traceparent => "00-$TID-$SID-01",
                  b3          => ('b' x 32) . "-$SID-1" );
    is(extract(\%mixed, 'tracecontext,b3')->{format}, 'b3',
        'a later propagator overrides an earlier one');
    is(extract(\%mixed, 'b3,tracecontext')->{format}, 'tracecontext',
        'so the two orders genuinely differ');

    is(inject('0' x 32, $SID, 1, 'tracecontext')->{traceparent}, undef,
        'an all-zero trace id propagates nothing rather than a bad header');
}

# ---- baggage ----------------------------------------------------------------
{
    my $b = bag_in('key1=value1,key2=value2');
    is($b->{key1}, 'value1', 'baggage is parsed');
    is($b->{key2}, 'value2', 'both entries');

    is(bag_in('k=%20a%2Cb')->{k}, ' a,b', 'values are percent-DEcoded');
    like(bag_out({ k => ' a,b' }), qr/k=%20a%2Cb/,
        'and percent-ENcoded on the way out');

    # a value taken from a request and re-emitted must not be able to forge an
    # entry or split the header
    my $evil = bag_out({ k => "x,injected=1" });
    unlike($evil, qr/,injected=1/, 'a comma in a value cannot forge an entry');
    is(scalar(keys %{ bag_in($evil) }), 1, 'and it round-trips as one entry');

    my $nl = bag_out({ k => "a\r\nX-Evil: 1" });
    unlike($nl, qr/[\r\n]/, 'a newline in a value cannot split the header');

    is(bag_out({ b => 2, a => 1 }), 'a=1,b=2', 'keys are sorted');

    # over-limit entries are DROPPED, not truncated: a truncated value is a
    # different value, and silently changing an application's data is worse
    # than not carrying it
    my $big = bag_in('k=' . ('v' x 5000));
    ok(!exists $big->{k}, 'an over-long entry is dropped, not truncated');

    my %many = map { ("k$_" => $_) } 1 .. 300;
    my $out = bag_out(\%many);
    my $n = () = $out =~ /=/g;
    ok($n <= 180, "the entry cap is honoured on inject ($n entries)");
    ok(length($out) <= 8192, 'and the total size cap');

    is_deeply(bag_in(''), {}, 'an empty header is empty baggage');
    is_deeply(bag_in('nonsense'), {}, 'and so is one with no =');
}

# ---- extraction feeds the tracer -------------------------------------------
{
    my $t = Punk::OpenTelemetry::Tracer->new(sampler => 'always_on');
    my $c = extract({ traceparent => "00-$TID-$SID-01" });
    my $span = $t->start('child', parent => $c);
    is($span->trace_id, $TID,
        'an extracted context is exactly what start(parent => ...) takes');
    is($span->to_hash->{parent_span_id}, $SID, 'with the right parent');
}

done_testing;
