#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis GETBIT command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->set( perl_redis_test_getbit => 'A' );    # 0100 0001
my $one  = $redis->getbit( 'perl_redis_test_getbit', 7 );
my $zero = $redis->getbit( 'perl_redis_test_getbit', 3 );

is $one, 1;
is $zero, 0;

ok $redis->del( 'perl_redis_test_getbit' );

$redis->lpush( perl_redis_test_list => 1 );

eval { $redis->getbit( 'perl_redis_test_list', 3 ) };

like $@, qr/wrong kind of value/;

done_testing;

