use warnings;
use strict;
use feature 'say';

use Tesla::API;
use Test::More;

my $constant_ua_string = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:98.0) Gecko/20100101 Firefox/98.0';

my $t = Tesla::API->new(unauthenticated => 1);

is
    $t->useragent_string,
    $constant_ua_string,
    "useragent_string() returns proper default ok";

is
    $t->useragent_string('Test Browser'),
    'Test Browser',
    "Setting user agent works ok";

done_testing();