#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 'lib';
use PAGI::Test::Client;

my $startup_called = 0;
my $shutdown_called = 0;

my $lifespan_app = async sub {
    my ($scope, $receive, $send) = @_;

    if ($scope->{type} eq 'lifespan') {
        my $event = await $receive->();

        if ($event->{type} eq 'lifespan.startup') {
            $startup_called = 1;
            $scope->{state}{db} = 'connected';
            await $send->({ type => 'lifespan.startup.complete' });
        }

        $event = await $receive->();
        if ($event->{type} eq 'lifespan.shutdown') {
            $shutdown_called = 1;
            await $send->({ type => 'lifespan.shutdown.complete' });
        }
        return;
    }

    # HTTP
    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [['content-type', 'text/plain']],
    });

    await $send->({
        type => 'http.response.body',
        body => "DB: " . ($scope->{state}{db} // 'none'),
        more => 0,
    });
};

subtest 'lifespan disabled by default' => sub {
    $startup_called = 0;
    my $client = PAGI::Test::Client->new(app => $lifespan_app);
    my $res = $client->get('/');

    ok !$startup_called, 'startup not called when lifespan disabled';
    is $res->text, 'DB: none', 'no state without lifespan';
};

subtest 'lifespan explicit start/stop' => sub {
    $startup_called = 0;
    $shutdown_called = 0;

    my $client = PAGI::Test::Client->new(app => $lifespan_app, lifespan => 1);
    $client->start;

    ok $startup_called, 'startup called';

    my $res = $client->get('/');
    is $res->text, 'DB: connected', 'state available';

    $client->stop;
    ok $shutdown_called, 'shutdown called';
};

subtest 'lifespan run() helper' => sub {
    $startup_called = 0;
    $shutdown_called = 0;

    PAGI::Test::Client->run($lifespan_app, sub {
        my ($client) = @_;
        ok $startup_called, 'startup called in run()';
        my $res = $client->get('/');
        is $res->text, 'DB: connected', 'state in run()';
    });

    ok $shutdown_called, 'shutdown called after run()';
};

done_testing;
