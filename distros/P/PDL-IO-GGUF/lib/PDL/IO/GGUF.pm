package PDL::IO::GGUF;

use 5.010;
use strict;
use warnings;
use Carp qw(croak);
use Exporter qw(import);
use PDL::Core ();
use PDL::Lite ();
use PDL::Types ();

our $VERSION   = '0.01';
our @EXPORT_OK = qw(rgguf wgguf gguf_header);

# GGUF v3 constants
use constant {
    GGUF_MAGIC         => 'GGUF',
    GGUF_VERSION       => 3,
    GGUF_DEFAULT_ALIGN => 32,
    GGUF_TYPE_UINT32   => 4,
    GGUF_TYPE_FLOAT32  => 6,
    GGUF_TYPE_STRING   => 8,
    GGML_TYPE_F32      => 0,
    GGML_TYPE_I8       => 24,
    GGML_TYPE_I16      => 25,
    GGML_TYPE_I32      => 26,
    GGML_TYPE_I64      => 27,
    GGML_TYPE_F64      => 28,
};

my %GGML_TO_PDL = (
    GGML_TYPE_F32() => [ PDL::float(),    4 ],
    GGML_TYPE_I8()  => [ PDL::sbyte(),    1 ],
    GGML_TYPE_I16() => [ PDL::short(),    2 ],
    GGML_TYPE_I32() => [ PDL::long(),     4 ],
    GGML_TYPE_I64() => [ PDL::longlong(), 8 ],
    GGML_TYPE_F64() => [ PDL::double(),   8 ],
);

my %PDL_TO_GGML = (
    float    => GGML_TYPE_F32(),
    sbyte    => GGML_TYPE_I8(),
    short    => GGML_TYPE_I16(),
    long     => GGML_TYPE_I32(),
    longlong => GGML_TYPE_I64(),
    double   => GGML_TYPE_F64(),
);

sub _read_exact {
    my ($fh, $len) = @_;
    return '' if $len == 0;
    my $buf = '';
    my $n   = read($fh, $buf, $len);
    croak "Unexpected EOF reading GGUF ($len bytes)" unless defined $n && $n == $len;
    return $buf;
}

sub _read_str {
    my ($fh) = @_;
    my $len = unpack('Q<', _read_exact($fh, 8));
    return _read_exact($fh, $len);
}

sub _read_kv_val {
    my ($fh, $vtype) = @_;
    return unpack('C',  _read_exact($fh, 1)) if $vtype == 0;
    return unpack('c',  _read_exact($fh, 1)) if $vtype == 1;
    return unpack('S<', _read_exact($fh, 2)) if $vtype == 2;
    return unpack('s<', _read_exact($fh, 2)) if $vtype == 3;
    return unpack('L<', _read_exact($fh, 4)) if $vtype == 4;
    return unpack('l<', _read_exact($fh, 4)) if $vtype == 5;
    return unpack('f<', _read_exact($fh, 4)) if $vtype == 6;
    return unpack('C',  _read_exact($fh, 1)) ? 1 : 0 if $vtype == 7;
    return _read_str($fh) if $vtype == 8;
    if ($vtype == 9) {
        my $elem_type = unpack('L<', _read_exact($fh, 4));
        my $count     = unpack('Q<', _read_exact($fh, 8));
        my @arr;
        for (1 .. $count) {
            push @arr, _read_kv_val($fh, $elem_type);
        }
        return \@arr;
    }
    return unpack('Q<', _read_exact($fh, 8)) if $vtype == 10;
    return unpack('q<', _read_exact($fh, 8)) if $vtype == 11;
    return unpack('d<', _read_exact($fh, 8)) if $vtype == 12;
    croak "Unsupported GGUF metadata value type: $vtype";
}

sub _parse_header_fh {
    my ($fh) = @_;
    my $magic = _read_exact($fh, 4);
    croak "Invalid GGUF magic: '$magic'" unless $magic eq GGUF_MAGIC;
    my $version      = unpack('L<', _read_exact($fh, 4));
    my $tensor_count = unpack('Q<', _read_exact($fh, 8));
    my $kv_count     = unpack('Q<', _read_exact($fh, 8));

    my %kv;
    for (1 .. $kv_count) {
        my $key   = _read_str($fh);
        my $vtype = unpack('L<', _read_exact($fh, 4));
        $kv{$key} = _read_kv_val($fh, $vtype);
    }

    my @tensors;
    for (1 .. $tensor_count) {
        my $name   = _read_str($fh);
        my $n_dims = unpack('L<', _read_exact($fh, 4));
        my @dims;
        for (1 .. $n_dims) {
            push @dims, unpack('Q<', _read_exact($fh, 8));
        }
        my $ggml_type = unpack('L<', _read_exact($fh, 4));
        my $offset    = unpack('Q<', _read_exact($fh, 8));
        push @tensors, {
            name   => $name,
            dims   => \@dims,
            type   => $ggml_type,
            offset => $offset,
        };
    }

    my $align = $kv{'general.alignment'} || GGUF_DEFAULT_ALIGN;
    my $pos   = tell($fh);
    my $pad   = ($align - ($pos % $align)) % $align;
    my $data_offset = $pos + $pad;

    return {
        version     => $version,
        metadata    => \%kv,
        tensors     => \@tensors,
        data_offset => $data_offset,
    };
}

