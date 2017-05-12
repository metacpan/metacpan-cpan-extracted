use strict;
use warnings;

use Test::More 'no_plan';

for my $i (1..500) {
    # chuck in some failures
    ok( $i % 11, "$i % 11 is true" );
}
