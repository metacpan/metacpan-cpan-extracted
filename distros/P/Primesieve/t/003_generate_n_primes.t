
use strict;
use warnings;

use Test::More tests => 2;
use Primesieve;

my @p = generate_n_primes (168,0);
ok (168 == @p);

my $scalar = generate_n_primes (168,0);

ok (168 == @$scalar);