sub gguf_header {
    my ($file) = @_;
    croak 'Filename required' unless defined $file;
    open my $fh, '<:raw', $file or croak "Cannot open '$file': $!";
    my $hdr = _parse_header_fh($fh);
    close $fh;
    return $hdr;
}

sub rgguf {
    my ($file) = @_;
    croak 'Filename required' unless defined $file;
    open my $fh, '<:raw', $file or croak "Cannot open '$file': $!";
    my $hdr = _parse_header_fh($fh);

    my %out;
    for my $t (@{ $hdr->{tensors} }) {
        my $spec = $GGML_TO_PDL{ $t->{type} }
            // croak "Unsupported GGML tensor type $t->{type} for '$t->{name}'";
        my ($pdl_type, $elem_bytes) = @{$spec};
        my $nelem = 1;
        $nelem *= $_ for @{ $t->{dims} };
        my $byte_len = $nelem * $elem_bytes;

        seek($fh, $hdr->{data_offset} + $t->{offset}, 0) or croak "seek failed: $!";
        my $raw = _read_exact($fh, $byte_len);

        my $pdl = PDL->zeroes($pdl_type, @{ $t->{dims} });
        ${ $pdl->get_dataref } = $raw;
        $pdl->upd_data;
        $out{ $t->{name} } = $pdl;
    }

    close $fh;
    return wantarray ? (\%out, $hdr->{metadata}) : \%out;
}

sub wgguf {
    my ($file, $tensors, $metadata) = @_;
    croak 'Filename and tensor hashref required'
        unless defined $file && ref($tensors) eq 'HASH';
    $metadata ||= {};

    my @names = sort keys %{$tensors};
    my @kv_keys = sort keys %{$metadata};
    my $align = $metadata->{'general.alignment'} || GGUF_DEFAULT_ALIGN;

    my @tensor_entries;
    my @chunks;
    my $rel_offset = 0;

    for my $name (@names) {
        my $pdl = $tensors->{$name};
        croak "Value for '$name' is not a PDL ndarray"
            unless ref($pdl) && eval { $pdl->isa('PDL') };
        my $tname = $pdl->type->ioname;
        my $gtype = $PDL_TO_GGML{$tname};
        croak "Unsupported PDL type '$tname' for GGUF" unless defined $gtype;

        my $contig = $pdl->make_physical;
        my $raw    = ${ $contig->get_dataref };
        my $len    = length($raw);
        my $pad    = ($align - ($len % $align)) % $align;

        push @tensor_entries, {
            name   => $name,
            dims   => [ $contig->dims ],
            type   => $gtype,
            offset => $rel_offset,
        };
        push @chunks, $raw . ("\0" x $pad);
        $rel_offset += $len + $pad;
    }

    open my $fh, '>:raw', $file or croak "Cannot write '$file': $!";
    print {$fh} GGUF_MAGIC;
    print {$fh} pack('L<Q<Q<', GGUF_VERSION, scalar(@tensor_entries), scalar(@kv_keys));

    for my $k (@kv_keys) {
        my $v = $metadata->{$k};
        print {$fh} pack('Q<', length($k)), $k;
        if (defined $v && $v =~ /\A[0-9]+\z/) {
            print {$fh} pack('L<L<', GGUF_TYPE_UINT32, $v);
        } else {
            $v = '' unless defined $v;
            print {$fh} pack('L<Q<', GGUF_TYPE_STRING, length($v)), $v;
        }
    }

    for my $e (@tensor_entries) {
        print {$fh} pack('Q<', length($e->{name})), $e->{name};
        print {$fh} pack('L<', scalar(@{ $e->{dims} }));
        print {$fh} pack('Q<', $_) for @{ $e->{dims} };
        print {$fh} pack('L<Q<', $e->{type}, $e->{offset});
    }

    my $pos = tell($fh);
    my $hdr_pad = ($align - ($pos % $align)) % $align;
    print {$fh} ("\0" x $hdr_pad) if $hdr_pad;
    print {$fh} $_ for @chunks;
    close $fh or croak "Failed closing '$file': $!";
    return 1;
}

1;

__END__

=head1 NAME

PDL::IO::GGUF - Read and write GGUF v3 model weight files as PDL ndarrays

=head1 SYNOPSIS

    use PDL;
    use PDL::IO::GGUF qw(rgguf wgguf gguf_header);

    wgguf('model.gguf', {
        'blk.0.attn_q.weight' => float([[1, 2], [3, 4]]),
    }, { 'general.architecture' => 'llama' });

    my ($tensors, $meta) = rgguf('model.gguf');

=head1 DESCRIPTION

C<PDL::IO::GGUF> provides pure-Perl reading and writing of GGUF v3 binary files
(used by C<llama.cpp> and C<ggml>) directly to and from L<PDL> ndarrays.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Google LLC. Apache License, Version 2.0.

=cut
