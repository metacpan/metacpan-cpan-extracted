# SMB Perl library, Copyright (C) 2014 Mikhael Goikhman, migo@cpan.org
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

package SMB::Packer;

use strict;
use warnings;

use bytes;
use Encode 'encode';

sub new ($$) {
	my $class = shift;

	my $self = bless {}, $class;

	return $self->reset;
}

sub reset ($) {
	my $self = shift;

	$self->{data} = '';
	$self->{offset} = 0;
	$self->{marks} = {};
	$self->{stubs} = {};

	return $self;
}

sub data { $_[0]->{data} }
sub size { length($_[0]->{data}) }
sub offset { $_[0]->{offset} }

sub zero ($$) {
	my $self = shift;
	my $n_bytes = shift // die;

	substr($self->{data}, $self->{offset}, $n_bytes) = "\0" x $n_bytes;

	return $self->skip($n_bytes);
}

sub skip ($$) {
	my $self = shift;
	my $n_bytes = shift // die;

	my $n_avail = $self->{offset} + $n_bytes > $self->size
		? $self->size - $self->{offset} : $n_bytes;

	$self->zero($n_bytes - $n_avail) if $n_avail < $n_bytes;

	$self->{offset} += $n_avail;

	return $self;
}

sub stub ($$$) {
	my $self = shift;
	my $name = shift // '';
	my $type = shift // '';

	die "type must be either size of bytes or uint{8,16{,_be},32{,_be},64}"
		unless $type =~ /^uint(8|16(_be)?|32(_be)?|64)$/ || $type =~ /^\d+$/;
	$self->{stubs}{$name} = [ $self->{offset}, $type ];

	$type =~ /^\d+$/
		? $self->bytes("\0" x $type)
		: $self->$type(0);

	return $self;
}

sub fill ($$) {
	my $self = shift;
	my $name = shift // '';
	my $data = shift // die;

	my $curr_offset = $self->{offset};
	my ($offset, $type) = @{$self->{stubs}{$name} || die "No previously set stub '$name'"};
	$self->{offset} = $offset;
	$type =~ /^\d+$/
		? $self->bytes($data)
		: $self->$type($data);
	$self->{offset} = $curr_offset;

	return $self;
}

sub mark ($$) {
	my $self = shift;
	my $name = shift // '';

	$self->{marks}{$name} = $self->{offset};

	return $self;
}

sub jump ($$) {
	my $self = shift;
	my $name = shift // '';

	$self->{offset} = $self->{marks}{$name} || 0;

	return $self;
}

sub diff ($$) {
	my $self = shift;
	my $name = shift // '';

	return $self->{offset} - ($self->{marks}{$name} || 0);
}

my %UINT_MODS = (
	+1 => 'C',
	+2 => 'v',
	+4 => 'V',
	-1 => 'C',
	-2 => 'n',
	-4 => 'N',
);

sub uint ($$$$) {
	my $self = shift;
	my $n_bytes = shift;
	my $be_factor = shift() ? -1 : 1;
	my $i = shift;

	return $self->bytes(pack($UINT_MODS{$be_factor * $n_bytes}, $i));
}

sub str ($$;$) {
	my $self = shift;
	my $str = shift;
	my $enc = shift || 'UTF-16LE';

	return $self->bytes(encode($enc, $str));
}

sub bytes ($$) {
	my $self = shift;
	my $data = shift;

	$data = join('', @$data) if ref($data) eq 'ARRAY';

	substr($self->{data}, $self->{offset}, length($data)) = $data;
	$self->{offset} += length($data);

	return $self;
}

sub uint8     { uint($_[0], 1, 0, $_[1]); }
sub uint16    { uint($_[0], 2, 0, $_[1]); }
sub uint32    { uint($_[0], 4, 0, $_[1]); }
sub uint16_be { uint($_[0], 2, 1, $_[1]); }
sub uint32_be { uint($_[0], 4, 1, $_[1]); }
sub uint64    { uint32($_[0], $_[1] & 0xffffffff); uint32($_[0], $_[1] >> 32); }
sub utf16     { str($_[0], $_[1]); }
sub utf16_be  { str($_[0], $_[1], 'UTF-16BE'); }
sub fid1      { uint16($_[0], $_[1]); }
sub fid2      { uint64($_[0], $_[1][0]); uint64($_[0], $_[1][1]); }

1;

__END__
# ----------------------------------------------------------------------------

=head1 NAME

SMB::Packer - Convenient data packer for network protocols like SMB

