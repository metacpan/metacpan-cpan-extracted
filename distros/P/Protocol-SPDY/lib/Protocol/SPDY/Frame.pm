package Protocol::SPDY::Frame;
$Protocol::SPDY::Frame::VERSION = '1.001';
use strict;
use warnings;

=head1 NAME

Protocol::SPDY::Frame - support for SPDY frames

=head1 VERSION

version 1.001

=head1 DESCRIPTION

Support for SPDY frames. Typically you'd interact with these through the top-level
L<Protocol::SPDY> object.

See the L<Protocol::SPDY::Frame::Control> and L<Protocol::SPDY::Frame::Data> subclasses
for the two currently-defined frame types.

=cut

use Encode;
use Protocol::SPDY::Constants ':all';

use overload
	'""' => 'to_string',
	bool => sub { 1 },
	fallback => 1;

=head1 METHODS

=cut

=head2 is_control

Returns true if this is a control frame. Recommended over
checking ->isa(L<Protocol::SPDY::Frame::Control>) directly.

=cut

sub is_control { !shift->is_data }

=head2 is_data

Returns true if this is a data frame. Recommended over
checking ->isa(L<Protocol::SPDY::Frame::Data>) directly.

=cut

sub is_data { shift->isa('Protocol::SPDY::Frame::Data') ? 1 : 0 }

=head2 fin

Returns true if the FIN flag is set for this frame.

=cut

sub fin { shift->{fin} }

=head2 new

Instantiate a new frame. Typically called as a super method
from the L<Protocol::SPDY::Frame::Control> or L<Protocol::SPDY::Frame::Data>
subclass implementation.

=cut

sub new {
	my ($class, %args) = @_;
	my $self = bless \%args, $class;
	$self->{packet} //= "\0" x 8;
	$self->{data} //= '';
	return $self;
}

=head2 length

Returns the length of the current packet in bytes.

=cut

sub length : method { shift->{length} }

=head2 type

Returns the numerical type of this frame, such as 1 for SYN_STREAM, 3 for RST_STREAM etc.

=cut

sub type { die 'abstract class, no type defined' }

=head2 type_string

Returns the type of this frame as a string.

=cut

sub type_string { FRAME_TYPE_BY_ID->{shift->type} }

=head2 as_packet

Abstract method for returning the byte data comprising the SPDY packet that
would hold this frame.

=cut

sub as_packet { die 'abstract method' }

=head2 parse

Extract a frame from the given packet if possible. Takes a
scalar reference to byte data, and returns a L<Protocol::SPDY::Frame>
subclass, or undef on failure.

=cut

sub parse {
	shift;
	my $pkt = shift;
	# 2.2 Frames always have a common header which is 8 bytes in length
	return undef unless length $$pkt >= 8;

	# Data frames technically have a different header structure, but the
	# length and control-bit values are the same.
	my ($ver, $type, $len) = unpack "n1n1N1", $$pkt;

	# 2.2.2 Length: An unsigned 24-bit value representing the number of
	# bytes after the length field... It is valid to have a zero-length data
	# frame.
	my $flags = ($len >> 24) & 0xFF;
	$len &= 0x00FFFFFF;
	return undef unless length $$pkt >= 8 + $len;

	my $control = $ver & 0x8000 ? 1 : 0;
	return Protocol::SPDY::Frame::Data->from_data(
		data => $$pkt
	) unless $control;

	$ver &= ~0x8000;

	my %args = @_;
	# Now we know what type we have, delegate to a subclass which knows more than
	# we do about constructing the object.
	my $target_class = $control ? 'Protocol::SPDY::Frame::Control' : 'Protocol::SPDY::Frame::Data';
	my $obj = $target_class->from_data(
		zlib    => $args{zlib},
		type    => $type,
		version => $ver,
		length  => $len,
		fin     => $flags & FLAG_FIN ? 1 : 0,
		uni     => $flags & FLAG_UNI ? 1 : 0,
		data    => substr $$pkt, 8, $len
	);
	substr $$pkt, 0, 8 + $len, '';
	$obj
}

=head2 version

Returns the version for this frame, probably 3.

=cut

sub version { shift->{version} }

=head2 extract_frame

Extracts a frame from the given data.

=cut

sub extract_frame {
	my $class = shift;
	$class->parse(@_)
}

=head2 extract_headers

Given a scalar containing bytes, constructs an arrayref of headers
and returns a 2-element list containing this arrayref and the length
of processed data.

=cut

sub extract_headers {
	my $self = shift;
	my $data = shift;
	my $start_len = length $data;
	my ($count) = unpack 'N1', substr $data, 0, 4, '';
	my @headers;
	for (1..$count) {
		my ($k, $v) = unpack 'N/A* N/A*', $data;
		my @v = split /\0/, $v;
		# Don't allow non-ASCII characters
		push @headers, [ Encode::encode(ascii => (my $key = $k), Encode::FB_CROAK) => @v ];
		substr $data, 0, 8 + length($k) + length($v), '';
	}
	return \@headers, $start_len - length($data);
}

=head2 to_string

String representation of this frame, for debugging.

=cut

sub to_string {
	my $self = shift;
	'SPDY:' . $self->type_string . ($self->fin ? ' (FIN)' : '')
}

1;

__END__

=head1 COMPONENTS

Further documentation can be found in the following modules:

=over 4

=item * L<Protocol::SPDY> - top-level protocol object

=item * L<Protocol::SPDY::Frame> - generic frame class

=item * L<Protocol::SPDY::Frame::Control> - specific subclass for control frames

=item * L<Protocol::SPDY::Frame::Data> - specific subclass for data frames

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
