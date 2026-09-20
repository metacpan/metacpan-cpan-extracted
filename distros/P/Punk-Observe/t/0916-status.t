#!perl
# The status page shows what is already being computed.
#
# shm_stats returned eleven keys and the page displayed four. The cardinality
# cap - whose whole failure mode is a service that silently appears to stop
# reporting - was computed on every request and rendered nowhere. The first
# test below is the one that stops that happening again: a key added to
# shm_stats and shown nowhere is a failing build, not a number nobody sees.
use 5.010;
use strict;
use warnings;
use Test::More;

use Punk::Observe ();
use Punk::Observe::Segment ();
use Punk::Plugin::Observe ();

# --- every counter is rendered or deliberately not ---------------------------
{
    my $h = eval { Punk::Observe::Segment::shm_new(100) };
    skip_all_arena() unless defined $h;
    my $s = Punk::Observe::Segment::shm_stats($h);
    ok(ref $s eq 'HASH', 'shm_stats answers');

    # RENDERED, via the status block in _page and the rows in status.tmpl.
    my %rendered = map { $_ => 1 } qw(
        records bytes rate_rejected shared
        series series_cap rejected overflow
        live_gaps
    );
    # DELIBERATELY NOT: the rate window's internal state. The user-facing
    # half of the rate limiter is `rate_rejected`; the window's bookkeeping
    # is how it works, not what it means.
    # `series_window` is the rotation interval behind the active-series
    # figure - semantics, not a metric. The label already says "active";
    # rendering the interval in nanoseconds would say it worse.
    my %internal = map { $_ => 1 } qw(
        rate_window_start rate_records rate_bytes series_window
    );

    my @unaccounted = grep { !$rendered{$_} && !$internal{$_} } sort keys %$s;
    is_deeply(\@unaccounted, [],
              'every shm_stats key is rendered or explicitly internal')
        or diag("decide for: @unaccounted");

    # And the accounting is not stale in the other direction.
    my @gone = grep { !exists $s->{$_} } sort(keys %rendered, keys %internal);
    is_deeply(\@gone, [], '  and lists no key shm_stats stopped returning');

    Punk::Observe::Segment::shm_free($h);
}

sub skip_all_arena { plan skip_all => 'no shared arena on this platform' }

# --- the template says it in words -------------------------------------------
#
# `orphan_index` means something to somebody who knows the storage engine. A
# label on this page is in the register of "live logs" and "on disk", so no
# internal identifier reaches a <dt>.
{
    my $t = do { open my $fh, '<', 'root/templates/status.tmpl' or die $!;
                 local $/; <$fh> };
    my @dts = $t =~ m{<dt>([^<]*)</dt>}g;
    cmp_ok(scalar @dts, '>', 10, 'the stats list has rows');
    my @raw = grep { /_/ || /\b[a-z]+[A-Z]/ } @dts;
    is_deeply(\@raw, [], 'no internal identifier is used as a label')
        or diag("label these: @raw");

    for my $var (qw(series_used series_rejected overflow_records orphan_index
                    live_gaps)) {
        like($t, qr/\Q{% $var %}\E/, "the page renders $var");
    }
    like($t, qr/series_dropping/, 'and warns when the cap is dropping series');
    # This assertion has flipped with the counter's semantics: the admitted
    # set now ROTATES on a window, so a series' slot frees when it stops
    # reporting and the figure genuinely is the ACTIVE set - no longer
    # boot-scoped, no longer "since start".
    like($t, qr/active metric series/,
         'the series label says active, which the window rotation made true');
}

# --- the ingest chart follows the window -------------------------------------
#
# It was hardcoded to the last hour, so ?range=24h changed the service links
# and quietly not the chart above them - one screen answering two different
# questions. Asserted by recording what the store is actually asked.
{
    package T::Store;
    sub new { bless { calls => [] }, shift }
    sub stats { return {} }
    sub query {
        my ($self, $q, %opt) = @_;
        push @{ $self->{calls} }, { q => $q, from => $opt{from}, to => $opt{to} };
        return { ok => 1, shape => 'buckets', series => [], meta => {} };
    }
    sub records { return [] }

    package T::Ctx;
    sub new { bless { p => $_[1] || {} }, $_[0] }
    sub param  { my ($s, $k) = @_; return $s->{p}{$k} }
    sub req    { return $_[0] }
    sub header { return undef }
    sub status { return $_[0] }
    sub text   { my ($s, $b) = @_; $s->{out} = $b; return $s }
    sub html   { my ($s, $b) = @_; $s->{out} = $b; return $s }
    sub can    { return UNIVERSAL::can(@_) }
}

