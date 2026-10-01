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

# ensure/ensure_all/ensure_only, the Future counterparts of Kubernetes::REST's
# own (lib/Kubernetes/REST.pm), whose semantics this exercises: idempotent
# create-or-update with 404/409 race handling, PersistentVolumeClaim/Job
# special-casing, and prune-by-label.

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

sub request_sequence {
    return [ map { "$_->{method} $_->{path}" } MockTransport::request_log ];
}

# ensure/ensure_all/ensure_only don't exist on Net::Async::Kubernetes yet, so a
# bare call dies with "Can't locate object method" -- a fatal exception that
# Test::More's subtest does NOT contain (see t/17-unknown-resource.t's
# identical guard, and t/20-mock-status.t which verified this empirically:
# an unguarded call kills the whole process, so every later subtest would
# silently never run). Route every call through these two helpers so a
# missing method fails just the current subtest's assertions.
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

sub get_list_or_bail {
    my ($label, $f) = @_;
    my @result = eval { $f->get };
    if ($@) {
        fail("$label future resolves without dying");
        diag("died: $@");
        return ();
    }
    return @result;
}

# ============================================================================
# ensure() -- create-or-update
# ============================================================================

subtest 'ensure: does not exist -> GET 404 then POST, result is the created object' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod',
        metadata => { name => 'x', namespace => 'default' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx' }] },
    );

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods/x',
        { kind => 'Status', status => 'Failure', message => 'not found', code => 404 }, 404);
    MockTransport::mock_response('POST', '/api/v1/namespaces/default/pods', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'x', namespace => 'default', resourceVersion => '1' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] }, status => {},
    });

    my $f = future_or_bail('ensure', sub { $kube->ensure($pod) }) or return;
    my $result = get_or_bail('ensure', $f) or return;

    isa_ok($result, 'IO::K8s::Api::Core::V1::Pod');
    is($result->metadata->resourceVersion, '1', 'result is the created object');
    is_deeply(request_sequence(),
        [ 'GET /api/v1/namespaces/default/pods/x', 'POST /api/v1/namespaces/default/pods' ],
        'GET then POST, no PUT');
};

subtest 'ensure: exists -> GET then PUT carrying the existing resourceVersion' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod',
        metadata => { name => 'x', namespace => 'default' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx:2' }] },
    );

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods/x', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'x', namespace => 'default', resourceVersion => '7' },
        spec => { containers => [{ name => 'nginx', image => 'nginx:1' }] }, status => {},
    });
    MockTransport::mock_response('PUT', '/api/v1/namespaces/default/pods/x', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'x', namespace => 'default', resourceVersion => '8' },
        spec => { containers => [{ name => 'nginx', image => 'nginx:2' }] }, status => {},
    });

    my $f = future_or_bail('ensure', sub { $kube->ensure($pod) }) or return;
    my $result = get_or_bail('ensure', $f) or return;

    is($result->metadata->resourceVersion, '8', 'result is the PUT response');
    is_deeply(request_sequence(),
        [ 'GET /api/v1/namespaces/default/pods/x', 'PUT /api/v1/namespaces/default/pods/x' ],
        'GET then PUT');

    my @log = MockTransport::request_log;
    is($JSON->decode($log[1]{content})->{metadata}{resourceVersion}, '7',
        q{PUT body carries the existing resourceVersion from GET, not the caller's});
};

subtest 'ensure: update conflict retries once by refetching, then succeeds' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod',
        metadata => { name => 'x', namespace => 'default' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx:2' }] },
    );

    MockTransport::mock_response_queue('GET', '/api/v1/namespaces/default/pods/x',
        [ { kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'x', namespace => 'default', resourceVersion => '7' },
            spec => { containers => [{ name => 'nginx', image => 'nginx:1' }] }, status => {} }, 200 ],
        [ { kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'x', namespace => 'default', resourceVersion => '8' },
            spec => { containers => [{ name => 'nginx', image => 'nginx:1' }] }, status => {} }, 200 ],
    );
    MockTransport::mock_response_queue('PUT', '/api/v1/namespaces/default/pods/x',
        [ { kind => 'Status', status => 'Failure', message => 'Conflict', code => 409 }, 409 ],
        [ { kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'x', namespace => 'default', resourceVersion => '9' },
            spec => { containers => [{ name => 'nginx', image => 'nginx:2' }] }, status => {} }, 200 ],
    );

    my $f = future_or_bail('ensure', sub { $kube->ensure($pod) }) or return;
    my $result = get_or_bail('ensure', $f) or return;

    is($result->metadata->resourceVersion, '9', 'result is the second PUT response');
    is_deeply(request_sequence(),
        [ 'GET /api/v1/namespaces/default/pods/x',
          'PUT /api/v1/namespaces/default/pods/x',
          'GET /api/v1/namespaces/default/pods/x',
          'PUT /api/v1/namespaces/default/pods/x' ],
        'GET, PUT(409), GET(refetch), PUT(succeeds)');

    my @log = MockTransport::request_log;
    is($JSON->decode($log[3]{content})->{metadata}{resourceVersion}, '8',
        'the retried PUT carries the refetched resourceVersion');
};

