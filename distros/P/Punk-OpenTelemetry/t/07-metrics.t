#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::OpenTelemetry;

# Metrics. Unlike a span, a metric point is STATE: accumulated per attribute
# set, for the life of the process. Both halves of that are where the trouble
# is, and both are asserted here.

sub meter { Punk::OpenTelemetry::Meter->new(scope_name => 's', @_) }
sub metrics_of {
    my ($p) = @_;
    return () unless $p;
    return @{ $p->{resource_metrics}[0]{scope_metrics}[0]{metrics} };
}
sub by_name {
    my ($p, $name) = @_;
    my ($m) = grep { $_->{name} eq $name } metrics_of($p);
    return $m;
}

# ---- the aggregations -------------------------------------------------------
{
    my $m = meter();
    $m->record('hits', 1, 1, { r => '/a' });
    $m->record('hits', 1, 1, { r => '/a' });
    $m->record('hits', 1, 5, { r => '/b' });

    my $p = $m->collect;
    my $hits = by_name($p, 'hits');
    is($hits->{monotonic}, 1, 'a counter is monotonic');
    is(scalar @{ $hits->{data_points} }, 2, 'one point per attribute set');
    my %sum = map { $_->{attributes}{r} => $_->{sum} } @{ $hits->{data_points} };
    is($sum{'/a'}, 2, 'the two /a hits summed');
    is($sum{'/b'}, 5, 'and /b kept its own accumulator');
}

{
    my $m = meter();
    $m->record('temp', 4, 20, {});
    $m->record('temp', 4, 25, {});
    my $dp = by_name($m->collect, 'temp')->{data_points}[0];
    is($dp->{value}, 25, 'a gauge keeps the LAST value, not a sum');
}

{
    my $m = meter();
    $m->record('dur', 3, $_, {}) for (0.001, 0.03, 0.4, 30);
    my $dp = by_name($m->collect, 'dur')->{data_points}[0];
    is($dp->{count}, 4, 'the histogram counted every observation');
    cmp_ok(abs($dp->{sum} - 30.431), '<', 1e-9, 'and summed them');
    is($dp->{min}, 0.001, 'with the minimum');
    is($dp->{max}, 30, 'and the maximum');
    is(scalar @{ $dp->{bucket_counts} },
       scalar(@{ $dp->{explicit_bounds} }) + 1,
       'there is one more bucket than there are boundaries');
    is($dp->{bucket_counts}[-1], 1, 'the 30s observation is in the overflow bucket');
}

# ---- temporality ------------------------------------------------------------
# The whole distinction, and what a backend notices when it is wrong.
{
    my $c = meter(temporality => 'cumulative');
    $c->record('n', 1, 1, {});
    my $first = by_name($c->collect, 'n')->{data_points}[0];
    $c->record('n', 1, 1, {});
    my $second = by_name($c->collect, 'n')->{data_points}[0];
    is($second->{sum}, 2, 'cumulative: the total keeps growing');
    is($second->{start_time_unix_nano}, $first->{start_time_unix_nano},
        'and the series start time stays FIXED across collections');

    my $d = meter(temporality => 'delta');
    $d->record('n', 1, 1, {});
    my $d1 = by_name($d->collect, 'n')->{data_points}[0];
    $d->record('n', 1, 1, {});
    my $d2 = by_name($d->collect, 'n')->{data_points}[0];
    is($d1->{sum}, 1, 'delta: the first interval');
    is($d2->{sum}, 1, 'delta: and the second RESET rather than accumulating');
    ok($d2->{start_time_unix_nano} >= $d1->{start_time_unix_nano},
        'and the interval start moved forward');
}

# ---- the cardinality cap ----------------------------------------------------
# One unbounded attribute - a URL path, a user id, a client-supplied header -
# would otherwise turn a web server into an out-of-memory incident.
{
    my $m = meter();
    $m->record('u', 1, 1, { id => "user$_" }) for 1 .. 2500;
    my %s = $m->stats;
    ok($s{series} <= 2001, "series are capped (got $s{series})");
    ok($s{overflow} > 0, 'and the overflow is COUNTED, not silently discarded');

    my $u = by_name($m->collect, 'u');
    my ($ov) = grep { exists $_->{attributes}{'otel.metric.overflow'} }
                    @{ $u->{data_points} };
    ok($ov, 'everything past the cap folds into one overflow series');
    is($u->{overflow} > 0, 1, 'which the metric reports');
}

