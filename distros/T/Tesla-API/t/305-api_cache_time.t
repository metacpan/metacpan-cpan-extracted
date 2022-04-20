use warnings;
use strict;
use feature 'say';

use Tesla::API;
use Test::More;

my $constant_time = 2;

my $t = Tesla::API->new(unauthenticated => 1);

is
    $t->api_cache_time,
    $constant_time,
    "api_cache_time() returns proper default ok";

for (-1, 'a', 2.1, 'a9', '9a') {
    my $ok = eval { $t->api_cache_time($_); 1; };
    is $ok, undef, "api_cache_time() croaks with '$_' as a param";
    like $@, qr/requires an int/, "...and error message is sane";
}

for (1, 99, 999) {
    is
        $t->api_cache_time($_),
        $_,
        "api_cache_time() returns proper value after set to '$_' ok";
}

done_testing();