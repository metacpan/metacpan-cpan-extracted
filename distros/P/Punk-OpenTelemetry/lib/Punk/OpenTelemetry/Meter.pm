package Punk::OpenTelemetry::Meter;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.01';

# All of it is C (include/otel_expo.h, otel_metric.h, otel_meter.h +
# xs/meter.xs). This file is documentation.

1;

__END__

=head1 NAME

Punk::OpenTelemetry::Meter - metrics

=head1 SYNOPSIS

    my $meter = Punk::OpenTelemetry::Meter->new(
        resource      => $resource,
        scope_name    => 'Punk::OpenTelemetry',
        temporality   => 'cumulative',
    );

    # drop an unbounded attribute before it becomes a problem
    $meter->view(match => 'http.*', keys => ['http.route',
                                             'http.response.status_code']);

    $meter->record('http.server.request.duration', 3, $seconds,
                   { 'http.route' => '/users/:id' }, $span);

    my $payload = $meter->collect;

=head1 WHAT MAKES METRICS DIFFERENT FROM TRACES

State.

A span is created, ended and forgotten. A metric point is accumulated B<per
attribute set>, B<for the life of the process>, and both of those phrases are
where the trouble is.

=head2 Per attribute set: the cardinality cap

The number of accumulators is the number of distinct attribute combinations
the application produces - a number the application does not know and an
attacker may choose.

So there is a hard cap (2000 series per instrument), and past it everything
folds into one overflow series marked C<otel.metric.overflow>, counted and
reported. Without a cap, one unbounded attribute - a URL path, a user id, a
client-supplied header - turns a web server into an out-of-memory incident,
and the attribute most likely to do it is exactly the one somebody added to
make a dashboard more useful.

The cap is the backstop. The B<tool> is a view that keeps only the bounded
keys; see L</view>.

=head2 For the life of the process: identity, and forking

A cumulative series is identified by its resource plus its attributes, and its
start timestamp must stay fixed.

If that identity is not unique per process, a collector receives several
contradictory monotonic series claiming to be one, and resolves it by
resetting, summing, or taking the last write. All three are wrong and none of
them looks wrong on a dashboard. That is why C<service.instance.id> must
differ per worker (see L<Punk::OpenTelemetry::Resource>), and why a meter that
finds itself in a forked child resets every accumulator rather than exporting
its parent's totals.

=head1 TEMPORALITY

C<cumulative> (the default) keeps totals growing and each series keeps its
original start time. C<delta> resets every accumulator at collection and moves
the interval start forward. That is the entire distinction, and it is what a
backend notices when it is wrong.

=head1 VIEWS

A view selects instruments by name - with a C<*> suffix for a family - and
reshapes what they produce.

    $meter->view(match => 'noisy',  aggregation => 'drop');
    $meter->view(match => 'a.b',    name => 'renamed');
    $meter->view(match => 'req',    keys => ['route']);
    $meter->view(match => 'dur',    bounds => [0.1, 0.5, 1]);

C<keys> is the important one: filtering to a bounded set of attribute keys is
the primary defence against cardinality, and it collapses a hundred series
into one without losing a single observation.

=head2 Conflicts

Two streams that end up with the same name but a different unit, kind or
aggregation are a conflict. A backend cannot store both, so it stores
whichever arrived last - silently. They are counted, and L</conflicts>
reports them, because the difference between finding that out at
configuration time and finding it out a quarter later is the whole value.

=head1 EXEMPLARS

An exemplar is a raw measurement stapled to a metric point, carrying the trace
it came from - what turns "the p99 is bad" into "here is a trace of one".

The filter is B<trace_based>: an exemplar is recorded only when there is a
sampled span in context, because one pointing at a trace nobody recorded is a
pointer to nothing. Histograms use an aligned-bucket reservoir, so exemplars
span the range instead of clustering in the busiest bucket; everything else
uses a fixed-size reservoir.

=head1 THE EXPONENTIAL HISTOGRAM

Bucket boundaries are powers of a base derived from a C<scale>, so one
configuration covers nanoseconds and hours at the same relative accuracy -
which is the reason to prefer it over fixed buckets somebody has to guess in
advance.

Two mappings are implemented, and both are needed: at C<scale E<lt>= 0> the
bucket is decided by the IEEE-754 exponent alone, which is fast and free of
rounding; above it, a logarithm is unavoidable.

When the populated range outgrows 160 buckets the scale is reduced and
adjacent buckets merged pairwise. B<That merge must be exact.> A downscale
that loses a count is a silently wrong percentile - the worst thing a
histogram can be, because it still looks like data. The tests assert it as a
property: whatever the scale does, the bucket total equals the count. Merging
two histograms of different scales coarsens both to fit their B<combined>
range first, for the same reason.

NaN and infinity are dropped - they are not measurements. Zero has its own
count, having no logarithm. Negative values go in the negative range.

=head1 METHODS

=head2 new(%opt)

C<resource>, C<scope_name>, C<scope_version>, C<temporality>.

=head2 view(%spec)

C<match>, C<name>, C<aggregation> (C<drop>, C<sum>, C<last_value>,
C<histogram>, C<exponential>), C<keys>, C<bounds>.

=head2 record($name, $kind, $value, \%attributes, $span)

C<$kind>: 1 counter, 2 up-down counter, 3 histogram, 4 gauge. C<$span> is
optional and is what makes an exemplar possible.

=head2 collect

An OTLP metrics payload, or C<undef> when nothing has been recorded.

=head2 conflicts / stats

C<stats> returns C<instruments>, C<series> and C<overflow> - the last being
the number that says a metric stopped being useful, before memory says it more
loudly.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
