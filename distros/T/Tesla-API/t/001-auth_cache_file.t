use warnings;
use strict;
use feature 'say';

use Tesla::API;
use Test::More;

my $default_file = 'tesla_auth_cache.json';
my $temp_file = 'test_data/tesla_auth_cache_test.json';

my $t = Tesla::API->new(unauthenticated => 1);

like
    $t->_authentication_cache_file,
    qr/.*\/$default_file/,
    "Default auth token cache file is ok";

$t->_authentication_cache_file($temp_file);

is
    $t->_authentication_cache_file,
    $temp_file,
    "_authentication_cache_file() with param ok";

done_testing();