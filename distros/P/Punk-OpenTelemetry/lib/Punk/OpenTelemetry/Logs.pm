package Punk::OpenTelemetry::Logs;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.04';

# All of it is C (include/otel_log.h + xs/logger.xs). This file is
# documentation.

1;

__END__

=head1 NAME

Punk::OpenTelemetry::Logs - the logs signal

=head1 SYNOPSIS

    my $logs = Punk::OpenTelemetry::Logs->new(
        resource   => $resource,
        scope_name => 'Punk::OpenTelemetry',
    );

    $logs->emit('error', 'db down', { dsn => $dsn }, $span);

    my $payload = $logs->drain;
    my $bytes   = Punk::OpenTelemetry::Encode::logs_protobuf($payload);

=head1 DESCRIPTION

The cheapest of the three signals, because Punk 0.19 already did the hard
part: a log record is a message plus fields, which is exactly what an OTLP
C<LogRecord> is. What remains is severity, trace correlation, and a queue.

=head1 A TAP, NOT A REPLACEMENT

These records are a B<copy>. The application's logs still go wherever they
were going - stderr, C<psgix.logger>, a C<to> coderef - and the collector gets
a duplicate.

Letting the exporter take over the sink is the obvious implementation and it
is wrong twice over: a telemetry layer would be silently redirecting an
operator's logs, and the failure mode when its collector is unreachable would
be that the logs B<vanish>. Nobody should have to choose between having their
logs and exporting them.

Punk 0.20's C<pk_abi> v3 C<on_log> is the registration point, and it is a tap
for exactly this reason.

=head1 SEVERITY

Punk has five levels; OTLP has a 24-point scale in bands of four.

    trace  1     debug  5     info   9
    warn  13     error 17     fatal 21

The mapping picks the B<first> value of each band rather than its middle. That
is what every other SDK emits, and it is what a backend filter written as
C<< >= 13 >> compares against - a number in the right band is not enough if
the threshold sits at the band start.

An unknown level falls back to C<info>, not to zero: zero is
C<SEVERITY_NUMBER_UNSPECIFIED>, which most backends treat as "unfiltered" and
would make a mis-spelled level louder rather than quieter.

=head1 TRACE CORRELATION

Passing the active span attaches its C<trace_id> and C<span_id> to the record.
This is the highest-value, lowest-cost part of the whole signal: it is what
makes somebody actually click from a log line into a trace.

C<trace_id> and C<span_id> became reserved keys in L<Punk::Logger> for this,
so an application field of the same name cannot forge a correlation and point
a reader at somebody else's trace.

A line emitted outside a span carries B<no> ids rather than empty ones.

=head1 THE QUEUE

Bounded at 4096 records - larger than the span queue, because logs are far
higher volume - dropping the oldest and counting what it dropped. Same
arrangement and the same reasoning as
L<Punk::OpenTelemetry::Tracer/THE QUEUE>, and the queue belongs to the process
that filled it, so a forked child starts empty.

=head1 THE RECURSION TRAP

The exporter sends over HTTP with Fetch, Fetch is instrumented, and the
exporter logs its own failures. Without a guard, the first collector outage
becomes an infinite loop of telemetry about failing to send telemetry.

A record emitted while L<Punk::OpenTelemetry::Instrument/suppress_begin> is in
effect is B<not> queued - so the exporter's own diagnostics reach the
operator's log and go no further.

=head1 METHODS

=head2 new(%opt)

C<resource>, C<scope_name>, C<scope_version>.

=head2 emit($level, $body, \%attributes, $span)

Queue one log record. C<$level> is mapped to an OTLP severity by
L<severity|/"severity($level)">, C<$body> is the message, and
C<\%attributes> is optional structured detail.

C<$span> is optional and is the part worth passing: it is what stamps the
record with the trace and span ids, and so what lets somebody click from a log
line into the trace that produced it. It is the highest-value, lowest-cost
part of this whole signal.

Emitting while the SDK is exporting is ignored rather than queued, or the
exporter's own diagnostics would come back round through here - see
L</THE RECURSION TRAP>.

=head2 drain($max)

An OTLP logs payload ready for
L<Punk::OpenTelemetry::Encode/logs_protobuf>, or C<undef> when there is
nothing to send.

=head2 severity($level)

The OTLP severity number for a Punk level.

=head2 stats

C<emitted>, C<dropped>, C<queued>.

=head1 SEE ALSO

L<Punk::OpenTelemetry::Tracer>, which supplies the ids these records are
correlated by, and L<Punk::Plugin::OpenTelemetry>, which turns the signal on.
L<Punk::OpenTelemetry> is the index.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
