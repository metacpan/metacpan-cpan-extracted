package PDL::IO::Protobuf;

use 5.010;
use strict;
use warnings;
use Carp qw(croak);
use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT = qw(
    rprotobuf
    wprotobuf
);

our @EXPORT_OK = qw(
    rprotobuf
    wprotobuf
    from_protobuf
    to_protobuf
    pdl_type_for_proto_type
);

my %PROTO_TO_PDL_TYPE = (
    double   => 'double',
    float    => 'float',
    int32    => 'long',
    sint32   => 'long',
    sfixed32 => 'long',
    uint32   => 'ulong',
    fixed32  => 'ulong',
    int64    => 'longlong',
    sint64   => 'longlong',
    sfixed64 => 'longlong',
    uint64   => 'ulonglong',
    fixed64  => 'ulonglong',
    bool     => 'byte',
);

sub pdl_type_for_proto_type {
    my ($proto_type) = @_;
    return unless defined $proto_type;
    return $PROTO_TO_PDL_TYPE{ lc($proto_type) };
}

sub _require_pdl {
    require PDL::Core;
    require PDL::Types;
    require PDL::Slices;
    return;
}

sub _pdl_type_obj {
    my ($type_name) = @_;
    _require_pdl();
    my $type = eval { PDL::Type->new($type_name) };
    croak 'Unsupported PDL type: ' . $type_name unless $type;
    return $type;
}

sub from_protobuf {
    my ($msg, $field, %opts) = @_;
    croak 'Protobuf message object is required' unless defined $msg;
    croak 'Field name is required' unless defined $field && length $field;

    _require_pdl();

    my $values;
    if (ref($msg) && $msg->can($field)) {
        $values = $msg->$field();
    } elsif (ref($msg) eq 'HASH' && exists $msg->{$field}) {
        $values = $msg->{$field};
    } else {
        croak 'Field "' . $field . '" not found on message';
    }

    my @arr = ref($values) eq 'ARRAY' ? @$values : ($values);

    my $pdl_type_name = $opts{type};
    if (!$pdl_type_name && $opts{proto_type}) {
        $pdl_type_name = pdl_type_for_proto_type($opts{proto_type})
            or croak 'Unsupported proto_type: ' . $opts{proto_type};
    }
    $pdl_type_name ||= 'double';

    my $pdl = PDL::Core::pdl(_pdl_type_obj($pdl_type_name), \@arr);

    if (my $dims = $opts{dims}) {
        croak 'dims must be an arrayref' unless ref($dims) eq 'ARRAY';
        $pdl = $pdl->reshape(@$dims);
    }

    return $pdl;
}

sub to_protobuf {
    my ($pdl, $class_or_msg, $field, %opts) = @_;
    croak 'PDL ndarray is required' unless defined $pdl;
    croak 'Target Protobuf class or message is required' unless defined $class_or_msg;
    croak 'Field name is required' unless defined $field && length $field;

    my @flat = $pdl->flat->list;

    my $msg;
    if (ref($class_or_msg)) {
        $msg = $class_or_msg;
        if ($msg->can($field)) {
            $msg->$field(\@flat);
        } elsif (ref($msg) eq 'HASH') {
            $msg->{$field} = \@flat;
        } else {
            croak 'Cannot set field "' . $field . '" on message';
        }
    } else {
        $msg = $class_or_msg->new($field => \@flat, %{ $opts{extra_fields} || {} });
    }

    return $msg;
}

sub rprotobuf {
    my ($source, $class, $field, %opts) = @_;
    croak 'Source file path or filehandle is required' unless defined $source;
    croak 'Protobuf message class is required' unless defined $class && length $class;
    croak 'Field name is required' unless defined $field && length $field;

    my $bytes;
    if (ref($source)) {
        local $/;
        $bytes = <$source>;
    } else {
        open my $fh, '<:raw', $source or croak 'Cannot open ' . $source . ': ' . $!;
        local $/;
        $bytes = <$fh>;
        close $fh;
    }

    my $msg = $class->parse($bytes);
    return from_protobuf($msg, $field, %opts);
}

