#!/usr/bin/env perl

use strict;
use warnings;

use lib 't';

use Test::More tests => 11;
use RedisClientTest;
use Redis::Client::String;

use_ok 'RedisClientTest';

eval { 
    tie my $str, 'Redis::Client::String';
};

like $@, qr/^Attribute/;
undef $@;

eval { 
    tie my $str, 'Redis::Client::String', key => 'blorb';
};

like $@, qr/^Attribute.+client/;
undef $@;

SKIP: { 
    my $redis = RedisClientTest->server;

    skip 'No Redis server available', 8 unless $redis;
    
    ok $redis;
    isa_ok $redis, 'Redis::Client';
    
    my $result = $redis->set( perl_redis_test_var => "foobar" );
    
    is $result, 'OK';

    tie my $val, 'Redis::Client::String', key => 'perl_redis_test_var', client => $redis;
    ok tied $val;
    isa_ok tied $val, 'Redis::Client::String';

    is $val, 'foobar';

    $val = 'narf';

    is $val, 'narf';

    ok $redis->del( 'perl_redis_test_var' );
}


