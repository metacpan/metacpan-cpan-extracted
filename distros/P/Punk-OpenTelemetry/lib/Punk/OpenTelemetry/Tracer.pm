package Punk::OpenTelemetry::Tracer;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.04';

1;

__END__

=head1 NAME

Punk::OpenTelemetry::Tracer - the trace SDK

=head1 SYNOPSIS

    my $tracer = Punk::OpenTelemetry::Tracer->new(
        resource      => { 'service.name' => 'maat' },
        scope_name    => 'Punk::OpenTelemetry',
        scope_version => '0.02',
        ratio         => 0.1,
    );

    my $span = $tracer->start('GET /users/:id', kind => 2);
    if ($span) {                       # undef when the trace is not sampled
        $span->attr('http.route' => '/users/:id');
        $span->event('cache miss');
        $span->status(2, 'upstream refused');
        $tracer->enqueue($span);
    }

    if (my $payload = $tracer->drain) {
        my $bytes = Punk::OpenTelemetry::Encode::traces_protobuf($payload);
    }

=head1 DESCRIPTION

The tracer and its spans. A span is a struct, not a blessed hash, and an
unsampled span is never built at all.

=head1 SAMPLING

The ratio decision is derived from the B<trace id>, not from a random draw per
service. That is the single most important property here.

With a coin flip per service, a request crossing three services that all
sample at 10% keeps the whole trace one time in a thousand. What a backend
receives is a stream of one-span fragments with dangling parents, while the
dashboard reports 10% sampling. Every service having flipped a fair coin is no
comfort at all.

Deriving the decision from the trace id makes it the B<same> decision
everywhere the trace goes, with no coordination: the id is already propagated,
and every service computes the same answer from it. 10% sampling then means
10% of traces, complete.

C<ParentBased> wraps it: a trace that already carries a decision inherits it,
including a decision B<not> to sample, because a service that re-decides
mid-trace produces a trace with holes in the middle. Only a root span consults
the ratio. C<always_on> and C<always_off> override outright.

=head2 An unsampled span returns undef

That is the success path, not an error. At a 1% ratio the other 99% of
requests must allocate nothing at all - no struct, no hash, no id, no
timestamp - which is the entire reason sampling is worth having. Callers cope
with C<undef>.

=head1 IDS AND CLOCKS

Ids come from C<getentropy(2)> where it exists and a cached C</dev/urandom>
descriptor where it does not, reopened after a fork. An B<all-zero id is never
generated and never accepted>: one arriving in a header is treated as absent,
because a span claiming a parent that cannot exist is worse than a root span.

The wall clock is read B<once>, at start, to place the span in time. The
B<duration> is measured on a monotonic clock and the end derived from it. Two
wall-clock reads can straddle an NTP step, a manual clock set or a VM resume,
and a span that ends before it began is one collectors variously drop, clamp,
or draw with a negative length - all of which happen to the trace that was
interesting enough to look at.

=head1 LIMITS

128 attributes, 128 events and 128 links, each with a B<dropped count> that
reaches the payload. Both halves matter, and the second more: a span that
quietly loses its 129th attribute looks complete, and somebody spends an
afternoon working out why the attribute they added is missing. A span that
says "1 dropped" answers before the question is asked.

Overwriting an existing attribute is not adding one: it neither counts against
the limit nor increments the dropped count, so a loop that updates one
attribute does not look like a span shedding hundreds.

=head1 THE QUEUE

Bounded at 2048 ended spans, dropping the B<oldest> when full, counting what
it dropped. Every part of that is deliberate:

=over 4

=item * B<Bounded>, because an unbounded queue in front of an unreachable
collector is not a queue, it is a memory leak with a schedule. The failure it
produces is a web server dying of memory exhaustion some hours after a
collector went down, which is a far worse outage than the missing telemetry.

=item * B<Drop-oldest>, because when a system is in trouble the interesting
spans are the recent ones.

=item * B<Counted>, because a telemetry layer that cannot report its own
losses is asking to be trusted for no reason. A gap with a number beside it is
a diagnosis; a gap without one is a mystery.

=back

The queue belongs to the process that filled it: a child that inherited one
starts empty, or every worker would export the parent's spans as its own, once
per worker.

=head1 METHODS

=head2 new(%opt)

C<resource> (a hashref of attributes), C<scope_name>, C<scope_version>,
C<schema_url>, C<sampler> (C<parent_ratio>, C<always_on>, C<always_off>),
C<ratio>.

=head2 start($name, %opt)

A span, or C<undef> when the trace is not sampled. C<kind> is the numeric
SpanKind; C<parent> is a C<< { trace_id, span_id, sampled } >> hashref from an
extracted inbound context.

=head2 enqueue($span)

End the span and put it on the export queue. The queue takes ownership.

=head2 drain($max)

Up to C<$max> queued spans as an OTLP payload ready for
L<Punk::OpenTelemetry::Encode>, or C<undef> when there is nothing to send.

=head2 queued / stats

C<queued> is the queue depth. C<stats> returns C<started>, C<ended>,
C<dropped>, C<sampled_out> and C<queued>.

=head1 SPAN METHODS

C<attr>, C<event>, C<link>, C<status> (all chainable), C<end>, C<trace_id>,
C<span_id>, C<to_hash>, C<counts>.

Only the application should set an C<OK> status. Instrumentation sets C<ERROR>
or leaves the status B<unset>, because a layer with no opinion about whether an
operation succeeded must not claim one.

=head1 SEE ALSO

L<Punk::OpenTelemetry::Instrument>, which is what starts most of these spans,
L<Punk::OpenTelemetry::Propagate> for the ids that arrive from another
service, and L<Punk::OpenTelemetry::Exporter> for where the drained batches
go. L<Punk::OpenTelemetry> is the index.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
