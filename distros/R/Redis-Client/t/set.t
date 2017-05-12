#!/usr/bin/env perl

use strict;
use warnings;

use lib 't';

use Test::More tests => 29;
use Data::Dumper;

use RedisClientTest;
use Redis::Client::Set;


use_ok 'RedisClientTest';

eval { 
    tie my %set, 'Redis::Client::Set';
};

like $@, qr/^Attribute/;
undef $@;

eval { 
    tie my %set, 'Redis::Client::Set', key => 'blorb';
};

like $@, qr/^Attribute.+client/;
undef $@;

SKIP: { 
    my $redis = RedisClientTest->server;

    skip 'No Redis server available', 26 unless $redis;
    
    ok $redis;
    isa_ok $redis, 'Redis::Client';

    for( 'A' .. 'E' ) {
        my $result = $redis->sadd( 'perl_redis_test_set', $_ );
        is $result, 1;
    }

    tie my %set, 'Redis::Client::Set', key => 'perl_redis_test_set', client => $redis;

    for( 'F', 'G', 'H' ) { 
        $set{$_} = undef;
    }

    ok exists $set{F};
    ok exists $set{G};
    ok exists $set{H};

    ok $redis->sismember( 'perl_redis_test_set', 'H' );

    my %members = map { $_ => 1 } keys %set; 
    foreach my $m( 'A' .. 'H' ) { 
        ok $members{$m};
    }

    ok exists $set{A};
    ok !exists $set{narf};

    ok delete $set{C};
    ok !exists $set{C};

    %set = ( );
    my @members2 = keys %set;
    ok @members2 == 0;

    $set{blorp} = undef;
    ok exists $set{blorp};

    ok $redis->del( 'perl_redis_test_set' );
}