SKIP: {
    eval { require Template::Stencil; 1 }
        or skip 'Template::Stencil is not installed', 4;

    my $span = sub {
        my (%param) = @_;
        my $store = T::Store->new;
        my $st = {
            prefix  => '/observe',
            opts    => {},
            limits  => {},
            store   => 'unused',
            stores  => { default => $store },
            tenant  => { fixed => 'default', resolver => undef },
            stencil => Template::Stencil->new(template_dir => 'root/templates',
                                              wrapper => 'layout.tmpl'),
            seam    => {},
        };
        my $c = T::Ctx->new(\%param);
        Punk::Plugin::Observe::_page($st, 'status', $c);

        my ($ingest) = grep { defined $_->{from} && defined $_->{to} }
                       @{ $store->{calls} };
        return undef unless $ingest;
        # ns strings; the span in hours, roughly.
        my $ns = Punk::Observe::Store::nsub($ingest->{to}, $ingest->{from});
        return $ns / 3_600_000_000_000;
    };

    my $default = $span->();
    ok(defined $default, 'the ingest chart queried the store');
    cmp_ok(abs($default - 1), '<', 0.1, '  over the default hour');

    my $day = $span->(range => '24h');
    ok(defined $day, 'and with ?range=24h it queried again');
    cmp_ok(abs($day - 24), '<', 0.5, '  over the day that was asked for');
}

# --- a dying stats callback is never silent ----------------------------------
SKIP: {
    eval { require Template::Stencil; 1 }
        or skip 'Template::Stencil is not installed', 2;

    my @warned;
    local $SIG{__WARN__} = sub { push @warned, $_[0] };

    my $store = T::Store->new;
    my $st = {
        prefix  => '/observe',
        opts    => { stats => sub { die "the numbers database is gone\n" } },
        limits  => {},
        store   => 'unused',
        stores  => { default => $store },
        tenant  => { fixed => 'default', resolver => undef },
        stencil => Template::Stencil->new(template_dir => 'root/templates',
                                          wrapper => 'layout.tmpl'),
        seam    => {},
    };
    Punk::Plugin::Observe::_page($st, 'status', T::Ctx->new({}));

    ok((grep { /stats callback died/ } @warned),
       'a stats callback that dies produces a warning');
    ok((grep { /numbers database is gone/ } @warned),
       '  carrying the exception, which is the only thing saying why');
}

# --- live tail gaps reach the arena ------------------------------------------
#
# po_live_gaps is per process: honest to the worker that drained, invisible to
# the worker that renders the status page. The drain now forwards the DELTA to
# the shared arena, so the number the page shows is the sum across workers.
SKIP: {
    skip 'no Shared::Arena ring in this build', 4
        unless eval { Punk::Observe::Live::have_bus() };

    require Punk::Observe::Live;
    my $h = eval { Punk::Observe::Segment::shm_new(10) };
    skip 'no shared arena on this platform', 4 unless defined $h;

    my $slots = 8;
    Punk::Observe::Live::bus_init($slots);
    Punk::Observe::Live::bus_reset_cursors();

    my $topic = Punk::Observe::Live::topic('default');

    # Publish more than the ring holds, so the consumer is lapped.
    Punk::Observe::Live::bus_publish($topic, "{\"n\":$_}") for 1 .. $slots * 3;

    my $d = Punk::Observe::Live::bus_drain($topic, $h);
    cmp_ok($d->{gaps}, '>', 0, 'over-publishing laps the consumer');

    my $s = Punk::Observe::Segment::shm_stats($h);
    is($s->{live_gaps}, $d->{gaps},
       'and the loss reaches the shared arena, where every worker can see it');

    # The DELTA, not the cumulative: a second drain with no new laps must not
    # count the same lost lines again.
    Punk::Observe::Live::bus_publish($topic, '{"n":0}');
    my $d2 = Punk::Observe::Live::bus_drain($topic, $h);
    my $s2 = Punk::Observe::Segment::shm_stats($h);
    is($s2->{live_gaps}, $d2->{gaps},
       'a drain with no new laps adds nothing');

    # Without a handle the arena is untouched - the old calling convention
    # still means what it did.
    Punk::Observe::Live::bus_publish($topic, "{\"n\":$_}") for 1 .. $slots * 3;
    my $before = Punk::Observe::Segment::shm_stats($h)->{live_gaps};
    Punk::Observe::Live::bus_drain($topic);
    is(Punk::Observe::Segment::shm_stats($h)->{live_gaps}, $before,
       'a drain without the handle leaves the arena alone');

    Punk::Observe::Segment::shm_free($h);
}

done_testing();
