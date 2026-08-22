package Punk::Plugin::Metrics;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.28';

1;

__END__

=head1 NAME

Punk::Plugin::Metrics - a Prometheus endpoint whose labels cannot run away

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    plugin 'Metrics';

    get '/users/:id' => sub { $_[0]->text('user') };

    # GET /metrics
    #   http_requests_total{method="GET",route="/users/:id",status="200",worker="4812"} 50
    #   http_request_duration_seconds_bucket{method="GET",route="/users/:id",worker="4812",le="0.0005"} 50
    #   http_requests_in_flight{worker="4812"} 0

=head1 DESCRIPTION

=head2 Why, given L<Punk::OpenTelemetry> exists

They are not substitutes, and the difference is push against pull.
OpenTelemetry pushes OTLP to a collector somebody has to run. Prometheus
scrapes an endpoint, and a scrape needs nothing deployed beside the
application - which for a great many deployments is the difference between
"metrics exist" and "metrics were a project".

They coexist. The same request feeds both, and an application that later
adopts a collector keeps its dashboards.

=head2 Cardinality, which is the thing most exporters get wrong

A counter labelled with the B<request> path is the classic monitoring outage:
C</users/1>, C</users/2> and a million more each become their own time series,
and the scrape target eventually takes the monitoring system down with it.

B<Punk cannot make that mistake, because the compiled route table is the label
set.> Every route pattern is known at C<to_app>, the set is bounded before a
single request arrives, and C</users/:id> is B<one> series however many ids
exist. That is a real dividend of compiling routes at boot rather than
matching them one at a time.

Anything with no route to name is labelled once as C<< <other> >>. A 404 has
no route by definition, and giving it the request path is precisely how the
bounded dimension becomes unbounded again. An C<api> mount is labelled with
its OpenAPI C<operationId>, which is bounded the same way.

=head2 A scrape hits one worker

This is the trap specific to a prefork server, and it has to be said out loud
rather than discovered from a graph.

Whichever worker the listener hands the scrape connection to answers with
B<that worker's> counters. A naive exporter therefore reports one Nth of the
traffic, and a different Nth every scrape - every graph wrong in a way that
looks like noise.

There are two ways out. Aggregate through the shared memory arena, which is
correct and costs an atomic per request on a contended cacheline - against a
request path of about 4.4 microseconds, that is a cost to measure before
committing to. Or export B<per-worker series> and let Prometheus add them up.

B<This does the second.> Every series carries a C<worker> label holding the
pid, and the query side pays for it:

    sum by (route, status) (rate(http_requests_total[5m]))

The cost is series count multiplied by worker count. The benefit is no shared
state, no contention on the request path, and numbers that are true.

=head2 The buckets

    0.0005 0.001 0.0025 0.005 0.01 0.025 0.05 0.1 0.25 0.5 1 2.5 5 10

Chosen once and documented, because changing them later invalidates every
histogram already recorded.

They are not Prometheus's defaults, which start at 5ms. Punk dispatches a
request in microseconds, so a first bucket of 5ms would hold essentially every
request and the histogram would answer no question anyone asks. These start at
half a millisecond and keep the familiar tail.

C<< Punk::Plugin::Metrics->buckets >> returns them.

=head2 The scrape does not count itself

A C</metrics> series whose only traffic is Prometheus asking about it is noise
in every panel, so the scrape's own request is excluded - from the counters
B<and> from C<http_requests_in_flight>.

The in-flight half matters more than it looks: a scrape is itself in flight
while it renders, so counting it would give an idle server a permanent floor
of one, on every dashboard, for ever.

=head1 WHAT IT EXPORTS

    http_requests_total{method,route,status,worker}          counter
    http_request_duration_seconds{method,route,worker}       histogram
    http_requests_in_flight{worker}                          gauge
    punk_cache_*{cache,worker}                               gauge

The cache gauges are whatever L<Punk::Cache> reports from C<stats> - hits,
misses, evictions, entries, bytes, and C<pool>, which says whether a shared
invalidation bus exists at all. They appear only when a cache is configured,
and B<every> configured cache is reported, labelled with its name - the label
set is bounded by the configuration, which is the rule the C<route> label
follows too.

C<status> is C<-> for a streaming or detached response, which has no status to
read. A guess would put a 200 on a graph that never happened.

=head2 Everything else goes through C<collect>

    plugin 'Metrics' => {
        collect => sub {
            return {
                queue_depth   => MyApp->queue->depth,
                queue_workers => MyApp->queue->workers,
            };
        },
    };

Values become gauges, labelled with the C<worker> pid.

A server's own counters and a queue's depth are deliberately B<not> read from
here. Reaching into another distribution would couple this plugin to versions
of things it cannot test against, and the application already has both in
scope. C<collect> is the seam.

Two guards on it, both because a scrape is all-or-nothing:

=over 4

=item * A name Prometheus will not accept is B<dropped>. One invalid name does
not break one series - it makes the whole document unparseable, and every
metric the application has vanishes at once.

=item * A callback that B<dies> is skipped and the scrape continues. Losing an
optional gauge must not lose the core metrics with it.

=back

=head1 OPTIONS

=head2 path

Where to serve, defaulting to C</metrics>. The route is excluded from
L<Punk::Plugin::Sitemap>: a scrape target is not a page.

=head2 collect

A coderef returning a hashref of C<< name => number >>. See above.

=head1 METHODS

=head2 Punk::Plugin::Metrics->buckets

The histogram bucket boundaries, in seconds.

=head1 CAVEATS

B<The counters are per process, not per application.> Two Punk applications in
one process share them, and the C<worker> label is the pid, so what a scrape
describes is the worker rather than the application. That is what a per-worker
exporter means, and it is the same thing the C<worker> label is telling you.

B<They are not persistent.> A restarted worker starts from zero. Prometheus
handles counter resets; this is only worth knowing when reading a raw scrape.

=head1 SEE ALSO

L<Punk>, L<Punk::Plugin::Health>, L<Punk::OpenTelemetry>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
