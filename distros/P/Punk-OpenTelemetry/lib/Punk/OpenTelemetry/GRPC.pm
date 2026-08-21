package Punk::OpenTelemetry::GRPC;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.04';

# The protocol half is C (include/otel_grpc.h + xs/grpc.xs). This file is
# documentation.

1;

__END__

=head1 NAME

Punk::OpenTelemetry::GRPC - OTLP over gRPC

=head1 DESCRIPTION

gRPC is not a framework here and is not a dependency. OTLP/gRPC is a narrow,
fixed use of HTTP/2:

=over 4

=item * C<POST> over HTTP/2 to one fixed path per signal.

=item * C<content-type: application/grpc+proto> and C<te: trailers>.

=item * The body is B<length-prefixed frames>: one byte compressed flag, four
bytes big-endian length, then the same protobuf message the HTTP transport
sends. gRPC changes the framing and the status channel, not the message.

=item * The response is the same framing, and then the part that catches
people out.

=back

=head1 THE STATUS IS IN THE TRAILERS

A gRPC call returns HTTP B<200 even when it fails>. The real outcome is in the
HTTP/2 trailing headers: C<grpc-status> (a number) and C<grpc-message>.

A transport that reads the HTTP status and stops will report every failure as
a success. That is worse than not implementing gRPC at all, because it looks
like it works: telemetry vanishes and every indicator stays green.

For the same reason, a B<missing> C<grpc-status> is not success. It means the
stream ended without the server saying how it went - a transport failure, and
retryable.
L<verdict|/"verdict($have_status, $code, $has_retry_info)">
treats it that way.

=head2 Retryable codes

C<CANCELLED>, C<DEADLINE_EXCEEDED>, C<ABORTED>, C<OUT_OF_RANGE>,
C<UNAVAILABLE> and C<DATA_LOSS>. Everything else is permanent.

C<RESOURCE_EXHAUSTED> is the exception: retryable B<only> when the server sent
C<RetryInfo> in C<grpc-status-details-bin>. Without it the server is refusing
a quota, and retrying a quota refusal on a timer is how a client turns its own
rate limit into an outage.

=head2 Compression

C<gzip> lives in the B<frame flag> and in C<grpc-encoding> - B<not> in HTTP's
C<content-encoding>. Two mechanisms with similar names, and using the HTTP one
produces a request the collector rejects with a confusing message.

=head2 Ports

C<4317> for gRPC, C<4318> for HTTP. Getting this wrong is the single most
common OTLP misconfiguration, which is why
L<default_port|/"default_port($protocol) / headers($compressed)">
states it rather than leaving it to a default somewhere else.

=head1 WHERE THE STATUS IS FOUND

Two places, and both are normal.

=over 4

=item * The B<trailers>, for an ordinary call: C<HEADERS>, then C<DATA>, then
a second C<HEADERS> carrying C<grpc-status>.

=item * The response B<headers>, for a B<Trailers-Only> response. A server
that fails before producing a body sends one C<HEADERS> frame with
C<:status>, the C<grpc-status> and C<END_STREAM>, and no C<DATA> at all -
nghttp2 reports that first frame as C<HCAT_RESPONSE>, so the status lands in
the ordinary header list. A client that looked only at trailers would find no
status on exactly the responses that failed fastest.

=back

L<classify|/"classify($res)">
looks in the trailers first and then the headers, so a trailer wins over a
stale header of the same name.

=head1 REQUIREMENTS

L<Fetch> B<0.15 or newer>, which captures HTTP/2 trailers. Before it, Fetch's
header callback filtered to C<NGHTTP2_HCAT_RESPONSE> and discarded them, so
there was no C<grpc-status> to read and a client could only ever report
success.

Fetch's HTTP/2 is compiled only when C<libnghttp2> is present; without it
there is no HTTP/2 for gRPC to sit on.

Streaming request bodies are deliberately not needed: OTLP uses unary calls,
so one frame goes out and one comes back, which removes the hardest part of a
general gRPC client.

=head1 FUNCTIONS

None are exported.

=head2 path($signal)

The fixed service path. Part of the protocol, not configuration.

=head2 frame($message, $compressed)

The message with its five-byte prefix. The length is B<big-endian>, unlike
every other length in this distribution.

=head2 unframe($buffer)

C<($body, $compressed, $consumed)>, or an empty list when the buffer does not
hold a whole frame yet - which means "not yet" and is not a failure. A length
that would run past the buffer is refused rather than trusted, because it
arrived over a network.

=head2 retryable($code, $has_retry_info)

Whether a gRPC status code may be retried. C<RESOURCE_EXHAUSTED> is the odd
one and needs the second argument: it is retryable only when the server sent
C<RetryInfo> in the details. Without it the server is refusing a quota, and
retrying a quota refusal on a timer is how a client turns its own rate limit
into an outage.

=head2 verdict($have_status, $code, $has_retry_info)

C<0> ok, C<1> retry, C<2> permanent - the same verdicts the HTTP transport
uses, so a caller branches once.

=head2 retry_after($details)

The delay a server named in C<grpc-status-details-bin>, in seconds, or
C<undef>. When the server names one it wins over any computed backoff: it
knows when it will be ready and the client does not.

=head2 default_port($protocol) / headers($compressed)

C<default_port> is C<4317> for C<grpc> and C<4318> for anything else. Stated
here rather than left implicit because pointing a gRPC exporter at the HTTP
port is the most common OTLP misconfiguration there is.

C<headers> is the header list a gRPC request must carry:
C<content-type: application/grpc+proto> and C<te: trailers>, plus
C<grpc-encoding: gzip> when compressed. C<te: trailers> is not optional - it
is how a client tells the server it will read the trailing metadata, and
L</THE STATUS IS IN THE TRAILERS> is where the status lives.

=head2 classify($res)

C<($verdict, $code, $message, $retry_after)> from a L<Fetch::Response>. See
L</WHERE THE STATUS IS FOUND>.

=head2 send($ua, $endpoint, $signal, $bytes, $timeout)

Frame the payload and POST it to the signal's service path, returning the
agent's future. C<$endpoint> is a scheme, host and port with B<no path> - the
path is protocol, not configuration.

=head1 SEE ALSO

L<Punk::OpenTelemetry::Exporter>, the same job over HTTP, and
L<Punk::OpenTelemetry::Config> for the C<OTEL_EXPORTER_OTLP_PROTOCOL> setting
that chooses between them.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
