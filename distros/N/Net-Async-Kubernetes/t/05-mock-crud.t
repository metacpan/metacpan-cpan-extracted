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
    $loop->add($kube);
    return $kube;
}

# ============================================================================
# list
# ============================================================================

subtest 'list namespaces' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET', '/api/v1/namespaces', {
        kind => 'NamespaceList',
        apiVersion => 'v1',
        items => [
            { kind => 'Namespace', apiVersion => 'v1',
              metadata => { name => 'default' }, spec => {}, status => { phase => 'Active' } },
            { kind => 'Namespace', apiVersion => 'v1',
              metadata => { name => 'kube-system' }, spec => {}, status => { phase => 'Active' } },
        ],
    });

    my $list = $kube->list('Namespace')->get;
    isa_ok($list, 'IO::K8s::List');
    is(scalar @{$list->items}, 2, 'got 2 namespaces');
    is($list->items->[0]->metadata->name, 'default', 'first namespace is default');
    is($list->items->[1]->metadata->name, 'kube-system', 'second namespace is kube-system');

    my $req = MockTransport::last_request();
    is($req->{method}, 'GET', 'used GET');
    like($req->{path}, qr{/api/v1/namespaces}, 'correct path');
};

subtest 'list pods in namespace' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods', {
        kind => 'PodList',
        apiVersion => 'v1',
        items => [
            { kind => 'Pod', apiVersion => 'v1',
              metadata => { name => 'nginx', namespace => 'default' },
              spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
              status => { phase => 'Running' } },
        ],
    });

    my $list = $kube->list('Pod', namespace => 'default')->get;
    is(scalar @{$list->items}, 1, 'got 1 pod');
    is($list->items->[0]->metadata->name, 'nginx', 'pod name is nginx');

    my $req = MockTransport::last_request();
    like($req->{path}, qr{/api/v1/namespaces/default/pods}, 'correct namespaced path');
};

# ============================================================================
# get
# ============================================================================

subtest 'get single resource by name' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET', '/api/v1/namespaces/default', {
        kind => 'Namespace', apiVersion => 'v1',
        metadata => { name => 'default', uid => 'test-uid' },
        spec => {}, status => { phase => 'Active' },
    });

    my $ns = $kube->get('Namespace', 'default')->get;
    is($ns->metadata->name, 'default', 'got default namespace');

    # Also test named args form
    MockTransport::reset();
    MockTransport::install($kube);
    MockTransport::mock_response('GET', '/api/v1/namespaces/default', {
        kind => 'Namespace', apiVersion => 'v1',
        metadata => { name => 'default' }, spec => {}, status => {},
    });

    my $ns2 = $kube->get('Namespace', name => 'default')->get;
    is($ns2->metadata->name, 'default', 'named args form works');
};

subtest 'get namespaced resource' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods/nginx', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'nginx', namespace => 'default' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => { phase => 'Running' },
    });

    my $pod = $kube->get('Pod', 'nginx', namespace => 'default')->get;
    is($pod->metadata->name, 'nginx', 'got pod by name');
    is($pod->metadata->namespace, 'default', 'correct namespace');
};

# ============================================================================
# create
# ============================================================================

subtest 'create resource' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('POST', '/api/v1/namespaces', {
        kind => 'Namespace', apiVersion => 'v1',
        metadata => { name => 'test-ns', uid => 'new-uid' },
        spec => {}, status => { phase => 'Active' },
    });

    my $ns = $kube->_rest->new_object('Namespace',
        metadata => { name => 'test-ns' },
    );
    my $created = $kube->create($ns)->get;
    is($created->metadata->name, 'test-ns', 'created namespace returned');

    my $req = MockTransport::last_request();
    is($req->{method}, 'POST', 'used POST');
    ok($req->{content}, 'request had body');
};

# ============================================================================
# update
# ============================================================================

subtest 'update resource' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('PUT', '/api/v1/namespaces/test-ns', {
        kind => 'Namespace', apiVersion => 'v1',
        metadata => { name => 'test-ns', uid => 'test-uid', resourceVersion => '2' },
        spec => {}, status => { phase => 'Active' },
    });

    my $ns = $kube->_rest->new_object('Namespace',
        metadata => { name => 'test-ns', resourceVersion => '1' },
    );
    my $updated = $kube->update($ns)->get;
    is($updated->metadata->name, 'test-ns', 'updated namespace returned');

    my $req = MockTransport::last_request();
    is($req->{method}, 'PUT', 'used PUT');
    ok($req->{content}, 'request had body');
};

# ============================================================================
# delete
# ============================================================================

subtest 'delete by class and name' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('DELETE', '/api/v1/namespaces/test-ns', {
        kind => 'Status', apiVersion => 'v1', status => 'Success',
    });

    my $ok = $kube->delete('Namespace', 'test-ns')->get;
    ok($ok, 'delete returned truthy');

    my $req = MockTransport::last_request();
    is($req->{method}, 'DELETE', 'used DELETE');
    like($req->{path}, qr{/api/v1/namespaces/test-ns}, 'correct path');
};

subtest 'delete by object' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('DELETE', '/api/v1/namespaces/test-ns', {
        kind => 'Status', apiVersion => 'v1', status => 'Success',
    });

    my $ns = $kube->_rest->new_object('Namespace',
        metadata => { name => 'test-ns' },
    );
    my $ok = $kube->delete($ns)->get;
    ok($ok, 'delete by object returned truthy');

    my $req = MockTransport::last_request();
    is($req->{method}, 'DELETE', 'used DELETE');
    like($req->{path}, qr{/api/v1/namespaces/test-ns}, 'correct path for object delete');
};

