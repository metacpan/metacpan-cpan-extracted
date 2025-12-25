#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::SSE;

subtest 'try_send returns true on success' => sub {
    my $send = sub { Future->done };
    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, $send);
    $sse->start->get;

    my $result = $sse->try_send("Hello")->get;
    ok($result, 'try_send returns true on success');
};

subtest 'try_send returns false when closed' => sub {
    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, sub { Future->done });
    $sse->_set_closed;

    my $result = $sse->try_send("Hello")->get;
    ok(!$result, 'try_send returns false when closed');
};

subtest 'try_send returns false on send error' => sub {
    my $send = sub { Future->fail("Connection lost") };
    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, $send);
    # Mark as started to avoid auto-start
    $sse->_set_state('started');

    my $result = $sse->try_send("Hello")->get;
    ok(!$result, 'try_send returns false on error');
    ok($sse->is_closed, 'connection marked as closed after error');
};

subtest 'try_send_json works' => sub {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };
    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, $send);
    $sse->start->get;

    my $result = $sse->try_send_json({ foo => 'bar' })->get;
    ok($result, 'try_send_json returns true');
    like($sent[1]{data}, qr/"foo"/, 'JSON was sent');
};

subtest 'try_send_event works' => sub {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };
    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, $send);
    $sse->start->get;

    my $result = $sse->try_send_event(
        data  => 'test',
        event => 'ping',
    )->get;

    ok($result, 'try_send_event returns true');
    is($sent[1]{event}, 'ping', 'event name sent');
};

done_testing;
