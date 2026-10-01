use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed);

use lib 't/lib';

use IO::Async::Loop;
use JSON::MaybeXS;
use Net::Async::Kubernetes;
use MockTransport;
use My::StaticWebSite;

# patch_status/update_status, the Future counterparts of Kubernetes::REST's
# own (lib/Kubernetes/REST.pm), whose semantics this exercises: update_status
# is the read-modify-write PUT counterpart of update(), patch_status is
# patch() but against the /status subresource with 'merge' (not 'strategic')
# as the default patch type.

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

sub make_crd_kube {
    MockTransport::reset();
    require IO::K8s;
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map => {
            %{ IO::K8s->default_resource_map },
            StaticWebSite => '+My::StaticWebSite',
        },
        resource_map_from_cluster => 0,
    );
    MockTransport::install($kube);
    $loop->add($kube);
    return $kube;
}

# A *qualified* name IO::K8s::expand_class fails closed on (see
# t/17-unknown-resource.t) -- the deterministic trigger for the "unknown
# resource" Future failure, independent of any real class.
my $BAD = 'bogus.io/v9/Pod';

# update_status/patch_status don't exist on Net::Async::Kubernetes yet, so a
# bare call dies with "Can't locate object method" -- a fatal exception that
# Test::More's subtest does NOT contain (verified: it kills the whole process,
# so every later subtest in the file would silently never run). Route every
# call through here, exactly like t/17-unknown-resource.t's guard, so a
# missing method fails just the current subtest's assertions and the rest of
# the file still gets its say.
sub future_or_bail {
    my ($label, $code) = @_;
    my $f = eval { $code->() };
    if ($@) {
        fail("$label does not die synchronously");
        diag("died: $@");
        return undef;
    }
    unless (blessed($f) && $f->isa('Future')) {
        fail("$label returns a Future");
        return undef;
    }
    return $f;
}

# Blocks on a Future known to be present, without letting a failed Future's
# ->get (which re-throws the failure reason) escape as a fatal die.
sub get_or_bail {
    my ($label, $f) = @_;
    my $result = eval { $f->get };
    if ($@) {
        fail("$label future resolves without dying");
        diag("died: $@");
        return undef;
    }
    return $result;
}

# ============================================================================
# update_status
# ============================================================================

subtest 'update_status: namespaced core kind (Pod) PUTs the full object incl. status' => sub {
    my $kube = make_kube();

    my $pod = $kube->_rest->new_object('Pod',
        metadata => { name => 'x', namespace => 'default', resourceVersion => '5' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status   => { phase => 'Running' },
    );

    MockTransport::mock_response('PUT', '/api/v1/namespaces/default/pods/x/status', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'x', namespace => 'default', resourceVersion => '6' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => { phase => 'Running' },
    });

    my $f = future_or_bail('update_status', sub { $kube->update_status($pod) }) or return;
    my $updated = get_or_bail('update_status', $f) or return;

    isa_ok($updated, 'IO::K8s::Api::Core::V1::Pod');
    is($updated->metadata->resourceVersion, '6',
        'resolves to an object built from the server response');

    my @log = MockTransport::request_log;
    is(scalar(@log), 1, 'exactly one request');
    is($log[0]{method}, 'PUT', 'used PUT');
    is($log[0]{path}, '/api/v1/namespaces/default/pods/x/status',
        'hit the status subresource');
    is_deeply($JSON->decode($log[0]{content}), $pod->TO_JSON,
        'request body is the full object, status included');
};

subtest 'update_status: cluster-scoped kind (Node) hits /nodes/<name>/status' => sub {
    my $kube = make_kube();

    my $node = $kube->_rest->new_object('Node',
        metadata => { name => 'n1', resourceVersion => '3' },
        status   => { phase => 'Ready' },
    );

    MockTransport::mock_response('PUT', '/api/v1/nodes/n1/status', {
        kind => 'Node', apiVersion => 'v1',
        metadata => { name => 'n1', resourceVersion => '4' },
        status => { phase => 'Ready' },
    });

    my $f = future_or_bail('update_status', sub { $kube->update_status($node) }) or return;
    my $updated = get_or_bail('update_status', $f) or return;

    isa_ok($updated, 'IO::K8s::Api::Core::V1::Node');

    my $req = MockTransport::last_request();
    is($req->{method}, 'PUT', 'used PUT');
    is($req->{path}, '/api/v1/nodes/n1/status',
        'no /namespaces/ segment for a cluster-scoped kind');
};

