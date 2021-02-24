#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

BEGIN {
    for my $req ( qw( Future::AsyncAwait  AnyEvent ) ) {
        eval "require $req" or plan skip_all => 'No Future::AsyncAwait';
    }
}

eval { Future::AsyncAwait->VERSION(0.47) } or do {
    plan skip_all => "Future::AsyncAwait ($Future::AsyncAwait::VERSION) is too old.";
};

use Promise::XS;

use Future::AsyncAwait future_class => 'Promise::XS::Promise';

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

async sub thethings {
    await delay(0.1);

    return 5;
}

my $cv = AnyEvent->condvar();

thethings()->then($cv);

my ($got) = $cv->recv();

is $got, 5, 'expected resolution';

done_testing;
