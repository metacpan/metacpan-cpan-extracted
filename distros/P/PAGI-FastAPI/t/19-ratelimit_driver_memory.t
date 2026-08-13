#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;

use PAGI::FastAPI::RateLimit::Driver::Memory;

subtest 'increment_async returns (count, expires_at), not just count' => sub {
    my $driver = PAGI::FastAPI::RateLimit::Driver::Memory->new;
    my $before = time;

    my ($count, $expires_at) = $driver->increment_async('k1', 60)->get;

    is $count, 1, 'first increment reports count 1';
    ok defined $expires_at, 'expires_at is defined on first increment';
    ok $expires_at >= $before + 60 && $expires_at <= $before + 61,
        'expires_at is set roughly ttl seconds from now';
};

subtest 'expires_at stays stable across increments within the same window' => sub {
    my $driver = PAGI::FastAPI::RateLimit::Driver::Memory->new;

    my (undef, $first_expiry)  = $driver->increment_async('k2', 60)->get;
    my ($count2, $second_expiry) = $driver->increment_async('k2', 60)->get;

    is $count2, 2, 'second increment reports count 2';
    is $second_expiry, $first_expiry,
        'expires_at does not get pushed out on every hit within the window';
};

subtest 'increment_async on separate keys is independent' => sub {
    my $driver = PAGI::FastAPI::RateLimit::Driver::Memory->new;

    $driver->increment_async('a', 60)->get;
    $driver->increment_async('a', 60)->get;
    my ($count_a) = $driver->increment_async('a', 60)->get;
    my ($count_b) = $driver->increment_async('b', 60)->get;

    is $count_a, 3, 'key "a" incremented independently';
    is $count_b, 1, 'key "b" starts fresh';
};

subtest 'get_async and reset_async' => sub {
    my $driver = PAGI::FastAPI::RateLimit::Driver::Memory->new;

    is $driver->get_async('c')->get, 0, 'get_async on unknown key returns 0';
    $driver->increment_async('c', 60)->get;
    is $driver->get_async('c')->get, 1, 'get_async reflects prior increments';

    $driver->reset_async('c')->get;
    is $driver->get_async('c')->get, 0, 'reset_async clears the counter';
};

done_testing;
