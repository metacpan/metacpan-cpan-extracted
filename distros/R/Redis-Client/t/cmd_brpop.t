#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 't';

use Test::More;

# ABSTRACT: Tests for the Redis BRPOP command.

use_ok 'RedisClientTest';

my $redis = RedisClientTest->server;
done_testing && exit unless $redis;

isa_ok $redis, 'Redis::Client';

$redis->lpush( perl_redis_test_list => 'foo' );
my ( $list, $foo ) = $redis->brpop( 'perl_redis_test_list', 1 );

is $list, 'perl_redis_test_list';
is $foo, 'foo';

my $pid = fork;

if ( !$pid ) { 
    # child
    my $redis2 = RedisClientTest->server;
    sleep 2;
    $redis2->lpush( perl_redis_test_list => 'child' );
    exit;
}

my ( $list2, $val ) = $redis->brpop( 'perl_redis_test_list', 5 );

is $list2, 'perl_redis_test_list';
is $val, 'child';

$redis->set( perl_redis_test_string => 'foo' );
eval { $redis->brpop( 'perl_redis_test_string', 1 ) };

like $@, qr/wrong kind of value/;

$redis->del( 'perl_redis_test_string' );

done_testing;

