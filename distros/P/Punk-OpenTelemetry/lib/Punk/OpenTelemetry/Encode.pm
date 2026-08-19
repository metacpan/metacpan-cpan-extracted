package Punk::OpenTelemetry::Encode;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::OpenTelemetry::Encode - OTLP on the wire

=head1 SYNOPSIS

    use Punk::OpenTelemetry::Encode ();

    my $bytes = Punk::OpenTelemetry::Encode::traces_protobuf($payload);

=head1 DESCRIPTION

The OTLP encoders. The payload shape is L<Punk::OpenTelemetry::OTLP>.

=head2 Why the protobuf writer is hand-rolled

OTLP's schema is small, versioned slowly and entirely known at compile time,
so encoding it needs no descriptors, no reflection and no dependency: varints,
length-delimited fields, and the field numbers. That is the whole of protobuf
OTLP uses. The encoding is also three to five times smaller than the JSON form
on every export, forever, which is why it is the default rather than the
fallback.

=head2 Two passes

Every embedded protobuf message is length-delimited, so a parent cannot be
written until its children's byte count is known. There are two ways out:
build backwards into a buffer, or walk twice - once to measure, once to write.

This walks twice. It costs a second pass over data already in cache, and in
exchange every C<size_> function sits directly beside the C<write_> function
it has to agree with, where a reader can check one against the other. Pointer
arithmetic into a buffer being filled from the end is quicker to run and much
harder to prove, and the failure it produces - a length prefix that lies - is
one a collector rejects with nothing useful to say about why.

The two halves are held together three ways: L</traces_protobuf_size> exposes
the measuring pass so a test can assert the agreement directly; an author
build (C<-DOTEL_PB_ASSERT>) checks every embedded message as it is written;
and the golden vectors in F<t/01-protobuf.t> compare the output against a
reader written from the wire spec alone, which shares no code with the encoder
and so cannot agree with its bugs.

=head1 FUNCTIONS

None are exported; call them fully qualified.

=head2 traces_protobuf($payload)

An C<ExportTraceServiceRequest> as protobuf bytes.

=head2 traces_protobuf_size($payload)

The size the measuring pass computes for the same payload, without writing it.
Exists so a test can assert that the two passes agree exactly, rather than
inferring it from bytes that happen to parse.

=head2 traces_json($payload)

The same request as OTLP/JSON bytes. A supported transport, not a convenience,
so it is B<not> a naive rendering of the protobuf tree. Four differences, each
of which fails silently - the payload parses, is stored, and is empty or wrong:

=over 4

=item * Field names are B<lowerCamelCase>. C<start_time_unix_nano> becomes
C<startTimeUnixNano>; a snake_case payload parses as a message with every
field absent.

=item * C<traceId> and C<spanId> are B<hex>, not the base64 proto3 maps a
C<bytes> field to. OTLP overrides it explicitly, and base64 ids are the single
most common way a hand-written OTLP/JSON payload joins to nothing.

=item * 64-bit integers are B<strings>. A nanosecond timestamp is around
1.7e18 and loses its last two digits as an IEEE double, so this is not a
portability nicety - it is the difference between the right timestamp and the
wrong one.

=item * Enums are B<names>: C<SPAN_KIND_SERVER>, not C<2>.

=back

Object keys are sorted, so the output is reproducible.

=head2 traces_json_tree($payload)

The OTLP/JSON structure as Perl data, before serialisation. The tests assert
the mapping rules against this so a failure names the offending field rather
than diffing two long strings.

=head2 One classifier, two renderings

Both encoders decide what a value B<is> through the same C function. If each
applied the rules itself the two would drift, and the drift would be
invisible: a value arriving at a collector as an int over one transport and a
string over the other is a bug nobody finds until a dashboard filter quietly
stops matching.

=head1 SEE ALSO

L<Punk::OpenTelemetry::OTLP> for the payload shape.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
