#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Promise::XS;

use Test::FailWarnings -allow_deps => 1;

use FindBin;
use lib "$FindBin::Bin/lib";
use AwaitWait;

my $failed_why;

BEGIN {
    eval 'use IO::Async::Loop; 1' or $failed_why = $@;
}

plan skip_all => "Can’t run test: $failed_why" if $failed_why;

my $loop = IO::Async::Loop->new();

Promise::XS::use_event('IO::Async', $loop);

AwaitWait::test_success(
    sub {
        my $d = shift;
        $loop->later( sub { $d->resolve(42, 34) } );
    },
);

done_testing;
