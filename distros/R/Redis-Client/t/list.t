#!/usr/bin/env perl

use strict;
use warnings;

use lib 't';

use Test::More tests => 34;
use RedisClientTest;
use Redis::Client::List;

use_ok 'RedisClientTest';

eval { 
    tie my @list, 'Redis::Client::List';
};

like $@, qr/^Attribute/;
undef $@;

eval { 
    tie my @list, 'Redis::Client::List', key => 'blorb';
};

like $@, qr/^Attribute.+client/;
undef $@;

SKIP: { 
    my $redis = RedisClientTest->server;

    skip 'No Redis server available', 31 unless $redis;
    
    ok $redis;
    isa_ok $redis, 'Redis::Client';
    
    for ( 1 .. 5 ) { 
        my $result = $redis->rpush( perl_redis_test_list => $_ );
        is $result, $_;
    }

    tie my @list, 'Redis::Client::List', key => 'perl_redis_test_list', client => $redis;

    ok @list == 5;

    for ( 1 .. 5 ) { 
        is $list[ $_ - 1 ], $_;
    }

    push @list, 'narf';
    ok @list == 6;
    is $list[5], 'narf';
    is $redis->lindex( 'perl_redis_test_list', 5 ), 'narf';


    push @list, 'foo', 'bar', 'baz';
    ok @list == 9;
    is $list[6], 'foo';
    is $list[7], 'bar';
    is $list[8], 'baz';

    my $item = shift @list;
    ok @list == 8;
    is $item, 1;

    my $item2 = pop @list;
    ok @list == 7;
    is $item2, 'baz';

    unshift @list, 'poit';
    ok @list == 8;
    is $list[0], 'poit';

    unshift @list, 'alpha', 'beta', 'charlie';
    ok @list == 11;
    is $list[0], 'charlie';
    is $list[1], 'beta';
    is $list[2], 'alpha';

    ok $redis->del( 'perl_redis_test_list' );
}
