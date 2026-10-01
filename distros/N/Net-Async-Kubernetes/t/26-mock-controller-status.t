use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed);

use lib 't/lib';

use IO::Async::Loop;
use JSON::MaybeXS;
use Net::Async::Kubernetes;
use MockTransport;

# The controller's status helpers are part of its public API with their own
# signature: a status => {...} argument (the helper wraps it as the patch
# document), both call forms, merge as the default patch type, and errors
# reported as failed Futures -- never as a synchronous die, including where
# the client's own update_status croaks. This pins what goes over the wire
# and what comes back, so the helpers can be built on the client's
# patch_status/update_status without their callers noticing.
#
# Mock-only: everything here is request building and error shape.

my $loop = IO::Async::Loop->new;
my $JSON = JSON::MaybeXS->new(utf8 => 1);

my $POD_STATUS = '/api/v1/namespaces/default/pods/pod-1/status';
my %MERGE = (merge => 'application/merge-patch+json');

sub make_controller {
    MockTransport::reset();
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
    );
    MockTransport::install($kube);
    $loop->add($kube);
    my $controller = $kube->controller(on_reconcile => sub { Future->done });
    return ($kube, $controller);
}

sub pod_json {
    my (%status) = @_;
    return {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'pod-1', namespace => 'default', resourceVersion => '12' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status   => { %status },
    };
}

