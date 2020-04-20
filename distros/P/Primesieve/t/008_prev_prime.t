
use strict;
use warnings;

use Test::More;
use Primesieve;

if (!Primesieve->can ("prev_prime")) {
        plan skip_all => 'not supported.';
} else {
        plan tests => 1;
        my $i = Primesieve->new;
        $i->skipto (100, 9999);
        ok(97 == $i->prev_prime);
}
