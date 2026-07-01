#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::SSE;

# Regression for S2: PAGI::SSE::close() is a synchronous method that drives the
# async _run_close_callbacks via ->get (SSE.pm:550). An on_close callback that
# suspends on a not-yet-ready Future (real async I/O -- e.g. DB cleanup) cannot
# complete: ->get on a pending Future dies (plain Future) or re-enters the event
# loop (IO::Async, deadlock-prone when close() is called from inside the loop).
# The async dispatch paths (run/disconnect) already `await` the callbacks; only
# the public close() uses ->get. close() must await the callbacks too.

subtest 'close() awaits a suspending async on_close instead of dying' => sub {
    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, sub { Future->done });
    $sse->start->get;

    my $gate = Future->new;          # pending: the async I/O the callback awaits
    my $cleanup_ran = 0;
    $sse->on_close(async sub { await $gate; $cleanup_ran = 1; return });

    # PRIMARY contract: close() must not blow up when a callback suspends.
    # Current sync close() does ->get on a still-pending Future and dies here.
    my $close_f = eval { $sse->close };
    my $err = $@;
    ok($close_f, 'close() did not die when an on_close callback suspended')
        or diag("close() threw: $err");

    if ($close_f) {
        $gate->done;
        Future->wrap($close_f)->get;
        ok($cleanup_ran, 'async on_close ran to completion via close()');
    }
};

# Same defect, seen through a real application: an SSE app that streams an event,
# registers an async cleanup (e.g. release a subscription / close a DB handle),
# then explicitly closes the stream -- a completely ordinary "done streaming"
# flow. The app uses the forward-looking idiom `await $sse->close`.
subtest 'an SSE app that closes after streaming, with async cleanup, does not crash' => sub {
    my @sent;
    my $send    = sub { push @sent, $_[0]; Future->done };
    my $receive = sub { Future->new };   # client never disconnects on its own

    my $gate        = Future->new;       # the async cleanup's I/O
    my $cleanup_ran = 0;

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        my $sse = PAGI::SSE->new($scope, $receive, $send);
        await $sse->start;
        $sse->on_close(async sub { await $gate; $cleanup_ran = 1; return });
        await $sse->send("hello");
        await $sse->close;               # app is done; close the stream
    };

    my $app_f = $app->({ type => 'sse' }, $receive, $send);

    # Release the cleanup's I/O so a correctly-awaiting close() can finish.
    $gate->done;

    my $lived = eval { $app_f->get; 1 };
    my $err = $@;
    ok($lived, 'SSE app that closes after streaming did not crash')
        or diag("app died: $err");
    # Guarded by $lived so a resumed orphan coroutine can't fake a green here.
    ok($lived && $cleanup_ran, 'async on_close cleanup completed as part of close()');
};

done_testing;
