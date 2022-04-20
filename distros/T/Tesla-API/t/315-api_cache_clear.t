use warnings;
use strict;
use feature 'say';

use lib 't/';

use Data::Dumper;
use Tesla::API;
use Test::More;
use TestSuite;

my $t = Tesla::API->new(unauthenticated => 1);
my $ts = TestSuite->new;

my $test_data = $ts->data;
my $stored_cache = $test_data->{api_cache_data};

$t->api_cache_clear;

my %copy = %$stored_cache;

my $api_cache = $t->_api_cache(%copy);
my %cache_data = $t->_api_cache_data;

my $known_endpoint = 'VEHICLE_SUMMARY';
my $known_id = 492932005972429;

is
    $api_cache->{data}{tokens}[0],
    '089956bbfcfe61ef',
    "_api_cache() returns proper data ok";

my ($endpoint) = keys %cache_data;
my ($id) = keys %{ $cache_data{$endpoint} };

is $endpoint, $known_endpoint, "_api_cache() has proper endpoint ok";
is $id, $known_id, "_api_cache() has proper ID ok";

$t->api_cache_clear;

%cache_data = $t->_api_cache_data;

is keys %cache_data, 0, "api_cache_clear() wipes out the cache entirely ok";

$api_cache = $t->_api_cache(
    endpoint => $known_endpoint,
    id   => $known_id
);

is defined $api_cache, '', "_api_cache() returns undef after api_cache_clear()";

done_testing();