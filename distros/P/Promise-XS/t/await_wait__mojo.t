#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Promise::XS;

use FindBin;
use lib "$FindBin::Bin/lib";
use AwaitWait;

use Test::FailWarnings -allow_deps => 1;

my $failed_why;

BEGIN {
    eval 'use Mojo::IOLoop; 1' or $failed_why = $@;
}

plan skip_all => "Can’t run test: $failed_why" if $failed_why;

Promise::XS::use_event('Mojo::IOLoop');

AwaitWait::test_success(
    sub {
        my $d = shift;
        Mojo::IOLoop->timer(
            0.1 => sub { $d->resolve(42, 34) },
        );
    },
);

done_testing;
