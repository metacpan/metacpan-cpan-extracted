#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis SETBIT command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->set( perl_redis_test_setbit => 'A' );    # 0100 0001
my $one  = $redis->setbit( 'perl_redis_test_setbit', 7, 0 );
my $zero = $redis->setbit( 'perl_redis_test_setbit', 3, 1 );

is $one, 1;
is $zero, 0;

my $zero2 = $redis->getbit( 'perl_redis_test_setbit', 7 );
my $one2  = $redis->getbit( 'perl_redis_test_setbit', 3 );

is $zero2, 0;
is $one2, 1;

eval { $redis->setbit( 'perl_redis_test_setbit', 7, 2 ) };
like $@, qr/not an integer or out of range/;

ok $redis->del( 'perl_redis_test_setbit' );

$redis->lpush( perl_redis_test_list => 1 );

eval { $redis->setbit( 'perl_redis_test_list', 3, 0 ) };

like $@, qr/wrong kind of value/;

done_testing;

