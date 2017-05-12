package Protocol::BitTorrent::Message::Bitfield;
{
  $Protocol::BitTorrent::Message::Bitfield::VERSION = '0.004';
}
use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';
use parent qw(Protocol::BitTorrent::Message);

=head1 NAME

Protocol::BitTorrent::Message::Bitfield - bitfield support

=head1 VERSION

version 0.004

=cut

=head1 METHODS

=cut

=head2 new

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {
		bitfield	=> $args{bitfield},
	}, $class;
	$self;
}

sub new_from_data {
	my $class = shift;
	my $data = shift;
	$class->new(
		bitfield => $data
	);
}

sub type { 'bitfield' }

sub bitfield { shift->{bitfield} }

sub as_data {
	my $self = shift;
	return pack 'N1C1a*', 1 + length($self->bitfield), $self->type_id, $self->bitfield;
}

sub as_string {
	my $self = shift;
	return sprintf '%s, %d bytes, pieces %s', $self->type, $self->packet_length, unpack 'B*', $self->bitfield;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
