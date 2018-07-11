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
    plan tests => 21;
}
else {
    plan skip_all =>
      "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

my $etcd = Net::Etcd->new($config);

my ( $user, $role );

# add user
lives_ok(
    sub {
        $user = $etcd->user( { name => 'samba', password => 'foo' } )->add;
    },
    "add a new user"
);

#print STDERR Dumper($user);

cmp_ok( $user->is_success, '==', 1, "add new user success" );

# add new role
lives_ok(
    sub {
        $role = $etcd->role( { name => 'myrole' } )->add;
    },
    "add a new role"
);

#print STDERR Dumper($role);

cmp_ok( $role->is_success, '==', 1, "add new role success" );

# role get
lives_ok(
    sub {
        $role = $etcd->role( { role => 'myrole' } )->get;
    },
    "get role"
);
cmp_ok( $role->is_success, '==', 1, "get role success" );

#print STDERR Dumper($role);

lives_ok(
    sub {
        $role =
          $etcd->role_perm(
            { name => 'myrole', key => 'foo', permType => 'READ', range_end => "\0" } )->grant;
    },
    "role_perm grant"
);

#print STDERR Dumper($role);

cmp_ok( $role->is_success, '==', 1, "role_perm grant success" );

lives_ok(
    sub {
        $role =
          $etcd->role_perm(
            { name => 'myrole', key => 'bar', permType => 'READ', prefix => 1 } )->grant;
    },
    "role_perm grant with prefix"
);

#print STDERR Dumper($role);

cmp_ok( $role->is_success, '==', 1, "role_perm grant with prefix success" );


# grant role
lives_ok(
    sub {
        $role =
          $etcd->user_role( { user => 'samba', role => 'myrole' } )->grant;
    },
    "grant role"
);

#print STDERR Dumper($role);

cmp_ok( $role->is_success, '==', 1, "grant role success" );

# list role
lives_ok(
    sub {
        $role = $etcd->role->list;
    },
    "list role"
);

cmp_ok( $role->is_success, '==', 1, "list role success" );

#print STDERR Dumper($role);

# revoke role
lives_ok(
    sub {
        $role = $etcd->role_perm( { role => 'myrole', key => 'foo' } )->revoke;
    },
    "role_perm revoke"
);

# revoke role
lives_ok(
    sub {
        $user =
          $etcd->user_role( { name => 'samba', role => 'myrole' } )->revoke;
    },
    "remove role from user"
);

cmp_ok( $user->is_success, '==', 1, "revoke role success" );

#print STDERR Dumper($user);

# delete role
lives_ok( sub { $user = $etcd->role( { role => 'myrole' } )->delete; },
    "delete role" );

cmp_ok( $user->is_success, '==', 1, "role delete success" );

# delete user
lives_ok( sub { $user = $etcd->user( { name => 'samba' } )->delete; },
    "deleted user" );

#print STDERR Dumper($user);

cmp_ok( $user->is_success, '==', 1, "delete user success" );

1;
