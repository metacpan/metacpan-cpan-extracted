#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 'lib';
use PAGI::Test::Client;

# Simple SSE app
my $sse_app = async sub {
    my ($scope, $receive, $send) = @_;
    die "Expected sse scope" unless ($scope->{type} // '') eq 'sse';

    await $send->({
        type    => 'sse.start',
        status  => 200,
        headers => [],
    });

    await $send->({
        type  => 'sse.send',
        event => 'connected',
        data  => '{"subscriber_id":1}',
    });

    await $send->({
        type => 'sse.send',
        data => 'plain message',
    });

    await $send->({
        type  => 'sse.send',
        event => 'update',
        data  => '{"count":42}',
        id    => 'msg-1',
    });
};

subtest 'sse receive events' => sub {
    my $client = PAGI::Test::Client->new(app => $sse_app);
    $client->sse('/events', sub {
        my ($sse) = @_;

        my $event = $sse->receive_event;
        is $event->{event}, 'connected', 'first event type';
        is $event->{data}, '{"subscriber_id":1}', 'first event data';

        my $plain = $sse->receive_event;
        is $plain->{data}, 'plain message', 'plain message data';
        ok !defined $plain->{event}, 'no event type for plain';

        my $update = $sse->receive_event;
        is $update->{event}, 'update', 'update event type';
        is $update->{id}, 'msg-1', 'event id';
    });
};

subtest 'sse receive_json convenience' => sub {
    my $client = PAGI::Test::Client->new(app => $sse_app);
    $client->sse('/events', sub {
        my ($sse) = @_;
        my $data = $sse->receive_json;
        is $data->{subscriber_id}, 1, 'json parsed';
    });
};

subtest 'sse explicit style' => sub {
    my $client = PAGI::Test::Client->new(app => $sse_app);
    my $sse = $client->sse('/events');
    my $event = $sse->receive_event;
    is $event->{event}, 'connected', 'explicit style works';
    $sse->close;
};

done_testing;