subtest 'update_status: CRD class hits the CRD status subresource' => sub {
    my $kube = make_crd_kube();

    my $site = $kube->_rest->new_object('StaticWebSite',
        metadata => { name => 'my-blog', namespace => 'default' },
        spec     => { domain => 'blog.example.com' },
        status   => { note => 'deployed' },
    );

    MockTransport::mock_response('PUT',
        '/apis/homelab.example.com/v1/namespaces/default/staticwebsites/my-blog/status', {
        kind => 'StaticWebSite', apiVersion => 'homelab.example.com/v1',
        metadata => { name => 'my-blog', namespace => 'default' },
        spec => { domain => 'blog.example.com' }, status => { note => 'deployed' },
    });

    my $f = future_or_bail('update_status', sub { $kube->update_status($site) }) or return;
    my $updated = get_or_bail('update_status', $f) or return;

    is($updated->metadata->name, 'my-blog', 'CRD status update resolved');

    my $req = MockTransport::last_request();
    is($req->{path},
        '/apis/homelab.example.com/v1/namespaces/default/staticwebsites/my-blog/status',
        'hit the CRD status subresource');
};

subtest 'update_status: missing metadata.name croaks like update(), no request sent' => sub {
    my $kube = make_kube();
    my $obj = $kube->_rest->new_object('Pod', metadata => {});

    throws_ok { $kube->update_status($obj)->get } qr/metadata\.name|name/,
        'update_status without a name croaks synchronously, like update()';

    is(scalar(MockTransport::request_log), 0, 'no request was sent');
};

subtest 'update_status: server error fails the Future, names the operation' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod',
        metadata => { name => 'x', namespace => 'default', resourceVersion => '5' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status   => { phase => 'Running' },
    );

    MockTransport::mock_response('PUT', '/api/v1/namespaces/default/pods/x/status',
        { kind => 'Status', status => 'Failure', message => 'Conflict', code => 409 }, 409);

    my $f = future_or_bail('update_status', sub { $kube->update_status($pod) }) or return;
    ok($f->is_failed, 'future fails on server error');
    like(($f->failure)[0], qr/update_status/, 'error names the operation');
};

# ============================================================================
# patch_status
# ============================================================================

subtest 'patch_status: object form defaults to merge, not strategic, and inflates the result' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod', metadata => { name => 'x', namespace => 'default' });

    MockTransport::mock_response('PATCH', '/api/v1/namespaces/default/pods/x/status', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'x', namespace => 'default', resourceVersion => '9' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => { phase => 'Succeeded' },
    });

    my $f = future_or_bail('patch_status', sub {
        $kube->patch_status($pod, patch => { status => { phase => 'Succeeded' } })
    }) or return;
    my $patched = get_or_bail('patch_status', $f) or return;

    isa_ok($patched, 'IO::K8s::Api::Core::V1::Pod');

    my $req = MockTransport::last_request();
    is($req->{method}, 'PATCH', 'used PATCH');
    is($req->{path}, '/api/v1/namespaces/default/pods/x/status', 'hit the status subresource');
    is($req->{headers}{'Content-Type'}, 'application/merge-patch+json',
        'defaults to merge, not strategic as patch() does');
    is_deeply($JSON->decode($req->{content}), { status => { phase => 'Succeeded' } },
        "patch document is passed through unchanged, carries its own 'status' key");
};

