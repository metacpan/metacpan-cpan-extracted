#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Promise::XS;

use FindBin;
use lib "$FindBin::Bin/lib";
use AwaitWait;

my $failed_why;

BEGIN {
    eval 'use AnyEvent; 1' or $failed_why = $@;
}

plan skip_all => "Can’t run test: $failed_why" if $failed_why;

Promise::XS::use_event('AnyEvent');

AwaitWait::test_success(
    sub {
        my $d = shift;
        AnyEvent->timer(
            after => 0.1, cb => sub { $d->resolve(42, 34) },
        );
    },
);

done_testing;
