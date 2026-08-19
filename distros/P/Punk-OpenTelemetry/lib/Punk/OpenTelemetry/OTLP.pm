package Punk::OpenTelemetry::OTLP;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::OpenTelemetry::OTLP - the payload the encoders take

=head1 DESCRIPTION

The OTLP encoders take one hashref, shaped like the protobuf schema it
becomes. This page documents that shape. It is written to be readable by a
person and cheap for the trace SDK to fill in, which are usually the same
thing.

The encoders themselves are L<Punk::OpenTelemetry::Encode>.

=head1 THE TRACE PAYLOAD

    {
      resource_spans => [ {
        resource   => { attributes => { 'service.name' => 'maat' } },
        schema_url => 'https://opentelemetry.io/schemas/1.30.0',
        scope_spans => [ {
          scope => { name => 'Punk::OpenTelemetry', version => '0.01' },
          spans => [ {
            trace_id             => '4bf92f3577b34da6a3ce929d0e0e4736',
            span_id              => '00f067aa0ba902b7',
            parent_span_id       => undef,
            name                 => 'GET /users/:id',
            kind                 => 2,            # SERVER
            start_time_unix_nano => 1_700_000_000_000_000_000,
            end_time_unix_nano   => 1_700_000_000_123_000_000,
            attributes => { 'http.route' => '/users/:id' },
            events => [ { name => 'cache miss', time_unix_nano => ... } ],
            links  => [ { trace_id => ..., span_id => ... } ],
            status => { code => 2, message => 'upstream refused' },
          } ],
        } ],
      } ],
    }

=head2 Ids

C<trace_id> is 16 bytes and C<span_id> 8. Both are accepted either as raw
bytes - what the SDK holds - or as lowercase hex, which is what a person
writes. Anything of another length is B<omitted> rather than padded or
truncated: an id of the wrong value looks valid and joins to nothing, which is
strictly worse than an absent one, because an absent one is visible.

=head2 Attributes

A plain hashref. Keys are B<sorted> before encoding, so the same payload
always produces the same bytes - which is what makes a golden vector possible,
a diff meaningful and a cache safe. Perl's hash order is randomised per
process, so this is not optional.

Values map onto OTLP's C<AnyValue> by these rules, in order:

=over 4

=item * C<undef> is a value with nothing set - a null attribute. Not an empty
string.

=item * C<\1> and C<\0> are booleans, the same convention
L<File::Raw::JSON> uses.

=item * A B<blessed> reference uses its stringification. An object is a value,
not a structure; one with an overloaded C<""> is an ordinary thing to attach,
and dumping its guts instead would silently change what an existing call
means. Same rule L<Punk::Logger> applies.

=item * An unblessed arrayref becomes an array, an unblessed hashref a
key/value list, both recursively.

=item * A coderef, glob or regexp uses its stringification. Attaching one is a
mistake, and a mistake in a telemetry attribute must not take the request
down.

=item * An integer that has never been used as a string is an int; a float, a
double.

=item * Everything else is a string - including a scalar that is both a number
and a string. If it has a string form the application has treated it as text,
and guessing C<"3"> into an integer turns an identifier into a number and
breaks every grouping built on it.

=back

=head2 Omitted fields

Protobuf 3 does not write a field at its default value, and this relies on
that. In particular a C<kind> of C<0> (UNSPECIFIED) and a C<status> of C<0>
(UNSET) are B<absent> from the bytes rather than present and zero. That is not
a size optimisation: an instrumentation layer with no opinion about whether an
operation succeeded must not claim one, and UNSET is how OTLP spells "no
opinion".

=head1 SEE ALSO

L<Punk::OpenTelemetry>, L<Punk::OpenTelemetry::Encode>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
