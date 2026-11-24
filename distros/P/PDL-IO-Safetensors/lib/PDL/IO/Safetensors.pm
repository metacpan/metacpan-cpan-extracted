package PDL::IO::Safetensors;

use 5.010;
use strict;
use warnings;
use Carp qw(croak);
use Exporter qw(import);
use JSON::MaybeXS qw(encode_json decode_json);
use PDL::Core ();
use PDL::Lite ();
use PDL::Types ();

our $VERSION   = '0.01';
our @EXPORT_OK = qw(rsafetensors wsafetensors safetensors_header);

my %DTYPE_TO_PDL = (
    F64 => PDL::double(),
    F32 => PDL::float(),
    I64 => PDL::longlong(),
    I32 => PDL::long(),
    I16 => PDL::short(),
    U8  => PDL::byte(),
    I8  => PDL::sbyte(),
);

my %PDL_TO_DTYPE = (
    double   => 'F64',
    float    => 'F32',
    longlong => 'I64',
    long     => 'I32',
    short    => 'I16',
    byte     => 'U8',
    sbyte    => 'I8',
);

sub safetensors_header {
    my ($file) = @_;
    croak 'Filename required' unless defined $file;
    open my $fh, '<:raw', $file or croak "Cannot open '$file': $!";
    my $len_buf;
    my $n = read($fh, $len_buf, 8);
    croak 'Truncated safetensors header length' unless defined $n && $n == 8;
    my $header_len = unpack('Q<', $len_buf);
    my $json_buf;
    $n = read($fh, $json_buf, $header_len);
    croak 'Truncated safetensors JSON header' unless defined $n && $n == $header_len;
    close $fh;
    return decode_json($json_buf);
}

sub rsafetensors {
    my ($file) = @_;
    croak 'Filename required' unless defined $file;
    open my $fh, '<:raw', $file or croak "Cannot open '$file': $!";
    my $len_buf;
    my $n = read($fh, $len_buf, 8);
    croak 'Truncated safetensors header length' unless defined $n && $n == 8;
    my $header_len = unpack('Q<', $len_buf);
    my $json_buf;
    $n = read($fh, $json_buf, $header_len);
    croak 'Truncated safetensors JSON header' unless defined $n && $n == $header_len;
    my $header = decode_json($json_buf);

    my $data_start = 8 + $header_len;
    my %tensors;

    for my $name (sort keys %{$header}) {
        next if $name eq '__metadata__';
        my $info = $header->{$name};
        my $dtype = $info->{dtype} // croak "Missing dtype for '$name'";
        my $pdl_type = $DTYPE_TO_PDL{$dtype}
            // croak "Unsupported safetensors dtype '$dtype' for '$name'";
        my $offsets = $info->{data_offsets} // croak "Missing data_offsets for '$name'";
        my ($start, $end) = @{$offsets};
        my $byte_len = $end - $start;

        seek($fh, $data_start + $start, 0) or croak "seek failed: $!";
        my $raw = '';
        if ($byte_len > 0) {
            my $got = read($fh, $raw, $byte_len);
            croak "Truncated tensor data for '$name'" unless defined $got && $got == $byte_len;
        }

        my @shape = reverse @{ $info->{shape} || [] };
        my $pdl = PDL->zeroes($pdl_type, @shape);
        ${ $pdl->get_dataref } = $raw;
        $pdl->upd_data;
        $tensors{$name} = $pdl;
    }

    close $fh;
    return \%tensors;
}

sub wsafetensors {
    my ($file, $tensors, $metadata) = @_;
    croak 'Filename and tensor hashref required'
        unless defined $file && ref($tensors) eq 'HASH';

    my %header;
    if (ref($metadata) eq 'HASH' && %{$metadata}) {
        $header{'__metadata__'} = $metadata;
    }

    my @chunks;
    my $offset = 0;

    for my $name (sort keys %{$tensors}) {
        my $pdl = $tensors->{$name};
        croak "Value for '$name' is not a PDL ndarray"
            unless ref($pdl) && eval { $pdl->isa('PDL') };

        my $type_name = $pdl->type->ioname;
        my $dtype = $PDL_TO_DTYPE{$type_name}
            // croak "Unsupported PDL type '$type_name' for '$name'";

        my $contig = $pdl->is_inplace ? $pdl : $pdl->make_physical;
        my $raw    = ${ $contig->get_dataref };
        my $len    = length($raw);
        my @shape  = reverse $contig->dims;

        $header{$name} = {
            dtype        => $dtype,
            shape        => \@shape,
            data_offsets => [ $offset, $offset + $len ],
        };
        push @chunks, $raw;
        $offset += $len;
    }

    my $json_bytes = encode_json(\%header);
    open my $fh, '>:raw', $file or croak "Cannot write '$file': $!";
    print {$fh} pack('Q<', length($json_bytes));
    print {$fh} $json_bytes;
    for my $chunk (@chunks) {
        print {$fh} $chunk;
    }
    close $fh or croak "Failed closing '$file': $!";
    return 1;
}

1;

__END__

=head1 NAME

PDL::IO::Safetensors - Read and write HuggingFace Safetensors files as PDL ndarrays

=head1 SYNOPSIS

    use PDL;
    use PDL::IO::Safetensors qw(rsafetensors wsafetensors safetensors_header);

    wsafetensors('weights.safetensors', {
        weight => float([[1, 2, 3], [4, 5, 6]]),
        bias   => float([0.1, 0.2]),
    }, { format => 'pt' });

    my $tensors = rsafetensors('weights.safetensors');
    my $header  = safetensors_header('weights.safetensors');

=head1 DESCRIPTION

C<PDL::IO::Safetensors> provides pure-Perl reading and writing of HuggingFace
C<.safetensors> model weight files directly to and from L<PDL> ndarrays.

=head1 FUNCTIONS

=head2 wsafetensors($file, \%tensors, [\%metadata])

Writes a hashref of named L<PDL> ndarrays to C<$file> in Safetensors format.

=head2 rsafetensors($file)

Reads all tensors from C<$file> and returns a hashref mapping tensor names to
L<PDL> ndarrays.

=head2 safetensors_header($file)

Reads and returns only the decoded JSON header from C<$file>.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Google LLC. Apache License, Version 2.0.

=cut
