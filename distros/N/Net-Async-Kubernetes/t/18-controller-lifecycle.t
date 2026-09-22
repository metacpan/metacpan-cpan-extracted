use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

use lib 't/lib';

use Future;
use IO::Async::Loop;
use Net::Async::Kubernetes;
use MockTransport;

my $loop = IO::Async::Loop->new;

sub make_kube {
    MockTransport::reset();
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
    );
    MockTransport::install($kube);
    return $kube;
}

sub pod_added {
    my ($name, $resource_version) = @_;
    return { type => 'ADDED', object => {
        kind => 'Pod', apiVersion => 'v1',
        metadata => {
            name => $name, namespace => 'default',
            resourceVersion => $resource_version,
        },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => { phase => 'Pending' },
    }};
}

subtest 'entries do not accumulate over cleanly reconciled keys' => sub {
    my $kube = make_kube();
    $loop->add($kube);

    my $key_count = 50;
    MockTransport::mock_watch_events('/api/v1/namespaces/default/pods',
        [ map { pod_added("pod-$_", 100 + $_) } 1 .. $key_count ]);

    my @reconciled;
    my $controller = $kube->controller(
        on_reconcile => sub {
            my ($ctx) = @_;
            push @reconciled, $ctx->{key};
            $loop->later(sub { $loop->stop }) if @reconciled == $key_count;
            return;
        },
    );
    $controller->watch_resource('Pod', namespace => 'default');

    my $guard = $loop->watch_time(after => 5, code => sub { $loop->stop });
    $loop->run;
    $loop->unwatch_time($guard);
    $controller->stop;

    is(scalar @reconciled, $key_count, "all $key_count keys reconciled");

    # {entries} is the workqueue index, one hashref per key. A key that
    # reconciled cleanly is neither queued, dirty nor retrying, so nothing
    # about it is still needed - keeping it grows the hash for the lifetime
    # of the process on a high churn resource.
    is(scalar keys %{ $controller->{entries} }, 0,
        'no entry left behind once every key reconciled cleanly');

    $loop->remove($kube);
};

subtest 'a failed reconcile keeps its entry and its retry state' => sub {
    my $kube = make_kube();
    $loop->add($kube);

    MockTransport::mock_watch_events('/api/v1/namespaces/default/pods',
        [ pod_added('pod-keep', 200) ]);

    my @attempts;
    my $controller;
    $controller = $kube->controller(
        on_reconcile => sub {
            my ($ctx) = @_;
            push @attempts, $ctx->{attempt};
            # stopping first keeps _schedule_retry from arming a timer, so the
            # entry is left holding nothing but its own failure state
            $ctx->{controller}->stop;
            $loop->later(sub { $loop->stop });
            return Future->fail('boom');
        },
    );
    $controller->watch_resource('Pod', namespace => 'default');

    my $guard = $loop->watch_time(after => 5, code => sub { $loop->stop });
    $loop->run;
    $loop->unwatch_time($guard);

    is_deeply(\@attempts, [1], 'reconcile ran once and failed');

    my $entry = $controller->{entries}{'default/pod-keep'};
    ok($entry, 'entry for the failed key survives');
    is($entry->{failures}, 1, 'failure count kept, so the next attempt is 2');
    ok($entry->{ctx}, 'ctx kept with the entry for the retry');

    $loop->remove($kube);
};

subtest 'a retained entry does not keep the controller alive' => sub {
    my $weak_controller;
    my @attempts;

    {
        my $kube = make_kube();
        $loop->add($kube);

        MockTransport::mock_watch_events('/api/v1/namespaces/default/pods',
            [ pod_added('pod-cycle', 300) ]);

        my $controller = $kube->controller(
            on_reconcile => sub {
                my ($ctx) = @_;
                push @attempts, $ctx->{attempt};
                # compare against the weak alias and drive the controller
                # through the ctx: capturing $controller in this callback
                # would pin it by itself, the callback lives in the controller
                is($ctx->{controller}, $weak_controller,
                    'reconcile ctx carries a usable controller');
                $ctx->{controller}->stop;
                $loop->later(sub { $loop->stop });
                return Future->fail('boom');
            },
        );
        $weak_controller = $controller;
        weaken($weak_controller);

        $controller->watch_resource('Pod', namespace => 'default');

        my $guard = $loop->watch_time(after => 5, code => sub { $loop->stop });
        $loop->run;
        $loop->unwatch_time($guard);

        is_deeply(\@attempts, [1], 'reconcile ran once and failed');
        is(scalar keys %{ $controller->{entries} }, 1,
            'the failed entry is still there, so the cycle is under test');

        $loop->remove($kube);
    }

    # controller -> {entries} -> {ctx} -> controller is a cycle the controller
    # closes on itself: no outside reference has to survive for it to leak.
    ok(!defined $weak_controller,
        'controller freed although an entry still holds its reconcile ctx');
};

