#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::SSE;

# Step 4 of the sse.close rollout: the framework close() sends the sse.close
# send-event (the server, merged separately, acts on it), carries an optional
# server-side reason, surfaces that reason to on_close, and wakes a parked run()
# so a close from deep in a helper actually ends the stream.

sub make_sse {
    my ($sent) = @_;
    return PAGI::SSE->new(
        { type => 'sse' },
        sub { Future->new },                         # receive: never resolves
        sub { push @$sent, $_[0]; Future->done },    # send: record events
    );
}

subtest 'close() sends an sse.close event carrying the reason' => sub {
    my @sent;
    my $sse = make_sse(\@sent);
    $sse->start->get;
    $sse->close(reason => 'job_done')->get;

    my ($ev) = grep { ($_->{type} // '') eq 'sse.close' } @sent;
    ok($ev, 'an sse.close event was sent');
    is($ev->{reason}, 'job_done', 'reason carried on the event');
};

subtest 'close() without a reason omits the reason field' => sub {
    my @sent;
    my $sse = make_sse(\@sent);
    $sse->start->get;
    $sse->close->get;

    my ($ev) = grep { ($_->{type} // '') eq 'sse.close' } @sent;
    ok($ev, 'an sse.close event was sent');
    ok(!exists $ev->{reason}, 'no reason key when none was given');
};

subtest 'on_close receives the close reason' => sub {
    my @sent;
    my $sse = make_sse(\@sent);
    $sse->start->get;

    my $got;
    $sse->on_close(sub { my ($s, $reason) = @_; $got = $reason });
    $sse->close(reason => 'quota_exhausted')->get;

    is($got, 'quota_exhausted', 'on_close was given the close reason');
};

subtest 'run() returns when close() is called from elsewhere' => sub {
    my @sent;
    my $sse = make_sse(\@sent);
    $sse->start->get;

    my $run_f = $sse->run;                  # parks awaiting receive (never resolves)
    ok(!$run_f->is_ready, 'run() is parked');

    $sse->close(reason => 'app_closed')->get;   # close from "a helper"

    ok($run_f->is_ready, 'run() completed after close()');
};

done_testing;
