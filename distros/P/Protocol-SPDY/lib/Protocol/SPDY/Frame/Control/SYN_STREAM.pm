package Protocol::SPDY::Frame::Control::SYN_STREAM;
$Protocol::SPDY::Frame::Control::SYN_STREAM::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Protocol::SPDY::Frame::HeaderSupport Protocol::SPDY::Frame::Control);

=head1 NAME

Protocol::SPDY::Frame::Control::SYN_STREAM - stream creation request packet for SPDY protocol

=head1 VERSION

version 1.001

=head1 SYNOPSIS

=head1 DESCRIPTION

See L<Protocol::SPDY> and L<Protocol::SPDY::Base>.

=cut

use Protocol::SPDY::Constants ':all';

=head2 type_name

The string type for this frame ('SYN_STREAM').

=cut

sub type_name { 'SYN_STREAM' }

=head2 new

Instantiate.

=cut

sub new {
	my $class = shift;
	my %args = @_;
	$args{headers} = $class->header_hashref_to_arrayref($args{headers}) if (ref($args{headers}) || '') eq 'HASH';
	$class->SUPER::new(%args)
}

=head2 slot

Which credential slot we're using (unimplemented).

=cut

sub slot { shift->{slot} }

=head2 from_data

Instantiate from the given data.

=cut

sub from_data {
	my $class = shift;
	my %args = @_;
	my ($stream_id, $associated_stream_id, $slot) = unpack "N1N1n1", substr $args{data}, 0, 10, '';
	$stream_id &= ~0x80000000;
	$associated_stream_id &= ~0x80000000;
	my $pri = ($slot & 0xE000) >> 13;
	$slot &= 0xFF;

	my $zlib = delete $args{zlib};
	my $out = $zlib->decompress($args{data});
	my ($headers) = $class->extract_headers($out);
	$class->new(
		%args,
		stream_id            => $stream_id,
		associated_stream_id => $associated_stream_id,
		priority             => $pri,
		slot                 => $slot,
		headers              => $headers,
	);
}

=head2 stream_id

Our stream ID.

=cut

sub stream_id { shift->{stream_id} }

=head2 associated_stream_id

The stream to which we're associated.

=cut

sub associated_stream_id { shift->{associated_stream_id} }

=head2 priority

Our priority.

=cut

sub priority { shift->{priority} }

=head2 as_packet

Returns byte representation for this frame.

=cut

sub as_packet {
	my $self = shift;
	my $zlib = shift;
	my $payload = pack 'N1', $self->stream_id & 0x7FFFFFFF;
	$payload .= pack 'N1', ($self->associated_stream_id || 0) & 0x7FFFFFFF;
	$payload .= pack 'C1', ($self->priority & 0x07) << 5;
	$payload .= pack 'C1', $self->slot;
	my $block = $self->pairs_to_nv_header(map {; $_->[0], join "\0", @{$_}[1..$#$_] } @{$self->headers});
	$payload .= $zlib->compress($block);
	return $self->SUPER::as_packet(
		payload => $payload,
	);
}

=head2 to_string

String representation, for debugging.

=cut

sub to_string {
	my $self = shift;
	$self->SUPER::to_string . ', id=' . $self->stream_id . ', ' . $self->header_line;
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
