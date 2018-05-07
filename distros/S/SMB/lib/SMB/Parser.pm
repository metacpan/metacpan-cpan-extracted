# SMB Perl library, Copyright (C) 2014-2018 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package SMB::Parser;

use strict;
use warnings;

use bytes;
use if (1 << 32 == 1), 'bigint';  # support native uint64 on 32-bit platforms
use Encode 'decode';

sub new ($$) {
	my $class = shift;
	my $data = shift // "";

	my $self = bless {}, $class;

	return $self->set($data);
}

sub reset ($;$) {
	my $self = shift;
	my $offset = shift || 0;
	die "Negative offset is invalid" if $offset < 0;

	$self->{offset} = $offset;

	return $self;
}

sub set ($$;$) {
	my $self = shift;

	$self->{data} = $_[0];
	$self->{size} = length($_[0]);

	return $self->reset($_[1]);
}

sub cut ($;$) {
	my $self = shift;
	my $offset = shift || $self->{offset};
	die "Negative offset is invalid" if $offset < 0;

	$offset = $self->{size} if $offset > $self->{size};
	$self->{offset} = $offset if $offset > $self->{offset};

	return $self->set(substr($self->{data}, $offset) . "", $self->{offset} - $offset);
}

sub data { $_[0]->{data} }
sub size { $_[0]->{size} }
sub offset { $_[0]->{offset} }

my %UINT_MODS = (
	+1 => 'C',
	+2 => 'v',
	+4 => 'V',
	-1 => 'C',
	-2 => 'n',
	-4 => 'N',
);

sub uint ($$;$) {
	my $self = shift;
	my $n_bytes = shift;
	my $be_factor = shift() ? -1 : 1;

	return unpack($UINT_MODS{$be_factor * $n_bytes}, $self->bytes($n_bytes));
}

sub str ($$;$) {
	my $self = shift;
	my $n_bytes = shift;
	my $enc = shift || 'UTF-16LE';

	return decode($enc, $self->bytes($n_bytes));
}

sub bytes ($$) {
	my $self = shift;
	my $n_bytes = shift;

	my $n_avail = $self->{offset} + $n_bytes > $self->{size}
		? $self->{size} - $self->{offset} : $n_bytes;

	my $bytes = $self->{offset} > $self->{size} ? '' : substr($self->{data}, $self->{offset}, $n_avail);
	$self->{offset} += $n_bytes;

	return $bytes;
}

sub skip ($) {
	my $self = shift;
	my $n_bytes = shift;

	$self->{offset} += $n_bytes;

	return $self;
}

sub align ($;$$) {
	my $self = shift;
	my $offset = shift || 0;
	my $step = shift || 4;

	$self->skip(($step - ($self->offset - $offset) % $step) % $step);
}

sub uint8     { uint($_[0], 1   ); }
sub uint16    { uint($_[0], 2   ); }
sub uint32    { uint($_[0], 4   ); }
sub uint16_be { uint($_[0], 2, 1); }
sub uint32_be { uint($_[0], 4, 1); }
sub uint64    { uint32($_[0]) + (uint32($_[0]) << 32); }
sub utf16     { str($_[0], $_[1]); }
sub utf16_be  { str($_[0], $_[1], 'UTF-16BE'); }
sub fid1      { uint16($_[0]); }
sub fid2      { [ uint64($_[0]), uint64($_[0]) ]; }

1;

__END__
# ----------------------------------------------------------------------------

=head1 NAME

SMB::Parser - Convenient data parser for network protocols like SMB