subtest 'ensure: a second update conflict is not retried again -- future fails' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod',
        metadata => { name => 'x', namespace => 'default' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx:2' }] },
    );

    MockTransport::mock_response_queue('GET', '/api/v1/namespaces/default/pods/x',
        [ { kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'x', namespace => 'default', resourceVersion => '7' },
            spec => { containers => [{ name => 'nginx', image => 'nginx:1' }] }, status => {} }, 200 ],
        [ { kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'x', namespace => 'default', resourceVersion => '8' },
            spec => { containers => [{ name => 'nginx', image => 'nginx:1' }] }, status => {} }, 200 ],
    );
    MockTransport::mock_response_queue('PUT', '/api/v1/namespaces/default/pods/x',
        [ { kind => 'Status', status => 'Failure', message => 'Conflict', code => 409 }, 409 ],
        [ { kind => 'Status', status => 'Failure', message => 'Conflict', code => 409 }, 409 ],
    );

    my $f = future_or_bail('ensure', sub { $kube->ensure($pod) }) or return;
    ok($f->is_failed, 'future fails after the second conflict');
    is_deeply(request_sequence(),
        [ 'GET /api/v1/namespaces/default/pods/x',
          'PUT /api/v1/namespaces/default/pods/x',
          'GET /api/v1/namespaces/default/pods/x',
          'PUT /api/v1/namespaces/default/pods/x' ],
        'exactly one retry attempted -- no third GET');
};

subtest 'ensure: create race (POST 409) retries as an update' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod',
        metadata => { name => 'x', namespace => 'default' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx' }] },
    );

    MockTransport::mock_response_queue('GET', '/api/v1/namespaces/default/pods/x',
        [ { kind => 'Status', status => 'Failure', message => 'not found', code => 404 }, 404 ],
        [ { kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'x', namespace => 'default', resourceVersion => '3' },
            spec => { containers => [{ name => 'nginx', image => 'nginx' }] }, status => {} }, 200 ],
    );
    MockTransport::mock_response('POST', '/api/v1/namespaces/default/pods',
        { kind => 'Status', status => 'Failure', message => 'AlreadyExists', code => 409 }, 409);
    MockTransport::mock_response('PUT', '/api/v1/namespaces/default/pods/x', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'x', namespace => 'default', resourceVersion => '4' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] }, status => {},
    });

    my $f = future_or_bail('ensure', sub { $kube->ensure($pod) }) or return;
    my $result = get_or_bail('ensure', $f) or return;

    is($result->metadata->resourceVersion, '4', 'result is the PUT response');
    is_deeply(request_sequence(),
        [ 'GET /api/v1/namespaces/default/pods/x',
          'POST /api/v1/namespaces/default/pods',
          'GET /api/v1/namespaces/default/pods/x',
          'PUT /api/v1/namespaces/default/pods/x' ],
        'GET(404), POST(409), GET(refetch), PUT(succeeds)');

    my @log = MockTransport::request_log;
    is($JSON->decode($log[3]{content})->{metadata}{resourceVersion}, '3',
        'PUT carries the resourceVersion from the post-409 refetch');
};