sub wprotobuf {
    my ($pdl, $dest, $class_or_msg, $field, %opts) = @_;
    croak 'PDL ndarray is required' unless defined $pdl;
    croak 'Destination file path or filehandle is required' unless defined $dest;

    my $msg   = to_protobuf($pdl, $class_or_msg, $field, %opts);
    my $bytes = $msg->serialize();

    if (ref($dest)) {
        print {$dest} $bytes or croak 'Cannot write to filehandle: ' . $!;
    } else {
        open my $fh, '>:raw', $dest or croak 'Cannot open ' . $dest . ' for writing: ' . $!;
        print {$fh} $bytes or croak 'Cannot write ' . $dest . ': ' . $!;
        close $fh or croak 'Cannot close ' . $dest . ': ' . $!;
    }

    return $msg;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDL::IO::Protobuf - Read and write PDL ndarrays from Protocol Buffers

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use PDL;
    use PDL::IO::Protobuf qw(rprotobuf wprotobuf from_protobuf to_protobuf);
    use My::Embedding::Vector;

    # Convert a PDL ndarray to a Protobuf message and write to disk
    my $vec = float([0.12, -0.45, 0.88, 0.31]);
    wprotobuf($vec, 'embedding.pb', 'My::Embedding::Vector', 'values');

    # Read a binary .pb file directly into a PDL ndarray
    my $loaded = rprotobuf('embedding.pb', 'My::Embedding::Vector', 'values',
        proto_type => 'float',
    );

    # Convert in-memory Protobuf messages (e.g. from Google::gRPC / Vertex AI)
    my $matrix = from_protobuf($msg, 'values',
        proto_type => 'float',
        dims       => [2, 2],
    );
    my $out_msg = to_protobuf($matrix, 'My::Embedding::Vector', 'values');

=head1 DESCRIPTION

C<PDL::IO::Protobuf> bridges L<PDL> (Perl Data Language) ndarrays and
L<Protobuf> messages backed by Google's C<upb> C/XS engine (or pure-Perl
fallback). It provides idiomatic L<PDL::IO>-style functions (L</rprotobuf>,
L</wprotobuf>) as well as in-memory converters (L</from_protobuf>,
L</to_protobuf>) for working with repeated numeric fields such as ML
embeddings, sensor time series, and scientific tensors.

=head1 FUNCTIONS

=head2 rprotobuf($source, $class, $field, %opts)

    my $pdl = rprotobuf('data.pb', 'My::Message', 'values', proto_type => 'float');

Reads binary Protocol Buffers wire bytes from a file path or open filehandle
C<$source>, parses them with C<< $class->parse($bytes) >>, and converts
C<$field> into a L<PDL> ndarray via L</from_protobuf>.

=head2 wprotobuf($pdl, $dest, $class_or_msg, $field, %opts)

    wprotobuf($pdl, 'data.pb', 'My::Message', 'values');

Converts C<$pdl> into a L<Protobuf::Message> via L</to_protobuf>, serializes
it with C<< $msg->serialize() >>, and writes the binary wire bytes to file
path or filehandle C<$dest>. Returns the constructed message.

=head2 from_protobuf($msg, $field, %opts)

    my $pdl = from_protobuf($msg, 'values',
        proto_type => 'float',   # or type => 'float'
        dims       => [128, 64], # optional reshape dimensions
    );

Extracts repeated numeric field C<$field> from C<$msg> and returns a L<PDL>
ndarray. Supports C<proto_type> (Protobuf scalar type name), C<type> (explicit
PDL type name, default C<'double'>), and optional C<dims> arrayref to reshape
the resulting ndarray.

=head2 to_protobuf($pdl, $class_or_msg, $field, %opts)

    my $msg = to_protobuf($pdl, 'My::Message', 'values',
        extra_fields => { id => 'vec-1' },
    );

Flattens C<$pdl> and populates C<$field> on an existing message object or a
newly constructed instance of C<$class_or_msg>.

=head2 pdl_type_for_proto_type($proto_type)

Returns the corresponding PDL type name for a Protocol Buffers scalar type
(e.g. C<float> =E<gt> C<float>, C<int32> =E<gt> C<long>,
C<int64> =E<gt> C<longlong>, C<bool> =E<gt> C<byte>).

=head1 TYPE MAPPING

=over 4

=item * C<double> =E<gt> C<double>

=item * C<float> =E<gt> C<float>

=item * C<int32>, C<sint32>, C<sfixed32> =E<gt> C<long>

=item * C<uint32>, C<fixed32> =E<gt> C<ulong>

=item * C<int64>, C<sint64>, C<sfixed64> =E<gt> C<longlong>

=item * C<uint64>, C<fixed64> =E<gt> C<ulonglong>

=item * C<bool> =E<gt> C<byte>

=back

=head1 SEE ALSO

L<PDL>, L<Protobuf>, L<Protobuf::Message>, L<Protobuf::Arena>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2026 Google LLC and contributors.

This program is released under the Apache License, Version 2.0.

=cut
