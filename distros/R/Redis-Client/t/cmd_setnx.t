#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis SETNX command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

my $one  = $redis->setnx( perl_redis_test_setnx => 'foo' );
my $zero = $redis->setnx( perl_redis_test_setnx => 'bar' );
my $val  = $redis->get( 'perl_redis_test_setnx' );

is $one, 1;
is $zero, 0;
is $val, 'foo';

ok $redis->del( 'perl_redis_test_setnx' ); 

done_testing;

