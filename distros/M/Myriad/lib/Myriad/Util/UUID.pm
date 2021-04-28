package Myriad::Util::UUID;

our $VERSION = '0.004'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use strict;
use warnings;

use Math::Random::Secure;

sub uuid {
    # UUIDv4 (random)
    my @rand = map Math::Random::Secure::irand(2**32), 1..4;
    return sprintf '%08x-%04x-%04x-%04x-%04x%08x',
        $rand[0],
        $rand[1] & 0xFFFF,
        (($rand[1] & 0x0FFF0000) >> 16) | 0x4000,
        $rand[2] & 0xBFFF,
        ($rand[2] & 0xFFFF0000) >> 16,
        $rand[3];
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

