use warnings;
use strict;

use lib 't/';

BEGIN {
    $ENV{DEBUG_TESLA_API_CACHE} = 99;
}

use Data::Dumper;
use Mock::Sub;
use Tesla::API;
use Test::More;
use TestSuite;

my $ms = Mock::Sub->new;
my $ts = TestSuite->new;

# We want a warning cache is being used

my $cache_warning = 0;

$SIG{__WARN__} = sub {
    my ($w) = @_;

    if ($w =~ /^Returning cache/) {
        $cache_warning++;
    }
    else {
        warn $w;
    }
};

my $access_token_sub = $ms->mock('Tesla::API::_access_token', return_value => 'ABCD');
my $tesla_api_sub = $ms->mock('Tesla::API::_tesla_api_call');

my $end_non_id = 'VEHICLE_LIST';

# Persist
{
    my $t= Tesla::API->new;
    $t->api_cache_persist(1);

    is $t->api_cache_persist, 1, "api_cache_persist set ok";

    my $response_data = $ts->json('api_vehicle_list_data');

    $tesla_api_sub->return_value(1, 200, $ts->json('api_vehicle_list_data'));

    my $api_data = $t->api(endpoint => $end_non_id);
    my $test_data = $ts->data->{api_vehicle_list_data}{response};

    is scalar @$api_data, scalar @$test_data, "API returns proper num of values";

    is
        keys %{ $api_data->[0] },
        keys %{ $test_data->[0] },
        "API return has proper number of keys ok";

    my $cache_data = $t->api(endpoint => $end_non_id);

    is
        keys %{ $cache_data->[0] },
        keys %{ $test_data->[0] },
        "cache return has proper number of keys ok";

    is $cache_warning, 1, "Confirmed the cache was used ok";
}

# Cache time
{
    my $t= Tesla::API->new;
    $t->api_cache_clear;
    $cache_warning = 0;

    $t->api_cache_time(10);

    is $t->api_cache_persist, 0, "api_cache_persist unset ok";
    is $t->api_cache_time, 10, "api_cache_time set ok";

    my $response_data = $ts->json('api_vehicle_list_data');

    $tesla_api_sub->return_value(1, 200, $ts->json('api_vehicle_list_data'));

    my $api_data = $t->api(endpoint => $end_non_id);
    my $test_data = $ts->data->{api_vehicle_list_data}{response};

    is scalar @$api_data, scalar @$test_data, "API returns proper num of values";

    is
        keys %{ $api_data->[0] },
        keys %{ $test_data->[0] },
        "API return has proper number of keys ok";

    my $cache_data = $t->api(endpoint => $end_non_id);

    is
        keys %{ $cache_data->[0] },
        keys %{ $test_data->[0] },
        "cache return has proper number of keys ok";

    is $cache_warning, 1, "Confirmed the cache was used with api_cache_time ok";
}

done_testing();