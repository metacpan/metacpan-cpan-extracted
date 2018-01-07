package Slob;

use 5.014000;
use strict;
use warnings;
our $VERSION = '0.002';

use constant MAGIC => "!-1SLOB\x1F";

use Carp qw/croak verbose/;
use Encode;

use Compress::Raw::Bzip2;
use Compress::Raw::Lzma;
use Compress::Raw::Zlib;

our %UNCOMPRESS = (
	'' => sub { $_[0] },
	'lzma2' => sub {
		my ($input) = @_;
		my ($lzma2, $code, $output);
		($lzma2, $code) = Compress::Raw::Lzma::RawDecoder->new(Filter => Lzma::Filter::Lzma2());
		die "Error creating LZMA2 decoder: $code\n" unless $code == LZMA_OK;

		$code = $lzma2->code($input, $output);
		die "Did not reach end of stream\n" if $code == LZMA_OK;
		die "Error decoding LZMA2: $code\n" if $code != LZMA_STREAM_END;
		$output
	},

	'bz2' => sub {
		my ($input) = @_;
		my ($bz2, $code, $output);
		($bz2, $code)= Compress::Raw::Bunzip2->new;
		die "Error creating Bunzip2: $code\n" unless $code == Z_OK;

		$code = $bz2->bzinflate($input, $output);
		die "Did not reach end of stream\n" if $code == BZ_OK;
		die "Error decoding Bzip2: $code\n" if $code != BZ_STREAM_END;

		$output
	},

	'zlib' => sub {
		my ($input) = @_;
		my ($zlib, $code, $output);
		($zlib, $code) = Compress::Raw::Zlib::Inflate->new(
			-WindowBits => WANT_GZIP_OR_ZLIB
		);
		die "Error creating Zlib inflate: $code\n" unless $code == Z_OK;

		$code = $zlib->inflate($input, \$output, 1);
		die "Did not reach end of stream\n" if $code == Z_OK;
		die "Error inflating zlib: $code\n" if $code != Z_STREAM_END;
		$output
	}
);

sub new {
	my ($class, $path) = @_;
	my $fh;
	if (ref $path eq 'IO') {
		$fh = $path
	} else {
		open $fh, '<', $path or croak "Cannot open \"$path\": $!"
	}
	my $self = bless {path => $path, fh => $fh}, $class;
	$self->{header} = $self->read_header;
	$self
}

sub read_data {
	my ($self, $len) = @_;
	my $data;
	my $result = read $self->{fh}, $data, $len;
	if (!defined $result) {
		croak "Failed to read from $self->{path}: $!"
	} elsif ($result == $len) {
		$data
	} elsif ($result == 0) {
		croak "$self->{path} is at end of file"
	} elsif ($result < $len) {
		croak "Only read $result bytes of $self->{path} before reaching EOF"
	}
}

sub read_formatted {
	my ($self, $len_of_format, $format) = @_;
	unpack $format, $self->read_data($len_of_format);
}

sub read_char  { shift->read_formatted(1, 'C') }
sub read_short { shift->read_formatted(2, 'n') }
sub read_int   { shift->read_formatted(4, 'N') }
sub read_long  { shift->read_formatted(8, 'Q>') }

sub read_tiny_text {
	my ($self, $encoding) = @_;
	my $data = $self->read_data($self->read_char);
	if (length $data == 255) {
		$data = unpack 'Z*', $data;
	}
	$encoding //= $self->{encoding};
	decode $encoding, $data;
}

sub read_text {
	my ($self, $encoding) = @_;
	my $data = $self->read_data($self->read_short);
	$encoding //= $self->{encoding};
	decode $encoding, $data;
}

sub read_large_byte_string {
	my ($self) = @_;
	$self->read_data($self->read_short)
}

sub read_tag {
	my ($self) = @_;
	my $name  = $self->read_tiny_text;
	my $value = $self->read_tiny_text;
	($name, $value)
}

sub read_tags {
	my ($self) = @_;
	my $tag_count = $self->read_char;
	map { $self->read_tag } 1..$tag_count
}

sub read_content_types {
	my ($self) = @_;
	my $content_type_count = $self->read_char;
	map { $self->read_text } 1..$content_type_count
}

sub read_positions {
	my ($self) = @_;
	my $count = $self->read_int;
	my @positions = map { $self->read_long } 1..$count;
	my $relative_to = $self->ftell;
	map { $relative_to + $_ } @positions
}

sub fseek {
	my ($self, $position) = @_;
	seek $self->{fh}, $position, 0 or croak "Failed to seek to byte $position"
}

sub ftell {
	my ($self) = @_;
	my $result = tell $self->{fh};
	croak "Failed to tell position in file" if $result == -1;
	$result
}

sub uncompress {
	my ($self, $data) = @_;
	$UNCOMPRESS{$self->{header}{compression}}->($data)
}

