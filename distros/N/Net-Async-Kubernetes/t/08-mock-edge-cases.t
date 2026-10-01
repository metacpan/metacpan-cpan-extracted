use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use Net::Async::Kubernetes::Watcher;
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
# Kubernetes.pm configure edge cases
# ============================================================================

subtest 'configure with context' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        context     => 'my-context',
        resource_map_from_cluster => 0,
    );
    is($kube->context, 'my-context', 'context stored');
};

subtest 'configure with non-hashref non-blessed credentials' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => 'plain-string-cred',
        resource_map_from_cluster => 0,
    );
    is($kube->credentials, 'plain-string-cred', 'plain string credentials stored');
};

# ============================================================================
# get() edge cases
# ============================================================================

subtest 'get with named name param' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('GET', '/api/v1/namespaces/test', {
        kind => 'Namespace', apiVersion => 'v1',
        metadata => { name => 'test' }, spec => {}, status => {},
    });

    my $ns = $kube->get('Namespace', name => 'test')->get;
    is($ns->metadata->name, 'test', 'get with named name param works');
};

subtest 'get fails with invalid odd args' => sub {
    my $kube = make_kube();
    # To hit the "Invalid arguments" branch: first arg must match name|namespace
    # and total args must be odd
    my $f = $kube->get('Namespace', 'name', 'foo', 'extra');
    ok($f->is_failed, 'get with invalid odd args fails');
    like(($f->failure)[0], qr/Invalid arguments/, 'error message');
};

subtest 'get fails without name' => sub {
    my $kube = make_kube();
    my $f = $kube->get('Namespace', namespace => 'default');
    ok($f->is_failed, 'get without name fails');
    like(($f->failure)[0], qr/name required/, 'error message');
};

# ============================================================================
# update() edge cases
# ============================================================================

subtest 'update croaks without metadata' => sub {
    my $kube = make_kube();
    # Create an object with no metadata method
    my $obj = bless {}, 'IO::K8s::Api::Core::V1::Namespace';
    eval { $kube->update($obj)->get };
    like($@, qr/metadata/, 'update without metadata croaks');
};

subtest 'update croaks without name in metadata' => sub {
    my $kube = make_kube();
    my $obj = $kube->_rest->new_object('Namespace', metadata => {});
    eval { $kube->update($obj)->get };
    like($@, qr/metadata\.name|name/, 'update without name croaks');
};

# ============================================================================
# patch() edge cases
# ============================================================================

subtest 'patch with only named params' => sub {
    my $kube = make_kube();
    MockTransport::mock_response('PATCH', '/api/v1/namespaces/default/pods/nginx', {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'nginx', namespace => 'default' },
        spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
        status => {},
    });

    my $patched = $kube->patch('Pod',
        name      => 'nginx',
        namespace => 'default',
        patch     => { metadata => { labels => { env => 'test' } } },
    )->get;
    is($patched->metadata->name, 'nginx', 'patch with named params works');
};

subtest 'patch fails with invalid args' => sub {
    my $kube = make_kube();
    # First arg must match name|namespace|patch|type and total odd
    my $f = $kube->patch('Pod', 'name', 'x', 'y');
    ok($f->is_failed, 'patch with invalid odd args fails');
    like(($f->failure)[0], qr/Invalid arguments/, 'error message');
};

subtest 'patch fails without name' => sub {
    my $kube = make_kube();
    my $f = $kube->patch('Pod',
        namespace => 'default',
        patch     => { metadata => {} },
    );
    ok($f->is_failed, 'patch without name fails');
    like(($f->failure)[0], qr/name required/, 'error message');
};

subtest 'patch fails without patch param' => sub {
    my $kube = make_kube();
    my $f = $kube->patch('Pod', 'nginx', namespace => 'default');
    ok($f->is_failed, 'patch without patch param fails');
    like(($f->failure)[0], qr/patch requires/, 'error message');
};

subtest 'patch fails with unknown type' => sub {
    my $kube = make_kube();
    my $f = $kube->patch('Pod', 'nginx',
        namespace => 'default',
        patch     => { metadata => {} },
        type      => 'invalid',
    );
    ok($f->is_failed, 'unknown patch type fails');
    like(($f->failure)[0], qr/Unknown patch type/, 'error message');
};

subtest 'patch by object without metadata fails' => sub {
    my $kube = make_kube();
    my $obj = bless {}, 'IO::K8s::Api::Core::V1::Pod';
    my $f = $kube->patch($obj, patch => { metadata => {} });
    ok($f->is_failed, 'patch object without metadata fails');
    like(($f->failure)[0], qr/metadata/, 'error message');
};

