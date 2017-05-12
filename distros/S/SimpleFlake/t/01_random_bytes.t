use strict;
use Test::More 0.98;

use SimpleFlake;

my $random = SimpleFlake->get_random_bits(3);

ok( $random, "Random Bytes generated: $random" );

done_testing;
