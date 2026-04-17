use strict;
use warnings;
use Test::More;

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