subtest 'ensure: existing PersistentVolumeClaim is returned unchanged, no write' => sub {
    my $kube = make_kube();
    my $pvc = $kube->_rest->new_object('PersistentVolumeClaim',
        metadata => { name => 'pvc1', namespace => 'default' },
    );

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/persistentvolumeclaims/pvc1', {
        kind => 'PersistentVolumeClaim', apiVersion => 'v1',
        metadata => { name => 'pvc1', namespace => 'default', resourceVersion => '5' },
        spec => {}, status => {},
    });

    my $f = future_or_bail('ensure', sub { $kube->ensure($pvc) }) or return;
    my $result = get_or_bail('ensure', $f) or return;

    is($result->metadata->resourceVersion, '5', 'result is the existing PVC');
    is_deeply(request_sequence(),
        [ 'GET /api/v1/namespaces/default/persistentvolumeclaims/pvc1' ],
        'GET only -- no POST or PUT for an existing PVC');
};

subtest 'ensure: PersistentVolumeClaim create-race returns the existing PVC, no PUT' => sub {
    my $kube = make_kube();
    my $pvc = $kube->_rest->new_object('PersistentVolumeClaim',
        metadata => { name => 'pvc1', namespace => 'default' },
    );

    MockTransport::mock_response_queue('GET', '/api/v1/namespaces/default/persistentvolumeclaims/pvc1',
        [ { kind => 'Status', status => 'Failure', message => 'not found', code => 404 }, 404 ],
        [ { kind => 'PersistentVolumeClaim', apiVersion => 'v1',
            metadata => { name => 'pvc1', namespace => 'default', resourceVersion => '5' },
            spec => {}, status => {} }, 200 ],
    );
    MockTransport::mock_response('POST', '/api/v1/namespaces/default/persistentvolumeclaims',
        { kind => 'Status', status => 'Failure', message => 'AlreadyExists', code => 409 }, 409);

    my $f = future_or_bail('ensure', sub { $kube->ensure($pvc) }) or return;
    my $result = get_or_bail('ensure', $f) or return;

    is($result->metadata->resourceVersion, '5', 'result is the existing PVC from the post-409 refetch');
    is_deeply(request_sequence(),
        [ 'GET /api/v1/namespaces/default/persistentvolumeclaims/pvc1',
          'POST /api/v1/namespaces/default/persistentvolumeclaims',
          'GET /api/v1/namespaces/default/persistentvolumeclaims/pvc1' ],
        'GET(404), POST(409), GET(refetch) -- no PUT for a PVC');
};

my $job_spec = { template => { spec => {
    containers    => [{ name => 'c', image => 'busybox' }],
    restartPolicy => 'Never',
} } };

subtest 'ensure: active Job is returned unchanged, no write' => sub {
    my $kube = make_kube();
    my $job = $kube->_rest->new_object('Job',
        metadata => { name => 'job1', namespace => 'default' }, spec => $job_spec);

    MockTransport::mock_response('GET', '/apis/batch/v1/namespaces/default/jobs/job1', {
        kind => 'Job', apiVersion => 'batch/v1',
        metadata => { name => 'job1', namespace => 'default', resourceVersion => '2' },
        spec => $job_spec, status => { active => 1 },
    });

    my $f = future_or_bail('ensure', sub { $kube->ensure($job) }) or return;
    my $result = get_or_bail('ensure', $f) or return;

    is($result->metadata->resourceVersion, '2', 'result is the existing active Job');
    is_deeply(request_sequence(),
        [ 'GET /apis/batch/v1/namespaces/default/jobs/job1' ],
        'GET only -- an active Job is not touched');
};

