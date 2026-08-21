package Punk::OpenTelemetry::Exporter;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();
use Punk::OpenTelemetry::Encode ();
use Fetch ();          # the default user agent, constructed from C by name

our $VERSION = '0.04';

# All of it is C (include/otel_export.h + xs/exporter.xs). The `use` lines
# above are load-bearing: the XS reaches Fetch and the encoders BY NAME.

1;

__END__


=head1 NAME

Punk::OpenTelemetry::Exporter - OTLP over HTTP

=head1 SYNOPSIS

    my $exp = Punk::OpenTelemetry::Exporter->new(
        endpoint => 'http://localhost:4318',
        protocol => 'http/protobuf',
        headers  => { 'x-api-key' => $key },
    );

    my $bytes = $exp->encode(traces => $payload);

=head1 DESCRIPTION

The OTLP/HTTP transport: endpoint resolution, what a response means, the
partial-success readers, C<Retry-After> and the backoff policy.

The object is a blessed hash and stays one, with the keys C<new> has always
set. C<< $e->{protocol} >> and C<< $e->{stats}{dropped}++ >> are part of the
interface, not an implementation detail that happened to be visible.

=head2 Endpoints

    endpoint  => 'http://collector:4318'         # /v1/traces is APPENDED
    endpoints => { traces => 'https://x/ingest' } # used EXACTLY as given

That asymmetry is in the spec and surprises everybody once. A per-signal
endpoint keeps whatever path it has, because collectors are routinely deployed
behind a path prefix and appending to it would break every one of them.

=head2 What a response means

=over 4

=item * B<2xx> is success - unless the body carries a C<partial_success>
naming rejected spans, which is B<not> a failure and B<not> retryable, but has
to be counted. Data silently disappearing while every dashboard stays green is
the worst failure mode this component has.

=item * B<429, 502, 503, 504> are retryable, honouring C<Retry-After>.

=item * Everything else is permanent. Drop it, count it, and do not spend the
next hour asking a collector that has already said no.

=back

=head2 Backoff

Exponential from one second to a thirty second ceiling, with B<full jitter>.
The jitter is not decoration: a fleet of workers that all failed at the same
moment and all back off by the same amount retries in a thundering herd, which
is how a collector that was briefly slow stays down.
L<backoff|/"backoff($attempt, $retry_after)"> is pure,
so the policy is tested directly rather than inferred from timings.

=head1 METHODS

=head2 new(%opt)

C<endpoint>, C<endpoints>, C<protocol> (C<http/protobuf> or C<http/json>),
C<headers>, C<timeout> (default 10), C<compression> (C<none> or C<gzip>),
C<max_retries> (default 5), C<ua>. An unknown protocol croaks here rather than
at the first export. Without a C<ua> one is built: C<< Fetch->new >> at the
configured timeout.

=head2 encode($signal, $payload)

The payload as bytes for the configured protocol.

=head2 backoff($attempt, $retry_after)

The delay before attempt C<$attempt>. A C<Retry-After> from the server wins
outright.

=head2 stats

A copy of the counters: what was exported, rejected, dropped, retried, and how
many attempts failed. A telemetry layer that cannot report its own losses is
asking to be trusted for no reason.

=head1 SEE ALSO

L<Punk::OpenTelemetry::GRPC>, the same job over gRPC, and
L<Punk::OpenTelemetry::Encode>, which renders what this sends.
L<Punk::Plugin::OpenTelemetry> is what drives it, and
L<Punk::OpenTelemetry::Config> documents the C<OTEL_EXPORTER_OTLP_*>
variables that configure it.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