subtest 'patch by object without name fails' => sub {
    my $kube = make_kube();
    my $obj = $kube->_rest->new_object('Pod', metadata => {});
    my $f = $kube->patch($obj, patch => { metadata => {} });
    ok($f->is_failed, 'patch object without name fails');
    like(($f->failure)[0], qr/metadata\.name|name/, 'error message');
};

subtest 'patch by object without patch param fails' => sub {
    my $kube = make_kube();
    my $obj = $kube->_rest->new_object('Pod',
        metadata => { name => 'nginx', namespace => 'default' },
    );
    my $f = $kube->patch($obj);
    ok($f->is_failed, 'patch object without patch param fails');
    like(($f->failure)[0], qr/patch requires/, 'error message');
};

# ============================================================================
# delete() edge cases
# ============================================================================

subtest 'delete fails with invalid args' => sub {
    my $kube = make_kube();
    # First arg must match name|namespace and total odd
    my $f = $kube->delete('Pod', 'name', 'x', 'y');
    ok($f->is_failed, 'delete with invalid odd args fails');
    like(($f->failure)[0], qr/Invalid arguments/, 'error message');
};

subtest 'delete fails without name in named args' => sub {
    my $kube = make_kube();
    my $f = $kube->delete('Pod', namespace => 'default');
    ok($f->is_failed, 'delete without name fails');
    like(($f->failure)[0], qr/name required/, 'error message');
};

subtest 'delete by object without metadata fails' => sub {
    my $kube = make_kube();
    my $obj = bless {}, 'IO::K8s::Api::Core::V1::Pod';
    my $f = $kube->delete($obj);
    ok($f->is_failed, 'delete object without metadata fails');
    like(($f->failure)[0], qr/metadata/, 'error message');
};

subtest 'delete by object without name fails' => sub {
    my $kube = make_kube();
    my $obj = $kube->_rest->new_object('Pod', metadata => {});
    my $f = $kube->delete($obj);
    ok($f->is_failed, 'delete object without name fails');
    like(($f->failure)[0], qr/metadata\.name|name/, 'error message');
};

# ============================================================================
# Watcher _add_to_loop validation
# ============================================================================

subtest 'watcher croaks without kube' => sub {
    eval {
        my $w = Net::Async::Kubernetes::Watcher->new(
            resource => 'Pod',
            on_event => sub {},
        );
        $loop->add($w);
    };
    like($@, qr/kube is required/, 'croak without kube');
};

subtest 'watcher croaks without resource' => sub {
    my $kube = make_kube();
    eval {
        my $w = Net::Async::Kubernetes::Watcher->new(
            kube     => $kube,
            on_event => sub {},
        );
        $loop->add($w);
    };
    like($@, qr/resource is required/, 'croak without resource');
};

# ============================================================================
# Watcher _remove_from_loop
# ============================================================================

subtest 'removing watcher from loop calls stop' => sub {
    my $kube = make_kube();
    MockTransport::mock_watch_events('/api/v1/pods', []);

    my $watcher = $kube->watcher('Pod', on_event => sub {});
    ok($watcher->loop, 'watcher has loop');
    $kube->remove_child($watcher);
    ok(!$watcher->loop, 'watcher removed from loop');
    # stop() already called via _remove_from_loop, double stop should be safe
    $watcher->stop;
    ok(1, 'stop after remove is safe');
};

# ============================================================================
# Watcher 410 Gone handling
# ============================================================================

subtest 'watcher handles 410 Gone' => sub {
    my $kube = make_kube();

    MockTransport::mock_watch_events('/api/v1/pods', [
        { type => 'ADDED', object => {
            kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'pod-1', namespace => 'default',
                           resourceVersion => '100' },
            spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
            status => {},
        }},
        { type => 'ERROR', object => {
            kind => 'Status', apiVersion => 'v1',
            status => 'Failure', message => 'Gone: too old resource version',
            code => 410,
        }},
    ]);

    my (@added, @errors);
    my $watcher;
    $watcher = $kube->watcher('Pod',
        on_added => sub { push @added, $_[0]->metadata->name },
        on_error => sub { push @errors, $_[0] },
        on_event => sub {
            # Stop after the ADDED event is processed (410 is handled before dispatch)
            $watcher->stop;
            $loop->stop;
        },
    );

    $loop->watch_time(after => 2, code => sub { $watcher->stop; $loop->stop; });
    $loop->run;

    is_deeply(\@added, ['pod-1'], 'ADDED event dispatched');
    is(scalar @errors, 0, '410 Gone does not reach on_error (handled internally)');
};

# ============================================================================
# Watcher ERROR event dispatch (non-410)
# ============================================================================