=head1 SYNOPSIS

	use SMB::Parser;

	# Parse an imaginative packet of the following structure:
	#   protocol signature (2 bytes in big-endian), header (48),
	#   secret key (8), flags (1), mode (2 in little-endian),
	#   payload offset (4) and length (4),
	#   filename prefixed with length (2 + length),
	#   padding to 4 bytes,
	#   payload
	# SMB::Packer documentation shows how it could be packed.

	my $parser = SMB::Parser->new($packet_data_buffer);

	die if $parser->uint16_be != 0xFACE;  # check signature
	$parser->skip(48);                 # skip header (48 bytes)
	my $body_start = $parser->offset;  # store offset (50 here)

	my $secret = $parser->bytes(8);
	my $flags  = $parser->uint8;
	my $mode   = $parser->uint16;

	my $payload_offset = $parser->uint32;
	my $payload_length = $parser->uint32;

	my $text_length = $parser->uint16;
	my $filename = $parser->utf16($text_length);

	$parser->align;  # redundant; mere jump using reset is enough
	$parser->reset($body_start + $payload_offset);
	my $payload = $parser->bytes($payload_length);

	$parser->align;
	my $unconsumed_buffer = $parser->bytes(
		bytes::length($packet_data_buffer) - $parser->offset);

=head1 DESCRIPTION

This class allows to parse a binary data, like a network packet data.

It supports extracting blobs, unsigned integers of different lengths,
text in arbitrary encoding (SMB uses UTF-16LE) and more.

The current data pointer is usually between 0 and the data size. The
managed data once set is never changed, so the data pointer may go over
the data size if the caller is not cautious. This is different from
L<SMB::Packer> where the data is automatically extended in this case.

This class inherits from L<SMB>, so B<msg>, B<err>, B<mem>, B<dump>,
auto-created field accessor and other methods are available as well.

=head1 METHODS

=over 4

=item new DATA

Class constructor. Returns an SMB::Parser instance and initializes its
data with DATA and its pointer with 0 using B<set>.

=item reset [OFFSET=0]

Resets the current data pointer.

Specifying OFFSET over the managed data size does not produce an error,
but may likely cause all consequent parsing calls to return empty/null
values with possible warnings, although the pointer consistently
continues to advance.

=item set DATA [OFFSET=0]

Sets the object DATA (binary scalar) to be parsed and resets the pointer
using B<reset>.

=item cut DATA [OFFSET=<current-offset>]

Cuts data until the given OFFSET (by default until the current offset).
This is useful to strip all processed data and have offset at 0.

If OFFSET is lesser than the current offset, then the current offset is
adjusted correspondingly (reduced by OFFSET). If it is greater, then the
data is still cut as requested and the current offset is reset to 0.

=item data

Returns the managed data (binary scalar).

=item size

Returns the managed data size.

=item offset

Returns the current data pointer (starts from 0).

=item align [START_OFFSET=0] [STEP=4]

Advances the pointer, if needed, until the next alignment point
(that is every STEP bytes starting from START_OFFSET).

=item skip N_BYTES

Advances the pointer in N_BYTES (non-negative integer).

Returns the object, to allow chaining a consequent parsing method.

=item bytes N_BYTES

Normally returns the binary scalar of length N_BYTES starting from the
current data pointer and advances the pointer.

On data overflow, less bytes than N_BYTES returned (and on consequent
calls, 0 bytes returns). The data pointer is guaranteed to be advanced
in N_BYTES, even on/after the overflow.

The following parsing methods use this method internally, so they share
the same logic about reaching the end-of-data and advancing the pointer.

=item str N_BYTES [ENCODING='UTF-16LE']

Decodes N_BYTES (non-negative integer) as the text in the requested
encoding starting from the current data pointer.

The returned string has the utf8 flag set if it is non-ASCII.

=item utf16 N_BYTES

The same as B<str> with encoding 'UTF-16LE'.

=item utf16_be N_BYTES

The same as B<str> with encoding 'UTF-16BE'.

=item uint8

=item uint16

=item uint32

=item uint16_be

=item uint32_be

=item uint64

Unpacks an unsigned integer of the specified length in bits (i.e. 1, 2,
4, 8 bytes).

By default, the byte order is little-endian (since it is used in SMB).
The method suffix "_be" denotes the big-endian byte order for parsing.

=item fid1

Parses a file id used in SMB 1.

Returns an unsigned integer of 2 bytes.

=item fid2

Parses a file id used in SMB 2.

Returns an array ref of two unsigned integers of 8 bytes each.

=back

=head1 SEE ALSO

L<SMB::Packer>, L<SMB>.

=head1 AUTHOR

Mikhael Goikhman <migo@cpan.org>

