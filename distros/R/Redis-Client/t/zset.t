#!/usr/bin/env perl

use strict;
use warnings;

use lib 't';

use Test::More tests => 28;
use Data::Dumper;

use RedisClientTest;
use Redis::Client::Zset;


use_ok 'RedisClientTest';

eval { 
    tie my %zset, 'Redis::Client::Zset';
};

like $@, qr/^Attribute/;
undef $@;

eval { 
    tie my %zset, 'Redis::Client::Zset', key => 'blorb';
};

like $@, qr/^Attribute.+client/;
undef $@;

SKIP: { 
    my $redis = RedisClientTest->server;

    skip 'No Redis server available', 25 unless $redis;
    
    ok $redis;
    isa_ok $redis, 'Redis::Client';

    my $val = 0;
    for( 'A' .. 'E' ) {
        my $result = $redis->zadd( 'perl_redis_test_zset', $val++, $_ );
        is $result, 1;
    }

    tie my %zset, 'Redis::Client::Zset', key => 'perl_redis_test_zset', client => $redis;

    for( 'F', 'G', 'H' ) { 
        $zset{$_} = $val++;
    }

    ok $zset{F};
    ok $zset{G};
    ok $zset{H};

    my @members = keys %zset; 
    my $tval = 0;
    foreach my $m( @members ) { 
        my $splort = ( $zset{$m} = ++$tval );
        is $splort, $tval;
    }

    ok exists $zset{A};
    ok !exists $zset{narf};

    ok delete $zset{C};
    ok !exists $zset{C};

    # %zset = ( );
    # my @members2 = keys %zset;
    # ok @members2 == 0;

    $zset{blorp} = 2;
    ok exists $zset{blorp};

    my $score = delete $zset{blorp};
    is $score, 2;

    my $del_res = $redis->del( 'perl_redis_test_zset' );
    is $del_res, 1;
}


