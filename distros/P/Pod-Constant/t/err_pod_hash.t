use strict;
use warnings;

# X<> used with unsupported variable type.

=head1 DESCRIPTION

X<%a=>(a => 1, b => 2)

=cut

use Test::More tests => 1;
use Test::Exception;

throws_ok {
    require Pod::Constant;
    Pod::Constant->import();
} qr/only supports scalar values/, 'X<> used with hash';

