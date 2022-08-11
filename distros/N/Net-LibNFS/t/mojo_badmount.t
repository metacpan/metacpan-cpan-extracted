#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings -allow_deps => 1;
use Test::Deep;

use Net::LibNFS;

eval { require Mojo::IOLoop } or do {
    plan skip_all => $@;
};

my $obj = Net::LibNFS->new()->mojo();
isa_ok($obj, 'Net::LibNFS::Async', 'return from mojo()');

my $err;

my $p = $obj->mount('localhost', '/home' . rand)->then(
    sub {
        die "promise OK (?!?)";
        die "should have failed";
    },
    sub {
        $err = shift || 'failure was falsy??';
        die "promise failed ($err)";
    },
)->finally( sub {
    diag "stopping loop";
    Mojo::IOLoop->stop();
} );

diag "starting loop";
Mojo::IOLoop->start();
diag "after loop";

cmp_deeply(
    $err,
    any(
        Isa('Net::LibNFS::X::BadConnection'),
        Isa('Net::LibNFS::X::NFSError'),
    ),
    'got expected error on mount() failure',
) or diag explain $err;

done_testing;
