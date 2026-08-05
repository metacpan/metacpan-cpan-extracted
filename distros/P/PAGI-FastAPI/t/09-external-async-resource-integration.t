#!/usr/bin/env perl

use v5.36;
use Test::More;
use Future::AsyncAwait;
use PAGI::FastAPI;
use PAGI::FastAPI::Depends qw(Depends);

# This guards the specific mechanism that external async resources (DB
# pools, cache clients, queue clients, etc) rely on to integrate with
# PAGI::FastAPI:
#
#   1. A resource created in on_startup() and torn down in on_shutdown().
#   2. The resource injected into handlers via Depends().
#   3. A handler awaiting a Future returned by that resource.
#
# It uses a fake in-memory "async resource" instead of a real external
# module, so this test adds no new dependencies and stays fast and
# deterministic. See eg/ for a worked example against a real dependency
# (DBIx::Class::Async).

sub run_request ($pagi_app, $scope, $receive = undef) {
    $receive //= async sub {
        return { type => 'http.request', more_body => 0 }
    };

    my ($sent_start, $sent_body);
    my $send = async sub ($event) {
        $sent_start = $event if $event->{type} eq 'http.response.start';
        $sent_body  = $event if $event->{type} eq 'http.response.body';
    };

    $pagi_app->($scope, $receive, $send)->get;
    return ($sent_start->{status}, $sent_body->{body});
}

subtest 'External async resource lifecycle + DI + await-in-handler' => sub {
    my $app = PAGI::FastAPI->new(title => 'Fake Async Resource Test');

    # Simulates an external client (DB pool, cache, etc.) that resolves
    # its calls via a Future, connected in on_startup and closed in
    # on_shutdown, the same shape DBIx::Class::Async's schema/disconnect
    # pairing takes.
    my ($resource, $connected, $disconnected) = (undef, 0, 0);

    $app->on_startup(async sub {
        $connected++;
        $resource = { store => {}, next_id => 1 };
    });

    $app->on_shutdown(async sub {
        $disconnected++;
        $resource = undef;
    });

    my $get_resource = async sub ($c) { return $resource };

    # A Future returning "async write", exactly like an ORM's ->create.
    async sub fake_create ($res, $data) {
        my $id = $res->{next_id}++;
        $res->{store}{$id} = $data;
        return { id => $id, %$data };
    }

    $app->post('/items',
        dependencies => { db => $get_resource },
        handler      => async sub ($c) {
            my $row = await fake_create($c->stash->{db}, { name => 'widget' });
            $c->status(201);
            return $row;
        }
    );

    my $pagi_app = $app->to_app;

    # Startup: on_startup must run before any request touches the resource.
    my $started         = 0;
    my $lifespan_events = [];
    my $startup_recv    = async sub { return { type => 'lifespan.startup' } };
    my $lsend           = async sub ($e)     { push @$lifespan_events, $e };

    $pagi_app->({ type => 'lifespan' },
        async sub {
            $started++;
            return $started == 1
            ? { type => 'lifespan.startup'  }
            : { type => 'lifespan.shutdown' };
    }, $lsend)->get;

    is $connected,    1, 'on_startup ran exactly once, connecting the resource';
    is $disconnected, 1, 'on_shutdown ran, disconnecting the resource';

    # Re-run startup only, to exercise a request against a live resource.
    $connected = 0;
    $app->on_startup(async sub {
        $connected++;
        $resource = { store => {}, next_id => 1 }
    });

    my $started2 = 0;
    $pagi_app->({ type => 'lifespan' }, async sub {
        $started2++;
        return $started2 == 1
        ? { type => 'lifespan.startup'  }
        : { type => 'lifespan.shutdown' };
    }, async sub { })->get;

    my ($status, $body) = run_request($pagi_app, {
        type         => 'http',
        method       => 'POST',
        path         => '/items',
        query_string => '',
        headers      => [],
    });

    is $status, 201, 'handler that awaits a Future-returning DI\'d resource responds correctly';
    like $body, qr/"name":"widget"/, 'the resource actually performed the async write';
};

done_testing;
