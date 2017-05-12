#!perl -T

use strict;
use warnings;
use Data::Dumper;
use Schedule::AdaptiveThrottler;
#$Schedule::AdaptiveThrottler::DEBUG = 1;
use lib 't';
use Util;

use Test::More;

diag "Testing long keys";

my ($memcached_client, $error) = get_test_memcached_client();

plan skip_all => $error if $error;

plan tests => 4;

my $sat;
ok( $sat = Schedule::AdaptiveThrottler->new( memcached_client => $memcached_client ),
    "Create the object" );

# don't remember which comes first in the key (and too lazy to check now), so
# make sure any one of the parts goes over the 250 characters threshold
# (memcached limitation for key length)

my $test_scheme = { all => {
    first_test    => {
        max     => 1,
        ttl     => 1,
        message => 'blocked',
        value   => '01234567890'x25,
    }},
    lockout    => 3,
    identifier => 'superLongKey'x25,
};

my $test_scheme_2 = { all => {
    first_test    => {
        max     => 1,
        ttl     => 1,
        message => 'blocked',
        value   => '01234567890'x25,
    }},
    lockout    => 3,
    identifier => 'superLongKey'x26, # 1 more
};

$| = 1;

is(($sat->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_AUTHORIZED, "Long key, authorized");
is(($sat->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_BLOCKED, "Long key, blocked");

# should be no collision, because of md5sum for long keys
is(($sat->authorize($test_scheme_2))[0], SCHED_ADAPTHROTTLE_AUTHORIZED, "Long key, no collision, authorized");
