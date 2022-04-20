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

my $t = Tesla::API->new(unauthenticated => 1);
my $ts = TestSuite->new;
my $ms = Mock::Sub->new;

my $test_data = $ts->data;
my %stored_token = %{ $test_data->{token_data} };
my $temp_cache = 't/test_data/tesla_auth_cache_test.json';

my %stored_copy = %stored_token;

is exists $stored_copy{expires_at}, '', "expires_at not in stored token ok";

my $token_data = $t->_access_token_set_expiry(\%stored_copy);

for (keys %stored_token) {
    is
        $token_data->{$_},
        $stored_token{$_},
        "Attr $_ has proper value in access token data";
}

is exists $stored_token{expires_at}, '', "expires_at not in stored token ok";
is exists $token_data->{expires_at}, 1, "expires_at in returned token ok";

my $in = $stored_token{expires_in};
my $at = $in + time;

is
    $token_data->{expires_at} > $at - 2 && $token_data->{expires_at} < $at + 2,
    1,
    "expires_at is within the proper window ok";

done_testing();