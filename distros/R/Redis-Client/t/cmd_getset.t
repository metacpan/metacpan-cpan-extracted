#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis GETSET command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->set( perl_redis_test_getset => 'foo' );
my $old = $redis->getset( perl_redis_test_getset => 'bar' );
my $new = $redis->get( 'perl_redis_test_getset' );

is $old, 'foo';
is $new, 'bar';

ok $redis->del( 'perl_redis_test_getset' );

my $old2 = $redis->getset( perl_redis_test_getset => 'bar' );
is $old2, undef;
ok $redis->del( 'perl_redis_test_getset' );

$redis->lpush( perl_redis_test_list => 1 );

eval { $redis->getset( perl_redis_test_list => 'foo' ) };

like $@, qr/wrong kind of value/;

done_testing;

