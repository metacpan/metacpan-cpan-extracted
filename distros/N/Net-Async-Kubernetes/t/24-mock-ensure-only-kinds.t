use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use MockTransport;

# ensure_only() deletes every labelled item it does not expect, so how it
# decides "expected" is the difference between pruning and wiping out what it
# just applied. The item and the object are compared by (Kind, namespace,
# name) with the Kind taken from each one's class -- not from the string
# passed in 'kinds'. Keyed on that string, as Kubernetes::REST's synchronous
# ensure_only is, a qualified 'group/version/Kind' never equals the bare Kind
# of the objects, so every ensured object would be deleted again.
#
# Mock-only: everything here is request routing, nothing needs a cluster.

my $loop = IO::Async::Loop->new;

sub make_kube {
    MockTransport::reset();
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
    );
    MockTransport::install($kube);
    $loop->add($kube);
    return $kube;
}

my $V1  = '/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers';
my $V2  = '/apis/autoscaling/v2/namespaces/default/horizontalpodautoscalers';
my $SEL = 'app=web';
my $BG  = '?propagationPolicy=Background';

sub hpa {
    my ($api_version, $name) = @_;
    return {
        kind => 'HorizontalPodAutoscaler', apiVersion => $api_version,
        metadata => { name => $name, namespace => 'default', labels => { app => 'web' } },
        spec => {
            scaleTargetRef => { apiVersion => 'apps/v1', kind => 'Deployment', name => 'web' },
            maxReplicas    => 3,
        },
    };
}

sub mock_v1_listing {
    MockTransport::mock_response('GET', "$V1?labelSelector=$SEL", {
        kind => 'HorizontalPodAutoscalerList', apiVersion => 'autoscaling/v1',
        items => [ hpa('autoscaling/v1', 'keep'), hpa('autoscaling/v1', 'stale') ],
    });
    MockTransport::mock_response('DELETE', "$V1/stale$BG", { kind => 'Status', status => 'Success' });
    MockTransport::mock_response('DELETE', "$V1/keep$BG",  { kind => 'Status', status => 'Success' });
}

sub deleted_paths {
    return [ map { $_->{path} } grep { $_->{method} eq 'DELETE' } MockTransport::request_log ];
}

subtest "qualified name in 'kinds' keeps the objects it just ensured" => sub {
    my $kube = make_kube();
    my $keep = $kube->new_object('autoscaling/v1/HorizontalPodAutoscaler', hpa('autoscaling/v1', 'keep'));
    isa_ok($keep, 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler', 'premise: v1 object');

    MockTransport::mock_response('GET', "$V1/keep",
        { kind => 'Status', status => 'Failure', message => 'not found', code => 404 }, 404);
    MockTransport::mock_response('POST', $V1, hpa('autoscaling/v1', 'keep'));
    mock_v1_listing();

    my $f = $kube->ensure_only(
        label      => $SEL,
        objects    => [$keep],
        kinds      => ['autoscaling/v1/HorizontalPodAutoscaler'],
        namespaces => ['default'],
    );
    my @applied = $f->get;

    is(scalar(@applied), 1, 'one object applied');
    is_deeply(deleted_paths(), ["$V1/stale$BG"],
        'only the unexpected item is deleted, the ensured one survives');
};

subtest 'expected objects match by Kind, not by class (v2 object, v1 listing)' => sub {
    my $kube = make_kube();
    my $keep = $kube->new_object('HorizontalPodAutoscaler', hpa('autoscaling/v2', 'keep'));
    isa_ok($keep, 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscaler',
        'premise: the bare name gives the v2 class');

    MockTransport::mock_response('GET', "$V2/keep",
        { kind => 'Status', status => 'Failure', message => 'not found', code => 404 }, 404);
    MockTransport::mock_response('POST', $V2, hpa('autoscaling/v2', 'keep'));
    mock_v1_listing();

    $kube->ensure_only(
        label      => $SEL,
        objects    => [$keep],
        kinds      => ['autoscaling/v1/HorizontalPodAutoscaler'],
        namespaces => ['default'],
    )->get;

    is_deeply(deleted_paths(), ["$V1/stale$BG"],
        'the v1 listing of the same resource recognises the v2-typed object');
};

done_testing;
