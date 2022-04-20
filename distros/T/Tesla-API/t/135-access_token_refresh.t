use warnings;
use strict;
use feature 'say';

use lib 't/';

use Data::Dumper;
use JSON;
use Mock::Sub;
use Tesla::API;
use Test::More;
use TestSuite;

if (! $ENV{VALID_TESLA_ACCOUNT}) {
    plan skip_all => "This test file requires a valid Tesla account";
}

my $t = Tesla::API->new(unauthenticated => 1);
my $ts = TestSuite->new;
my $ms = Mock::Sub->new;

my $test_data = $ts->data;
my %stored_token = %{ $test_data->{token_data} };

my %stored_copy = %stored_token;

my $token_data = $t->_access_token_set_expiry(\%stored_copy);
$token_data = $t->_access_token_data($token_data);

is
    $t->_access_token_valid($token_data),
    1,
    "Freshly updated token is valid ok";

$token_data->{expires_at} = 0;

is
    $t->_access_token_valid($token_data),
    0,
    "Token with an expired 'expires_at' is invalid ok";

done_testing();