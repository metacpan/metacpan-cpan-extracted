#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use lib 't';

use Encode;
use Test::More tests => 4;

use_ok 'RedisClientTest';

SKIP: { 
    my $redis = RedisClientTest->server;
    
    skip 'No Redis server available', 3 unless $redis;
    
    ok $redis;
    isa_ok $redis, 'Redis::Client';

    my $str = '你好，世界';
    my $encoded_str = encode 'utf8', $str;

    my $res = $redis->echo( $encoded_str );
    
    my $decoded_res = decode 'utf8', $res;

    is $decoded_res, $str;

}

