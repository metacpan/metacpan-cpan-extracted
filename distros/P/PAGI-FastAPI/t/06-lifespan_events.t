#!/usr/bin/env perl

use v5.36;
use Test::More;
use Future::AsyncAwait;
use PAGI::FastAPI;

my $app = PAGI::FastAPI->new();

my $startup_called  = 0;
my $shutdown_called = 0;

$app->on_startup(async sub {
    $startup_called = 1;
});

$app->on_shutdown(async sub {
    $shutdown_called = 1;
});

subtest 'Lifespan Protocol Event Execution' => sub {
    my $app_code = $app->to_app;

    my @events = (
        { type => 'lifespan.startup' },
        { type => 'lifespan.shutdown' },
    );
    my $event_idx = 0;

    my $receive = async sub {
        return $events[$event_idx++];
    };

    my @sent_events;
    my $send = async sub ($event) {
        push @sent_events, $event;
    };

    my $scope = { type => 'lifespan' };

    $app_code->($scope, $receive, $send)->get;

    is $startup_called,  1, 'Startup event handler was executed';
    is $shutdown_called, 1, 'Shutdown event handler was executed';
    is $sent_events[0]{type}, 'lifespan.startup.complete',  'Startup complete sent';
    is $sent_events[1]{type}, 'lifespan.shutdown.complete', 'Shutdown complete sent';
};

subtest 'Lifespan Startup Failure Handling' => sub {
    my $failing_app = PAGI::FastAPI->new();
    $failing_app->on_startup(async sub {
        die "DB Connection Failed!";
    });

    my $app_code = $failing_app->to_app;
    my $receive  = async sub { return { type => 'lifespan.startup' } };

    my @sent_events;
    my $send = async sub ($event) {
        push @sent_events, $event;
    };

    $failing_app->to_app->({ type => 'lifespan' }, $receive, $send)->get;

    is $sent_events[0]{type}, 'lifespan.startup.failed', 'Failed event sent on exception';
    like $sent_events[0]{message}, qr/DB Connection Failed!/, 'Error message reported in payload';
};

done_testing;
