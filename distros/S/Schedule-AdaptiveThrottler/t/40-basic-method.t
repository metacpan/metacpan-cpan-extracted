#!perl -T

use strict;
use warnings;
use Data::Dumper;
use Schedule::AdaptiveThrottler;
#$Schedule::AdaptiveThrottler::DEBUG = 1;
use lib 't';
use Util;

use Test::More;

diag "Testing both flavours of class method calls";

my ($memcached_client, $error) = get_test_memcached_client();

plan skip_all => $error if $error;

plan tests => 9;

my $class = "Schedule::AdaptiveThrottler";
ok($class->set_client($memcached_client), "Set the memcached client");

my $test_scheme = { all => {
    first_test    => {
        max     => 5,
        ttl     => 1,
        message => 'blocked',
        value   => 'test_foo'
    }},
    lockout    => 3,
    identifier => 'first_test',
};

$| = 1;

diag "Parameters passed by hashref";

is(($class->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_AUTHORIZED, "Authorized");
for (1..4) { $class->authorize($test_scheme) }
is(($class->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_BLOCKED, "Over threshold, blocked");
sleep 2;
is(($class->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_BLOCKED, "Locked out for 3 seconds");
sleep 2;
is(($class->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_AUTHORIZED, "Ban lifted");

diag "Parameters passed by hash";

is(($class->authorize(%$test_scheme))[0], SCHED_ADAPTHROTTLE_AUTHORIZED, "Authorized");
for (1..4) { $class->authorize(%$test_scheme) }
is(($class->authorize(%$test_scheme))[0], SCHED_ADAPTHROTTLE_BLOCKED, "Over threshold, blocked");
sleep 2;
is(($class->authorize(%$test_scheme))[0], SCHED_ADAPTHROTTLE_BLOCKED, "Locked out for 3 seconds");
sleep 2;
is(($class->authorize(%$test_scheme))[0], SCHED_ADAPTHROTTLE_AUTHORIZED, "Ban lifted");


#ok(defined SCHED_ADAPTHROTTLE_BLOCKED, "Block constant defined");
#ok(defined SCHED_ADAPTHROTTLE_AUTHORIZED, "Authorize constant defined");

