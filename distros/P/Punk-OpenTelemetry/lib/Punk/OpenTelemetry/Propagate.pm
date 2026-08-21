package Punk::OpenTelemetry::Propagate;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.04';

# All of it is C (include/otel_ctx.h, otel_w3c.h, otel_b3.h, otel_jaeger.h,
# otel_baggage.h + xs/propagate.xs). This file is documentation.

1;

__END__

=head1 NAME

Punk::OpenTelemetry::Propagate - trace context across a process boundary

=head1 SYNOPSIS

    my $ctx = Punk::OpenTelemetry::Propagate::extract(\%headers, $order);
    my $span = $tracer->start('GET /x', kind => 2, parent => $ctx);

    my $out = Punk::OpenTelemetry::Propagate::inject(
        $span->trace_id, $span->span_id, 1, $order);
    # { traceparent => '00-...-...-01', b3 => '...' }

=head1 DESCRIPTION

Four propagators and a composite.

=head1 EVERY BYTE HERE CAME FROM THE CLIENT

A C<traceparent> is a request header: attacker-controlled input, arriving on
the hot path of every request. Three rules follow, and they are the reason
this is written the way it is.

=over 4

=item * Nothing allocates on a length the client supplied. Every parse is
fixed-width or bounded by a constant.

=item * Nothing croaks. A malformed header yields B<no context> rather than an
error - a 500 because somebody sent a bad trace header would be a denial of
service with extra steps.

=item * Anything reflected back out is validated on the way B<out> as well as
in. Bytes do not become safe by having been seen once already; that is the
lesson of CVE-2026-75628 and the Punk markdown 301, both in this ecosystem.

=back

B<Invalid is absent.> An unparseable, wrong-length or all-zero id yields no
context at all rather than a partial one, because a span claiming a parent
that cannot exist hangs off nothing for ever in every UI, while a root span is
correct and legible.

=head1 W3C TRACE CONTEXT

C<traceparent> is fixed-shape and 55 bytes at version C<00>.

A version B<above> C<00> is parsed leniently - take the first 55 bytes, ignore
a trailing C<-suffix> - rather than rejected. Rejecting an unknown version is
how a service becomes the one that breaks every trace the day the ecosystem
moves to C<01>: it would be the only participant dropping context, and the
traces would be broken in a way that points at everyone except the offender.
Version C<ff> is the one explicit invalid.

Every flag bit is preserved, not only the sampled bit. A bit whose meaning we
do not know today is still somebody's information.

=head2 tracestate

The member you changed moves to the B<front>; everyone else keeps their
relative order. That ordering is how a downstream vendor knows which system
touched the trace most recently, and it is the rule implementations get wrong.

A malformed member invalidates B<that member>, not the header: dropping
everyone else's state because one vendor emitted something odd is both rude
and lossy. Capped at 32 members, dropped from the right - the oldest state.

=head1 B3

Both spellings: the single C<b3> header and the C<X-B3-*> family. The single
header wins when both are present.

A B3 trace id may be 64-bit as well as 128-bit, and a short one is
B<left-padded>. Get the side wrong and you produce a well-formed id of an
entirely different value - worse than a rejection, because it looks correct
and joins to nothing.

C<sampled> has five spellings in the wild - C<1>, C<0>, C<true>, C<false> and
C<d> - and C<d> is B<debug>, a distinct state that B<implies> sampled rather
than being a synonym for it. C<X-B3-Flags: 1> is the multi-header spelling,
and it overrides an C<X-B3-Sampled> of C<0>.

=head1 JAEGER

C<uber-trace-id: {trace}:{span}:{parent}:{flags}>.

The trace id is frequently written short, with leading zeroes trimmed, and is
left-padded - the same trap as B3. The parent field is deprecated and
discarded. Flags is a bitfield: C<1> sampled, C<2> debug.

The whole value is often B<percent-encoded>, because proxies and client
libraries treat it as a URL component and escape the colons. A parser that
only accepts the raw form silently drops context from every request that
passed through one of those, which presents as an intermittent tracing bug and
is really a decoding one. Decoding is unconditional; a value with no escapes
comes back unchanged.

=head1 BAGGAGE

C<key=value;prop,key2=value2>, percent-encoded, capped at 180 entries, 4096
bytes an entry and 8192 bytes total. Over-limit entries are B<dropped, not
truncated>: a truncated value is a different value, and silently changing an
application's data is worse than not carrying it.

=head2 Baggage is not attached to spans

That is a security decision, not an omission.

Baggage arrives in a request header, so on any public endpoint an attacker
chooses its contents. Copying it into every span's attributes - the obvious
convenience, and a default in some SDKs - hands that attacker two things at
once: a cardinality bomb, because they pick both the key names and the values,
and a data-leak path, because whatever they put there lands in a telemetry
backend that is usually less guarded than the application and often a third
party.

An application that wants baggage on its spans asks for it, by name, for the
keys it expects.

=head1 THE COMPOSITE

C<$order> is a comma-separated list, default C<tracecontext,baggage>.

B<Inject> emits every configured format, so one request can carry
C<traceparent> and C<b3> together - which is what makes a mixed-fleet
migration possible without a flag day.

B<Extract> runs them in order, and a later one that finds a valid context
overrides an earlier one. So C<b3,tracecontext> and C<tracecontext,b3> behave
differently, and both are reasonable things to configure.

=head1 FUNCTIONS

=head2 extract(\%headers, $order)

The context as C<< { trace_id, span_id, sampled, flags, debug, format } >>, or
C<undef>. C<%headers> is keyed by lowercased header name. The result is
exactly what L<Punk::OpenTelemetry::Tracer/start>'s C<parent> option takes.

=head2 inject($trace_id, $span_id, $sampled, $order)

A hashref of headers to add to an outbound request.

=head2 tracestate($existing, $key, $value)

The mutated C<tracestate> value.

=head2 baggage_extract($header) / baggage_inject(\%baggage)

C<baggage_extract> parses a C<baggage> header value into a hashref;
C<baggage_inject> renders one back. Both are the W3C encoding, so a value
carrying a comma or an equals sign survives the round trip.

Baggage is B<not> attached to spans - see L</Baggage is not attached to spans>
for why that is a deliberate refusal rather than an omission.

=head1 SEE ALSO

L<Punk::OpenTelemetry::Tracer>, which starts the spans this joins up, and
L<Punk::OpenTelemetry::Config> for C<OTEL_PROPAGATORS>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
