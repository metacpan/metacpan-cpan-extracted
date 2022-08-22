#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings -allow_deps => 1;

if ($^V ge v5.16.0 && $^V le v5.25.0) {
    plan skip_all => "Future::AsyncAwait breaks on this perl ($^V). See https://rt.cpan.org/Public/Bug/Display.html?id=137723.";
}

use Promise::XS;

BEGIN {
    for my $req ( qw( Future::AsyncAwait  AnyEvent ) ) {
        eval "require $req" or plan skip_all => 'No Future::AsyncAwait';
    }

    eval { Future::AsyncAwait->VERSION(0.47) } or do {
        plan skip_all => "Future::AsyncAwait ($Future::AsyncAwait::VERSION) is too old.";
    };
}

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
