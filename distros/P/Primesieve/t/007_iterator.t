
use strict;
use warnings;

use Test::More tests => 2;
use Primesieve;

my $i = Primesieve->new;
$i->skipto (96, 9999);
ok(97 == $i->next_prime);
ok(101 == $i->next_prime);

