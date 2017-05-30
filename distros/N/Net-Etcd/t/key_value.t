#!perl

use strict;
use warnings;

use Net::Etcd;
use Test::More;
use Test::Exception;
use Data::Dumper;
my ($host, $port);

if ( $ENV{ETCD_TEST_HOST} and $ENV{ETCD_TEST_PORT}) {
    $host = $ENV{ETCD_TEST_HOST};
    $port = $ENV{ETCD_TEST_PORT};
    plan tests => 6;
}
else {
    plan skip_all => "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

my $etcd = Net::Etcd->new( { host => $host, port => $port } );

my $key;

# put key/value
lives_ok(
    sub {
        $key = $etcd->put( { key => 'foo1', value => 'bar' } );
    },
    "kv put"
);

cmp_ok( $key->{response}{success}, '==', 1, "kv put success" );

# get range
lives_ok(
    sub {
        $key = $etcd->range( { key => 'foo1' } )
    },
    "kv range"
);

cmp_ok( $key->{response}{success}, '==', 1, "kv range success" );

#print STDERR Dumper($key);

# delete range
lives_ok(
    sub {
        $key = $etcd->range( { key => 'foo1' } )->delete
    },
    "kv range_delete"
);

#print STDERR Dumper($key);

cmp_ok( $key->{response}{success}, '==', 1, "kv delete success" );

1;
