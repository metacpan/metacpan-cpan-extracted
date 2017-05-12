use strict;
use warnings;

# Pod constants without sigil should be default to scalar ($)

=head1 DESCRIPTION

Blah, X<x=>12, X<y=>48

=cut

use Test::More tests => 2;
use Pod::Constant qw(x y);

is( $x, 12 );
is( $y, 48 );