# ---- views ------------------------------------------------------------------
{
    my $m = meter();
    $m->view(match => 'noisy', aggregation => 'drop');
    $m->record('noisy', 1, 1, {});
    $m->record('kept', 1, 1, {});
    my @names = map { $_->{name} } metrics_of($m->collect);
    is_deeply(\@names, ['kept'], 'a drop view removes the stream entirely');
}

{
    my $m = meter();
    $m->view(match => 'a.b', name => 'renamed');
    $m->record('a.b', 1, 1, {});
    is(by_name($m->collect, 'renamed')->{name}, 'renamed', 'a view renames');
}

{
    my $m = meter();
    $m->view(match => 'http.*', aggregation => 'drop');
    $m->record('http.one', 1, 1, {});
    $m->record('http.two', 1, 1, {});
    $m->record('other', 1, 1, {});
    my @names = map { $_->{name} } metrics_of($m->collect);
    is_deeply(\@names, ['other'], 'a prefix wildcard selects a family');
}

# dropping attribute KEYS is the primary tool against cardinality, and is
# worth reaching for before the hard cap has to
{
    my $m = meter();
    $m->view(match => 'req', keys => ['route']);
    $m->record('req', 1, 1, { route => '/a', user => "u$_" }) for 1 .. 100;
    my %s = $m->stats;
    is($s{series}, 1,
        'filtering to one bounded key collapses 100 series into one');
    my $dp = by_name($m->collect, 'req')->{data_points}[0];
    is($dp->{attributes}{route}, '/a', 'the kept key survives');
    ok(!exists $dp->{attributes}{user}, 'and the unbounded one is gone');
    is($dp->{sum}, 100, 'with every observation still counted');
}

{
    my $m = meter();
    $m->view(match => 'd', bounds => [1, 2, 3]);
    $m->record('d', 3, 1.5, {});
    my $dp = by_name($m->collect, 'd')->{data_points}[0];
    is_deeply($dp->{explicit_bounds}, [1, 2, 3], 'a view overrides the buckets');
    is(scalar @{ $dp->{bucket_counts} }, 4, 'and the bucket count follows');
}

# ---- conflict detection -----------------------------------------------------
# A backend resolves a name collision silently, by storing whichever arrived
# last. Saying so is the difference between a minute and a quarter.
{
    my $m = meter();
    $m->record('x', 1, 1, {});     # counter
    is($m->conflicts, 0, 'no conflict for one consistent stream');
    $m->record('x', 3, 1, {});     # the same name as a histogram
    ok($m->conflicts > 0, 'the same name with a different KIND is a conflict');
}

# ---- exemplars --------------------------------------------------------------
# The default filter is trace_based: an exemplar pointing at a trace nobody
# recorded is a pointer to nothing.
{
    my $t = Punk::OpenTelemetry::Tracer->new(sampler => 'always_on');
    my $m = meter();

    $m->record('e', 3, 0.5, {});
    my $dp = by_name($m->collect, 'e')->{data_points}[0];
    ok(!exists $dp->{exemplars},
        'with no span in context there is no exemplar');

    my $span = $t->start('op');
    $m->record('e2', 3, 0.5, {}, $span);
    $dp = by_name($m->collect, 'e2')->{data_points}[0];
    ok($dp->{exemplars}, 'with a sampled span there IS one');
    is($dp->{exemplars}[0]{trace_id}, $span->trace_id,
        'carrying the trace id, which is what makes it clickable');
    is($dp->{exemplars}[0]{span_id}, $span->span_id, 'and the span id');
    cmp_ok(abs($dp->{exemplars}[0]{value} - 0.5), '<', 1e-9, 'and the value');
}