=head1 SYNOPSIS

	use SMB::Packer;

	# Pack an imaginative packet of the following structure:
	#   protocol signature (2 bytes in big-endian), header (48),
	#   secret key (8), flags (1), mode (2 in little-endian),
	#   payload offset (4) and length (4),
	#   filename prefixed with length (2 + length),
	#   payload
	# SMB::Parser documentation shows how it can be parsed back.

	my $packer = SMB::Packer->new;

	$packer
		->uint16_be(0xFACE)
		->zero(48)
		->mark('body-start')
		->bytes([ map { chr(rand(0x100)) } 1 .. 8 ]),
		->uint8(1)
		->uint16($mode)
		->stub('payload-offset', 'uint32')
		->uint32(bytes::length($payload))
		->uint16(length($filename) * 2)  # 2-byte chars in utf16
		->utf16($filename)
		->fill('payload-offset', $packer->diff('body-start'))
		->bytes($payload)
	;

	# send the packet
	send_tcp_payload($packer->data, $packer->size);

=head1 DESCRIPTION

This class allows to pack a binary data, like a network packet data.

It supports packing blobs, unsigned integers of different lengths, text
in arbitrary encoding (SMB uses UTF-16LE), defining named marks inside
the data for later reference/jumping, defining named stubs for later
filling and more.

The current data pointer is normally at the data end, but may be between
0 and the currently packed data size. The data is automatically extended
when needed, and the pointer is advanced accordingly. This is different
from L<SMB::Parser> where the initially set data is never extended even
when the pointer is over its size.

This class inherits from L<SMB>, so B<msg>, B<err>, B<mem>, B<dump>,
auto-created field accessor and other methods are available as well.

=head1 METHODS

=over 4

=item new

Class constructor. Returns an SMB::Packer instance with initially empty
data and state using B<reset>.

=item reset

Resets the gathered data, the current data pointer, as well as the named
marks and stubs.

=item data

Returns the data packed so far (binary scalar).

=item size

Returns length of the data packed so far (in bytes).

=item offset

Returns the current data pointer (integer starting from 0).

Please use the mechanisms of named marks or gaps (see below) instead of
manipulating the current data pointer directly.

=item skip N_BYTES

Advances the pointer in N_BYTES.

If the data needs to be extended over the currently packed data (for
example, when the current data pointer is at or near the end), it is
appended with the missing number of zeros using B<zero> method.

Returns the object, to allow chaining.

=item zero N_BYTES

Packs N_BYTES of "\0" bytes starting from the current data pointer
and advances the pointer in N_BYTES.

The data is extended if needed.

=item bytes BYTES

Packs a sub-buffer of BYTES (where BYTES is either a binary scalar or an
array ref of 1-byte scalars) and advances the pointer in length of BYTES.

The data is extended if needed.

The following packing methods use this method internally, so they share
the same logic about extending the data and advancing the pointer.

=item str STRING [ENCODING='UTF-16LE']

Encodes STRING (potentially with utf8 flag set) as the text in the
requested encoding starting from the current data pointer.

=item utf16 STRING

The same as B<str> with encoding 'UTF-16LE'.

=item utf16_be STRING

The same as B<str> with encoding 'UTF-16BE'.

=item uint8

=item uint16

=item uint32

=item uint16_be

=item uint32_be

=item uint64

Packs an unsigned integer of the specified length in bits (i.e. 1, 2,
4, 8 bytes).

By default, the byte order is little-endian (since it is used in SMB).
The method suffix "_be" denotes the big-endian byte order for packing.

=item fid1 FID1

Packs a file id used in SMB 1, that is an unsigned integer of 2 bytes.

=item fid2 FID2

Packs a file id used in SMB 2, that is an array ref of two unsigned
integers of 8 bytes each.

=item mark MARK_NAME

Labels the current data position as MARK_NAME (human readable string).

=item jump MARK_NAME

Changes the current data position to the one previously labeled with
MARK_NAME (if any, otherwise defaults to 0).

=item diff MARK_NAME

Returns the difference between the current data position and the one
previously labeled with MARK_NAME (if any, otherwise defaults to 0).

=item stub STUB_NAME TYPE

Labels the current data position as STUB_NAME (human readable string),
advances the data pointer according to TYPE by temporarily filling
this region with a zero equivalent, according to TYPE.

TYPE may be either a number matching /^\d+$/, in which case the stub type
is taken to be "bytes" of this size; or "uint8", "uint16" and so on, then
this is the stub type (see the corresponding "uint*" methods above).

=item fill STUB_NAME DATA

Fills the previously set stub with DATA. The DATA should correspond to
the TYPE previously specified in B<stub>(STUB_NAME, TYPE) method call.
I.e. if the TYPE was size of bytes, then DATA should correspond to the
B<bytes> method argument of size TYPE (scalar or array ref of this size).
And if the TYPE is, say, "uint16", then DATA should be 2-byte integer.

The packing is done at the previously stored data pointer position.
The current data pointer is not changed after this method!

If no STUB_NAME was previously set using B<stub> method, the fatal
exception is thrown.

=back

=head1 SEE ALSO

L<SMB::Parser>, L<SMB>.

=head1 AUTHOR

Mikhael Goikhman <migo@cpan.org>

