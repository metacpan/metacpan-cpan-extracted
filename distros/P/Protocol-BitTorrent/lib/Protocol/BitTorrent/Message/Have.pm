package Protocol::BitTorrent::Message::Have;
{
  $Protocol::BitTorrent::Message::Have::VERSION = '0.004';
}
use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';
use parent qw(Protocol::BitTorrent::Message);

=head1 NAME

Protocol::BitTorrent::Message::Have - have message support

=head1 VERSION

version 0.004

=cut

=head1 METHODS

=cut

=head2 new

=cut

sub new_from_data {
	my $class = shift;
	my $self = bless {
	}, $class;
	$self;
}

sub type { 'have' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
