#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Promise::XS;

my $failed_why;

BEGIN {
    eval 'use Test::Future::AsyncAwait::Awaitable; 1' or $failed_why = $@;

    if (!$failed_why) {
        eval 'require Future::AsyncAwait' or $failed_why = $@;
    }

    plan skip_all => "Can’t run test: $failed_why" if $failed_why;
}

use Future::AsyncAwait;

SKIP: {
    eval 'require AnyEvent' or skip $@, 1;

    Promise::XS::use_event('AnyEvent');

    my $timer_cr = sub {
        my $d = Promise::XS::deferred();

        my $t;
        $t = AnyEvent->timer(
            after => 0.01,
            cb => sub {
                $d->resolve(42, 53);
                undef $t;
            },
        );

        return $d->promise();
    };

    my $label = 'AnyEvent';

    my @vals = await $timer_cr->();
    is_deeply(\@vals, [42, 53], "$label: await() return");

    @vals = await $timer_cr->();
    is_deeply(\@vals, [42, 53], "$label: await() return (redux)");

    @vals = await $timer_cr->();
    is_deeply(\@vals, [42, 53], "$label: await() return (yet again)");
}

SKIP: {
    eval 'require IO::Async::Loop' or skip $@, 1;

    my $loop = IO::Async::Loop->new();

    Promise::XS::use_event('IO::Async', $loop);

    my $timer_cr = sub {
        my $d = Promise::XS::deferred();

        $loop->watch_time(
            after => 0.01,
            code => sub {
                $d->resolve(42, 53);
            },
        );

        return $d->promise();
    };

    my $label = 'IO::Async';

    my @vals = await $timer_cr->();
    is_deeply(\@vals, [42, 53], "$label: await() return");

    @vals = await $timer_cr->();
    is_deeply(\@vals, [42, 53], "$label: await() return (redux)");

    @vals = await $timer_cr->();
    is_deeply(\@vals, [42, 53], "$label: await() return (yet again)");
}

SKIP: {
    eval 'require Mojo::IOLoop' or skip $@, 1;

    Promise::XS::use_event('Mojo::IOLoop');

    my $timer_cr = sub {
        my $d = Promise::XS::deferred();

        Mojo::IOLoop->timer( 0.01, $d->resolve(42, 53) );

        return $d->promise();
    };

    my $label = 'Mojo';

    my @vals = await $timer_cr->();
    is_deeply(\@vals, [42, 53], "$label: await() return");

    @vals = await $timer_cr->();
    is_deeply(\@vals, [42, 53], "$label: await() return (redux)");

    @vals = await $timer_cr->();
    is_deeply(\@vals, [42, 53], "$label: await() return (yet again)");
}

done_testing();
