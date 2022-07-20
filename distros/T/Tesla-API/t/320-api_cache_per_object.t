use warnings;
use strict;
use feature 'say';

use lib 't/';

use Data::Dumper;
use Storable qw(dclone);
use Tesla::API;
use Test::More;
use TestSuite;

my $t1 = Tesla::API->new(unauthenticated => 1);
my $t2 = Tesla::API->new(unauthenticated => 1);

my $ts = TestSuite->new;

my $test_data = $ts->data;
my $stored_cache = $test_data->{api_cache_data};

# ok
{
    my $known_endpoint = 'VEHICLE_SUMMARY';
    my $known_id = 492932005972429;
    my $known_token = '089956bbfcfe61ef';

    $t1->api_cache_clear;
    $t2->api_cache_clear;

    my %t1_copy = %{dclone($stored_cache)};
    my %t2_copy = %{dclone($stored_cache)};

    my $t1_cache = $t1->_api_cache(%t1_copy);

    # Check the data after initial insert

    is
        $t1_cache->{data}{tokens}[0],
        $known_token,
        "obj 1 cache ok before second object modification";

    $t2_copy{data}{tokens}[0] = 2;

    # Update the cache with a second object

    my $t2_cache = $t2->_api_cache(%t2_copy);

    # Check the data after modification in second object

    is
        $t2_cache->{data}{tokens}[0],
        2,
        "obj 2 cache ok after second object modification";

    is
        $t1_cache->{data}{tokens}[0],
        $known_token,
        "obj 1 cache ok after second object modification";
}

done_testing();