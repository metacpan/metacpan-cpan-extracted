#!perl

use strict;
use warnings;

use Net::Etcd;
use Test::More;
use Test::Exception;
use Math::Int64 qw(int64_rand int64_to_string);
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
    $config->{ca_file}   = "$dir/t/tls/ca.pem";
    $config->{key_file}  = "$dir/t/tls/client-key.pem";
    $config->{cert_file} = "$dir/t/tls/client.pem";
    $config->{ssl}       = 1;
    plan tests => 16;
}
else {
    plan skip_all =>
      "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

my $etcd = Net::Etcd->new($config);

my $lease;
my $int64    = int64_rand();
my $lease_id = int64_to_string($int64);

# add lease
lives_ok(
    sub {
        $lease = $etcd->lease( { ID => $lease_id, TTL => 20 } )->grant;
    },
    "add a new lease"
);

cmp_ok( $lease->is_success, '==', 1, "add lease success" );

# add lease to key
lives_ok(
    sub {
        $lease =
          $etcd->put( { key => 'foo2', value => 'bar2', lease => $lease_id } );
    },
    "add a new lease to a key"
);

cmp_ok( $lease->is_success, '==', 1, "add lease to key success" );

my $key;

# validate key
lives_ok( sub { $key = $etcd->range( { key => 'foo2' } )->get_value },
    "check value for key" );

cmp_ok( $key, 'eq', 'bar2', "lease key value" );

# lease keep alive
lives_ok( sub { $lease = $etcd->lease( { ID => $lease_id } )->keepalive },
    "lease_keep_alive" );

#print STDERR Dumper($lease);

cmp_ok( $lease->is_success, '==', 1, "reset lease keep alive success" );

# lease ttl
lives_ok( sub { $lease = $etcd->lease( { ID => $lease_id, keys => 1 } )->ttl },
    "lease_ttl" );

cmp_ok( $lease->is_success, '==', 1, "return lease_ttl success" );

#print STDERR Dumper($lease);

# lease leases
lives_ok( sub { $lease = $etcd->lease()->leases }, "lease_leases" );

cmp_ok( $lease->is_success, '==', 1, "return lease_leases success" );

#print STDERR Dumper($lease);

# revoke lease
lives_ok( sub { $lease = $etcd->lease( { ID => $lease_id } )->revoke },
    "revoke lease" );

#print STDERR Dumper($lease);

cmp_ok( $lease->is_success, '==', 1, "revoke lease success" );

# validate key
lives_ok( sub { $key = $etcd->range( { key => 'foo2' } )->get_value },
    "check value for revoked lease key" );

is( $key, undef, "lease key revoked" );

1;

