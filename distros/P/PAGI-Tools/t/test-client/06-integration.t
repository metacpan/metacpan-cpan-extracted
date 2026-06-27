#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 'lib';
use PAGI::Test::Client;

# Realistic app with routing
my $app = async sub {
    my ($scope, $receive, $send) = @_;

    my $type = $scope->{type} // 'http';
    my $path = $scope->{path} // '/';
    my $method = $scope->{method} // 'GET';

    # Lifespan handling
    if ($type eq 'lifespan') {
        my $event = await $receive->();
        if ($event->{type} eq 'lifespan.startup') {
            $scope->{state}{counter} = 0;
            await $send->({ type => 'lifespan.startup.complete' });
        }
        $event = await $receive->();
        if ($event->{type} eq 'lifespan.shutdown') {
            await $send->({ type => 'lifespan.shutdown.complete' });
        }
        return;
    }

    # WebSocket echo
    if ($type eq 'websocket') {
        await $receive->();  # connect
        await $send->({ type => 'websocket.accept' });
        while (1) {
            my $msg = await $receive->();
            last if $msg->{type} eq 'websocket.disconnect';
            await $send->({ type => 'websocket.send', text => $msg->{text} }) if defined $msg->{text};
        }
        return;
    }

    # SSE events
    if ($type eq 'sse') {
        await $send->({ type => 'sse.start', status => 200, headers => [] });
        await $send->({ type => 'sse.send', event => 'hello', data => 'world' });
        return;
    }

    # HTTP routes
    if ($path eq '/' && $method eq 'GET') {
        await $send->({ type => 'http.response.start', status => 200, headers => [['content-type', 'text/plain']] });
        await $send->({ type => 'http.response.body', body => 'Welcome!', more => 0 });
    }
    elsif ($path eq '/api/users' && $method eq 'POST') {
        my $event = await $receive->();
        require JSON::MaybeXS;
        my $data = JSON::MaybeXS::decode_json($event->{body});

        # Increment counter if lifespan state available
        my $id = ($scope->{state} && exists $scope->{state}{counter})
            ? ++$scope->{state}{counter}
            : 1;

        await $send->({ type => 'http.response.start', status => 201, headers => [['content-type', 'application/json']] });
        await $send->({ type => 'http.response.body', body => JSON::MaybeXS::encode_json({ id => $id, name => $data->{name} }), more => 0 });
    }
    else {
        await $send->({ type => 'http.response.start', status => 404, headers => [['content-type', 'text/plain']] });
        await $send->({ type => 'http.response.body', body => 'Not Found', more => 0 });
    }
};

subtest 'full HTTP workflow' => sub {
    my $client = PAGI::Test::Client->new(app => $app);

    # GET
    my $res = $client->get('/');
    is $res->status, 200, 'GET / status';
    is $res->text, 'Welcome!', 'GET / body';

    # POST JSON
    $res = $client->post('/api/users', json => { name => 'Alice' });
    is $res->status, 201, 'POST status';
    is $res->json->{name}, 'Alice', 'POST name';

    # 404
    $res = $client->get('/nonexistent');
    is $res->status, 404, '404 status';
};

subtest 'full WebSocket workflow' => sub {
    my $client = PAGI::Test::Client->new(app => $app);

    $client->websocket('/ws', sub {
        my ($ws) = @_;
        $ws->send_text('ping');
        is $ws->receive_text, 'ping', 'echo received';
    });
};

subtest 'full SSE workflow' => sub {
    my $client = PAGI::Test::Client->new(app => $app);

    $client->sse('/events', sub {
        my ($sse) = @_;
        my $event = $sse->receive_event;
        is $event->{event}, 'hello', 'SSE event type';
        is $event->{data}, 'world', 'SSE event data';
    });
};

subtest 'lifespan with state' => sub {
    PAGI::Test::Client->run($app, sub {
        my ($client) = @_;

        # Counter increments via lifespan state
        my $res = $client->post('/api/users', json => { name => 'Bob' });
        is $res->json->{id}, 1, 'first id';

        $res = $client->post('/api/users', json => { name => 'Carol' });
        is $res->json->{id}, 2, 'second id';
    });
};

done_testing;