subtest 'ensure: succeeded Job is returned unchanged, no write' => sub {
    my $kube = make_kube();
    my $job = $kube->_rest->new_object('Job',
        metadata => { name => 'job1', namespace => 'default' }, spec => $job_spec);

    MockTransport::mock_response('GET', '/apis/batch/v1/namespaces/default/jobs/job1', {
        kind => 'Job', apiVersion => 'batch/v1',
        metadata => { name => 'job1', namespace => 'default', resourceVersion => '2' },
        spec => $job_spec, status => { succeeded => 1 },
    });

    my $f = future_or_bail('ensure', sub { $kube->ensure($job) }) or return;
    my $result = get_or_bail('ensure', $f) or return;

    is($result->metadata->resourceVersion, '2', 'result is the existing succeeded Job');
    is_deeply(request_sequence(),
        [ 'GET /apis/batch/v1/namespaces/default/jobs/job1' ],
        'GET only -- a succeeded Job is not touched');
};

subtest 'ensure: failed Job is deleted and recreated' => sub {
    my $kube = make_kube();
    my $job = $kube->_rest->new_object('Job',
        metadata => { name => 'job1', namespace => 'default' }, spec => $job_spec);

    MockTransport::mock_response('GET', '/apis/batch/v1/namespaces/default/jobs/job1', {
        kind => 'Job', apiVersion => 'batch/v1',
        metadata => { name => 'job1', namespace => 'default', resourceVersion => '2' },
        spec => $job_spec, status => { failed => 1 },
    });
    MockTransport::mock_response('DELETE', '/apis/batch/v1/namespaces/default/jobs/job1?propagationPolicy=Background',
        { kind => 'Status', status => 'Success' });
    MockTransport::mock_response('POST', '/apis/batch/v1/namespaces/default/jobs', {
        kind => 'Job', apiVersion => 'batch/v1',
        metadata => { name => 'job1', namespace => 'default', resourceVersion => '10' },
        spec => $job_spec, status => {},
    });

    my $f = future_or_bail('ensure', sub { $kube->ensure($job) }) or return;
    my $result = get_or_bail('ensure', $f) or return;

    is($result->metadata->resourceVersion, '10', 'result is the newly created Job');
    is_deeply(request_sequence(),
        [ 'GET /apis/batch/v1/namespaces/default/jobs/job1',
          'DELETE /apis/batch/v1/namespaces/default/jobs/job1?propagationPolicy=Background',
          'POST /apis/batch/v1/namespaces/default/jobs' ],
        'GET(failed), DELETE, POST');
};

subtest 'ensure: a failing DELETE on a failed Job is ignored, POST still happens' => sub {
    my $kube = make_kube();
    my $job = $kube->_rest->new_object('Job',
        metadata => { name => 'job1', namespace => 'default' }, spec => $job_spec);

    MockTransport::mock_response('GET', '/apis/batch/v1/namespaces/default/jobs/job1', {
        kind => 'Job', apiVersion => 'batch/v1',
        metadata => { name => 'job1', namespace => 'default', resourceVersion => '2' },
        spec => $job_spec, status => { failed => 1 },
    });
    MockTransport::mock_response('DELETE', '/apis/batch/v1/namespaces/default/jobs/job1?propagationPolicy=Background',
        { kind => 'Status', status => 'Failure', message => 'server error', code => 500 }, 500);
    MockTransport::mock_response('POST', '/apis/batch/v1/namespaces/default/jobs', {
        kind => 'Job', apiVersion => 'batch/v1',
        metadata => { name => 'job1', namespace => 'default', resourceVersion => '10' },
        spec => $job_spec, status => {},
    });

    my $f = future_or_bail('ensure', sub { $kube->ensure($job) }) or return;
    my $result = get_or_bail('ensure', $f) or return;

    is($result->metadata->resourceVersion, '10', 'ensure still succeeds despite the failed delete');
    is_deeply(request_sequence(),
        [ 'GET /apis/batch/v1/namespaces/default/jobs/job1',
          'DELETE /apis/batch/v1/namespaces/default/jobs/job1?propagationPolicy=Background',
          'POST /apis/batch/v1/namespaces/default/jobs' ],
        'DELETE is attempted and its failure is ignored -- POST still happens');
};