subtest 'delete namespaced by named args' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('DELETE', '/api/v1/namespaces/default/pods/nginx', {
        kind => 'Status', apiVersion => 'v1', status => 'Success',
    });

    my $ok = $kube->delete('Pod', name => 'nginx', namespace => 'default')->get;
    ok($ok, 'delete with named args works');

    my $req = MockTransport::last_request();
    is($req->{method}, 'DELETE', 'used DELETE');
    like($req->{path}, qr{/api/v1/namespaces/default/pods/nginx}, 'correct namespaced delete path');
};

# ============================================================================
# patch
# ============================================================================

subtest 'patch resource' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('PATCH', '/api/v1/namespaces/default/pods/nginx', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'nginx', namespace => 'default',
                       labels => { env => 'staging' } },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => { phase => 'Running' },
    });

    my $patched = $kube->patch('Pod', 'nginx',
        namespace => 'default',
        patch     => { metadata => { labels => { env => 'staging' } } },
    )->get;
    is($patched->metadata->name, 'nginx', 'patched pod returned');

    my $req = MockTransport::last_request();
    is($req->{method}, 'PATCH', 'used PATCH');
    like($req->{headers}{'Content-Type'}, qr{strategic-merge-patch}, 'default patch type');
};

subtest 'patch with merge type' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('PATCH', '/api/v1/namespaces/default/pods/nginx', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'nginx', namespace => 'default' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => {},
    });

    $kube->patch('Pod', 'nginx',
        namespace => 'default',
        patch     => { metadata => { labels => { env => 'prod' } } },
        type      => 'merge',
    )->get;

    my $req = MockTransport::last_request();
    like($req->{headers}{'Content-Type'}, qr{merge-patch}, 'merge patch content type');
};

subtest 'patch with json type' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('PATCH', '/api/v1/namespaces/default/pods/nginx', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'nginx', namespace => 'default' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => {},
    });

    $kube->patch('Pod', 'nginx',
        namespace => 'default',
        patch     => [{ op => 'add', path => '/metadata/labels/env', value => 'test' }],
        type      => 'json',
    )->get;

    my $req = MockTransport::last_request();
    like($req->{headers}{'Content-Type'}, qr{json-patch}, 'json patch content type');
};

subtest 'patch by object' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('PATCH', '/api/v1/namespaces/default/pods/nginx', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'nginx', namespace => 'default',
                       labels => { env => 'test' } },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => {},
    });

    my $pod = $kube->_rest->new_object('Pod',
        metadata => { name => 'nginx', namespace => 'default' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx' }] },
    );
    my $patched = $kube->patch($pod,
        patch => { metadata => { labels => { env => 'test' } } },
    )->get;
    is($patched->metadata->name, 'nginx', 'patch by object works');

    my $req = MockTransport::last_request();
    is($req->{method}, 'PATCH', 'used PATCH');
    like($req->{headers}{'Content-Type'}, qr{strategic-merge-patch}, 'default patch type for object');
};

# ============================================================================
# Error handling
# ============================================================================

subtest 'HTTP error propagated' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET', '/api/v1/namespaces/nonexistent', {
        kind => 'Status', status => 'Failure',
        message => 'namespaces "nonexistent" not found',
        code => 404,
    }, 404);

    eval { $kube->get('Namespace', 'nonexistent')->get };
    like($@, qr/error|404|Failure/i, 'error from 404');
};

# ============================================================================
# Request headers
# ============================================================================

subtest 'auth header sent' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET', '/api/v1/namespaces', {
        kind => 'NamespaceList', apiVersion => 'v1', items => [],
    });

    $kube->list('Namespace')->get;

    my $req = MockTransport::last_request();
    like($req->{headers}{Authorization}, qr{Bearer mock-token}, 'Bearer token in header');
    is($req->{headers}{Accept}, 'application/json', 'Accept header');
};

# ============================================================================
# public rest / new_object accessors
# ============================================================================

subtest 'rest returns the same instance as _rest' => sub {
    my $kube = make_kube();

    my $rest = $kube->rest;
    isa_ok($rest, 'Kubernetes::REST', 'rest returns a Kubernetes::REST');
    is($rest, $kube->_rest, 'rest and _rest are the identical cached instance');
};

subtest 'new_object mirrors _rest->new_object' => sub {
    my $kube = make_kube();

    my $via_public = $kube->new_object('ConfigMap',
        metadata => { name => 'my-config' },
        data     => { key => 'value' },
    );
    my $via_private = $kube->_rest->new_object('ConfigMap',
        metadata => { name => 'my-config' },
        data     => { key => 'value' },
    );
    isa_ok($via_public, ref($via_private), 'new_object builds the same kind of object');
    is($via_public->metadata->name, 'my-config', 'metadata carried through');
    is($via_public->data->{key}, 'value', 'data carried through');
};

subtest 'object built via new_object round-trips through create' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('POST', '/api/v1/namespaces/default/configmaps', {
        kind => 'ConfigMap', apiVersion => 'v1',
        metadata => { name => 'my-config', namespace => 'default', uid => 'cm-uid' },
        data => { key => 'value' },
    });

    my $cm = $kube->new_object('ConfigMap',
        metadata => { name => 'my-config', namespace => 'default' },
        data     => { key => 'value' },
    );
    my $created = $kube->create($cm)->get;
    is($created->metadata->name, 'my-config', 'created ConfigMap returned');

    my $req = MockTransport::last_request();
    is($req->{method}, 'POST', 'used POST');
    ok($req->{content}, 'request had body');
};

done_testing;
