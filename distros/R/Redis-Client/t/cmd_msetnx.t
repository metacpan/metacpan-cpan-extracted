#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis MSETNX command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

my $res = $redis->msetnx( perl_redis_test_msetnx1 => 'foo',
                          perl_redis_test_msetnx2 => 'bar',
                          perl_redis_test_msetnx3 => 'baz' );

my $foo = $redis->get( 'perl_redis_test_msetnx1' );
my $bar = $redis->get( 'perl_redis_test_msetnx2' );
my $baz = $redis->get( 'perl_redis_test_msetnx3' );

is $res, 1;
is $foo, 'foo';
is $bar, 'bar';
is $baz, 'baz';

ok $redis->del( 'perl_redis_test_msetnx1' );
ok $redis->del( 'perl_redis_test_msetnx2' );

my $res2 = $redis->msetnx( perl_redis_test_msetnx1 => 'foo',
                           perl_redis_test_msetnx2 => 'bar',
                           perl_redis_test_msetnx3 => 'baz' );

is $res2, 0;

ok $redis->del( 'perl_redis_test_msetnx3' );

done_testing;

