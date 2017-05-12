package Protocol::SPDY::Frame::Data;
$Protocol::SPDY::Frame::Data::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Protocol::SPDY::Frame);

=head1 NAME

Protocol::SPDY::Frame::Data - data frame support

=head1 VERSION

version 1.001

=head1 DESCRIPTION

See L<Protocol::SPDY> and L<Protocol::SPDY::Base>.

=cut

use Protocol::SPDY::Constants ':all';

=head1 METHODS

=cut

=head2 stream_id

The stream ID for this data packet.

=cut

sub stream_id { shift->{stream_id} }

=head2 payload

The bytes comprising this data packet. Note that there are no guarantees
on boundaries: UTF-8 decoding for example could fail if this packet is
processed in isolation.

=cut

sub payload { shift->{payload} }

=head2 from_data

Generates an instance from the given data.

=cut

sub from_data {
	my $class = shift;
	my %args = @_;
	my ($stream_id, $flags, $len, $len2) = unpack "N1C1n1c1", substr $args{data}, 0, 8, '';
	$len = ($len << 8) | $len2;
	return $class->new(
		fin       => $flags & FLAG_FIN,
		stream_id => $stream_id,
		payload   => $args{data},
	);
}

=head2 as_packet

Returns the scalar bytes representing this frame.

=cut

sub as_packet {
	my $self = shift;
	my $len = length(my $payload = $self->payload);
	my $pkt = pack 'N1C1n1C1',
		($self->is_control ? 0x80000000 : 0x00000000) | ($self->stream_id & 0x7FFFFFFF),
		($self->fin ? FLAG_FIN : 0),
		$len >> 8,
		$len & 0xFF;
	$pkt .= $payload;
	return $pkt;
}

=head2 type_string

Returns 'data' - data frames don't have a type field, so we pick a value
that isn't going to conflict with any control frame types.

=cut

sub type_string { 'data' }

=head2 type_name

Returns 'data' - data frames don't have a type field, so we pick a value
that isn't going to conflict with any control frame types.

=cut

sub type_name { 'data' }

=head2 to_string

String representation, for debugging.

=cut

sub to_string {
	my $self = shift;
	$self->SUPER::to_string . ', stream=' . $self->stream_id . ', payload ' . length($self->payload) . " bytes";
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
