#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis MGET command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->set( perl_redis_test_mget_1 => 'foo' );
$redis->set( perl_redis_test_mget_2 => 'bar' );
$redis->set( perl_redis_test_mget_3 => 'baz' );

my @vals = $redis->mget( 'perl_redis_test_mget_1', 
                         'perl_redis_test_blargh', 
                         'perl_redis_test_mget_2', 
                         'perl_redis_test_mget_3' );

is $vals[0], 'foo';
is $vals[1], undef;
is $vals[2], 'bar';
is $vals[3], 'baz';

ok $redis->del( 'perl_redis_test_mget_1' );
ok $redis->del( 'perl_redis_test_mget_2' );
ok $redis->del( 'perl_redis_test_mget_3' );


done_testing;

