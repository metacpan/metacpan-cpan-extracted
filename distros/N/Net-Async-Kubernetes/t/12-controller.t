use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

use lib 't/lib';

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

subtest 'controller deduplicates queued events and reconciles latest state' => sub {
    require_ok('Net::Async::Kubernetes::Controller');

    my $kube = make_kube();
    my @reconciled;

    MockTransport::mock_watch_events('/api/v1/namespaces/default/pods', [
        { type => 'ADDED', object => {
            kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'pod-1', namespace => 'default', resourceVersion => '10' },
            spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
            status => { phase => 'Pending' },
        }},
        { type => 'MODIFIED', object => {
            kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'pod-1', namespace => 'default', resourceVersion => '11' },
            spec => { containers => [{ name => 'nginx', image => 'nginx:latest' }] },
            status => { phase => 'Running' },
        }},
    ], { complete => 1 });

    my $controller;
    $controller = Net::Async::Kubernetes::Controller->new(
        kube => $kube,
        on_reconcile => sub {
            my ($ctx) = @_;
            push @reconciled, $ctx;
            $controller->stop;
            $loop->later(sub { $loop->stop });
            return;
        },
    );

    isa_ok($controller, 'Net::Async::Kubernetes::Controller');

    $controller->watch_resource('Pod',
        namespace => 'default',
    );

    $loop->add($controller);
    $loop->watch_time(after => 2, code => sub { $controller->stop; $loop->stop; });
    $loop->run;

    is(scalar @reconciled, 1, 'duplicate queued key reconciled once');
    is($reconciled[0]{resource}, 'Pod', 'resource passed to reconcile');
    is($reconciled[0]{key}, 'default/pod-1', 'default key derived from namespace/name');
    is($reconciled[0]{event_type}, 'MODIFIED', 'latest event wins for queued key');
};

subtest 'kube client creates controller runtime' => sub {
    my $kube = make_kube();
    my $controller = $kube->controller(
        on_reconcile => sub { return },
    );

    isa_ok($controller, 'Net::Async::Kubernetes::Controller');
    is($controller->kube, $kube, 'controller keeps original kube client');
};

subtest 'controller does not keep a borrowed client alive' => sub {
    my $weak_kube;

    {
        # $kube->controller() add_child()s the controller, so a strong client
        # reference inside the controller would cycle and free neither.
        my $kube = make_kube();
        $weak_kube = $kube;
        weaken($weak_kube);

        my $controller = $kube->controller(on_reconcile => sub { return });
        is($controller->kube, $kube, 'borrowed client reachable while in scope');
    }

    ok(!defined $weak_kube, 'client freed after controller and client leave scope');
};

subtest 'reconcile context does not keep the client alive' => sub {
    my $weak_kube;
    my @keys;

    {
        my $kube = make_kube();
        $weak_kube = $kube;
        weaken($weak_kube);
        $loop->add($kube);

        MockTransport::mock_watch_events('/api/v1/namespaces/default/pods', [
            { type => 'ADDED', object => {
                kind => 'Pod', apiVersion => 'v1',
                metadata => { name => 'pod-ctx', namespace => 'default', resourceVersion => '30' },
                spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
                status => { phase => 'Pending' },
            }},
        ], { complete => 1 });

        my $controller;
        $controller = $kube->controller(
            on_reconcile => sub {
                my ($ctx) = @_;
                push @keys, $ctx->{key};
                # compare against the weak alias: capturing $kube in this
                # callback would itself pin the client
                is($ctx->{kube}, $weak_kube, 'reconcile ctx carries the client');
                $controller->stop;
                $loop->later(sub { $loop->stop });
                # fail so the entry keeps its ctx: a cleanly reconciled key is
                # dropped from {entries}, which would leave nothing to retain
                # the client and make this test pass for the wrong reason
                return Future->fail('keep the entry');
            },
        );
        $controller->watch_resource('Pod', namespace => 'default');

        my $guard = $loop->watch_time(after => 2, code => sub { $controller->stop; $loop->stop });
        $loop->run;
        $loop->unwatch_time($guard);

        is_deeply(\@keys, ['default/pod-ctx'], 'reconcile ran once');

        # the ctx stays behind in the controller entries after the reconcile
        is(scalar keys %{ $controller->{entries} }, 1,
            'entry retained, so the ctx is what holds the client here');
        $loop->remove($kube);
    }

    ok(!defined $weak_kube, 'client freed although the reconcile ctx is retained');
};

subtest 'controller owns a self-constructed client' => sub {
    my $controller = Net::Async::Kubernetes::Controller->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
        on_reconcile => sub { return },
    );

    isa_ok($controller->kube, 'Net::Async::Kubernetes');
};

