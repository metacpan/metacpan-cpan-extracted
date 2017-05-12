use strict;
use warnings;

# Attempt to import an array

=head1 DESCRIPTION

X<@a=>1

=cut

use Test::More tests => 1;
use Test::Exception;

throws_ok {
    require Pod::Constant;
    Pod::Constant->import('@a');
} qr/only supports scalar values/, 'import used with array';

