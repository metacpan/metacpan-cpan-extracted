package Protocol::SPDY::Frame::Control;
$Protocol::SPDY::Frame::Control::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Protocol::SPDY::Frame);

=head1 NAME

Protocol::SPDY::Frame::Control - control frame subclass for the SPDY protocol

=head1 VERSION

version 1.001

=head1 DESCRIPTION

Support for control frames. Typically you'd interact with these through the top-level
L<Protocol::SPDY> object.

Subclass of L<Protocol::SPDY::Frame>. See also L<Protocol::SPDY::Frame::Data>.

=head2 TYPES

The following control frame types are known:

=over 4

=item * L<SYN_STREAM|Protocol::SPDY::Frame::Control::SYN_STREAM>

=item * L<RST_STREAM|Protocol::SPDY::Frame::Control::RST_STREAM>

=item * L<SYN_REPLY|Protocol::SPDY::Frame::Control::SYN_REPLY>

=item * L<HEADERS|Protocol::SPDY::Frame::Control::HEADERS>

=item * L<CREDENTIAL|Protocol::SPDY::Frame::Control::CREDENTIAL>

=item * L<GOAWAY|Protocol::SPDY::Frame::Control::GOAWAY>

=item * L<PING|Protocol::SPDY::Frame::Control::PING>

=item * L<SETTINGS|Protocol::SPDY::Frame::Control::SETTINGS>

=back

=cut

use Protocol::SPDY::Constants ':all';

=head1 METHODS

=cut

=head2 is_control

This is a control frame, so it will return true.

=cut

sub is_control { 1 }

=head2 is_data

This is not a data frame, so it returns false.

=cut

sub is_data { 0 }

=head2 version

The version for this frame - probably 3.

=cut

sub version {
	die "no version for $_[0]" unless $_[0]->{version};
	shift->{version}
}

=head2 type

The numerical type for this frame.

=cut

sub type { FRAME_TYPE_BY_NAME->{ shift->type_name } }

=head2 uni

Unidirectional flag (if set, we expect no response from the other side).

=cut

sub uni { shift->{uni} }

=head2 compress

The compression flag. Used on some frames.

=cut

sub compress { shift->{compress} }

=head2 as_packet

Returns the byte representation for this frame.

=cut

sub as_packet {
	my $self = shift;
	my %args = @_;
	my $len = length($args{payload});
	my $pkt = pack 'n1n1C1n1C1',
		($self->is_control ? 0x8000 : 0x0000) | ($self->version & 0x7FFF),
		$self->type,
		($self->fin ? FLAG_FIN : 0) | ($self->uni ? FLAG_UNI : 0) | ($self->compress ? FLAG_COMPRESS : 0),
		$len >> 8,
		$len & 0xFF;
	$pkt .= $args{payload};
	return $pkt;
}

=head2 pairs_to_nv_header

Returns a name-value pair header block.

=cut

sub pairs_to_nv_header {
	shift;
	my @hdr = @_;
	my $data = pack 'N1', @hdr / 2;
	$data .= pack '(N/A*)*', @hdr;
	return $data;
}

=head2 find_class_for_type

Returns the class appropriate for the given type (can be numerical
or string representation).

=cut

sub find_class_for_type {
	shift;
	my $type = shift;
	my $name = exists FRAME_TYPE_BY_NAME->{$type} ? $type : FRAME_TYPE_BY_ID->{$type} or die "No class for $type";
	return 'Protocol::SPDY::Frame::Control::' . $name;
}

=head2 from_data

Instantiates a frame from the given bytes.

=cut

sub from_data {
	my $class = shift;
	my %args = @_;
	my $type = $args{type};
	my $target_class = $class->find_class_for_type($type);
	return $target_class->from_data(%args);
}

=head2 to_string

String representation for debugging.

=cut

sub to_string {
	my $self = shift;
	$self->SUPER::to_string . ', control';
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
