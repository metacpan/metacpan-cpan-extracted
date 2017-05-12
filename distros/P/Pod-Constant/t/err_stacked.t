use strict;
use warnings;

=head1 DESCRIPTION

X<$a=>X<$b=>2

=cut

use Test::More tests => 1;
use Test::Exception;

throws_ok {
    require Pod::Constant;
    Pod::Constant->import('$b');
} qr/Invalid POD/, 'invalid pod - stacked X<>';
