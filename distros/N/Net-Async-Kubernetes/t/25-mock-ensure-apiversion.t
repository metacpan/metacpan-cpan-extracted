use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';

use IO::Async::Loop;
use IO::K8s;
use Net::Async::Kubernetes;
use MockTransport;

# A hashref manifest handed to ensure()/ensure_only() carries its own
# apiVersion, and that apiVersion is authoritative. The bare Kind
# HorizontalPodAutoscaler resolves to autoscaling/v2; an autoscaling/v1
# manifest must stay autoscaling/v1 -- class, endpoint and request body. An
# apiVersion no class serves croaks before anything is sent, instead of
# quietly falling back to the version the bare Kind maps to.
#
# ensure_only() decides what to prune by (Kind, namespace, name). The Kind is
# the object's own kind(), not its class name: every IO::K8s::Unstructured
# object shares one class, so keying on the class name lets a Gadget named
# like an applied Widget survive the prune.
#
# Mock-only: everything here is request routing, nothing needs a cluster.

# Two resource classes whose class names end the same way but which are
# different Kinds -- the shape IO::K8s::Unstructured has (one class, the Kind
# as data). Unstructured itself needs a discovery catalog to build a path;
# t/32-mock-unstructured.t mocks one. kind() is defined before the APIObject
# role is applied, so the role leaves it alone.
BEGIN {
    package My::Test::Widget::Thing;
    sub kind { 'Widget' }
    use IO::K8s::APIObject
        api_version     => 'example.com/v1',
        resource_plural => 'widgets';
    with 'IO::K8s::Role::Namespaced';

    package My::Test::Gadget::Thing;
    sub kind { 'Gadget' }
    use IO::K8s::APIObject
        api_version     => 'example.com/v1',
        resource_plural => 'gadgets';
    with 'IO::K8s::Role::Namespaced';
}

my $loop = IO::Async::Loop->new;

sub make_kube {
    my (%extra) = @_;
    MockTransport::reset();
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
        %extra,
    );
    MockTransport::install($kube);
    $loop->add($kube);
    return $kube;
}

my $V1  = '/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers';
my $V2  = '/apis/autoscaling/v2/namespaces/default/horizontalpodautoscalers';
my $SEL = 'app=web';
my $BG  = '?propagationPolicy=Background';
my $NOT_FOUND = { kind => 'Status', status => 'Failure', message => 'not found', code => 404 };
my $SUCCESS   = { kind => 'Status', status => 'Success' };

sub hpa {
    my ($name, %extra) = @_;
    return {
        kind     => 'HorizontalPodAutoscaler',
        metadata => { name => $name, namespace => 'default', labels => { app => 'web' } },
        spec     => {
            scaleTargetRef => { apiVersion => 'apps/v1', kind => 'Deployment', name => 'web' },
            maxReplicas    => 3,
        },
        %extra,
    };
}

sub requests {
    my ($method) = @_;
    return [ map { $_->{path} } grep { $_->{method} eq $method } MockTransport::request_log ];
}

# ============================================================================
# ensure()
# ============================================================================

subtest 'ensure: apiVersion autoscaling/v1 -> v1 class, v1 endpoint, v1 body' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('GET', "$V1/hpa-v1", $NOT_FOUND, 404);
    MockTransport::mock_response('POST', $V1,
        hpa('hpa-v1', apiVersion => 'autoscaling/v1'));

    my $result = eval { $kube->ensure(hpa('hpa-v1', apiVersion => 'autoscaling/v1'))->get };
    is($@, '', 'ensure resolves');
    isa_ok($result, 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler', 'result');

    is_deeply([ map { "$_->{method} $_->{path}" } MockTransport::request_log ],
        [ "GET $V1/hpa-v1", "POST $V1" ],
        'looked up and created on the autoscaling/v1 endpoint');
    like(MockTransport::last_request()->{content}, qr{"apiVersion":"autoscaling/v1"},
        'the request body still says autoscaling/v1');
};

subtest 'ensure: no apiVersion -> the bare Kind resolves as before (v2)' => sub {
    for my $case (['absent', ()], ['empty string', apiVersion => '']) {
        my ($label, @api_version) = @$case;
        my $kube = make_kube();
        MockTransport::mock_response('GET', "$V2/hpa-bare", $NOT_FOUND, 404);
        MockTransport::mock_response('POST', $V2,
            hpa('hpa-bare', apiVersion => 'autoscaling/v2'));

        my $result = eval { $kube->ensure(hpa('hpa-bare', @api_version))->get };
        is($@, '', "$label: ensure resolves");
        isa_ok($result, 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscaler',
            "$label: result");
        is_deeply(requests('POST'), [$V2], "$label: created on the default (v2) endpoint");
    }
};