sub pod_object {
    my ($kube, %status) = @_;
    return $kube->new_object(Pod => {
        metadata => { name => 'pod-1', namespace => 'default', resourceVersion => '11' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx' }] },
        (%status ? (status => { %status }) : ()),
    });
}

# Runs one call that must fail: no synchronous die, a failed Future whose
# message matches, and nothing sent.
sub fails_like {
    my ($label, $code, $rx) = @_;
    my $f = eval { $code->() };
    my $err = $@;
    ok(!$err, "$label: does not die synchronously") or diag("died: $err");
    unless (blessed($f) && $f->isa('Future')) {
        fail("$label: returns a Future");
        return;
    }
    ok($f->is_failed, "$label: the Future is failed");
    like(($f->failure)[0] // '', $rx, "$label: failure message");
    is(scalar(MockTransport::request_log), 0, "$label: no request sent");
}

sub request_ok {
    my ($label, %want) = @_;
    my @log = MockTransport::request_log;
    is(scalar(@log), 1, "$label: exactly one request");
    my $req = $log[0] or return;
    is($req->{method}, $want{method}, "$label: method");
    is($req->{path}, $want{path}, "$label: path");
    is($req->{headers}{'Content-Type'}, $want{content_type}, "$label: Content-Type");
    is_deeply($JSON->decode($req->{content}), $want{body}, "$label: body");
}

# ============================================================================
# patch_status
# ============================================================================

subtest 'patch_status: class + name, shorthand and named forms' => sub {
    for my $form (
        [ shorthand => sub { $_[0]->patch_status('Pod', 'pod-1',
              namespace => 'default', status => { phase => 'Running' }) } ],
        [ named     => sub { $_[0]->patch_status('Pod', name => 'pod-1',
              namespace => 'default', status => { phase => 'Running' }) } ],
    ) {
        my ($label, $call) = @$form;
        my ($kube, $controller) = make_controller();
        MockTransport::mock_response('PATCH', $POD_STATUS, pod_json(phase => 'Running'));

        my $patched = eval { $call->($controller)->get };
        is($@, '', "$label: resolves");
        isa_ok($patched, 'IO::K8s::Api::Core::V1::Pod', "$label: result");
        is($patched && $patched->metadata->resourceVersion, '12',
            "$label: inflated from the response");
        request_ok($label,
            method       => 'PATCH',
            path         => $POD_STATUS,
            content_type => $MERGE{merge},
            body         => { status => { phase => 'Running' } },
        );
        $controller->remove_from_parent;
    }
};

subtest 'patch_status: object form, explicit status and the object status fallback' => sub {
    {
        my ($kube, $controller) = make_controller();
        MockTransport::mock_response('PATCH', $POD_STATUS, pod_json(phase => 'Running'));
        my $pod = pod_object($kube, phase => 'Pending');

        my $patched = eval {
            $controller->patch_status($pod, status => { phase => 'Running' })->get
        };
        is($@, '', 'explicit status: resolves');
        isa_ok($patched, 'IO::K8s::Api::Core::V1::Pod', 'explicit status: result');
        request_ok('explicit status',
            method       => 'PATCH',
            path         => $POD_STATUS,
            content_type => $MERGE{merge},
            body         => { status => { phase => 'Running' } },
        );
        $controller->remove_from_parent;
    }
    {
        my ($kube, $controller) = make_controller();
        MockTransport::mock_response('PATCH', $POD_STATUS, pod_json(phase => 'Pending'));
        my $pod = pod_object($kube, phase => 'Pending');

        my $patched = eval { $controller->patch_status($pod)->get };
        is($@, '', 'status fallback: resolves');
        isa_ok($patched, 'IO::K8s::Api::Core::V1::Pod', 'status fallback: result');
        request_ok('status fallback',
            method       => 'PATCH',
            path         => $POD_STATUS,
            content_type => $MERGE{merge},
            body         => { status => { phase => 'Pending' } },
        );
        $controller->remove_from_parent;
    }
};

subtest 'patch_status: cluster-scoped kind has no namespace segment' => sub {
    my ($kube, $controller) = make_controller();
    MockTransport::mock_response('PATCH', '/api/v1/nodes/n1/status', {
        kind => 'Node', apiVersion => 'v1', metadata => { name => 'n1' },
        status => { phase => 'Running' },
    });

    my $node = eval {
        $controller->patch_status('Node', 'n1', status => { phase => 'Running' })->get
    };
    is($@, '', 'resolves');
    isa_ok($node, 'IO::K8s::Api::Core::V1::Node', 'result');
    request_ok('Node',
        method       => 'PATCH',
        path         => '/api/v1/nodes/n1/status',
        content_type => $MERGE{merge},
        body         => { status => { phase => 'Running' } },
    );
    $controller->remove_from_parent;
};

subtest 'patch_status: type selects the Content-Type' => sub {
    for my $case (
        [ strategic => 'application/strategic-merge-patch+json' ],
        [ json      => 'application/json-patch+json' ],
        [ merge     => 'application/merge-patch+json' ],
    ) {
        my ($type, $content_type) = @$case;
        my ($kube, $controller) = make_controller();
        MockTransport::mock_response('PATCH', $POD_STATUS, pod_json(phase => 'Running'));

        eval {
            $controller->patch_status('Pod', 'pod-1', namespace => 'default',
                status => { phase => 'Running' }, type => $type)->get;
        };
        is($@, '', "$type: resolves");
        is(MockTransport::last_request()->{headers}{'Content-Type'}, $content_type,
            "$type: Content-Type");
        $controller->remove_from_parent;
    }
};

subtest 'patch_status: argument errors fail the Future' => sub {
    my ($kube, $controller) = make_controller();
    my $status = { phase => 'Running' };

    fails_like('odd argument list',
        sub { $controller->patch_status('Pod', name => 'pod-1', 'status') },
        qr/^Invalid arguments to patch_status\(\)/);
    fails_like('class form without name',
        sub { $controller->patch_status('Pod', namespace => 'default', status => $status) },
        qr/^name required for patch_status/);
    fails_like('class form without status',
        sub { $controller->patch_status('Pod', 'pod-1', namespace => 'default') },
        qr/^status required for patch_status/);
    fails_like('object without metadata',
        sub { $controller->patch_status($kube->new_object(Pod => {}), status => $status) },
        qr/^object must have metadata\b/);
    fails_like('object without metadata.name',
        sub { $controller->patch_status(
            $kube->new_object(Pod => { metadata => { namespace => 'default' } }),
            status => $status) },
        qr/^object must have metadata\.name/);
    fails_like('object form without any status',
        sub { $controller->patch_status(pod_object($kube)) },
        qr/^status required for patch_status/);
    # No status attribute to fall back on: the fallback is skipped, not called.
    fails_like('object form, class without a status attribute',
        sub { $controller->patch_status($kube->new_object(ConfigMap => {
            metadata => { name => 'cm-1', namespace => 'default' } })) },
        qr/^status required for patch_status/);
    fails_like('unknown patch type',
        sub { $controller->patch_status('Pod', 'pod-1', namespace => 'default',
            status => $status, type => 'bogus') },
        qr/^Unknown patch type 'bogus'/);
    fails_like('qualified unknown resource',
        sub { $controller->patch_status('bogus.io/v9/Pod', 'pod-1', status => $status) },
        qr/^unknown resource 'bogus\.io\/v9\/Pod'/);
    fails_like('bare unknown Kind',
        sub { $controller->patch_status('Bogus', 'pod-1', status => $status) },
        qr/^unknown resource 'Bogus'/);

    $controller->remove_from_parent;
};

# karr k68: an odd list after the object, or after a positional name, was
# assigned to a hash anyway - Perl warned "Odd number of elements" and the
# patch went out with the stray key's value undef (a trailing 'type' sent a
# merge patch). It fails the Future like the keyed class form, and warns
# nothing.
subtest 'patch_status: an odd argument list fails without a warning' => sub {
    my ($kube, $controller) = make_controller();
    MockTransport::mock_response('PATCH', $POD_STATUS, pod_json(phase => 'Running'));
    my $status = { phase => 'Running' };
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    fails_like('object form, a stray key',
        sub { $controller->patch_status(pod_object($kube), status => $status, 'type') },
        qr/\AInvalid arguments to patch_status\(\)\z/);
    fails_like('object form, a lone key',
        sub { $controller->patch_status(pod_object($kube, phase => 'Pending'), 'status') },
        qr/\AInvalid arguments to patch_status\(\)\z/);
    fails_like('class form, a positional name and a stray key',
        sub { $controller->patch_status('Pod', 'pod-1', namespace => 'default',
            status => $status, 'type') },
        qr/\AInvalid arguments to patch_status\(\)\z/);
    is_deeply(\@warnings, [], 'no warning');

    $controller->remove_from_parent;
};

subtest 'patch_status: a server error fails the Future' => sub {
    my ($kube, $controller) = make_controller();
    MockTransport::mock_response('PATCH', $POD_STATUS,
        { kind => 'Status', status => 'Failure', message => 'boom', code => 500 }, 500);

    my $f = $controller->patch_status('Pod', 'pod-1',
        namespace => 'default', status => { phase => 'Running' });
    eval { $f->await };
    ok($f->is_failed, 'the Future is failed');
    like(($f->failure)[0], qr/\b500\b.*boom/s, 'failure carries status and message');
    like(($f->failure)[0], qr/IO::K8s::Api::Core::V1::Pod/, 'failure names the class');
    $controller->remove_from_parent;
};

# ============================================================================
# update_status
# ============================================================================

subtest 'update_status: PUTs the full object to the status subresource' => sub {
    my ($kube, $controller) = make_controller();
    MockTransport::mock_response('PUT', $POD_STATUS, pod_json(phase => 'Running'));
    my $pod = pod_object($kube, phase => 'Running');

    my $updated = eval { $controller->update_status($pod)->get };
    is($@, '', 'resolves');
    isa_ok($updated, 'IO::K8s::Api::Core::V1::Pod', 'result');
    is($updated && $updated->metadata->resourceVersion, '12', 'inflated from the response');
    request_ok('update_status',
        method       => 'PUT',
        path         => $POD_STATUS,
        content_type => 'application/json',
        body         => $pod->TO_JSON,
    );
    $controller->remove_from_parent;
};

subtest 'update_status: errors fail the Future, never die' => sub {
    my ($kube, $controller) = make_controller();

    fails_like('object without metadata',
        sub { $controller->update_status($kube->new_object(Pod => {})) },
        qr/^object must have metadata\b/);
    # The client's update_status croaks here; the controller helper must not.
    fails_like('object without metadata.name',
        sub { $controller->update_status(
            $kube->new_object(Pod => { metadata => { namespace => 'default' } })) },
        qr/^object must have metadata\.name/);

    MockTransport::mock_response('PUT', $POD_STATUS,
        { kind => 'Status', status => 'Failure', message => 'conflict', code => 409 }, 409);
    my $f = $controller->update_status(pod_object($kube, phase => 'Running'));
    eval { $f->await };
    ok($f->is_failed, 'server error: the Future is failed');
    like(($f->failure)[0], qr/\b409\b.*conflict/s, 'server error: status and message');
    like(($f->failure)[0], qr/IO::K8s::Api::Core::V1::Pod/, 'server error: names the class');

    $controller->remove_from_parent;
};

done_testing;
