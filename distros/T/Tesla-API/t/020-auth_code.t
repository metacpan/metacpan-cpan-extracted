use warnings;
use strict;
use feature 'say';

use lib 't/';

use Tesla::API;
use TestSuite;
use Test::More;

my $ts = TestSuite->new;
my $data = $ts->data;
my $url = $data->{auth_url_extract};
my $known_code = '2B51b8031f2b4ad4db52873da125b729497593e6c15c4a2dd591e698777f';

# Set some necessary environment variables

$ENV{TESLA_API_TESTING} = 1;
$ENV{TESLA_API_TESTING_CODE_URL} = $url;

my $t = Tesla::API->new(unauthenticated => 1);

is
    $t->_authentication_code,
    $known_code,
    "Full run of _authentication_code() in test mode works ok";

is
    $t->_authentication_code,
    $known_code,
    "Full run of _authentication_code() in test mode works on second run";

done_testing();