subtest 'patch_status: both class+name call forms hit the same path' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('PATCH', '/api/v1/namespaces/default/pods/x/status', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'x', namespace => 'default' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => { phase => 'Succeeded' },
    });

    my $f1 = future_or_bail('patch_status (shorthand)', sub {
        $kube->patch_status('Pod', 'x', namespace => 'default',
            patch => { status => { phase => 'Succeeded' } })
    }) or return;
    my $p1 = get_or_bail('patch_status (shorthand)', $f1) or return;
    isa_ok($p1, 'IO::K8s::Api::Core::V1::Pod', 'shorthand form resolves to an inflated object');

    my $f2 = future_or_bail('patch_status (named)', sub {
        $kube->patch_status('Pod', name => 'x', namespace => 'default',
            patch => { status => { phase => 'Succeeded' } })
    }) or return;
    my $p2 = get_or_bail('patch_status (named)', $f2) or return;
    isa_ok($p2, 'IO::K8s::Api::Core::V1::Pod', 'named-args form resolves to an inflated object');

    my @log = MockTransport::request_log;
    is(scalar(@log), 2, 'both call forms made a request');
    is($log[0]{path}, '/api/v1/namespaces/default/pods/x/status', 'shorthand form path');
    is($log[1]{path}, '/api/v1/namespaces/default/pods/x/status', 'named-args form path');
};

subtest 'patch_status: type selects the Content-Type' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('PATCH', '/api/v1/namespaces/default/pods/x/status', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'x', namespace => 'default' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => { phase => 'Succeeded' },
    });

    my $f1 = future_or_bail('patch_status (strategic)', sub {
        $kube->patch_status('Pod', 'x', namespace => 'default',
            patch => { status => { phase => 'Succeeded' } }, type => 'strategic')
    }) or return;
    get_or_bail('patch_status (strategic)', $f1) or return;
    is((MockTransport::last_request())->{headers}{'Content-Type'},
        'application/strategic-merge-patch+json',
        "type => 'strategic' selects strategic-merge-patch+json");

    my $f2 = future_or_bail('patch_status (json)', sub {
        $kube->patch_status('Pod', 'x', namespace => 'default',
            patch => [{ op => 'replace', path => '/status/phase', value => 'Succeeded' }],
            type  => 'json')
    }) or return;
    get_or_bail('patch_status (json)', $f2) or return;
    my $req = MockTransport::last_request();
    is($req->{headers}{'Content-Type'}, 'application/json-patch+json',
        "type => 'json' selects json-patch+json");
    is_deeply($JSON->decode($req->{content}),
        [{ op => 'replace', path => '/status/phase', value => 'Succeeded' }],
        'array patch document passed through unchanged');
};

subtest 'patch_status: unknown type fails the Future, no request' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod', metadata => { name => 'x', namespace => 'default' });

    my $f = future_or_bail('patch_status', sub {
        $kube->patch_status($pod, patch => { status => {} }, type => 'bogus')
    }) or return;
    ok($f->is_failed, 'unknown patch type fails');
    like(($f->failure)[0], qr/Unknown patch type/, 'error message');
    is(scalar(MockTransport::request_log), 0, 'no request was sent');
};

subtest 'patch_status: missing patch parameter fails the Future, no request' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod', metadata => { name => 'x', namespace => 'default' });

    my $f = future_or_bail('patch_status', sub { $kube->patch_status($pod) }) or return;
    ok($f->is_failed, 'missing patch fails');
    like(($f->failure)[0], qr/patch requires|requires 'patch'/, 'error message');
    is(scalar(MockTransport::request_log), 0, 'no request was sent');
};

subtest 'patch_status: unknown kind fails the Future like patch() does' => sub {
    my $kube = make_kube();
    my $f = future_or_bail('patch_status', sub {
        $kube->patch_status($BAD, 'x', namespace => 'default', patch => { status => {} })
    }) or return;
    ok($f->is_failed, 'unknown resource fails');
    like(($f->failure)[0], qr/unknown resource '\Q$BAD\E'/, 'error names the resource');
};

subtest 'patch_status: server error fails the Future, names the operation' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod', metadata => { name => 'x', namespace => 'default' });

    MockTransport::mock_response('PATCH', '/api/v1/namespaces/default/pods/x/status',
        { kind => 'Status', status => 'Failure', message => 'Unprocessable', code => 422 }, 422);

    my $f = future_or_bail('patch_status', sub {
        $kube->patch_status($pod, patch => { status => { phase => 'Succeeded' } })
    }) or return;
    ok($f->is_failed, 'future fails on server error');
    like(($f->failure)[0], qr/patch_status/, 'error names the operation');
};

done_testing;
