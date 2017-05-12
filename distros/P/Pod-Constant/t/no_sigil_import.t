use strict;
use warnings;

# Importing without sigil should default to scalar ($)

=head1 DESCRIPTION

Blah, X<$x=>1, X<$y=>2

=cut

use Test::More tests => 2;
use Pod::Constant qw(x y);

is( $x, 1 );
is( $y, 2 );