subtest 'ensure: an apiVersion no class serves croaks, nothing is sent' => sub {
    my $kube = make_kube();
    throws_ok { $kube->ensure(hpa('hpa-v9', apiVersion => 'autoscaling/v9')) }
        qr{apiVersion 'autoscaling/v9', kind 'HorizontalPodAutoscaler'},
        'croaks synchronously, naming the apiVersion and the Kind';
    is_deeply([ MockTransport::request_log ], [], 'no request was sent');
};

# ============================================================================
# ensure_only()
# ============================================================================

subtest 'ensure_only: an apiVersion hashref is applied as v1 and kept in a v2 listing' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('GET', "$V1/keep", $NOT_FOUND, 404);
    MockTransport::mock_response('POST', $V1, hpa('keep', apiVersion => 'autoscaling/v1'));
    # Listed through the bare Kind, i.e. the autoscaling/v2 collection: the
    # same resource in another representation, so the version is not part of
    # what makes an item "expected".
    MockTransport::mock_response('GET', "$V2?labelSelector=$SEL", {
        kind => 'HorizontalPodAutoscalerList', apiVersion => 'autoscaling/v2',
        items => [ hpa('keep'), hpa('stale') ],
    });
    MockTransport::mock_response('DELETE', "$V2/stale$BG", $SUCCESS);
    MockTransport::mock_response('DELETE', "$V2/keep$BG",  $SUCCESS);

    my @applied = eval {
        $kube->ensure_only(
            label      => $SEL,
            objects    => [ hpa('keep', apiVersion => 'autoscaling/v1') ],
            kinds      => ['HorizontalPodAutoscaler'],
            namespaces => ['default'],
        )->get;
    };
    is($@, '', 'ensure_only resolves');
    isa_ok($applied[0], 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler',
        'applied object');
    is_deeply(requests('POST'), [$V1], 'created on the autoscaling/v1 endpoint');
    is_deeply(requests('DELETE'), ["$V2/stale$BG"],
        'only the stale item is deleted, the applied one is recognised');
};

subtest 'ensure_only: an unknown apiVersion croaks before anything is applied' => sub {
    my $kube = make_kube();
    my $first = $kube->new_object(ConfigMap =>
        metadata => { name => 'first', namespace => 'default' });

    throws_ok {
        $kube->ensure_only(
            label   => $SEL,
            objects => [ $first, hpa('keep', apiVersion => 'autoscaling/v9') ],
            kinds   => ['HorizontalPodAutoscaler'],
        );
    } qr{apiVersion 'autoscaling/v9', kind 'HorizontalPodAutoscaler'},
        'croaks synchronously, naming the apiVersion and the Kind';
    is_deeply([ MockTransport::request_log ], [],
        'no request was sent -- not even for the valid object before it');
};

subtest 'ensure_only: the key is the object kind(), not the class name' => sub {
    my $kube = make_kube(resource_map => {
        %{ IO::K8s->default_resource_map },
        Widget => '+My::Test::Widget::Thing',
        Gadget => '+My::Test::Gadget::Thing',
    });
    my $WIDGETS = '/apis/example.com/v1/namespaces/default/widgets';
    my $GADGETS = '/apis/example.com/v1/namespaces/default/gadgets';
    my $item = sub {
        my ($kind, $name) = @_;
        return {
            apiVersion => 'example.com/v1', kind => $kind,
            metadata   => { name => $name, namespace => 'default', labels => { app => 'web' } },
        };
    };

    my $widget = $kube->new_object(Widget => $item->('Widget', 'foo'));
    isa_ok($widget, 'My::Test::Widget::Thing', 'premise: the Widget class');
    is($widget->kind, 'Widget', 'premise: kind() is not the class-name tail');

    MockTransport::mock_response('GET', "$WIDGETS/foo", $NOT_FOUND, 404);
    MockTransport::mock_response('POST', $WIDGETS, $item->('Widget', 'foo'));
    MockTransport::mock_response('GET', "$WIDGETS?labelSelector=$SEL", {
        kind => 'WidgetList', apiVersion => 'example.com/v1',
        items => [ $item->('Widget', 'foo'), $item->('Widget', 'stale') ],
    });
    MockTransport::mock_response('GET', "$GADGETS?labelSelector=$SEL", {
        kind => 'GadgetList', apiVersion => 'example.com/v1',
        items => [ $item->('Gadget', 'foo') ],
    });
    MockTransport::mock_response('DELETE', "$WIDGETS/stale$BG", $SUCCESS);
    MockTransport::mock_response('DELETE', "$WIDGETS/foo$BG",   $SUCCESS);
    MockTransport::mock_response('DELETE', "$GADGETS/foo$BG",   $SUCCESS);

    eval {
        $kube->ensure_only(
            label      => $SEL,
            objects    => [$widget],
            kinds      => [qw(Widget Gadget)],
            namespaces => ['default'],
        )->get;
    };
    is($@, '', 'ensure_only resolves');
    is_deeply([ sort @{ requests('DELETE') } ], [ "$GADGETS/foo$BG", "$WIDGETS/stale$BG" ],
        'the applied Widget foo stays; the stale Widget and the same-named Gadget go');
};

done_testing;