subtest 'ensure: hashref with kind is inflated to a typed object and ensured' => sub {
    my $kube = make_kube();
    my $manifest = {
        apiVersion => 'v1', kind => 'Secret',
        metadata => { name => 'my-secret', namespace => 'default' },
        stringData => { password => 'hunter2' },
    };

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/secrets/my-secret',
        { kind => 'Status', status => 'Failure', message => 'not found', code => 404 }, 404);
    MockTransport::mock_response('POST', '/api/v1/namespaces/default/secrets', {
        kind => 'Secret', apiVersion => 'v1',
        metadata => { name => 'my-secret', namespace => 'default', resourceVersion => '1' },
        data => {},
    });

    my $f = future_or_bail('ensure', sub { $kube->ensure($manifest) }) or return;
    my $result = get_or_bail('ensure', $f) or return;

    isa_ok($result, 'IO::K8s::Api::Core::V1::Secret', 'result is a typed object');

    my $req = MockTransport::last_request();
    is($req->{method}, 'POST', 'used POST');
    like($req->{content}, qr/"stringData"/, 'POST body carries stringData');
    like($req->{content}, qr/"password"/, 'POST body carries the secret field');
};

subtest 'ensure: hashref without kind croaks, no request' => sub {
    my $kube = make_kube();
    throws_ok { $kube->ensure({ apiVersion => 'v1', metadata => { name => 'x' } })->get }
        qr/kind/i, 'ensure on a kindless hashref croaks synchronously';
    is(scalar(MockTransport::request_log), 0, 'no request was sent');
};

subtest 'ensure: a non-404 GET error fails the Future, no write' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod',
        metadata => { name => 'x', namespace => 'default' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx' }] },
    );

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods/x',
        { kind => 'Status', status => 'Failure', message => 'Forbidden', code => 403 }, 403);

    my $f = future_or_bail('ensure', sub { $kube->ensure($pod) }) or return;
    ok($f->is_failed, 'future fails on a non-404 GET error');
    is_deeply(request_sequence(),
        [ 'GET /api/v1/namespaces/default/pods/x' ],
        'GET only -- no POST or PUT attempted');
};

subtest 'ensure: a non-409 PUT error fails the Future, no retry' => sub {
    my $kube = make_kube();
    my $pod = $kube->_rest->new_object('Pod',
        metadata => { name => 'x', namespace => 'default' },
        spec     => { containers => [{ name => 'nginx', image => 'nginx:2' }] },
    );

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods/x', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'x', namespace => 'default', resourceVersion => '7' },
        spec => { containers => [{ name => 'nginx', image => 'nginx:1' }] }, status => {},
    });
    MockTransport::mock_response('PUT', '/api/v1/namespaces/default/pods/x',
        { kind => 'Status', status => 'Failure', message => 'Unprocessable', code => 422 }, 422);

    my $f = future_or_bail('ensure', sub { $kube->ensure($pod) }) or return;
    ok($f->is_failed, 'future fails on a non-409 PUT error');
    is_deeply(request_sequence(),
        [ 'GET /api/v1/namespaces/default/pods/x', 'PUT /api/v1/namespaces/default/pods/x' ],
        'exactly one GET and one PUT -- no retry on a non-409 error');
};

# ============================================================================
# ensure_all() -- batch of ensure(), in order
# ============================================================================

