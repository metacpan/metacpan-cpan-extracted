#!perl

use strict;
use warnings;
use Net::Etcd;
use Test::More;
use Test::Exception;
use Data::Dumper;

my $config;

if ( $ENV{ETCD_TEST_HOST} and $ENV{ETCD_TEST_PORT}) {

    $config->{host}   = $ENV{ETCD_TEST_HOST};
    $config->{port}   = $ENV{ETCD_TEST_PORT};
    $config->{cacert} = $ENV{ETCD_TEST_CAPATH} if $ENV{ETCD_TEST_CAPATH};
    plan tests => 2;
}
else {
    plan skip_all => "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

my $member;
my $etcd = Net::Etcd->new( $config );

# snapshot
lives_ok(
    sub {
        $member = $etcd->member()->list;
    },
    "list members"
);

#print STDERR Dumper($member);
cmp_ok( $member->is_success, '==', 1, "list member success" );

1;
