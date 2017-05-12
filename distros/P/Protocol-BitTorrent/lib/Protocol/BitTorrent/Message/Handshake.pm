package Protocol::BitTorrent::Message::Handshake;
{
  $Protocol::BitTorrent::Message::Handshake::VERSION = '0.004';
}
use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';
use parent qw(Protocol::BitTorrent::Message);

=head1 NAME

Protocol::BitTorrent::Message::Handshake - initial bittorrent peer handshake message

=head1 VERSION

version 0.004

=cut

=head1 METHODS

=cut

=head2 new

=cut

sub new_from_data {
	my $class = shift;
	my %args = @_;
	my $pstr = exists($args{pstr}) ? $args{pstr} : 'BitTorrent protocol';
	my $self = bless {
		pstr		=> $pstr,
		info_hash	=> $args{info_hash},
		peer_id		=> $args{peer_id},
	}, $class;
	$self;
}

=head2 new_from_buffer

Returns an instance of a L<Protocol::BitTorrent::Message::Handshake> subclass
by parsing the given buffer.

Takes a single scalar ref as parameter - this should be a reference to the scalar
buffer containing data to be parsed. Removes packet data from this buffer if
parsing was successful.

=cut

sub new_from_buffer {
	my $class = shift;
	my $buffer = shift;
	return undef unless defined $buffer && length $$buffer >= 49;

	my ($pstr, $reserved, $info_hash, $peer_id) = unpack 'C/a a8 a20 a20', $$buffer;
	substr $$buffer, 0, 49 + length($pstr), '';

	return $class->new_from_data(
		pstr		=> $pstr,
		info_hash	=> $info_hash,
		peer_id		=> $peer_id,
		reserved	=> $reserved,
	);
}

sub pstr { shift->{pstr} }
sub info_hash { shift->{info_hash} }
sub peer_id { shift->{peer_id} }

sub as_data {
	my $self = shift;
	return pack 'C1A*a8a20a20', length($self->pstr), $self->pstr, '', $self->info_hash, $self->peer_id;
}

sub type { 'handshake' }

sub as_string {
	my $self = shift;
	return sprintf '%s, peer_id = %s (%s), info_hash = %s, pstr = %s', $self->type, $self->peer_id, Protocol::BitTorrent->peer_type_from_id($self->peer_id), unpack('H*', $self->info_hash), $self->pstr;
}
1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
