package Punk::OpenTelemetry;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Punk::OpenTelemetry', $VERSION);

1;

__END__

=head1 NAME

Punk::OpenTelemetry - OpenTelemetry for Punk: traces, metrics and logs over OTLP

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    package MyApp;
    use Punk;
    use Punk::Plugin::OpenTelemetry;

    otel service_name => 'checkout';
    plugin 'OpenTelemetry';

    get '/orders/:id' => sub {
        my ($c) = @_;
        $c->json({ id => $c->param('id') });
    };

That is the whole of it. Every request is now a span named for its route
pattern, every outbound call a child span with the C<traceparent> on the wire,
every query a span carrying the prepared statement, and batches leave for the
collector on a timer.

Or with no code at all, which is how a deployment usually wants it:

    OTEL_SERVICE_NAME=checkout \
    OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318 \
      plackup -s Hyperman app.psgi

=head1 DESCRIPTION

An OpenTelemetry SDK for L<Punk>: the tracer and its spans, the OTLP encoders
and transports, context propagation, resource detection, metrics, log records,
and the plugin that wires all of it into an application.

There is a working demonstration in F<example/> - an instrumented application
and a collector that prints what it receives to STDERR, so the whole path is
visible without a vendor account.

=head2 What you get by registering the plugin

=over 4

=item * B<Server spans> named for the route B<pattern>, C<"GET /users/:id">
and never C<"GET /users/7">. The span opens before routing, when only the
method is known, and is renamed once the pattern exists. Naming it after the
path would be a cardinality mistake that no dashboard recovers from.

=item * B<Client spans> for outbound HTTP, with the C<traceparent> injected on
the way out. Without that injection the far side starts a new trace and the
two halves of a call are never joined.

=item * B<Database spans> carrying the B<prepared> statement. Bind values are
not passed to an observer at all, so the literal data cannot leak by accident.

=item * B<Metrics> and B<log records> when they are asked for, the logs
correlated to the trace that produced them.

=item * B<Batching>, on the worker's own event loop. Nothing is sent from the
request path and nothing is waited on, so a collector that is down costs the
application nothing.

=back

=head2 Both OTLP transports, and gRPC

Protobuf over HTTP is the default, because it is three to five times smaller
on the wire than the JSON form. JSON is supported for the times when being
able to read a payload matters more than its size, which is most of them when
something has gone wrong. OTLP/gRPC is there too, as the narrow fixed use of
HTTP/2 that it is rather than as a framework dependency.

=head1 THE MODULES

Start with the plugin. The rest is what it is made of, and is documented
because a telemetry layer nobody can read is a telemetry layer nobody can
trust.

=over 4

=item * L<Punk::Plugin::OpenTelemetry> - the plugin, the C<otel> keyword, the
F<punk.yml> block, and the roughly thirty C<OTEL_*> environment variables.
B<Read this one.>

=item * L<Punk::OpenTelemetry::Tracer> - spans, sampling and the batch queue.

=item * L<Punk::OpenTelemetry::Instrument> - what is instrumented, and the two
rules it follows.

=item * L<Punk::OpenTelemetry::Exporter> - OTLP over HTTP: endpoints, what a
response means, retries and backoff.

=item * L<Punk::OpenTelemetry::GRPC> - the same, over gRPC.

=item * L<Punk::OpenTelemetry::Encode> and L<Punk::OpenTelemetry::OTLP> - the
payload shape and the two encoders that render it.

=item * L<Punk::OpenTelemetry::Propagate> - W3C Trace Context and Baggage, B3
and Jaeger, behind one composite propagator.

=item * L<Punk::OpenTelemetry::Resource> - what produced this telemetry, and
why C<service.instance.id> has to be taken after a fork.

=item * L<Punk::OpenTelemetry::Meter> and L<Punk::OpenTelemetry::Logs> - the
other two signals.

=item * L<Punk::OpenTelemetry::Schema> - converting a payload between
semantic convention versions.

=item * L<Punk::OpenTelemetry::Config> - the configuration surface, and the
precedence between its layers.

=back

=head1 TURNING IT OFF

    OTEL_SDK_DISABLED=true

Answered before anything is built and before a single hook is registered: no
tracer, no exporter, nothing in the request path. An SDK that still builds a
tracer and throws the spans away has not been disabled, it has been made
pointless.

The value is the specification's boolean and not Perl's truth: only the string
C<true>, case-insensitively. Under any looser rule C<OTEL_SDK_DISABLED=false>
would switch telemetry off, using the word an operator reaches for to switch
it on.

=head1 SEE ALSO

L<Punk>, L<Hyperman>, L<Fetch>.

The OpenTelemetry specification: L<https://opentelemetry.io/docs/specs/otel/>,
and the OTLP protocol: L<https://opentelemetry.io/docs/specs/otlp/>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-punk-opentelemetry at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Punk-OpenTelemetry>. I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Punk::OpenTelemetry

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Punk-OpenTelemetry>

=item * Search CPAN

L<https://metacpan.org/release/Punk-OpenTelemetry>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
