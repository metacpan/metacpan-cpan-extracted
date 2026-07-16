#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Time::HiRes ();

use lib 'lib';
use PAGI::Test::Client;
use PAGI::Lifespan;

# Net against a regression that hangs the suite. Neither the old nor the fixed
# start() should ever exceed a couple of seconds here; this only fires if a
# regression wedges the loop, so it fails loud instead of stalling prove.
sub with_timeout {
    my ($seconds, $code) = @_;
    my @result;
    my $ok = eval {
        local $SIG{ALRM} = sub { die "TEST TIMEOUT after ${seconds}s\n" };
        alarm $seconds;
        @result = $code->();
        alarm 0;
        1;
    };
    my $err = $@;
    alarm 0;
    die $err unless $ok;
    return wantarray ? @result : $result[0];
}

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

subtest 'lifespan manager aggregates hooks' => sub {
    my @events;

    my $lifespan = PAGI::Lifespan->new;
    $lifespan->on_startup(async sub {
        my ($state) = @_;
        push @events, 'outer_start';
        $state->{outer} = 1;
    });
    $lifespan->on_shutdown(async sub {
        my ($state) = @_;
        push @events, 'outer_stop';
    });
    $lifespan->on_startup(async sub {
        my ($state) = @_;
        push @events, 'inner_start';
        $state->{inner} = 1;
    });
    $lifespan->on_shutdown(async sub {
        my ($state) = @_;
        push @events, 'inner_stop';
    });

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        if ($scope->{type} eq 'lifespan') {
            return await $lifespan->handle($scope, $receive, $send);
        }
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'text/plain']],
        });
        await $send->({
            type => 'http.response.body',
            body => "ok",
            more => 0,
        });
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;
    $client->get('/');
    $client->stop;

    is \@events, ['outer_start', 'inner_start', 'inner_stop', 'outer_stop'],
        'startup runs outer->inner, shutdown runs inner->outer';

    ok $client->state->{outer}, 'outer startup wrote to shared state';
    ok $client->state->{inner}, 'inner startup wrote to shared state';
};

subtest 'startup failure surfaces the error instead of silently hanging' => sub {
    my $lifespan = PAGI::Lifespan->new;
    $lifespan->on_startup(async sub { die "database unreachable\n" });

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        return await $lifespan->handle($scope, $receive, $send)
            if ($scope->{type} // '') eq 'lifespan';
        return;
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);

    my $t0 = Time::HiRes::time();
    my $err = dies { with_timeout(20, sub { $client->start }) };
    my $elapsed = Time::HiRes::time() - $t0;

    ok $err, 'start() dies when startup fails';
    like $err, qr/database unreachable/,
        'the startup failure message is surfaced, not swallowed';
    ok $elapsed < 2,
        sprintf('fails promptly (%.3fs), not a ~5s silent deadline spin', $elapsed);
    ok !$client->{started}, 'client is not marked started after a failed startup';
};

subtest 'startup awaiting real off-loop I/O completes (loop is driven)' => sub {
    unless (eval { require Future::IO::Impl::IOAsync; 1 }) {
        skip_all('Future::IO::Impl::IOAsync required to drive real off-loop I/O');
    }
    require Future::IO;

    my $hook_finished = 0;
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        if (($scope->{type} // '') eq 'lifespan') {
            my $event = await $receive->();
            if ($event->{type} eq 'lifespan.startup') {
                await Future::IO->sleep(0.05);   # real off-loop I/O
                $scope->{state}{ready} = 1;
                $hook_finished = 1;
                await $send->({ type => 'lifespan.startup.complete' });
            }
            await $receive->();   # block until shutdown
            return;
        }
        return;
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);

    my $t0 = Time::HiRes::time();
    ok lives { with_timeout(20, sub { $client->start }) },
        'start() returns after a startup that awaits off-loop I/O';
    my $elapsed = Time::HiRes::time() - $t0;

    ok $hook_finished, 'startup hook ran to completion (the loop was driven)';
    ok $client->state->{ready}, 'startup wrote to shared state';
    ok $elapsed < 2,
        sprintf('completes promptly (%.3fs), not a ~5s deadline spin', $elapsed);

    $client->stop;
};

done_testing;
