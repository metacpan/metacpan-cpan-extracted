#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis DECRBY command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->set( perl_redis_test_decrby => 10 );

my $new = $redis->decrby( 'perl_redis_test_decrby', 3 );

is $new, 7;

ok $redis->del( 'perl_redis_test_decrby' );

$redis->lpush( perl_redis_test_list => 1 );

eval { $redis->decrby( 'perl_redis_test_list', 3 ) };

like $@, qr/wrong kind of value/;

ok $redis->del( 'perl_redis_test_list' );

done_testing;

