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
    plan tests => 2;
}
else {
    plan skip_all => "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

my $maint;
my $etcd = Net::Etcd->new( { host => $host, port => $port } );

lives_ok(
    sub {
        $maint = $etcd->maintenance()->snapshot;
    },
    "snapshot create"
);

#print STDERR Dumper($maint);
cmp_ok( $maint->{response}{content}, 'ne', "", "snapshot create" );

1;
