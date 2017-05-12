#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis DECR command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->set( perl_redis_test_decr => 3 );
my $new = $redis->decr( 'perl_redis_test_decr' );

is $new, 2;

ok $redis->del( 'perl_redis_test_decr' );

$redis->lpush( perl_redis_test_list => 1 );

eval { $redis->decr( 'perl_redis_test_list' ) };

like $@, qr/wrong kind of value/;

ok $redis->del( 'perl_redis_test_list' );

done_testing;

