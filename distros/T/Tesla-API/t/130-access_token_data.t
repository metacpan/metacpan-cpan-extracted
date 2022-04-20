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

my $test_data = $ts->data;
my $temp_cache = 't/test_data/tesla_auth_cache_test.json';
my %stored_token = %{ $test_data->{token_data} };
my %stored_copy = %stored_token;

if (-e $temp_cache) {
    unlink $temp_cache or die $!;
}

is -e $temp_cache, undef, "Tesla API token cache file unavailable ok";

is
    $t->_authentication_cache_file($temp_cache),
    $temp_cache,
    "Auth cache file set to proper file ok";

my $open_ok = eval { $t->_access_token_data; 1; };

is
    $open_ok,
    undef,
    "If the token cache store file is unavailable, we croak ok";

my $token_data = $t->_access_token_set_expiry(\%stored_copy);

open my $fh, '>', $temp_cache or die $!;
print $fh JSON->new->allow_nonref->encode($token_data);
close $fh;

$token_data = $t->_access_token_data;

is ref $token_data, 'HASH', "_access_token_data() reads the JSON file ok";

for (keys %stored_token) {
    is
        $token_data->{$_},
        $stored_token{$_},
        "Attr $_ has proper value in access token data";
}

is exists $stored_token{expires_at}, '', "expires_at not in stored token ok";
is exists $token_data->{expires_at}, 1, "expires_at in returned token ok";

my $next_token_data = $t->_access_token_data;

is ref $next_token_data, 'HASH', "_access_token_data() returns from cache ok";

for (keys %stored_token) {
    is
        $next_token_data->{$_},
        $stored_token{$_},
        "Attr $_ has proper value in access token 2nd call data ok";
}

if (-e $temp_cache) {
    unlink $temp_cache or die $!;
}

done_testing();