subtest 'ensure_all: resolves to results in input order' => sub {
    my $kube = make_kube();
    my @objects = map {
        my $n = $_;
        $kube->_rest->new_object('Pod',
            metadata => { name => "pod-$n", namespace => 'default' },
            spec     => { containers => [{ name => 'nginx', image => 'nginx' }] },
        );
    } (1, 2, 3);

    for my $n (1, 2, 3) {
        MockTransport::mock_response('GET', "/api/v1/namespaces/default/pods/pod-$n",
            { kind => 'Status', status => 'Failure', message => 'not found', code => 404 }, 404);
    }
    MockTransport::mock_response_queue('POST', '/api/v1/namespaces/default/pods',
        map {
            my $n = $_;
            [ { kind => 'Pod', apiVersion => 'v1',
                metadata => { name => "pod-$n", namespace => 'default', resourceVersion => "$n" },
                spec => { containers => [{ name => 'nginx', image => 'nginx' }] }, status => {} }, 201 ]
        } (1, 2, 3),
    );

    my $f = future_or_bail('ensure_all', sub { $kube->ensure_all(@objects) }) or return;
    my @results = get_list_or_bail('ensure_all', $f);
    return unless @results;

    is(scalar(@results), 3, 'three results');
    is_deeply([ map { $_->metadata->name } @results ], ['pod-1', 'pod-2', 'pod-3'],
        'results are in input order');
};

subtest 'ensure_all: objects are ensured strictly one after another, not concurrently' => sub {
    my $kube = make_kube();
    my @objects = map {
        my $n = $_;
        $kube->_rest->new_object('Pod',
            metadata => { name => "seq-$n", namespace => 'default' },
            spec     => { containers => [{ name => 'nginx', image => 'nginx' }] },
        );
    } (1, 2, 3);

    # GET is deferred one loop tick. With everything resolving synchronously,
    # a wrongly-parallel ensure_all (e.g. issuing all three GETs up front via
    # a plain map + needs_all) is indistinguishable from a correct
    # one-after-another chain, because nothing ever actually yields to the
    # loop -- Future callbacks on an already-ready Future run immediately,
    # not deferred. Deferring the GET forces a real interleaving point
    # between "start object N" and "object N is done", which is exactly
    # where the two implementations diverge in request order.
    for my $n (1, 2, 3) {
        MockTransport::mock_response('GET', "/api/v1/namespaces/default/pods/seq-$n",
            { kind => 'Status', status => 'Failure', message => 'not found', code => 404 },
            404, { delay => 1 });
    }
    MockTransport::mock_response_queue('POST', '/api/v1/namespaces/default/pods',
        map {
            my $n = $_;
            [ { kind => 'Pod', apiVersion => 'v1',
                metadata => { name => "seq-$n", namespace => 'default', resourceVersion => "$n" },
                spec => { containers => [{ name => 'nginx', image => 'nginx' }] }, status => {} }, 201 ]
        } (1, 2, 3),
    );

    my $f = future_or_bail('ensure_all', sub { $kube->ensure_all(@objects) }) or return;
    my @results = get_list_or_bail('ensure_all', $f);
    return unless @results;

    is_deeply([ map { $_->metadata->name } @results ], ['seq-1', 'seq-2', 'seq-3'],
        'results still in input order');
    is_deeply(request_sequence(),
        [ 'GET /api/v1/namespaces/default/pods/seq-1', 'POST /api/v1/namespaces/default/pods',
          'GET /api/v1/namespaces/default/pods/seq-2', 'POST /api/v1/namespaces/default/pods',
          'GET /api/v1/namespaces/default/pods/seq-3', 'POST /api/v1/namespaces/default/pods' ],
        'object N+1 is not started until object N is fully done -- a concurrent '
      . 'implementation would show all three GETs before any POST');
};