subtest 'watcher dispatches non-410 ERROR to on_error' => sub {
    my $kube = make_kube();

    MockTransport::mock_watch_events('/api/v1/pods', [
        { type => 'ERROR', object => {
            kind => 'Status', apiVersion => 'v1',
            status => 'Failure', message => 'Forbidden',
            code => 403,
        }},
    ]);

    my @errors;
    my $watcher;
    $watcher = $kube->watcher('Pod',
        on_error => sub { push @errors, $_[0] },
        on_event => sub {
            $watcher->stop;
            $loop->stop;
        },
    );

    $loop->watch_time(after => 2, code => sub { $watcher->stop; $loop->stop; });
    $loop->run;

    is(scalar @errors, 1, 'on_error received non-410 ERROR');
    is($errors[0]->{code}, 403, 'error code is 403');
    is($errors[0]->{message}, 'Forbidden', 'error message preserved');
};

# ============================================================================
# Watcher on_done reconnect
# ============================================================================

subtest 'watcher reconnects on stream completion' => sub {
    my $kube = make_kube();

    # First watch: one event, then stream completes (simulating server timeout)
    MockTransport::mock_watch_events('/api/v1/namespaces/test/pods', [
        { type => 'ADDED', object => {
            kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'pod-a', namespace => 'test',
                           resourceVersion => '50' },
            spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
            status => {},
        }},
    ], { complete => 1 });

    my @added;
    my $watch_count = 0;
    my $watcher;
    $watcher = $kube->watcher('Pod',
        namespace => 'test',
        on_added  => sub { push @added, $_[0]->metadata->name },
        on_event  => sub {
            $watch_count++;
            # Stop after we've seen at least 2 events (proving reconnect happened)
            if ($watch_count >= 2) {
                $watcher->stop;
                $loop->stop;
            }
        },
    );

    $loop->watch_time(after => 2, code => sub { $watcher->stop; $loop->stop; });
    $loop->run;

    ok($watch_count >= 2, "reconnect happened, saw $watch_count events");
};

# ============================================================================
# Watcher on_fail retry
# ============================================================================

subtest 'watcher retries on stream failure' => sub {
    my $kube = make_kube();

    # Watch stream that fails
    MockTransport::mock_watch_events('/api/v1/namespaces/retry/pods', [
        { type => 'ADDED', object => {
            kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'pod-retry', namespace => 'retry',
                           resourceVersion => '60' },
            spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
            status => {},
        }},
    ], { fail => 'Connection reset' });

    my @added;
    my $event_count = 0;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $watcher;
    $watcher = $kube->watcher('Pod',
        namespace        => 'retry',
        reconnect_jitter => 0,
        on_added         => sub { push @added, $_[0]->metadata->name },
        on_event         => sub {
            $event_count++;
            if ($event_count >= 2) {
                $watcher->stop;
                $loop->stop;
            }
        },
    );

    # Allow 3s for retry (1s delay built into watcher)
    $loop->watch_time(after => 3, code => sub { $watcher->stop; $loop->stop; });
    $loop->run;

    ok($event_count >= 2, "retry happened, saw $event_count events");
    like($warnings[0] // '', qr/^watch Pod failed, retrying in 1s: Connection reset/,
        'the failure is warned about, without on_error');
};

# ============================================================================
# Watcher label_selector and field_selector in request
# ============================================================================

subtest 'watcher passes selectors to request' => sub {
    my $kube = make_kube();

    MockTransport::mock_watch_events('/api/v1/pods', []);

    my $watcher = $kube->watcher('Pod',
        label_selector => 'app=web',
        field_selector => 'status.phase=Running',
        on_event       => sub {},
    );

    my $req = MockTransport::last_request();
    like($req->{url}, qr/labelSelector=app%3Dweb|labelSelector=app=web/,
        'labelSelector in request URL');
    like($req->{url}, qr/fieldSelector=status\.phase%3DRunning|fieldSelector=status.phase=Running/,
        'fieldSelector in request URL');
    $watcher->stop;
};

# ============================================================================
# Watcher with no on_event (only type-specific callbacks)
# ============================================================================

subtest 'watcher without on_event fires type-specific only' => sub {
    my $kube = make_kube();

    MockTransport::mock_watch_events('/api/v1/pods', [
        { type => 'ADDED', object => {
            kind => 'Pod', apiVersion => 'v1',
            metadata => { name => 'solo-pod', namespace => 'default',
                           resourceVersion => '70' },
            spec => { containers => [{ name => 'nginx', image => 'nginx' }] },
            status => {},
        }},
    ]);

    my @added;
    my $watcher;
    $watcher = $kube->watcher('Pod',
        on_added => sub {
            push @added, $_[0]->metadata->name;
            $watcher->stop;
            $loop->stop;
        },
    );

    $loop->watch_time(after => 2, code => sub { $watcher->stop; $loop->stop; });
    $loop->run;

    is_deeply(\@added, ['solo-pod'], 'type-specific callback without on_event');
};

done_testing;
