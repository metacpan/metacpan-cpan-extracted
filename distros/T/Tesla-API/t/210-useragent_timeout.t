use warnings;
use strict;
use feature 'say';

use Tesla::API;
use Test::More;

my $constant_ua_timeout = 180;

my $t = Tesla::API->new(unauthenticated => 1);

is
    $t->useragent_timeout,
    $constant_ua_timeout,
    "useragent_timeout() returns proper default ok";

for ('*', '?', 'aa', '99a', 'aa9', '0.a', '-1', '-1.0', '1.') {
    my $ok = eval { $t->useragent_timeout($_); 1; };
    is $ok, undef, "useragent_timeout() with '$_' param croaks ok";
}

for (999, .2, 2.2, 10.10, 0.1) {
    is
        $t->useragent_timeout($_),
        $_,
        "Setting user agent to '$_' works ok";
}

done_testing();