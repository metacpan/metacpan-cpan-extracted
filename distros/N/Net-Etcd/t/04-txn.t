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
    plan tests => 14;
}
else {
    plan skip_all => "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

my ($put, $comp, $range, @op, @compare, $txn);
my $etcd = Net::Etcd->new( { host => $host, port => $port } );

my @chars = ("A".."Z", "a".."z");

# gen random key so we can kee[ it realz
my $rand_key;
$rand_key .= $chars[rand @chars] for 1..8;

lives_ok(
    sub {
        $put = $etcd->put( { key => $rand_key , value => 'randy' } );
    },
    "put random key"
);

cmp_ok( $put->{response}{success}, '==', 1, "create static key success" );

lives_ok(
    sub {
        $put = $etcd->put( { key => 'foozilla', value => 'baz' } );
    },
    "put key"
);

cmp_ok( $put->{response}{success}, '==', 1, "put key success" );

#print STDERR Dumper($put);

lives_ok(
    sub {
        $put = $etcd->put( { key => 'foo', value => 'bar', hold => 1 } );
    },
    "put hold create"
);

#print STDERR Dumper($put);


lives_ok(
    sub {
        push @op, $etcd->op( { request_put => $put } );
    },
    "op request_put create"
);

#print STDERR Dumper(\@op);

lives_ok(
    sub {
        push @compare, $etcd->compare( { key => 'foozilla', result => 'EQUAL', target => 'VALUE', value => 'baz' });
    },
    "compare create"
);

#print STDERR Dumper(\@compare);

lives_ok(
    sub {
        $txn = $etcd->txn( { compare => \@compare, success => \@op } );
    },
    "txn create"
);

cmp_ok( $txn->{response}{success}, '==', 1, "txn create success" );

#print STDERR Dumper($txn);

# make a cleanup txn
undef @op;
undef @compare;
undef $txn;

lives_ok(
    sub {
        $comp =  $etcd->compare( { key => $rand_key, target => 'CREATE', result => 'NOT_EQUAL', create_revision => '0' });
        push @compare, $comp;
    },
    "compare create"
);

#print STDERR Dumper($comp);


lives_ok(
    sub {
        $range = $etcd->range( { key => 'foozilla', hold => 1 } );
    },
    "range hold create"
);

lives_ok(
    sub {
        push @op, $etcd->op( { request_delete_range => $range } );
    },
    "op request_delete create"
);

lives_ok(
    sub {
        $txn = $etcd->txn( { compare => \@compare, success => \@op } );
    },
    "compare create"
);

cmp_ok( $txn->{response}{success}, '==', 1, "txn create cleanup success" );
#print STDERR Dumper($txn);

1;