subtest 'ensure_all: a failing object fails the overall Future' => sub {
    my $kube = make_kube();
    my @objects = (
        $kube->_rest->new_object('Pod',
            metadata => { name => 'ok-1', namespace => 'default' },
            spec     => { containers => [{ name => 'nginx', image => 'nginx' }] }),
        $kube->_rest->new_object('Pod',
            metadata => { name => 'bad', namespace => 'default' },
            spec     => { containers => [{ name => 'nginx', image => 'nginx' }] }),
    );

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods/ok-1',
        { kind => 'Status', status => 'Failure', message => 'not found', code => 404 }, 404);
    MockTransport::mock_response('POST', '/api/v1/namespaces/default/pods', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'ok-1', namespace => 'default', resourceVersion => '1' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] }, status => {},
    });
    MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods/bad',
        { kind => 'Status', status => 'Failure', message => 'Forbidden', code => 403 }, 403);

    my $f = future_or_bail('ensure_all', sub { $kube->ensure_all(@objects) }) or return;
    ok($f->is_failed, 'a failing object fails the overall ensure_all Future');
};

# ============================================================================
# ensure_only() -- ensure_all(), then prune by label
# ============================================================================

subtest 'ensure_only: ensures objects, then deletes unlisted items matching the label' => sub {
    my $kube = make_kube();
    my $keep = $kube->_rest->new_object('ConfigMap',
        metadata => { name => 'keep-me', namespace => 'default' },
        data     => { a => '1' },
    );

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/configmaps/keep-me',
        { kind => 'Status', status => 'Failure', message => 'not found', code => 404 }, 404);
    MockTransport::mock_response('POST', '/api/v1/namespaces/default/configmaps', {
        kind => 'ConfigMap', apiVersion => 'v1',
        metadata => { name => 'keep-me', namespace => 'default', resourceVersion => '1' },
        data => { a => '1' },
    });

    MockTransport::mock_response('GET',
        '/api/v1/namespaces/default/configmaps?labelSelector=app.kubernetes.io/component=queen', {
        kind => 'ConfigMapList', apiVersion => 'v1',
        items => [
            { kind => 'ConfigMap', apiVersion => 'v1',
              metadata => { name => 'keep-me', namespace => 'default' }, data => {} },
            { kind => 'ConfigMap', apiVersion => 'v1',
              metadata => { name => 'stale-cm', namespace => 'default' }, data => {} },
        ],
    });
    MockTransport::mock_response('DELETE', '/api/v1/namespaces/default/configmaps/stale-cm?propagationPolicy=Background',
        { kind => 'Status', status => 'Success' });

    my $f = future_or_bail('ensure_only', sub {
        $kube->ensure_only(
            label      => 'app.kubernetes.io/component=queen',
            objects    => [$keep],
            kinds      => ['ConfigMap'],
            namespaces => ['default'],
        )
    }) or return;
    my @applied = get_list_or_bail('ensure_only', $f);
    return unless @applied;

    is(scalar(@applied), 1, 'resolves to the list of ensure_all results');
    is($applied[0]->metadata->name, 'keep-me', 'the ensured object is in the applied list');

    my @deletes = grep { $_->{method} eq 'DELETE' } MockTransport::request_log;
    is(scalar(@deletes), 1, 'exactly one delete');
    is($deletes[0]{path}, '/api/v1/namespaces/default/configmaps/stale-cm?propagationPolicy=Background',
        'the unlisted item is deleted, the expected one is left alone');
};

subtest 'ensure_only: namespaces omitted lists only the cluster-scoped (no-namespace) endpoint' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET',
        '/api/v1/configmaps?labelSelector=app.kubernetes.io/component=queen', {
        kind => 'ConfigMapList', apiVersion => 'v1', items => [],
    });

    my $f = future_or_bail('ensure_only', sub {
        $kube->ensure_only(
            label   => 'app.kubernetes.io/component=queen',
            objects => [],
            kinds   => ['ConfigMap'],
        )
    }) or return;
    get_list_or_bail('ensure_only', $f);

    my @lists = grep { $_->{method} eq 'GET' } MockTransport::request_log;
    is(scalar(@lists), 1, 'exactly one list request');
    is($lists[0]{path}, '/api/v1/configmaps?labelSelector=app.kubernetes.io/component=queen',
        'no /namespaces/ segment when namespaces is omitted');
};