# ---- the exponential histogram ---------------------------------------------
# The one piece of numeric code here where being slightly wrong produces a
# plausible number rather than an obvious failure, so it is driven as property
# tests: whatever the scale does, count and total must agree.
{
    my $h = Punk::OpenTelemetry::Expo->new(20);
    my %s = $h->state;
    is($s{count}, 0, 'a fresh histogram is empty');

    $h->record(1);
    %s = $h->state;
    is($s{count}, 1, 'a value is recorded');
    is($s{total}, 1, 'and lands in exactly one bucket');
}

{
    # THE invariant: auto-downscaling must be exact. A downscale that loses a
    # count is a silently wrong percentile, which still looks like data.
    for my $trial (1 .. 5) {
        my $h = Punk::OpenTelemetry::Expo->new(20);
        my $n = 0;
        for (1 .. 400) {
            my $v = exp(rand() * 20 - 10);      # spans many orders of magnitude
            $h->record($v);
            $n++;
        }
        my %s = $h->state;
        is($s{count}, $n, "trial $trial: every value counted");
        is($s{total}, $n, "trial $trial: and every one is still in a bucket "
                        . "after auto-downscaling to scale $s{scale}");
        ok($s{pos_len} <= 160, "trial $trial: the window stayed bounded");
    }
}

{
    # an explicit downscale changes no total
    my $h = Punk::OpenTelemetry::Expo->new(10);
    $h->record($_) for map { $_ / 3 } 1 .. 200;
    my %before = $h->state;
    $h->downscale(3);
    my %after = $h->state;
    is($after{total}, $before{total}, 'an explicit downscale preserves the total');
    is($after{count}, $before{count}, 'and the count');
    is($after{scale}, $before{scale} - 3, 'while reducing the scale');
}

{
    # merging across DIFFERENT scales is where delta-to-cumulative lives, and
    # the operation most likely to lose a count
    my $a = Punk::OpenTelemetry::Expo->new(10);
    my $b = Punk::OpenTelemetry::Expo->new(4);
    $a->record($_) for 1 .. 50;
    $b->record($_ * 1000) for 1 .. 50;
    my %sa = $a->state;
    my %sb = $b->state;
    $a->merge($b);
    my %m = $a->state;
    is($m{count}, $sa{count} + $sb{count}, 'a merge adds the counts');
    is($m{total}, $sa{total} + $sb{total},
        'and loses nothing across differing scales');
    cmp_ok(abs($m{sum} - ($sa{sum} + $sb{sum})), '<', 1e-6, 'sums add too');
}

{
    # the values that are not measurements
    my $h = Punk::OpenTelemetry::Expo->new(10);
    $h->record(9**9**9);              # +inf
    $h->record(-(9**9**9));           # -inf
    $h->record((9**9**9) - (9**9**9)); # NaN
    my %s = $h->state;
    is($s{count}, 0, 'NaN and infinity are dropped: they are not measurements');

    $h->record(0);
    %s = $h->state;
    is($s{zero_count}, 1, 'zero has its own count - it has no logarithm');
    is($s{total}, 1, 'and is included in the total');

    $h->record(-5);
    %s = $h->state;
    is($s{neg_len} > 0, 1, 'a negative value goes in the negative range');
    is($s{total}, 2, 'and is counted');
}

# ---- fork -------------------------------------------------------------------
# A worker inheriting accumulated points would export the parent's totals as
# its own - and under cumulative temporality that is not a duplicate, it is a
# contradictory series under one identity, which a backend resolves by
# resetting, summing or taking the last write. All three wrong.
SKIP: {
    skip 'fork', 1 if $^O =~ /Win32/;
    my $m = meter();
    $m->record('n', 1, 5, {});
    pipe my ($r, $w) or skip 'pipe', 1;
    my $pid = fork;
    skip 'fork failed', 1 unless defined $pid;
    if (!$pid) {
        close $r;
        my $p = $m->collect;
        my $dp = $p ? by_name($p, 'n')->{data_points}[0] : undef;
        print {$w} ($dp ? $dp->{sum} : 0), "\n";
        close $w;
        exit 0;
    }
    close $w;
    chomp(my $child = <$r> // '');
    waitpid $pid, 0;
    is($child + 0, 0,
        'a forked child does NOT inherit the parent accumulated totals');
}

done_testing;
