
use strict;
use warnings;

use Test::More tests => 6;
use Primesieve;

ok (168 == count_primes (0,1000));
ok (8 == count_twins (0, 100));
ok (30 == count_triplets (0, 1000));
ok (12 == count_quadruplets (0, 10000));
ok (21 == count_quintuplets (0, 100000));
ok (5 == count_sextuplets (0, 100000));