subtest 'a key queued when the controller stops reconciles after a restart' => sub {
    my $kube = make_kube();
    $loop->add($kube);

    MockTransport::mock_watch_events('/api/v1/namespaces/default/pods',
        [ pod_added('pod-restart', 400) ]);

    my @reconciled;
    my $controller = $kube->controller(
        on_reconcile => sub {
            my ($ctx) = @_;
            push @reconciled, $ctx->{key};
            $loop->later(sub { $loop->stop });
            return;
        },
    );
    $controller->watch_resource('Pod', namespace => 'default');

    # The mock delivers the watch event from a later(), and the enqueue in that
    # same tick schedules the drain with another later() - so a stop queued
    # here lands after the key is queued and before it is drained.
    $loop->later(sub {
        is(scalar @reconciled, 0, 'stop lands before the queued key drains');
        is(scalar @{ $controller->{queue} }, 1, 'the key is queued at stop time');

        $controller->stop;

        is(scalar @{ $controller->{queue} }, 0, 'stop leaves no key in the queue');
        ok(!$controller->{entries}{'default/pod-restart'}{queued},
            'stop clears the queued flag together with the queue');

        $loop->later(sub { $controller->start });
    });

    my $guard = $loop->watch_time(after => 2, code => sub { $loop->stop });
    $loop->run;
    $loop->unwatch_time($guard);
    $controller->stop;

    # The restarted watch re-lists and delivers the object again. A key left
    # flagged queued makes that event return early without scheduling a drain,
    # so it sits in the queue until some unrelated key drags it out.
    is_deeply(\@reconciled, ['default/pod-restart'],
        'the key reconciles again after the restart');

    $loop->remove($kube);
};

subtest 'a queued key without an entry does not abandon the drain' => sub {
    my $kube = make_kube();
    $loop->add($kube);

    MockTransport::mock_watch_events('/api/v1/namespaces/default/pods',
        [ pod_added('pod-behind', 500) ]);

    my @reconciled;
    my $controller = $kube->controller(
        on_reconcile => sub {
            my ($ctx) = @_;
            push @reconciled, $ctx->{key};
            $loop->later(sub { $loop->stop });
            return;
        },
    );
    $controller->watch_resource('Pod', namespace => 'default');

    # Constructed state: the runtime cannot reach it today, because an entry is
    # only dropped while its key is not queued and the queued flag keeps a key
    # at most once in the queue. It is put here on purpose - whoever loosens
    # those conditions has to find the drain skipping the stale key rather than
    # dropping the rest of the queue with it.
    push @{ $controller->{queue} }, 'default/ghost';

    my $guard = $loop->watch_time(after => 2, code => sub { $loop->stop });
    $loop->run;
    $loop->unwatch_time($guard);
    $controller->stop;

    is_deeply(\@reconciled, ['default/pod-behind'],
        'the key queued behind the stale one still reconciles');
    is(scalar @{ $controller->{queue} }, 0, 'the stale key left the queue');

    $loop->remove($kube);
};

subtest 'an event arriving during a reconcile does not requeue past stop()' => sub {
    my $kube = make_kube();
    $loop->add($kube);

    MockTransport::mock_watch_events('/api/v1/namespaces/default/pods',
        [ pod_added('pod-dirty', 700) ]);

    my $key = 'default/pod-dirty';
    my @reconciled;
    my ($controller, $watcher, $in_flight);

    $controller = $kube->controller(
        on_reconcile => sub {
            my ($ctx) = @_;
            push @reconciled, $ctx->{key};

            if (@reconciled > 1) {   # the reconcile after the restart
                $loop->later(sub { $loop->stop });
                return;
            }

            # A second event for the same key, delivered while its reconcile is
            # in flight: this is the watcher's own MODIFIED callback, the one
            # the controller registered. _enqueue_event finds the key active
            # and marks the entry dirty instead of queueing it.
            $watcher->on_modified->($ctx->{object});

            $loop->later(sub {
                my $entry = $controller->{entries}{$key};
                ok($entry->{dirty},
                    'the event during the reconcile marked the key dirty');
                is(scalar @{ $controller->{queue} }, 0,
                    'a dirty key is not in the queue while it reconciles');

                $controller->stop;

                ok(!$entry->{dirty},
                    'stop clears the dirty flag with the rest of the pending work');

                # The reconcile finishes after the stop - the window the dirty
                # requeue used to fire in.
                $in_flight->done;

                is(scalar @{ $controller->{queue} }, 0,
                    'the finished reconcile queues nothing while stopped');
                is(scalar keys %{ $controller->{entries} }, 0,
                    'the cleanly reconciled key leaves no entry behind');

                $loop->later(sub { $controller->start });
            });

            return $in_flight = $loop->new_future;
        },
    );
    $watcher = $controller->watch_resource('Pod', namespace => 'default');

    my $guard = $loop->watch_time(after => 2, code => sub { $loop->stop });
    $loop->run;
    $loop->unwatch_time($guard);
    $controller->stop;

    # A requeue landing after stop() puts the key back in the emptied queue and
    # flags it queued, with no drain scheduled to take it out again. The event
    # the restarted watch re-lists then returns early on that flag: the key
    # never reconciles again.
    is_deeply(\@reconciled, [$key, $key],
        'the key reconciles again after the restart');

    $loop->remove($kube);
};

subtest 'stop() leaves no watcher attached to the client' => sub {
    my $kube = make_kube();
    $loop->add($kube);

    MockTransport::mock_watch_events('/api/v1/namespaces/default/pods',
        [ pod_added('pod-children', 600) ]);

    my $controller = $kube->controller(on_reconcile => sub { return });
    $controller->watch_resource('Pod', namespace => 'default');

    # The watcher is a child of the client, not of the controller:
    # $kube->watcher() add_child()s it. Count what is attached there.
    my $watchers = sub {
        scalar grep { $_->isa('Net::Async::Kubernetes::Watcher') } $kube->children;
    };

    is($watchers->(), 1, 'the started watch is attached to the client');

    for my $cycle (1 .. 3) {
        $controller->stop;
        is($watchers->(), 0, "cycle $cycle: stop detaches the watcher again");
        $controller->start;
        is($watchers->(), 1,
            "cycle $cycle: the restart leaves exactly one watcher attached");
    }

    $controller->stop;
    $loop->remove($kube);
};

done_testing;
