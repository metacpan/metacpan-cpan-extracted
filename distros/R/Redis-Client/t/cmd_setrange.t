#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis SETRANGE command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->set( perl_redis_test_setrange => 'foobar' );
my $length = $redis->setrange( 'perl_redis_test_setrange', 3, 'bazquux' );
my $val = $redis->get( 'perl_redis_test_setrange' );

is $length, 10;
is $val, 'foobazquux';

ok $redis->del( 'perl_redis_test_setrange' );

$redis->lpush( perl_redis_test_list => 1 );

eval { $redis->setrange( 'perl_redis_test_list', 3, 'blah' ) };
like $@, qr/wrong kind of value/;

ok $redis->del( 'perl_redis_test_list' );

done_testing;

