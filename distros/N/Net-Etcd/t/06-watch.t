#!perl

use strict;
use warnings;
use Net::Etcd;
use Test::More;
use Test::Exception;
use Data::Dumper;
use Cwd;

my $config;
my $dir = getcwd;

if ( $ENV{ETCD_TEST_HOST} and $ENV{ETCD_TEST_PORT} ) {
    $config->{host}      = $ENV{ETCD_TEST_HOST};
    $config->{port}      = $ENV{ETCD_TEST_PORT};
    $config->{ca_file}   = $ENV{ETCD_CLIENT_CA_FILE} || "$dir/t/tls/ca.pem";
    $config->{key_file}  = $ENV{ETCD_CLIENT_KEY_FILE} || "$dir/t/tls/client-key.pem";
    $config->{cert_file} = $ENV{ETCD_CLIENT_CERT_FILE} || "$dir/t/tls/client.pem";
    $config->{ssl}       = 1;
    plan tests => 8;
}
else {
    plan skip_all =>
      "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

my ( $watch, $key );
my $etcd = Net::Etcd->new($config);

our @events;

# create watch with callback and store events
lives_ok(
    sub {
        $watch = $etcd->watch(
            { key => 'foo' },
            sub {
                my ($result) = @_;
                push @events, $result;

                #print STDERR Dumper(undef, $result);
            }
        )->create;
    },
    "watch create"
);

lives_ok(
    sub {
        $key = $etcd->put( { key => 'foo', value => 'bar' } );
    },
    "kv put"
);

#print STDERR Dumper($key);
cmp_ok( $key->is_success, '==', 1, "kv put success" );

# get range
lives_ok(
    sub {
        $key = $etcd->range( { key => 'foo' } );
    },
    "kv range"
);

cmp_ok( $key->is_success, '==', 1, "kv range success" );

#print STDERR Dumper($key);

cmp_ok( scalar @events,
    '==', 2, "number of async events stored. (create_watch, create key)" );

#print STDERR 'events ' . Dumper(@events);

# delete range
lives_ok(
    sub {
        $key = $etcd->deleterange( { key => 'foo' } );
    },
    "kv range_delete"
);

cmp_ok( $key->is_success, '==', 1, "kv delete success" );

1;
