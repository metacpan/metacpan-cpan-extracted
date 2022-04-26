use warnings;
use strict;

use lib 't/';

use Data::Dumper;
use Mock::Sub;
use Tesla::API;
use Test::More;
use TestSuite;

my $ms = Mock::Sub->new;
my $ts = TestSuite->new;

my $access_token_sub = $ms->mock('Tesla::API::_access_token', return_value => 'ABCD');
my $tesla_api_sub = $ms->mock('Tesla::API::_tesla_api_call');

my $end_non_id = 'VEHICLE_LIST';
my $end_with_id = 'VEHICLE_SUMMARY';

# default config - no ID
{
    my $t= Tesla::API->new;
    my $response_data = $ts->json('api_vehicle_list_data');

    $tesla_api_sub->return_value(1, 200, $ts->json('api_vehicle_list_data'));

    my $api_data = $t->api(endpoint => $end_non_id);
    my $test_data = $ts->data->{api_vehicle_list_data}{response};

    is scalar @$api_data, scalar @$test_data, "API returns proper num of values";

    is
        keys %{ $api_data->[0] },
        keys %{ $test_data->[0] },
        "API return has proper number of keys ok";

    my %cache = $t->_api_cache_data;
    my $cache_data = $cache{$end_non_id}{0}->{data};

    is scalar @$cache_data, scalar @$test_data, "API cache returns proper num of values";

    is
        keys %{ $cache_data->[0] },
        keys %{ $test_data->[0] },
        "API cache return has proper number of keys ok";
}

sub check_cache {

}

done_testing();