subtest 'ensure_only: undef inside namespaces adds the cluster-scoped list alongside named ones' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET',
        '/api/v1/namespaces/default/configmaps?labelSelector=app.kubernetes.io/component=queen', {
        kind => 'ConfigMapList', apiVersion => 'v1', items => [],
    });
    MockTransport::mock_response('GET',
        '/api/v1/configmaps?labelSelector=app.kubernetes.io/component=queen', {
        kind => 'ConfigMapList', apiVersion => 'v1', items => [],
    });

    my $f = future_or_bail('ensure_only', sub {
        $kube->ensure_only(
            label      => 'app.kubernetes.io/component=queen',
            objects    => [],
            kinds      => ['ConfigMap'],
            namespaces => ['default', undef],
        )
    }) or return;
    get_list_or_bail('ensure_only', $f);

    my @lists = sort map { $_->{path} } grep { $_->{method} eq 'GET' } MockTransport::request_log;
    is_deeply(\@lists, [
        '/api/v1/configmaps?labelSelector=app.kubernetes.io/component=queen',
        '/api/v1/namespaces/default/configmaps?labelSelector=app.kubernetes.io/component=queen',
    ], 'both the namespaced and the cluster-scoped list are requested');
};

subtest 'ensure_only: a failing list for one namespace does not stop the others; a failing delete does not stop the prune' => sub {
    my $kube = make_kube();

    MockTransport::mock_response('GET',
        '/api/v1/namespaces/default/configmaps?labelSelector=app.kubernetes.io/component=queen',
        { kind => 'Status', status => 'Failure', message => 'server error', code => 500 }, 500);

    MockTransport::mock_response('GET',
        '/api/v1/namespaces/kube-system/configmaps?labelSelector=app.kubernetes.io/component=queen', {
        kind => 'ConfigMapList', apiVersion => 'v1',
        items => [
            { kind => 'ConfigMap', apiVersion => 'v1',
              metadata => { name => 'stale-cm', namespace => 'kube-system' }, data => {} },
        ],
    });
    MockTransport::mock_response('DELETE',
        '/api/v1/namespaces/kube-system/configmaps/stale-cm?propagationPolicy=Background',
        { kind => 'Status', status => 'Failure', message => 'server error', code => 500 }, 500);

    # Both failures are reported (t/33-mock-ensure-only-warnings.t has the
    # details); collected here to keep the output clean.
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $f = future_or_bail('ensure_only', sub {
        $kube->ensure_only(
            label      => 'app.kubernetes.io/component=queen',
            objects    => [],
            kinds      => ['ConfigMap'],
            namespaces => ['default', 'kube-system'],
        )
    }) or return;
    get_list_or_bail('ensure_only', $f);
    ok($f->is_done, 'ensure_only future still resolves despite the failing list and delete');
    is(scalar @warnings, 2, 'the failing list and the failing delete each warn');

    my @deletes = grep { $_->{method} eq 'DELETE' } MockTransport::request_log;
    is(scalar(@deletes), 1, 'the delete for the reachable namespace was still attempted');
    is($deletes[0]{path}, '/api/v1/namespaces/kube-system/configmaps/stale-cm?propagationPolicy=Background',
        'delete targeted the item from the namespace whose list succeeded');
};

subtest 'ensure_only: missing label croaks synchronously' => sub {
    my $kube = make_kube();
    throws_ok { $kube->ensure_only(objects => [], kinds => [], namespaces => []) }
        qr/label/i, 'ensure_only without a label croaks';
};

done_testing;
