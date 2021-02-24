#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

eval { require AnyEvent } or plan skip_all => 'Need AnyEvent';

diag "Using AnyEvent $AnyEvent::VERSION";

use Promise::AsyncAwait;
use Promise::XS;

sub delay {
    my $secs = shift;

    my $d = Promise::XS::deferred();

    my $timer; $timer = AnyEvent->timer(
        after => $secs,
        cb => sub {
            undef $timer;
            $d->resolve($secs);
        },
    );

    return $d->promise();
}

async sub wait_plus_1 {
    my $num = await delay(0.01);

    return 1 + $num;
}

my $cv = AnyEvent->condvar();
wait_plus_1()->then($cv, sub { $cv->croak(@_) });

my ($got) = $cv->recv();

is($got, 1.01, 'expected result');

done_testing;

1;
