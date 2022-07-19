#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings -allow_deps => 1;

use Net::LibNFS;

eval { require AnyEvent } or do {
    plan skip_all => $@;
};

my $obj = Net::LibNFS->new()->anyevent();
isa_ok($obj, 'Net::LibNFS::Async', 'return from new()');

my $cv = AnyEvent->condvar();

my $p = $obj->mount('localhost', '/home' . rand)->then(
    sub { $cv->croak("should have failed") },
    sub {
        $cv->send(shift);
    },
);

my $err = $cv->recv();

isa_ok(
    $err,
    'Net::LibNFS::X::Base',
    'either localhost isn’t an NFS server, or we connect to nonexistent export',
) or diag explain $err;

ok(
    $err->isa('Net::LibNFS::X::BadConnection') || $err->isa('Net::LibNFS::X::NFSError'),
    'one of the expected error classes',
);

done_testing;
