package Punk::OpenTelemetry::Instrument;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.04';

# All of it is C (include/otel_semconv.h, otel_instr.h, otel_consume.h +
# xs/instrument.xs). This file is documentation.

1;

__END__

=head1 NAME

Punk::OpenTelemetry::Instrument - where the spans come from

=head1 SYNOPSIS

    my $tracer = Punk::OpenTelemetry::Tracer->new(...);
    Punk::OpenTelemetry::Instrument::install($tracer);

    # later, if the database spans are drowning you
    Punk::OpenTelemetry::Instrument::configure(db => 0);

=head1 DESCRIPTION

Attaches the SDK to the hooks the ecosystem grew for it in phase 1: Punk's
C<pk_abi> request, response and query observers, and Fetch's outbound request
observer.

Both ABIs are B<optional> and resolved lazily. A process with neither loaded
still gets a working tracer - manual spans, encoders, exporter - and simply
has nothing automatic to observe. That is the difference between a telemetry
layer and a dependency: this one attaches to what is there.

=head1 TWO RULES

=head2 The sampling decision comes first

Attributes are built only after a span exists. An unsampled request must not
pay to assemble strings nobody will read, which is why
L<Punk::OpenTelemetry::Tracer/start> returns C<undef> rather than a null
object and why every callback here begins by checking for one.

=head2 http.route is the pattern, or it is absent

Never the path. For a 404, a 405 or a mounted app, C<pk_abi>'s
C<route_pattern_of> returns nothing and the attribute is simply not set.

Falling back to C<url.path> there is the exact substitution that turns a
bounded dimension into an unbounded one - and 404 traffic is precisely where a
scanner will hand you a million distinct values. An API operation has no route
pattern either, and uses its C<operationId>, which is bounded the same way.

=head1 WHAT IS INSTRUMENTED

=over 4

=item * B<Server spans>, from the C<pk_abi> request and response observers.
The request side runs before routing, so the span is named for the method
alone and B<upgraded> to C<"GET /users/:id"> on the response side, once the
pattern exists. Naming it after the path at request time would be the
cardinality mistake, permanently.

=item * B<Client spans>, from Fetch's observer - which also B<injects the
traceparent>. Without that injection the far side starts a new trace and the
two halves of a call are never joined, which is the whole reason Fetch grew
the hook.

=item * B<Database spans>, from C<pk_abi>'s C<on_query> (the shipped
L<Punk::Model::DBI> backend). The statement text is the B<prepared> one; the
phase-1 observers do not pass bind values at all, so the literal data cannot
leak even by accident.

=back

=head1 STATUS DIFFERS BY SPAN KIND

A C<4xx> does B<not> fail a SERVER span: the server worked and said no.
Marking those as errors makes the error rate a measure of how many people
mistyped a URL, which is a graph nobody can act on. Only C<5xx> is an error.

On a CLIENT span the rule inverts, deliberately - a C<4xx> the client received
B<is> a failure of the call this process made.

=head1 THE RECURSION GUARD

The exporter sends spans over HTTP with Fetch. Fetch is instrumented. So an
export would produce a client span, which is queued, and exported, and...

The first collector outage would become an infinite loop of telemetry about
failing to send telemetry. Everything the SDK does on its own behalf runs
inside
L<suppress_begin|/"suppress_begin / suppress_end / suppressed"> /
L<suppress_end|/"suppress_begin / suppress_end / suppressed">,
which nest, and every instrumentation point checks the flag.

=head1 FUNCTIONS

=head2 install($tracer, %opt)

Wire everything up. Returns a hashref saying which points went live -
C<server>, C<client>, C<db_punk> - so a caller can tell the difference between
"instrumented" and "nothing to instrument". Idempotent: the underlying
registrations are process-global and permanent, so this is meant to be called
once, at boot, in the worker that will serve.

C<%opt> takes C<server>, C<client> and C<db>, each true by default.

=head2 configure(%opt)

Turn a point on or off afterwards. The registrations stay; the callbacks
return immediately. An application drowning in database spans can silence
those without losing its server spans. C<enabled> is the master switch.

=head2 config

The current state of all four switches.

=head2 suppress_begin / suppress_end / suppressed

The recursion guard, above.

=head2 method / server_status / client_status / db_operation / schema_url

The semantic conventions, exposed because they are pure functions over strings
and are where the cardinality rules live - so they are asserted directly
rather than inferred from a span that happens to look right.

C<method> bounds an unknown HTTP method to C<_OTHER>; the raw value is kept in
C<http.request.method_original>, where it cannot become a metric dimension.

C<schema_url> is the semantic convention version this distribution emits,
pinned in C as C<OTEL_SCHEMA_URL> so it cannot drift from what the encoder
puts on the wire. It is the single source of that answer: the file
L<Punk::OpenTelemetry::Schema> ships is the one this names, and
C<< Punk::OpenTelemetry::Schema->shipped_version >> is derived from it.

=head1 SEE ALSO

L<Punk::OpenTelemetry::Schema> - what a schema URL means on the far end, and
converting telemetry between two of them.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
