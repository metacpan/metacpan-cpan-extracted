package Protocol::BitTorrent::Message::Request;
{
  $Protocol::BitTorrent::Message::Request::VERSION = '0.004';
}
use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';
use parent qw(Protocol::BitTorrent::Message);

=head1 NAME

Protocol::BitTorrent::Message::Request - a piece request

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

# Complain mightily if we have an invalid request.
# TODO extend this to all message types
	die "Bad length for buffer: " . join ' ', map sprintf('%02x', ord), split //, $data if length($data) != 12;

	my ($index, $begin, $len) = unpack 'N1N1N1', $data;
	die join ' ', "Data", unpack('H*', $data), 'has no length' unless defined $len;
	$class->new(
		piece_index	=> $index,
		offset		=> $begin,
		block_length	=> $len,
	);
}

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {
		piece_index	=> $args{piece_index},
		offset		=> $args{offset},
		block_length	=> $args{block_length},
	}, $class;
	$self;
}

sub type { 'request' }

sub piece_index { shift->{piece_index} }
sub offset { shift->{offset} }
sub block_length { shift->{block_length} }

=head2 as_string

Returns a stringified version of this message.

=cut

sub as_string {
	my $self = shift;
	return sprintf '%s, %d bytes, index = %d, begin = %d, length = %d', $self->type, $self->packet_length, $self->piece_index, $self->offset, $self->block_length;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
