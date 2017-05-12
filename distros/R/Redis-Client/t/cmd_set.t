#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis SET command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->set( perl_redis_test_set => 'yabbity' );
my $val = $redis->get( 'perl_redis_test_set' );

is $val, 'yabbity';

ok $redis->del( 'perl_redis_test_set' );

done_testing;

