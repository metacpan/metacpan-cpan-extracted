use warnings;
use strict;
use feature 'say';

use lib 't/';

use Data::Dumper;
use Tesla::API;
use Test::More;
use TestSuite;

my $mod = 'Tesla::API';

my $t = Tesla::API->new(unauthenticated => 1);
my $ts = TestSuite->new;

my $test_data = $ts->data;
my $stored_cache = $test_data->{api_cache_data};

# no endpoint
{
    $t->api_cache_clear;

    my %copy = %$stored_cache;
    delete $copy{endpoint};

    my $ok = eval { $t->_api_cache(%copy); 1; };

    is $ok, undef, "_api_cache() without an 'endpoint' param croaks ok";
}

# default id
{
    $t->api_cache_clear;

    my %copy = %$stored_cache;
    delete $copy{id};

    $t->_api_cache(%copy);

    my %api_cache = $t->_api_cache_data;
    my ($id) = keys %{ $api_cache{VEHICLE_SUMMARY} };

    is $id, 0, "_api_cache() defaults to id 0 if not sent in ok";
}

# no data param
{
    $t->api_cache_clear;

    my %copy = %$stored_cache;
    delete $copy{data};

    my $api_cache = $t->_api_cache(%copy);

    is
        defined $api_cache,
        '',
        "If no data sent into _api_cache(), result is undef";

    my %data = $t->_api_cache_data;

    is
        keys %{ $data{VEHICLE_SUMMARY} },
        0,
        "If no data sent in, no data is returned";

}

# ok
{
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
}

done_testing();