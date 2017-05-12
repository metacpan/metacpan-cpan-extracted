#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis APPEND command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->set( perl_redis_test_append => 'foo' );

my $length = $redis->append( perl_redis_test_append => 'bar' );

is $length, 6;

my $new = $redis->get( 'perl_redis_test_append' );

is $new, 'foobar';

ok $redis->del( 'perl_redis_test_append' );

$redis->lpush( perl_redis_test_list => 1 );
eval { $redis->append( perl_redis_test_list => 2 ) };

like $@, qr/wrong kind of value/;

ok $redis->del( 'perl_redis_test_list' );

done_testing;