sub read_header {
	my ($self) = @_;
	my $magic = $self->read_data(length MAGIC);
	croak "Not a SLOB dictionary" unless MAGIC eq $magic;
	my $uuid = $self->read_data(16);

	my $encoding = $self->read_tiny_text('UTF-8');
	$self->{encoding} = $encoding;

	my $compression = $self->read_tiny_text;
	die "Compression '$compression' not yet supported" unless exists $UNCOMPRESS{$compression};
	my %tags = $self->read_tags;
	my @content_types = $self->read_content_types;
	my $blob_count = $self->read_int;
	my $store_offset = $self->read_long;
	my $size = $self->read_long;
	my @refs = $self->read_positions;

	$self->fseek($store_offset);
	my @storage_bins = $self->read_positions;

	+{
		uuid => $uuid,
		encoding => $encoding,
		compression => $compression,
		tags => \%tags,
		content_types => \@content_types,
		blob_count => $blob_count,
		store_offset => $store_offset,
		size => $size,
		refs => \@refs,
		storage_bins => \@storage_bins,
	}
}

sub read_ref {
	my ($self) = @_;
	my $key = $self->read_text;
	my $bin_index = $self->read_int;
	my $item_index = $self->read_short;
	my $fragment = $self->read_tiny_text;
	+{
		key => $key,
		bin_index => $bin_index,
		item_index => $item_index,
		fragment => $fragment,
	}
}

sub read_storage_bin {
	my ($self) = @_;
	my $count = $self->read_int;
	my @content_types = map { $self->read_char } 1..$count;
	my $compressed_size = $self->read_int;
	my $compressed_data = $self->read_data($compressed_size);
	my $uncompressed_data = $self->uncompress($compressed_data);

	my @positions = unpack "N$count", $uncompressed_data;
	my $data = substr $uncompressed_data, $count * 4;
	+{
		positions => \@positions,
		data => $data
	}
}

sub ref_count { shift @{shift->{header}{refs}} }

sub seek_and_read_ref {
	my ($self, $index) = @_;
	croak "No ref has index $index" unless exists $self->{header}{refs}[$index];
	$self->fseek($self->{header}{refs}[$index]);
	$self->read_ref
}

sub seek_and_read_storage_bin {
	my ($self, $index) = @_;
	croak "No storage bin has index $index" unless exists $self->{header}{storage_bins}[$index];
	$self->fseek($self->{header}{storage_bins}[$index]);
	$self->read_storage_bin
}

sub get_entry_of_storage_bin {
	my ($self, $storage_bin, $index) = @_;
	my $start_of_data = substr $storage_bin->{data}, $storage_bin->{positions}[$index];
	my $length = unpack 'N', $start_of_data;
	substr $start_of_data, 4, $length;
}

sub seek_and_read_ref_and_data {
	my ($self, $index) = @_;
	my $ref = $self->seek_and_read_ref($index);
	my $bin = $self->seek_and_read_storage_bin($ref->{bin_index});
	my $data = $self->get_entry_of_storage_bin($bin, $ref->{item_index});
	$ref->{data} = $data;
	$ref
}

1;
__END__

=encoding utf-8

=head1 NAME

Slob - Read .slob dictionaries (as used by Aard 2)

=head1 SYNOPSIS

  use feature qw/:5.14/;
  use Slob;
  my $slob = Slob->new('path/to/dict.slob');

  my $nr_of_entries = $slob->ref_count; # if the same content has two
                                        # keys pointing to it, this
                                        # counts it twice

  my $second_ref = $slob->seek_and_read_ref(4);
  say "Entry is for $second_ref->{key}";
  say "Data is in bin $second_ref->{bin_index} at position $second_ref->{item_index}";

  my $bin = $slob->seek_and_read_storage_bin($second_ref->{bin_index});
  say "Bin has ", (scalar @{$bin->{positions}}), " entries";
  say "Value at position $second_ref->{item_index} is ",
    $slob->get_entry_of_storage_bin($bin, $second_ref->{item_index});

  # instead of the above, we can do
  my $second_ref_and_data = $slob->seek_and_read_ref_and_data(4);
  say "Entry is for $second_ref_and_data->{key}";
  say "Value is $second_ref_and_data->{data}";

=head1 DESCRIPTION

Slob is a compressed read-only format for storing natural language
dictionaries. It is used in Aard 2. C<Slob.pm> is a module that reads
dictionaries in slob format.

The following methods are available:

=over

=item Slob->B<new>(I<$path>)
=item Slob->B<new>(I<$fh>)

Create a new slob reader reading from the given path or filehandle.

=item $slob->B<ref_count>

The number of refs (keys) in the dictionary.

=item $slob->B<seek_and_read_ref>(I<$index>)

Read the ref (key) at the given index. Returns a hashref with the
following keys:

=over

=item key

The key

=item bin_index

The storage bin that contains the value for this key

=item item_index

The index in the bin_index storage bin of the value for this key

=item fragment

HTML fragment that, when applied to the HTML value, points to the
definition of the key.

=back

=item $slob->B<seek_and_read_storage_bin>(I<$index>)

Read the storage bin with the given index. Returns the storage bin,
which can later be given to B<get_entry_of_storage_bin>.

=item $slob->B<get_entry_of_storage_bin>(I<$bin>, I<$index>)

Given a storage bin (as returned by C<seek_and_read_storage_bin>) and
item index, returns the value at the index i nthe storage bin.

=item $slob->B<seek_and_read_ref_and_data>($index)

Convenience method that returns the key and value at a given index.
Returns a hashref like C<seek_and_read_ref> with an extra key,
I<data>, which is the value of the key.

=back

=head1 SEE ALSO

L<https://github.com/itkach/slob>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2018 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
