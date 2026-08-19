#!/usr/bin/env perl

# Optional live integration test against a real Redis server. Skipped
# entirely unless Async::Redis is installed and PAGI_TEST_REDIS is set,
# so `prove` runs cleanly for anyone without a Redis handy (t/01 already
# covers the driver's own logic offline via a fake client).
#
# Start the Redis server:
#   docker compose up -d
#
# Run it with, e.g.:
#   PAGI_TEST_REDIS=127.0.0.1:6379 prove -l t/02-queue_driver_redis_live.t
#
# When done then remove the container:
#   docker rm -f pagi-redis-test

use v5.38;
use Test::More;

plan skip_all => 'Set PAGI_TEST_REDIS=127.0.0.1:6379 to run the live Redis test'
    unless $ENV{PAGI_TEST_REDIS};

eval 'use Async::Redis; 1'
    or plan skip_all => 'Async::Redis not installed';

use Future::AsyncAwait;
use PAGI::FastAPI::Queue::Driver::Redis;

my ($host, $port) = split /:/, $ENV{PAGI_TEST_REDIS}, 2;
$port //= 6379;

my $prefix = 'pagi:queue:live-test:' . $$ . ':';
my $driver = PAGI::FastAPI::Queue::Driver::Redis->new(
    host   => $host,
    port   => $port,
    prefix => $prefix,
);

my $connected = eval {
    $driver->size('probe')->get;
    1;
};
plan skip_all => "Could not reach Redis at $ENV{PAGI_TEST_REDIS}: $@"
    unless $connected;

subtest 'push/pop/size against a real Redis server' => sub {
    $driver->push('jobs', 'first')->get;
    $driver->push('jobs', 'second')->get;

    is $driver->size('jobs')->get, 2, 'size reflects two pushed items';
    is $driver->pop('jobs')->get, 'first', 'FIFO order holds against real Redis';
    is $driver->size('jobs')->get, 1, 'size drops after pop';
};

subtest 'payloads round-trip through real Redis' => sub {
    $driver->push('data', { a => 1, b => [1, 2, 3] })->get;
    is_deeply $driver->pop('data')->get, { a => 1, b => [1, 2, 3] },
        'structured payload survives a real Redis round-trip';
};

# Drain everything this test pushed so repeated runs don't accumulate
# stray items (the PID-scoped prefix keeps runs from colliding, but this
# still leaves tidy state behind on the shared server).
$driver->pop('jobs')->get while $driver->size('jobs')->get;
$driver->pop('data')->get while $driver->size('data')->get;

$driver->disconnect;

done_testing;
