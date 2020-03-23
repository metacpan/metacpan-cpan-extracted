
use strict;
use warnings;

use Test::More tests => 2;
use Primesieve;

my @p = generate_primes (0,1000);
ok (168 == @p);

my $s = generate_primes (0,1000);
ok (@$s == 168);


