#!/usr/bin/env perl

use v5.36;
use Test::More;
use experimental 'class';
use PAGI::FastAPI::RateLimit::Driver::Redis;

class MockRedis {
    field %data;
    field %ttl;

    method eval ($script, $numkeys, $key, $arg) {
        $data{$key}++;
        if ($data{$key} == 1) {
            $ttl{$key} = $arg;
        }
        return $data{$key};
    }

    method incr ($key) {
        $data{$key}++;
        return $data{$key};
    }

    method expire ($key, $seconds) {
        $ttl{$key} = $seconds;
        return 1;
    }

    method ttl ($key) {
        return $ttl{$key} // -1;
    }

    method get ($key) {
        return $data{$key};
    }

    method del ($key) {
        delete $data{$key};
        delete $ttl{$key};
        return 1;
    }
}

subtest 'Driver initialises with default prefix' => sub {
    my $redis  = MockRedis->new();
    my $driver = PAGI::FastAPI::RateLimit::Driver::Redis->new(redis => $redis);

    ok($driver, 'Redis driver instantiated successfully');
    isa_ok($driver, 'PAGI::FastAPI::RateLimit::Driver::Redis');
};

subtest 'First hit increments key and sets TTL' => sub {
    my $redis  = MockRedis->new();
    my $driver = PAGI::FastAPI::RateLimit::Driver::Redis->new(
        redis      => $redis,
        key_prefix => 'test_rl:',
    );

    my $count = $driver->increment_async('user_123', 60)->get;

    is($count, 1, 'First hit count is 1');
    is($redis->get('test_rl:user_123'), 1, 'Key was set with prefix in Redis');
    is($redis->ttl('test_rl:user_123'), 60, 'TTL set to 60 seconds');
};

subtest 'Subsequent hits increment counter' => sub {
    my $redis  = MockRedis->new();
    my $driver = PAGI::FastAPI::RateLimit::Driver::Redis->new(
        redis      => $redis,
        key_prefix => 'test_rl:',
    );

    my $count1 = $driver->increment_async('user_456', 30)->get;
    my $count2 = $driver->increment_async('user_456', 30)->get;

    is($count1, 1, 'First count is 1');
    is($count2, 2, 'Second count is 2');
};

subtest 'get_async and reset_async operations' => sub {
    my $redis  = MockRedis->new();
    my $driver = PAGI::FastAPI::RateLimit::Driver::Redis->new(
        redis      => $redis,
        key_prefix => 'test_rl:',
    );

    $driver->increment_async('user_789', 30)->get;

    my $current = $driver->get_async('user_789')->get;
    is($current, 1, 'get_async fetches current count');

    $driver->reset_async('user_789')->get;

    my $after_reset = $driver->get_async('user_789')->get;
    is($after_reset, 0, 'get_async returns 0 after reset');
};

done_testing;
