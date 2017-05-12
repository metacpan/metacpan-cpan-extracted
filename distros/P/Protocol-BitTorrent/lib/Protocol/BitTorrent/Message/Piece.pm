package Protocol::BitTorrent::Message::Piece;
{
  $Protocol::BitTorrent::Message::Piece::VERSION = '0.004';
}
use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';
use parent qw(Protocol::BitTorrent::Message);

=head1 NAME

Protocol::BitTorrent::Message::Piece - contains partial piece data

=head1 VERSION

version 0.004

=cut

=head1 METHODS

=cut

=head2 new

=cut

sub new_from_data {
	my $class = shift;
	my $data = shift;
	my ($index, $begin, $block) = unpack 'N1N1a*', $data;
	$class->new(
		piece_index	=> $index,
		offset		=> $begin,
		block		=> $block,
	);
}

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {
		piece_index	=> $args{piece_index},
		offset		=> $args{offset},
		block		=> $args{block},
	}, $class;
	$self;
}

sub type { 'piece' }

sub piece_index { shift->{piece_index} }
sub offset { shift->{offset} }
sub block { shift->{block} }

=head2 as_string

Returns a stringified version of this message.

=cut

sub as_string {
	my $self = shift;
	return sprintf '%s, %d bytes, index = %d, begin = %d, length = %d', $self->type, $self->packet_length, $self->piece_index, $self->offset, length($self->block);
}

sub as_data {
	my $self = shift;
	return pack 'N1C1N1N1a*', 9 + length($self->block), $self->type_id, $self->piece_index, $self->offset, $self->block;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
