use warnings;
use strict;
use feature 'say';

use Tesla::API;
use Test::More;

my $constant_persist = 0;

my $t = Tesla::API->new(unauthenticated => 1);

is
    $t->api_cache_persist,
    $constant_persist,
    "api_cache_persist() returns proper default ok";

is
    $t->api_cache_persist(1),
    1,
    "api_cache_persist() returns proper value after set ok";

done_testing();