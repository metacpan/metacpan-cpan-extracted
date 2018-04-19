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

my $etcd = Net::Etcd->new($config);

my $key;

# put key/value
lives_ok(
    sub {
        $key = $etcd->put( { key => 'foo1', value => 'bar' } );
    },
    "kv put"
);

cmp_ok( $key->is_success, '==', 1, "kv put success" );

#print STDERR Dumper($key);

# get range
lives_ok(
    sub {
        $key = $etcd->range( { key => 'foo1' } );
    },
    "kv range"
);

cmp_ok( $key->is_success, '==', 1, "kv range success" );

#print STDERR Dumper($key);

# delete range
lives_ok(
    sub {
        $key = $etcd->deleterange( { key => 'foo1' } );
    },
    "kv range_delete"
);

#print STDERR Dumper($key);

cmp_ok( $key->is_success, '==', 1, "kv delete success" );

# verify delete
lives_ok(
    sub {
        $key = $etcd->range( { key => 'foo1' } );
    },
    "kv range against deleted key"
);

is( $key->get_value, undef, "key undef as expected" );

1;
