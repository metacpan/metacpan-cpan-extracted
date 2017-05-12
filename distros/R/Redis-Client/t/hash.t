#!/usr/bin/env perl

use strict;
use warnings;

use lib 't';

use Test::More tests => 38;
use Data::Dumper;

use RedisClientTest;
use Redis::Client::Hash;


use_ok 'RedisClientTest';

eval { 
    tie my %hash, 'Redis::Client::Hash';
};

like $@, qr/^Attribute/;
undef $@;

eval { 
    tie my %hash, 'Redis::Client::Hash', key => 'blorb';
};

like $@, qr/^Attribute.+client/;
undef $@;

SKIP: { 
    my $redis = RedisClientTest->server;

    skip 'No Redis server available', 35 unless $redis;
    
    ok $redis;
    isa_ok $redis, 'Redis::Client';

    my $val = 0;
    for( 'A' .. 'E' ) {
        my $result = $redis->hset( 'perl_redis_test_hash', $_ => ++$val );
        is $result, 1;
    }

    tie my %hash, 'Redis::Client::Hash', key => 'perl_redis_test_hash', client => $redis;

    for( 'F', 'G', 'H' ) { 
        $hash{$_} = ++$val;
    }

    is $hash{F}, 6;
    is $hash{G}, 7;
    is $hash{H}, 8;

    is $redis->hget( 'perl_redis_test_hash', 'H' ), 8;

    my @keys = sort { $a cmp $b } keys %hash;

    my $i = 0;
    for ( 'A' .. 'H' ) { 
        is $keys[$i++], $_;
    }

    ok exists $hash{A};
    ok !exists $hash{narf};

    my $dval = delete $hash{C};
    is $dval, 3;
    is $hash{C}, undef;

    my @vals = sort { $a <=> $b } values %hash;
    is $vals[0], 1;
    is $vals[1], 2;
    is $vals[2], 4;
    is $vals[3], 5;
    is $vals[4], 6;
    is $vals[5], 7;
    is $vals[6], 8;

    %hash = ( );

    my @keys2 = keys %hash;
    ok @keys2 == 0;

    my @vals2 = values %hash;
    ok @vals2 == 0;

    $hash{foo} = 42;
    ok exists $hash{foo};
    is $hash{foo}, 42;

    ok $redis->del( 'perl_redis_test_hash' );
}
