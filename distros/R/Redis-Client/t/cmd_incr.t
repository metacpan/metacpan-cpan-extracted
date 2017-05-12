#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis INCR command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->set( perl_redis_test_incr => 3 );
my $new = $redis->incr( 'perl_redis_test_incr' );

is $new, 4;

ok $redis->del( 'perl_redis_test_incr' );

$redis->lpush( perl_redis_test_list => 1 );

eval { $redis->incr( 'perl_redis_test_list' ) };

like $@, qr/wrong kind of value/;

ok $redis->del( 'perl_redis_test_list' );


done_testing;

