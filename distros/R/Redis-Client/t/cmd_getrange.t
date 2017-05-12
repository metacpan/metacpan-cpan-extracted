#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis GETRANGE command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->set( perl_redis_test_getrange => 'foobarbaz' );

my $foo = $redis->getrange( 'perl_redis_test_getrange', 0, 2 );
my $bar = $redis->getrange( 'perl_redis_test_getrange', 3, 5 );
my $baz = $redis->getrange( 'perl_redis_test_getrange', -3, -1 );
my $all = $redis->getrange( 'perl_redis_test_getrange', 0, -1 );

is $foo, 'foo';
is $bar, 'bar';
is $baz, 'baz';
is $all, 'foobarbaz';

ok $redis->del( 'perl_redis_test_getrange' );

$redis->lpush( perl_redis_test_list => 1 );

eval { $redis->getrange( 'perl_redis_test_list', 1, 2 ) };

like $@, qr/wrong kind of value/;

ok $redis->del( 'perl_redis_test_list' );

done_testing;

