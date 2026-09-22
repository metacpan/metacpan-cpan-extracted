use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use IO::K8s;
use Net::Async::Kubernetes;
use Net::Async::Kubernetes::Watcher;
use MockTransport;

# IO::K8s 1.106 gave %DEFAULT_RESOURCE_MAP 113 qualified "apiVersion/Kind"
# keys (0 on the 1.105 release). That makes a name of the form
# 'group/version/Kind' resolve exactly, through expand_class(), all the way
# through list()/get()/watcher(). The point of the feature -- and the reason
# it earns a test -- is that a qualified name can reach a *different* API
# version than the bare Kind name: 'autoscaling/v1/HorizontalPodAutoscaler'
# resolves to a different class and endpoint than the bare
# 'HorizontalPodAutoscaler', which defaults to Autoscaling::V2.
#
# expand_class()/build_path() are pure lookups that run before any request
# goes out, so mock coverage is enough here -- nothing below needs a cluster.

diag("MOCK mode: using MockTransport");

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

# ============================================================================
# Premises: the qualified keys exist, and existing bare-name behavior is
# unaffected. If either of these fail, the subtests below are testing the
# wrong thing (e.g. running against IO::K8s 1.105, where expand_class()
# returns undef for every qualified name).
# ============================================================================

subtest 'premise: qualified apiVersion/Kind keys resolve (IO::K8s 1.106+)' => sub {
    my $kube = make_kube();
    my $map  = IO::K8s->default_resource_map;
    my @qualified_keys = grep { m{/} } keys %$map;
    ok(@qualified_keys > 0,
        'resource map carries at least one qualified "apiVersion/Kind" key (0 on IO::K8s 1.105)');

    is($kube->_rest->expand_class('resource.k8s.io/v1beta1/DeviceClass'),
        'IO::K8s::Api::Resource::V1beta1::DeviceClass',
        "qualified 'resource.k8s.io/v1beta1/DeviceClass' resolves");
    is($kube->_rest->expand_class('events.k8s.io/v1/Event'),
        'IO::K8s::Api::Events::V1::Event',
        "qualified 'events.k8s.io/v1/Event' resolves");
    is($kube->_rest->expand_class('autoscaling/v1/HorizontalPodAutoscaler'),
        'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler',
        "qualified 'autoscaling/v1/HorizontalPodAutoscaler' resolves");
};

subtest 'premise: bare short names still resolve to their historical default class' => sub {
    my $kube = make_kube();
    is($kube->_rest->expand_class('DeviceClass'),
        'IO::K8s::Api::Resource::V1::DeviceClass',
        "bare 'DeviceClass' still defaults to v1");
    is($kube->_rest->expand_class('Event'),
        'IO::K8s::Api::Core::V1::Event',
        "bare 'Event' still defaults to Core::V1");
    is($kube->_rest->expand_class('HorizontalPodAutoscaler'),
        'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscaler',
        "bare 'HorizontalPodAutoscaler' still defaults to Autoscaling::V2");
};

subtest 'qualified name resolves to a different class than the bare name' => sub {
    my $kube = make_kube();
    my $rest = $kube->_rest;

    isnt($rest->expand_class('resource.k8s.io/v1beta1/DeviceClass'), $rest->expand_class('DeviceClass'),
        'DeviceClass: qualified (v1beta1) diverges from bare (v1)');
    isnt($rest->expand_class('events.k8s.io/v1/Event'), $rest->expand_class('Event'),
        'Event: qualified (events.k8s.io) diverges from bare (core)');
    isnt($rest->expand_class('autoscaling/v1/HorizontalPodAutoscaler'), $rest->expand_class('HorizontalPodAutoscaler'),
        'HorizontalPodAutoscaler: qualified (v1) diverges from bare (v2)');
};

# ============================================================================
# list() / get() -- a qualified name reaches the qualified path and inflates
# the response into the qualified class, not the bare-name default.
# ============================================================================

subtest 'list() with a qualified name hits the qualified path and class' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET', '/apis/autoscaling/v1/horizontalpodautoscalers', {
        kind => 'HorizontalPodAutoscalerList', apiVersion => 'autoscaling/v1',
        items => [
            { kind => 'HorizontalPodAutoscaler', apiVersion => 'autoscaling/v1',
              metadata => { name => 'web', namespace => 'default' } },
        ],
    });

    my $list = $kube->list('autoscaling/v1/HorizontalPodAutoscaler')->get;
    isa_ok($list, 'IO::K8s::List');
    is(scalar @{$list->items}, 1, 'got 1 item');
    isa_ok($list->items->[0], 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler',
        'inflated to the qualified v1 class, not the bare-name v2 default');

    my $req = MockTransport::last_request();
    is($req->{path}, '/apis/autoscaling/v1/horizontalpodautoscalers',
        'request hit the v1 (qualified) path, not /apis/autoscaling/v2/...');
};

subtest 'get() with a qualified name hits the qualified path and class' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET',
        '/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers/web', {
        kind => 'HorizontalPodAutoscaler', apiVersion => 'autoscaling/v1',
        metadata => { name => 'web', namespace => 'default' },
    });

    my $hpa = $kube->get('autoscaling/v1/HorizontalPodAutoscaler', 'web', namespace => 'default')->get;
    isa_ok($hpa, 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler',
        'inflated to the qualified v1 class, not the bare-name v2 default');
    is($hpa->metadata->name, 'web', 'name round-trips');

    my $req = MockTransport::last_request();
    is($req->{path}, '/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers/web',
        'request hit the v1 (qualified) namespaced path');
};

subtest 'list() with the bare name still hits the historical (v2) path' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET', '/apis/autoscaling/v2/horizontalpodautoscalers', {
        kind => 'HorizontalPodAutoscalerList', apiVersion => 'autoscaling/v2',
        items => [],
    });

    my $list = $kube->list('HorizontalPodAutoscaler')->get;
    isa_ok($list, 'IO::K8s::List');

    my $req = MockTransport::last_request();
    is($req->{path}, '/apis/autoscaling/v2/horizontalpodautoscalers',
        'bare name still hits the v2 path, unaffected by the new qualified keys');
};

# ============================================================================
# watcher() -- a qualified name watches the qualified path and inflates
# events into the qualified class.
# ============================================================================

subtest 'watcher() with a qualified name watches the qualified path and class' => sub {
    my $kube = make_kube();

    MockTransport::mock_watch_events(
        '/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers', [
        { type => 'ADDED', object => {
            kind => 'HorizontalPodAutoscaler', apiVersion => 'autoscaling/v1',
            metadata => { name => 'web', namespace => 'default', resourceVersion => '10' },
        }},
    ]);

    my @added;
    my $watcher;
    $watcher = $kube->watcher('autoscaling/v1/HorizontalPodAutoscaler',
        namespace => 'default',
        on_added  => sub { push @added, $_[0] },
        on_event  => sub { $watcher->stop; $loop->stop; },
    );
    is($watcher->resource, 'autoscaling/v1/HorizontalPodAutoscaler',
        'watcher stores the qualified name as given');

    $loop->watch_time(after => 2, code => sub { $watcher->stop; $loop->stop; });
    $loop->run;

    is(scalar @added, 1, 'got 1 ADDED event')
        or diag('timed out waiting for the watch event');
    isa_ok($added[0], 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler',
        'watch event inflated to the qualified v1 class, not the bare-name v2 default');
    is($added[0]->metadata->name, 'web', 'name round-trips');

    my $req = MockTransport::last_request();
    is($req->{path}, '/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers',
        'watch request hit the v1 (qualified) path');
};

done_testing;
