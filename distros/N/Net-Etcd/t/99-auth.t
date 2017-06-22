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

    plan tests => 8;
}
else {
    plan skip_all => "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

my $etcd = Net::Etcd->new( { host => $host, port => $port, name => 'root', password => 'toor' } );

my ($user, $role, $auth);

# add user
lives_ok(
    sub {
        $user =
          $etcd->user( { name => 'root', password => 'toor' } )->add;
    },
    "add a new user"
);

#print STDERR Dumper($user);

# add new role
lives_ok( sub { $role = $etcd->role( { name => 'root' } )->add;
    },
    "add a new role" );

#print STDERR Dumper($role);

# grant role
lives_ok(
    sub {
        $role =
          $etcd->user_role( { user => 'root', role => 'root' } )->grant;
    },
    "grant role"
);

#print STDERR Dumper($role);

cmp_ok( $role->{response}{success}, '==', 1, "grant role success" );

# enable auth
lives_ok(
    sub {
        $auth =
          $etcd->auth()->enable;
    },
    "enable auth"
);

cmp_ok( $auth->{response}{success}, '==', 1, "enable auth" );

# disable auth
lives_ok(
    sub {
        $auth =
          $etcd->auth()->disable;
    },  
    "disable auth"
);

cmp_ok( $auth->{response}{success}, '==', 1, "disable auth" );

1;
