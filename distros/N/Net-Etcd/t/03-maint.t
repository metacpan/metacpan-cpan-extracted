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

my $maint;
my $etcd = Net::Etcd->new($config);

# snapshot
lives_ok(
    sub {
        $maint = $etcd->maintenance()->snapshot;
    },
    "snapshot create"
);

#print STDERR Dumper($maint);
cmp_ok( $maint->{response}{content}, 'ne', "", "snapshot create" );

# status
lives_ok(
    sub {
        $maint = $etcd->maintenance()->status;
    },
    "check status"
);

#print STDERR Dumper($maint);
cmp_ok( $maint->is_success, '==', 1, "check status success" );

# defragment
lives_ok(
    sub {
        $maint = $etcd->maintenance()->defragment;
    },
    "defragment request"
);

#print STDERR Dumper($maint);
cmp_ok( $maint->is_success, '==', 1, "defragment request success" );
my $version;

# version helper
lives_ok(
    sub {
        $version = $etcd->version;
    },
    "version"
);

cmp_ok( $version, 'ne', "", "version success" );

1;
