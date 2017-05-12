#!perl -T

use strict;
use warnings;
use Data::Dumper;
use Schedule::AdaptiveThrottler;
#$Schedule::AdaptiveThrottler::DEBUG = 1;
use lib 't';
use Util;

use Test::More;

diag "Testing various ways to initialize an instance";

my ($memcached_client, $error) = get_test_memcached_client();

plan skip_all => $error if $error;

plan tests => 13;

my $SAT;

my $test_scheme;

#########################################

ok($SAT = Schedule::AdaptiveThrottler->new(), "Create instance (empty arglist)");
ok($SAT->set_client($memcached_client), "Set the memcached client");

$test_scheme = { all => {
    first_test    => {
        max     => 5,
        ttl     => 1,
        message => 'blocked',
        value   => 'test_foo' . join('', map {(('a'..'z'))[rand 26]} (1..5)), 
    }},
    lockout    => 3,
    identifier => 'first_test',
};

$| = 1;

is(($SAT->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_AUTHORIZED, "Authorized");
for (1..4) { $SAT->authorize($test_scheme) }
is(($SAT->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_BLOCKED, "Over threshold, blocked");

#########################################

ok($SAT = Schedule::AdaptiveThrottler->new($memcached_client), "Create instance with client (single arg)");

$test_scheme = { all => {
    first_test    => {
        max     => 5,
        ttl     => 1,
        message => 'blocked',
        value   => 'test_foo' . join('', map {(('a'..'z'))[rand 26]} (1..5)), 
    }},
    lockout    => 3,
    identifier => 'first_test',
};

$| = 1;

is(($SAT->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_AUTHORIZED, "Authorized");
for (1..4) { $SAT->authorize($test_scheme) }
is(($SAT->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_BLOCKED, "Over threshold, blocked");

#########################################

ok($SAT = Schedule::AdaptiveThrottler->new(memcached_client => $memcached_client), "Create instance with client (hash)");

$test_scheme = { all => {
    first_test    => {
        max     => 5,
        ttl     => 1,
        message => 'blocked',
        value   => 'test_foo' . join('', map {(('a'..'z'))[rand 26]} (1..5)), 
    }},
    lockout    => 3,
    identifier => 'first_test',
};

$| = 1;

is(($SAT->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_AUTHORIZED, "Authorized");
for (1..4) { $SAT->authorize($test_scheme) }
is(($SAT->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_BLOCKED, "Over threshold, blocked");

#########################################

ok($SAT = Schedule::AdaptiveThrottler->new({memcached_client => $memcached_client}), "Create instance with client (hashref)");

$test_scheme = { all => {
    first_test    => {
        max     => 5,
        ttl     => 1,
        message => 'blocked',
        value   => 'test_foo' . join('', map {(('a'..'z'))[rand 26]} (1..5)), 
    }},
    lockout    => 3,
    identifier => 'first_test',
};

$| = 1;

is(($SAT->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_AUTHORIZED, "Authorized");
for (1..4) { $SAT->authorize($test_scheme) }
is(($SAT->authorize($test_scheme))[0], SCHED_ADAPTHROTTLE_BLOCKED, "Over threshold, blocked");

