use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use JSON::MaybeXS;
use Net::Async::Kubernetes;
use MockTransport;

# ensure() special-cases two built-in Kinds whose spec is immutable: an
# existing core v1 PersistentVolumeClaim is left alone, an existing batch/v1
# Job is kept while active or succeeded and replaced otherwise. Both are
# recognised by apiVersion and Kind together -- not by the last segment of the
# class name, which a CRD is free to reuse in its own group. A CRD Kind named
# Job or PersistentVolumeClaim is ensured like any other object: GET, then PUT
# at the server's resourceVersion.
#
# ensure_only() keys what it keeps by (API group, Kind, namespace, name): the
# same Kind name in two groups is two resources (Istio's and the Gateway API's
# Gateway), so a labelled one outside the object set is deleted whichever
# group the applied one is in. The version stays out of the key (t/24, t/25).
#
# The real batch/v1 Job and core v1 PersistentVolumeClaim keep their special
# cases; t/21-mock-ensure.t characterises those. IO::K8s::Unstructured needs
# a discovery catalog to build a path, so its instance-data branch is
# exercised in t/32-mock-unstructured.t, which mocks one.
#
# Mock-only: everything here is request routing, nothing needs a cluster.

# A resource class whose kind() is not its class-name tail, as for
# IO::K8s::Unstructured. kind() is defined before the APIObject role is
# applied, so the role leaves it alone (same shape as in t/25).
BEGIN {
    package My::Test::Widget::Thing;
    sub kind { 'Widget' }
    use IO::K8s::APIObject
        api_version     => 'example.com/v1',
        resource_plural => 'widgets';
    with 'IO::K8s::Role::Namespaced';
}

my $loop = IO::Async::Loop->new;
my $JSON = JSON::MaybeXS->new(utf8 => 1);

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

sub calls {
    return [ map { "$_->{method} $_->{path}" } MockTransport::request_log ];
}

sub requests {
    my ($method) = @_;
    return [ map { $_->{path} } grep { $_->{method} eq $method } MockTransport::request_log ];
}

my $NOT_FOUND = { kind => 'Status', status => 'Failure', message => 'not found', code => 404 };
my $CONFLICT  = { kind => 'Status', status => 'Failure', message => 'AlreadyExists', code => 409 };
my $SUCCESS   = { kind => 'Status', status => 'Success' };

my $PIPELINE = '/apis/pipeline.example.com/v1/namespaces/default';

# ============================================================================
# ensure(): a CRD reusing a special-cased Kind name
# ============================================================================

subtest 'ensure: a CRD Kind named Job in its own group is updated like any object' => sub {
    # With a plain-map status the batch/v1 Job path would call
    # status->succeeded on an unblessed hashref; without a status it would
    # delete and recreate the object instead of updating it.
    for my $case (
        [ 'plain-map status', status => { phase => 'Running' } ],
        [ 'no status' ],
    ) {
        my ($label, @status) = @$case;
        my $kube = make_kube();
        MockTransport::mock_response('GET', "$PIPELINE/jobs/nightly", {
            apiVersion => 'pipeline.example.com/v1', kind => 'Job',
            metadata   => { name => 'nightly', namespace => 'default', resourceVersion => '5' },
            spec       => { schedule => 'daily' },
            @status,
        });
        MockTransport::mock_response('PUT', "$PIPELINE/jobs/nightly", {
            apiVersion => 'pipeline.example.com/v1', kind => 'Job',
            metadata   => { name => 'nightly', namespace => 'default', resourceVersion => '6' },
            spec       => { schedule => 'hourly' },
        });

        my $job = $kube->new_object('+My::Pipeline::Job',
            metadata => { name => 'nightly', namespace => 'default' },
            spec     => { schedule => 'hourly' },
        );
        my $result = eval { $kube->ensure($job)->get };
        is($@, '', "$label: ensure resolves");
        isa_ok($result, 'My::Pipeline::Job', "$label: result");
        is_deeply(calls(),
            [ "GET $PIPELINE/jobs/nightly", "PUT $PIPELINE/jobs/nightly" ],
            "$label: a plain GET then PUT -- no batch Job keep or delete/recreate");
        my ($put) = grep { $_->{method} eq 'PUT' } MockTransport::request_log;
        is($put && $JSON->decode($put->{content})->{metadata}{resourceVersion}, '5',
            "$label: PUT at the server resourceVersion");
        is($result && $result->metadata->resourceVersion, '6',
            "$label: the updated object is returned");
    }
};

subtest 'ensure: a CRD Kind named PersistentVolumeClaim in its own group is updated' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('GET', "$PIPELINE/persistentvolumeclaims/cache", {
        apiVersion => 'pipeline.example.com/v1', kind => 'PersistentVolumeClaim',
        metadata   => { name => 'cache', namespace => 'default', resourceVersion => '8' },
        spec       => { size => '1Gi' },
    });
    MockTransport::mock_response('PUT', "$PIPELINE/persistentvolumeclaims/cache", {
        apiVersion => 'pipeline.example.com/v1', kind => 'PersistentVolumeClaim',
        metadata   => { name => 'cache', namespace => 'default', resourceVersion => '9' },
        spec       => { size => '2Gi' },
    });

    my $claim = $kube->new_object('+My::Pipeline::PersistentVolumeClaim',
        metadata => { name => 'cache', namespace => 'default' },
        spec     => { size => '2Gi' },
    );
    my $result = eval { $kube->ensure($claim)->get };
    is($@, '', 'ensure resolves');
    is_deeply(calls(),
        [ "GET $PIPELINE/persistentvolumeclaims/cache",
          "PUT $PIPELINE/persistentvolumeclaims/cache" ],
        'updated, not returned unchanged');
    is($result && $result->metadata->resourceVersion, '9', 'the updated object is returned');
};

