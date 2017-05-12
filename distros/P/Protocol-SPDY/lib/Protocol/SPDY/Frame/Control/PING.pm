package Protocol::SPDY::Frame::Control::PING;
$Protocol::SPDY::Frame::Control::PING::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Protocol::SPDY::Frame::Control);

=head1 NAME

Protocol::SPDY::Frame::Control::PING - aliveness test

=head1 VERSION

version 1.001

=head1 SYNOPSIS

=head1 DESCRIPTION

See L<Protocol::SPDY> and L<Protocol::SPDY::Base>.

=cut

use Protocol::SPDY::Constants ':all';

=head2 type_name

The string type for this frame ('PING').

=cut

sub type_name { 'PING' }

=head2 id

The unique ping ID.

=cut

sub id {
	my $self = shift;
	return $self->{id} unless @_;
	$self->{id} = shift;
	return $self;
}

=head2 from_data

Instantiate from the given data.

=cut

sub from_data {
	my $class = shift;
	my %args = @_;
	my ($id) = unpack "N1", substr $args{data}, 0, 4, '';
	$class->new(
		%args,
		id => $id,
	);
}

=head2 as_packet

Returns the packet as a byte string.

=cut

sub as_packet {
	my $self = shift;
	my $payload = pack 'N1', $self->id;
	return $self->SUPER::as_packet(
		payload => $payload,
	);
}

=head2 to_string

String representation, for debugging.

=cut

sub to_string {
	my $self = shift;
	$self->SUPER::to_string . ', id ' . $self->id;
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
