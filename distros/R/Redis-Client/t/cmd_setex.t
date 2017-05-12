#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis SETEX command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->setex( 'perl_redis_test_setex', 1, 'foo' );
my $val = $redis->get( 'perl_redis_test_setex' );
is $val, 'foo';

sleep 2;

my $val2 = $redis->get( 'perl_redis_test_setex' );
is $val2, undef;

done_testing;

