#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis MSET command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->mset( perl_redis_test_mset_1 => 'foo', 
              perl_redis_test_mset_2 => 'bar', 
              perl_redis_test_mset_3 => 'baz' );

my $val1 = $redis->get( 'perl_redis_test_mset_1' );
my $val2 = $redis->get( 'perl_redis_test_mset_2' );
my $val3 = $redis->get( 'perl_redis_test_mset_3' );

is $val1, 'foo';
is $val2, 'bar';
is $val3, 'baz';

ok $redis->del( 'perl_redis_test_mset_1' );
ok $redis->del( 'perl_redis_test_mset_2' );
ok $redis->del( 'perl_redis_test_mset_3' );


done_testing;