subtest 'controller retries failed reconciles' => sub {
    my $kube = make_kube();
    my @attempts;

    MockTransport::mock_watch_events('/api/v1/namespaces/default/pods', [
        { type => 'ADDED', object => {
            kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'pod-retry', namespace => 'default', resourceVersion => '20' },
            spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
            status => { phase => 'Pending' },
        }},
    ], { complete => 1 });

    my $controller;
    $controller = Net::Async::Kubernetes::Controller->new(
        kube => $kube,
        retry_delay => sub { 0 },
        on_reconcile => sub {
            my ($ctx) = @_;
            push @attempts, $ctx->{attempt};
            if (@attempts == 1) {
                return Future->fail('boom');
            }
            $controller->stop;
            $loop->later(sub { $loop->stop });
            return;
        },
    );

    $controller->watch_resource('Pod', namespace => 'default');

    $loop->add($controller);
    $loop->watch_time(after => 2, code => sub { $controller->stop; $loop->stop; });
    $loop->run;

    is_deeply(\@attempts, [1, 2], 'failed reconcile requeued immediately');
};

my @watch_error_events = (
    { type => 'ERROR', object => {
        kind => 'Status', apiVersion => 'v1', status => 'Failure',
        reason => 'Forbidden', code => 403,
        message => 'pods is forbidden: User cannot watch resource "pods"',
    }},
    { type => 'ADDED', object => {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'pod-err', namespace => 'default', resourceVersion => '40' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => { phase => 'Pending' },
    }},
);

subtest 'watch ERROR events reach the controller hook' => sub {
    my $kube = make_kube();
    my (@errors, @reconciled);

    MockTransport::mock_watch_events('/api/v1/namespaces/default/pods',
        [@watch_error_events]);

    my $controller;
    $controller = Net::Async::Kubernetes::Controller->new(
        kube => $kube,
        on_watch_error => sub {
            my ($error, $ctx) = @_;
            push @errors, [$error, $ctx];
        },
        on_reconcile => sub {
            my ($ctx) = @_;
            push @reconciled, $ctx->{key};
            $controller->stop;
            $loop->later(sub { $loop->stop });
            return;
        },
    );

    $controller->watch_resource('Pod', namespace => 'default');

    $loop->add($controller);
    my $guard = $loop->watch_time(after => 2, code => sub { $controller->stop; $loop->stop });
    $loop->run;
    $loop->unwatch_time($guard);

    is(scalar @errors, 1, 'ERROR event delivered to on_watch_error');
    is($errors[0][0]{code}, 403, 'raw status hashref passed to the hook');
    is($errors[0][1]{resource}, 'Pod', 'error context names the watched resource');
    is($errors[0][1]{controller}, $controller, 'error context carries the controller');
    is_deeply(\@reconciled, ['default/pod-err'], 'ERROR event stays out of the workqueue');
};

subtest 'per watch on_error keeps precedence over the controller hook' => sub {
    my $kube = make_kube();
    my (@hook_errors, @spec_errors, @reconciled);

    MockTransport::mock_watch_events('/api/v1/namespaces/default/pods',
        [@watch_error_events]);

    my $controller;
    $controller = Net::Async::Kubernetes::Controller->new(
        kube => $kube,
        on_watch_error => sub { push @hook_errors, $_[0] },
        on_reconcile => sub {
            my ($ctx) = @_;
            push @reconciled, $ctx->{key};
            $controller->stop;
            $loop->later(sub { $loop->stop });
            return;
        },
    );

    $controller->watch_resource('Pod',
        namespace => 'default',
        on_error  => sub { push @spec_errors, $_[0] },
    );

    $loop->add($controller);
    my $guard = $loop->watch_time(after => 2, code => sub { $controller->stop; $loop->stop });
    $loop->run;
    $loop->unwatch_time($guard);

    is(scalar @spec_errors, 1, 'watch level on_error received the ERROR event');
    is($spec_errors[0]{code}, 403, 'watch level on_error gets the raw status hashref');
    is(scalar @hook_errors, 0, 'controller hook not called when the watch handles errors');
    is_deeply(\@reconciled, ['default/pod-err'], 'reconcile still runs for the object event');
};

subtest 'controller patches status subresource' => sub {
    my $kube = make_kube();
    my $controller = Net::Async::Kubernetes::Controller->new(
        kube => $kube,
        on_reconcile => sub { return },
    );

    MockTransport::mock_response('PATCH', '/api/v1/namespaces/default/pods/pod-1/status', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'pod-1', namespace => 'default', resourceVersion => '12' },
        spec => { containers => [{ name => 'nginx', image => 'nginx:latest' }] },
        status => { phase => 'Running' },
    });

    my $patched = $controller->patch_status('Pod', 'pod-1',
        namespace => 'default',
        status    => { phase => 'Running' },
    )->get;

    is($patched->metadata->name, 'pod-1', 'patched object returned');

    my $req = MockTransport::last_request();
    is($req->{method}, 'PATCH', 'used PATCH for status update');
    like($req->{path}, qr{/api/v1/namespaces/default/pods/pod-1/status$}, 'patched status subresource path');
    like($req->{content}, qr/"status"/, 'request contains status payload');
};

done_testing;
