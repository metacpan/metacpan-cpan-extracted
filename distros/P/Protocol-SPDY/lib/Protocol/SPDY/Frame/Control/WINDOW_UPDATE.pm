package Protocol::SPDY::Frame::Control::WINDOW_UPDATE;
$Protocol::SPDY::Frame::Control::WINDOW_UPDATE::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Protocol::SPDY::Frame::Control);

=head1 NAME

Protocol::SPDY::Frame::Control::SynStream - stream creation request packet for SPDY protocol

=head1 VERSION

version 1.001

=head1 SYNOPSIS

=head1 DESCRIPTION

See L<Protocol::SPDY> and L<Protocol::SPDY::Base>.

=cut

use Protocol::SPDY::Constants ':all';

=head2 type_name

The string type for this frame ('WINDOW_UPDATE').

=cut

sub type_name { 'WINDOW_UPDATE' }

=head2 from_data

Instantiate from the given data.

=cut

sub from_data {
	my $class = shift;
	my %args = @_;
	my ($stream_id, $window_delta) = unpack "N1N1", substr $args{data}, 0, 8, '';
	$stream_id    &= ~0x80000000;
	$window_delta &= ~0x80000000;

	$class->new(
		%args,
		stream_id    => $stream_id,
		window_delta => $window_delta,
	);
}

=head2 stream_id

Which stream we're updating the window for.

=cut

sub stream_id { shift->{stream_id} }

=head2 window_delta

Change in window size (always positive).

=cut

sub window_delta { shift->{window_delta} }

=head2 as_packet

Returns byte representation for this frame.

=cut

sub as_packet {
	my $self = shift;
	my $payload = pack 'N1N1', $self->stream_id & ~0x80000000, $self->window_delta & ~0x80000000;
	return $self->SUPER::as_packet(
		payload => $payload,
	);
}

=head2 to_string

String representation, for debugging.

=cut

sub to_string {
	my $self = shift;
	$self->SUPER::to_string . ', stream ' . $self->stream_id . ', delta ' . $self->window_delta;
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