subtest 'ensure: a CRD PersistentVolumeClaim create race is updated, not taken as-is' => sub {
    my $kube = make_kube();
    MockTransport::mock_response_queue('GET', "$PIPELINE/persistentvolumeclaims/cache",
        [ $NOT_FOUND, 404 ],
        [ { apiVersion => 'pipeline.example.com/v1', kind => 'PersistentVolumeClaim',
            metadata   => { name => 'cache', namespace => 'default', resourceVersion => '8' },
            spec       => { size => '1Gi' } }, 200 ],
    );
    MockTransport::mock_response('POST', "$PIPELINE/persistentvolumeclaims", $CONFLICT, 409);
    MockTransport::mock_response('PUT', "$PIPELINE/persistentvolumeclaims/cache", {
        apiVersion => 'pipeline.example.com/v1', kind => 'PersistentVolumeClaim',
        metadata   => { name => 'cache', namespace => 'default', resourceVersion => '9' },
        spec       => { size => '2Gi' },
    });

    my $claim = $kube->new_object('+My::Pipeline::PersistentVolumeClaim',
        metadata => { name => 'cache', namespace => 'default' },
        spec     => { size => '2Gi' },
    );
    my $result = eval { $kube->ensure($claim)->get };
    is($@, '', 'ensure resolves');
    is_deeply(calls(),
        [ "GET $PIPELINE/persistentvolumeclaims/cache",
          "POST $PIPELINE/persistentvolumeclaims",
          "GET $PIPELINE/persistentvolumeclaims/cache",
          "PUT $PIPELINE/persistentvolumeclaims/cache" ],
        'GET(404), POST(409), GET(refetch), PUT -- the core PVC shortcut does not apply');
    is($result && $result->metadata->resourceVersion, '9', 'the updated object is returned');
};

subtest 'ensure: failures name the object Kind, not the class-name tail' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('GET', '/apis/example.com/v1/namespaces/default/widgets/foo',
        { kind => 'Status', status => 'Failure', message => 'boom', code => 500 }, 500);

    my $widget = $kube->new_object('+My::Test::Widget::Thing',
        metadata => { name => 'foo', namespace => 'default' });
    is($widget->kind, 'Widget', 'premise: kind() is not the class-name tail');

    my $f = $kube->ensure($widget);
    eval { $f->await };
    ok($f->is_failed, 'the Future is failed');
    like(($f->failure)[0] // '', qr{ensure get Widget/foo}, 'the message names Widget/foo');
};

# ============================================================================
# ensure_only(): the API group is part of the key
# ============================================================================

my $ISTIO_GW = '/apis/networking.istio.io/v1/namespaces/default/gateways';
my $API_GW   = '/apis/gateway.networking.k8s.io/v1/namespaces/default/gateways';
my $SEL      = 'app=demo';
my $BG       = '?propagationPolicy=Background';

sub gateway_item {
    my ($name) = @_;
    return {
        metadata => { name => $name, namespace => 'default', labels => { app => 'demo' } },
        spec     => { selector => 'ingress' },
    };
}

subtest 'ensure_only: the same Kind in another API group is another resource' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('GET', "$API_GW/web", $NOT_FOUND, 404);
    MockTransport::mock_response('POST', $API_GW, {
        apiVersion => 'gateway.networking.k8s.io/v1', kind => 'Gateway',
        %{ gateway_item('web') },
    });
    # Items carry no kind/apiVersion, as in a real list response -- the group
    # comes from the class each collection was listed through.
    MockTransport::mock_response('GET', "$API_GW?labelSelector=$SEL", {
        apiVersion => 'gateway.networking.k8s.io/v1', kind => 'GatewayList',
        items      => [ gateway_item('web') ],
    });
    MockTransport::mock_response('GET', "$ISTIO_GW?labelSelector=$SEL", {
        apiVersion => 'networking.istio.io/v1', kind => 'GatewayList',
        items      => [ gateway_item('web') ],
    });
    MockTransport::mock_response('DELETE', "$API_GW/web$BG",   $SUCCESS);
    MockTransport::mock_response('DELETE', "$ISTIO_GW/web$BG", $SUCCESS);

    my $gateway = $kube->new_object('+My::GatewayApi::Gateway', gateway_item('web'));
    my @applied = eval {
        $kube->ensure_only(
            label      => $SEL,
            objects    => [$gateway],
            kinds      => [qw( +My::GatewayApi::Gateway +My::Istio::Gateway )],
            namespaces => ['default'],
        )->get;
    };
    is($@, '', 'ensure_only resolves');
    is(scalar(@applied), 1, 'one applied object returned');
    is_deeply(requests('GET'),
        [ "$API_GW/web", "$API_GW?labelSelector=$SEL", "$ISTIO_GW?labelSelector=$SEL" ],
        'both groups were listed');
    is_deeply(requests('DELETE'), ["$ISTIO_GW/web$BG"],
        'the Istio Gateway web goes; the applied Gateway API Gateway web stays');
};

done_testing;
