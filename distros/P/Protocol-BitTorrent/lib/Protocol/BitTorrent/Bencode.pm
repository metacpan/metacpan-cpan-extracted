package Protocol::BitTorrent::Bencode;
{
  $Protocol::BitTorrent::Bencode::VERSION = '0.004';
}
use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';
use Convert::Bencode_XS qw();

=head1 NAME

Protocol::BitTorrent::Bencode - mixin for bencode/bdecode support

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 package Some::Package;
 use parent qw(Protocol::BitTorrent::Bencode);

 sub new { bless {}, shift }
 sub method {
 	my $self = shift;
	$self->bencode({ data => ... });
 }

=head1 DESCRIPTION

A simple mixin that provides L</bencode> and L</bdecode> methods for
use in other classes. The intention is to allow different bencode
implementations by changing a single class.

=cut

=head1 METHODS

=cut

=head2 bdecode

Decode the given data. May die() if the given bytestring is not valid
bencoded data.

=cut

sub bdecode {
	my $self = shift;
	my $data = shift;

	Convert::Bencode_XS::bdecode($data);
}

=head2 bencode

Encode the given data. May die() if the given Perl data structure contains
any undefined values.

=cut

sub bencode {
	my $self = shift;
	my $data = shift;

	Convert::Bencode_XS::bencode($data);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
