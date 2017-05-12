use strict;
use warnings;

# No value provided after X<>.

=head1 DESCRIPTION

The value is X<$a=>

=cut

use Test::More tests => 1;
use Test::Exception;

throws_ok {
    require Pod::Constant;
    Pod::Constant->import('$a');
} qr/No value provided for '\$a'/;
