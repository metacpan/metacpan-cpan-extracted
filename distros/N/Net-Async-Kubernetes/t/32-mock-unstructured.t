use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use JSON::MaybeXS;
use IO::K8s::Unstructured;
use Kubernetes::REST;
use Net::Async::Kubernetes;
use MockTransport;

# karr k41: a Kind no IO::K8s class ships resolves, with
# resource_map_from_cluster, to IO::K8s::Unstructured once the cluster's
# discovery confirms it. That class has no api_version of its own - Kind and
# apiVersion are instance data - so build_path needs both from the caller and
# looks plural and scope up in the discovery catalog. The client has to pass
# them on wherever it builds a path: from the name it was given (a qualified
# 'group/version/Kind' keeps its group and version, as in Kubernetes::REST's
# k40), or from the object. Without them every request for such a Kind died
# synchronously in build_path with "needs a Kind".
#
# ensure() and ensure_only() then tell Unstructured objects apart by their
# instance data (t/25 and t/27 cover the same rules with typed stand-ins):
# the batch/v1 Job and core v1 PersistentVolumeClaim special cases, and the
# prune key of ensure_only.
#
# Mock-only. Kubernetes::REST fetches its discovery catalog (GET /api, GET
# /apis) through its own io backend, not through this client's transport, so
# the client below hands it one through Kubernetes::REST's public io
# attribute. Every resource request still goes through the mocked _do_request.

{
    package Test::DiscoveryIO;
    use Moo;
    use JSON::MaybeXS ();
    use Kubernetes::REST::HTTPResponse;

    # path => the document served there; anything else is a 404.
    has documents => (is => 'ro', required => 1);
    has requests  => (is => 'ro', default => sub { [] });

    my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

    sub call {
        my ($self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        push @{ $self->requests }, $req->method . ' ' . $path;
        my $document = $self->documents->{$path};
        return Kubernetes::REST::HTTPResponse->new(
            status  => $document ? 200 : 404,
            content => $json->encode($document // { kind => 'Status', code => 404 }),
        );
    }

    sub call_streaming { die "Test::DiscoveryIO does not stream\n" }

    with 'Kubernetes::REST::Role::IO';
}

{
    package Test::DiscoveryKube;
    use parent -norequire, 'Net::Async::Kubernetes';

    sub configure {
        my ($self, %params) = @_;
        $self->{discovery_io} = delete $params{discovery_io} if exists $params{discovery_io};
        $self->SUPER::configure(%params);
    }

    # The client's own Kubernetes::REST, plus the discovery io.
    sub rest {
        my ($self) = @_;
        $self->{_test_rest} //= Kubernetes::REST->new(
            server                    => $self->server,
            credentials               => $self->credentials,
            resource_map_from_cluster => $self->resource_map_from_cluster,
            io                        => $self->{discovery_io},
        );
    }
}

my $loop = IO::Async::Loop->new;
my $JSON = JSON::MaybeXS->new(utf8 => 1);

# One APIGroupDiscoveryList item: $group serving, per version, each
# [ Kind, plural, scope ].
sub group_entry {
    my ($group, @versions) = @_;
    return {
        metadata => { name => $group },
        versions => [ map {
            my ($version, @resources) = @$_;
            +{
                version   => $version,
                resources => [ map {
                    my ($kind, $plural, $scope) = @$_;
                    +{
                        resource     => $plural,
                        responseKind => { group => $group, version => $version, kind => $kind },
                        scope        => $scope // 'Namespaced',
                    };
                } @resources ],
            };
        } @versions ],
    };
}

# A client whose cluster serves the core v1 PersistentVolumeClaim plus the
# given API groups.
sub make_kube {
    my (@groups) = @_;
    my $io = Test::DiscoveryIO->new(documents => {
        '/api' => {
            kind => 'APIGroupDiscoveryList', apiVersion => 'apidiscovery.k8s.io/v2',
            items => [ group_entry('', [ 'v1', [ 'PersistentVolumeClaim', 'persistentvolumeclaims' ] ]) ],
        },
        '/apis' => {
            kind => 'APIGroupDiscoveryList', apiVersion => 'apidiscovery.k8s.io/v2',
            items => \@groups,
        },
    });
    MockTransport::reset();
    my $kube = Test::DiscoveryKube->new(
        server                    => { endpoint => 'https://mock.local' },
        credentials               => { token => 'mock-token' },
        resource_map_from_cluster => 1,
        discovery_io              => $io,
    );
    MockTransport::install($kube);
    $loop->add($kube);
    return ($kube, $io);
}

sub calls {
    return [ map { "$_->{method} $_->{path}" } MockTransport::request_log ];
}

sub requests {
    my ($method) = @_;
    return [ map { $_->{path} } grep { $_->{method} eq $method } MockTransport::request_log ];
}

sub manifest {
    my ($api_version, $kind, $name, %extra) = @_;
    return {
        apiVersion => $api_version,
        kind       => $kind,
        metadata   => { name => $name, namespace => 'ns', %{ delete $extra{metadata} || {} } },
        %extra,
    };
}

sub unstructured { IO::K8s::Unstructured->FROM_HASH(manifest(@_)) }

my $NOT_FOUND = { kind => 'Status', status => 'Failure', message => 'not found', code => 404 };
my $SUCCESS   = { kind => 'Status', apiVersion => 'v1', status => 'Success' };
my $BG        = '?propagationPolicy=Background';   # what ensure and ensure_only delete with

# ============================================================================
# Path building
# ============================================================================

subtest 'a Kind resolved through discovery builds its path from the discovery entry' => sub {
    my ($kube, $io) = make_kube(group_entry('example.com', [ 'v1', [ 'Widget', 'widgets' ] ]));
    my $WIDGETS = '/apis/example.com/v1/namespaces/ns/widgets';
    my $w1 = manifest('example.com/v1', 'Widget', 'w1', metadata => { resourceVersion => '1' });

    is($kube->expand_class('Widget'), 'IO::K8s::Unstructured',
        'premise: Widget resolves to IO::K8s::Unstructured');

    MockTransport::mock_response('GET', $WIDGETS,
        { apiVersion => 'example.com/v1', kind => 'WidgetList', items => [ $w1 ] });
    MockTransport::mock_response($_, "$WIDGETS/w1", $w1) for qw(GET PUT PATCH);
    MockTransport::mock_response($_, "$WIDGETS/w1/status", $w1) for qw(PUT PATCH);
    MockTransport::mock_response('POST', $WIDGETS, $w1);
    MockTransport::mock_response('DELETE', "$WIDGETS/w1", $SUCCESS);

    my $patch = { spec => { color => 'blue' } };
    my %by_name = (
        list         => sub { $kube->list('Widget', namespace => 'ns') },
        get          => sub { $kube->get('Widget', 'w1', namespace => 'ns') },
        patch        => sub { $kube->patch('Widget', 'w1', namespace => 'ns', patch => $patch, type => 'merge') },
        patch_status => sub { $kube->patch_status('Widget', 'w1', namespace => 'ns', patch => { status => {} }) },
        delete       => sub { $kube->delete('Widget', 'w1', namespace => 'ns') },
    );
    my $object = unstructured('example.com/v1', 'Widget', 'w1');
    my %by_object = (
        create        => sub { $kube->create($object) },
        update        => sub { $kube->update($object) },
        update_status => sub { $kube->update_status($object) },
        patch         => sub { $kube->patch($object, patch => $patch, type => 'merge') },
        patch_status  => sub { $kube->patch_status($object, patch => { status => {} }) },
        delete        => sub { $kube->delete($object) },
    );

    my %want = (
        list          => "GET $WIDGETS",
        get           => "GET $WIDGETS/w1",
        create        => "POST $WIDGETS",
        update        => "PUT $WIDGETS/w1",
        update_status => "PUT $WIDGETS/w1/status",
        patch         => "PATCH $WIDGETS/w1",
        patch_status  => "PATCH $WIDGETS/w1/status",
        delete        => "DELETE $WIDGETS/w1",
    );
    for my $form ([ 'name', \%by_name ], [ 'object', \%by_object ]) {
        my ($label, $calls) = @$form;
        for my $method (sort keys %$calls) {
            my $before = scalar(MockTransport::request_log);
            my $result = eval { $calls->{$method}->()->get };
            is($@, '', "$method ($label form) does not die");
            my @sent = @{ calls() }[ $before .. scalar(MockTransport::request_log) - 1 ];
            is_deeply(\@sent, [ $want{$method} ], "$method ($label form) goes to the discovery path");
            if ($method eq 'list') {
                isa_ok($result && $result->items->[0], 'IO::K8s::Unstructured', 'a listed item');
            } elsif ($method ne 'delete') {
                isa_ok($result, 'IO::K8s::Unstructured', "the $method result");
            }
        }
    }

    is_deeply($io->requests, [ 'GET /api', 'GET /apis' ],
        "Kubernetes::REST's own io only fetched discovery, once");
};

subtest 'a qualified name keeps its group and version, not the first group serving the Kind' => sub {
    # a.example.org sorts ahead of example.org - the group the bare Kind
    # would land in.
    my ($kube) = make_kube(
        group_entry('a.example.org', [ 'v1', [ 'Widget', 'widgets' ] ]),
        group_entry('example.org',   [ 'v1', [ 'Widget', 'widgets' ] ]),
    );
    my $GVK     = 'example.org/v1/Widget';
    my $WIDGETS = '/apis/example.org/v1/namespaces/ns/widgets';
    my $w1 = manifest('example.org/v1', 'Widget', 'w1');

    is($kube->expand_class($GVK), 'IO::K8s::Unstructured',
        'premise: the qualified name resolves to IO::K8s::Unstructured');

    MockTransport::mock_response('GET', $WIDGETS,
        { apiVersion => 'example.org/v1', kind => 'WidgetList', items => [ $w1 ] });
    MockTransport::mock_response('GET', "$WIDGETS/w1", $w1);
    MockTransport::mock_response('DELETE', "$WIDGETS/w1", $SUCCESS);

    for my $call (
        [ list   => sub { $kube->list($GVK, namespace => 'ns') } ],
        [ get    => sub { $kube->get($GVK, 'w1', namespace => 'ns') } ],
        [ delete => sub { $kube->delete($GVK, 'w1', namespace => 'ns') } ],
    ) {
        my ($method, $code) = @$call;
        eval { $code->()->get };
        is($@, '', "$method does not die");
    }
    is_deeply(calls(), [ "GET $WIDGETS", "GET $WIDGETS/w1", "DELETE $WIDGETS/w1" ],
        'list, get and delete stay in example.org');

    MockTransport::mock_watch_events($WIDGETS, [ { type => 'ADDED', object => $w1 } ]);
    my @added;
    my $watcher = eval {
        $kube->watcher($GVK,
            namespace => 'ns',
            on_added  => sub { push @added, $_[0]; $loop->stop },
        );
    };
    is($@, '', 'the watcher starts');
    $loop->watch_time(after => 2, code => sub { $loop->stop });
    $loop->run if $watcher;
    $watcher->stop if $watcher;

    is_deeply([ grep { m{/watch|widgets} } map { $_->{path} } grep { $_->{streaming} } MockTransport::request_log ],
        [ $WIDGETS ], 'the watch goes to example.org');
    isa_ok($added[0], 'IO::K8s::Unstructured', 'the watched object');
    is($added[0] && $added[0]->kind, 'Widget', 'the watched object keeps its Kind');
    is_deeply([ grep { /a\.example\.org/ } @{ calls() } ], [], 'nothing went to a.example.org');
};

subtest 'a qualified name whose group/version is not served sends nothing anywhere' => sub {
    # karr k56 (Kubernetes::REST k43): example.org/v1 is not served, but
    # a.example.org/v1 and example.org/v2 serve a Widget. A qualified name
    # counts only in its own group and version; a fallback would list,
    # delete and prune in one of the others.
    my ($kube, $io) = make_kube(
        group_entry('a.example.org', [ 'v1', [ 'Widget', 'widgets' ] ]),
        group_entry('example.org',   [ 'v2', [ 'Widget', 'widgets' ] ]),
    );
    my $GVK = 'example.org/v1/Widget';

    # Anything that lands in a group/version that does serve a Widget
    # succeeds, so a misrouted request shows up as one.
    for my $gv ('a.example.org/v1', 'example.org/v2') {
        my $widgets = "/apis/$gv/namespaces/ns/widgets";
        my $w1 = manifest($gv, 'Widget', 'w1', metadata => { labels => { app => 'demo' } });
        MockTransport::mock_response('GET', $_,
            { apiVersion => $gv, kind => 'WidgetList', items => [ $w1 ] })
            for $widgets, "$widgets?labelSelector=app=demo";
        MockTransport::mock_response($_, "$widgets/w1", $w1) for qw(GET PUT PATCH);
        MockTransport::mock_response($_, "$widgets/w1/status", $w1) for qw(PUT PATCH);
        MockTransport::mock_response('POST', $widgets, $w1);
        MockTransport::mock_response('DELETE', "$widgets/w1", $SUCCESS);
        MockTransport::mock_response('GET', "$widgets/w1/log", 'a line');
        MockTransport::mock_watch_events($widgets, [ { type => 'ADDED', object => $w1 } ]);
    }

    my $croak = eval { $kube->expand_class($GVK); 1 } ? '' : $@;
    like($croak, qr{example\.org/v1}, 'expand_class croaks, naming the group/version');

    for my $call (
        [ list         => sub { $kube->list($GVK, namespace => 'ns') } ],
        [ get          => sub { $kube->get($GVK, 'w1', namespace => 'ns') } ],
        [ patch        => sub { $kube->patch($GVK, 'w1', namespace => 'ns', patch => {}, type => 'merge') } ],
        [ patch_status => sub { $kube->patch_status($GVK, 'w1', namespace => 'ns', patch => { status => {} }) } ],
        [ delete       => sub { $kube->delete($GVK, 'w1', namespace => 'ns') } ],
        [ log          => sub { $kube->log($GVK, 'w1', namespace => 'ns') } ],
        [ port_forward => sub { $kube->port_forward($GVK, 'w1', namespace => 'ns', ports => [80]) } ],
        [ exec         => sub { $kube->exec($GVK, 'w1', namespace => 'ns', command => ['true']) } ],
        [ attach       => sub { $kube->attach($GVK, 'w1', namespace => 'ns') } ],
    ) {
        my ($method, $code) = @$call;
        my $f = eval { $code->() };
        is($@, '', "$method does not croak");
        ok($f && $f->is_failed, "$method returns a failed Future");
        like($f && $f->is_failed ? ($f->failure)[0] : '', qr{example\.org/v1}, "$method: the failure names the group/version");
    }

    my $watch_croak = eval {
        $kube->watcher($GVK, namespace => 'ns', on_added => sub { });
        1;
    } ? '' : $@;
    like($watch_croak, qr{example\.org/v1}, 'the watcher croaks when it starts');

    my @warnings;
    my @applied = eval {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $kube->ensure_only(
            label      => 'app=demo',
            objects    => [],
            kinds      => [ $GVK ],
            namespaces => ['ns'],
        )->get;
    };
    is($@, '', 'ensure_only does not die');
    is(scalar @warnings, 1, 'ensure_only warns once');
    like($warnings[0] // '', qr{cannot list \Q$GVK\E in namespace 'ns', nothing pruned there},
        'ensure_only: the entry is skipped, not listed elsewhere');

    # The same apiVersion on an Unstructured object, and in a manifest.
    my $object = unstructured('example.org/v1', 'Widget', 'w1');
    for my $call (
        [ create       => sub { $kube->create($object) } ],
        [ patch        => sub { $kube->patch($object, patch => {}, type => 'merge') } ],
        [ patch_status => sub { $kube->patch_status($object, patch => { status => {} }) } ],
        [ delete       => sub { $kube->delete($object) } ],
    ) {
        my ($method, $code) = @$call;
        my $f = eval { $code->() };
        is($@, '', "$method (object) does not croak");
        like($f && $f->is_failed ? ($f->failure)[0] : '', qr{example\.org/v1},
            "$method (object) returns a failed Future naming the apiVersion");
    }
    for my $call (
        [ update            => sub { $kube->update($object) } ],
        [ update_status     => sub { $kube->update_status($object) } ],
        [ ensure            => sub { $kube->ensure($object) } ],
        [ 'ensure manifest' => sub { $kube->ensure(manifest('example.org/v1', 'Widget', 'w1')) } ],
    ) {
        my ($method, $code) = @$call;
        my $croak = eval { $code->(); 1 } ? '' : $@;
        like($croak, qr{example\.org/v1}, "$method croaks, naming the apiVersion");
    }

    is_deeply(calls(), [], 'no request was sent, to any group or version');
    is_deeply($io->requests, [ 'GET /api', 'GET /apis' ], "Kubernetes::REST's own io only fetched discovery");
};

subtest 'log, port_forward, exec and attach take the discovery path too' => sub {
    my ($kube) = make_kube(group_entry('example.com', [ 'v1', [ 'Widget', 'widgets' ] ]));
    my $W1 = '/apis/example.com/v1/namespaces/ns/widgets/w1';

    MockTransport::mock_response('GET', "$W1/log", 'a line');
    MockTransport::mock_duplex_session({ ok => 1 });

    for my $call (
        [ log          => sub { $kube->log('Widget', 'w1', namespace => 'ns') } ],
        [ port_forward => sub { $kube->port_forward('Widget', 'w1', namespace => 'ns', ports => [80]) } ],
        [ exec         => sub { $kube->exec('Widget', 'w1', namespace => 'ns', command => ['true']) } ],
        [ attach       => sub { $kube->attach('Widget', 'w1', namespace => 'ns') } ],
    ) {
        my ($method, $code) = @$call;
        eval { $code->()->get };
        is($@, '', "$method does not die");
    }
    is_deeply([ map { $_->{path} } MockTransport::request_log ],
        [ "$W1/log", "$W1/portforward", "$W1/exec", "$W1/attach" ],
        'each subresource hangs off the discovery path');
};

# ============================================================================
# ensure()
# ============================================================================

subtest 'ensure: a manifest resolved through discovery is created, then updated' => sub {
    my ($kube) = make_kube(group_entry('example.com', [ 'v1', [ 'Widget', 'widgets' ] ]));
    my $WIDGETS = '/apis/example.com/v1/namespaces/ns/widgets';

    MockTransport::mock_response('GET', "$WIDGETS/w1", $NOT_FOUND, 404);
    MockTransport::mock_response('POST', $WIDGETS,
        manifest('example.com/v1', 'Widget', 'w1', metadata => { resourceVersion => '1' }));
    my $created = eval { $kube->ensure(manifest('example.com/v1', 'Widget', 'w1'))->get };
    is($@, '', 'ensure (absent) does not die');
    isa_ok($created, 'IO::K8s::Unstructured', 'the created object');
    is_deeply(calls(), [ "GET $WIDGETS/w1", "POST $WIDGETS" ], 'GET 404, then POST');

    MockTransport::reset();
    MockTransport::mock_response('GET', "$WIDGETS/w1",
        manifest('example.com/v1', 'Widget', 'w1', metadata => { resourceVersion => '7' }));
    MockTransport::mock_response('PUT', "$WIDGETS/w1",
        manifest('example.com/v1', 'Widget', 'w1', metadata => { resourceVersion => '8' }));
    my $updated = eval { $kube->ensure(manifest('example.com/v1', 'Widget', 'w1'))->get };
    is($@, '', 'ensure (present) does not die');
    is($updated && $updated->metadata->resourceVersion, '8', 'the updated object');
    is_deeply(calls(), [ "GET $WIDGETS/w1", "PUT $WIDGETS/w1" ], 'GET, then PUT');
    my ($put) = grep { $_->{method} eq 'PUT' } MockTransport::request_log;
    is($put && $JSON->decode($put->{content})->{metadata}{resourceVersion}, '7',
        'PUT at the server resourceVersion');
};

subtest 'ensure: the Job and PVC special cases follow the instance data' => sub {
    # batch/v2 does not exist; it stands for "an apiVersion the Job special
    # case was not written for".
    my ($kube) = make_kube(
        group_entry('batch', [ 'v1', [ 'Job', 'jobs' ] ], [ 'v2', [ 'Job', 'jobs' ] ]),
        group_entry('example.com', [ 'v1', [ 'Job', 'jobs' ] ]),
    );
    my $BATCH = '/apis/batch/v1/namespaces/ns/jobs';

    # Kubernetes::REST t/17 case 13: the real batch/v1 Job, succeeded.
    MockTransport::mock_response('GET', "$BATCH/done", manifest('batch/v1', 'Job', 'done',
        metadata => { resourceVersion => '3' }, status => { succeeded => 1 }));
    my $kept = eval { $kube->ensure(unstructured('batch/v1', 'Job', 'done'))->get };
    is($@, '', 'succeeded batch/v1 Job: ensure does not die');
    isa_ok($kept, 'IO::K8s::Unstructured', 'succeeded batch/v1 Job: the result');
    is_deeply(calls(), [ "GET $BATCH/done" ], 'succeeded batch/v1 Job: returned unchanged');

    # A failed one is deleted - through its own instance data - and recreated.
    MockTransport::reset();
    MockTransport::mock_response('GET', "$BATCH/broken", manifest('batch/v1', 'Job', 'broken',
        metadata => { resourceVersion => '4' }, status => { failed => 1 }));
    MockTransport::mock_response('DELETE', "$BATCH/broken$BG", $SUCCESS);
    MockTransport::mock_response('POST', $BATCH, manifest('batch/v1', 'Job', 'broken',
        metadata => { resourceVersion => '5' }));
    my $recreated = eval { $kube->ensure(unstructured('batch/v1', 'Job', 'broken'))->get };
    is($@, '', 'failed batch/v1 Job: ensure does not die');
    is_deeply(calls(), [ "GET $BATCH/broken", "DELETE $BATCH/broken$BG", "POST $BATCH" ],
        'failed batch/v1 Job: deleted and recreated, no PUT');
    is($recreated && $recreated->metadata->resourceVersion, '5',
        'failed batch/v1 Job: the recreated object');

    # Cases 14 and 15: Kind Job in another group, or under another apiVersion,
    # is an ordinary object.
    for my $case (
        [ 'example.com/v1', '/apis/example.com/v1/namespaces/ns/jobs', 'Job in its own group' ],
        [ 'batch/v2',       '/apis/batch/v2/namespaces/ns/jobs',       'Job under batch/v2' ],
    ) {
        my ($api_version, $collection, $label) = @$case;
        MockTransport::reset();
        MockTransport::mock_response('GET', "$collection/run", manifest($api_version, 'Job', 'run',
            metadata => { resourceVersion => '5' }, status => { phase => 'Running' }));
        MockTransport::mock_response('PUT', "$collection/run", manifest($api_version, 'Job', 'run',
            metadata => { resourceVersion => '6' }));
        my $object = unstructured($api_version, 'Job', 'run');
        eval { $kube->ensure($object)->get };
        is($@, '', "$label: ensure does not die");
        is_deeply(calls(), [ "GET $collection/run", "PUT $collection/run" ], "$label: GET, then PUT");
        is($object->metadata->resourceVersion, '5', "$label: PUT at the server resourceVersion");
    }

    # The core v1 PersistentVolumeClaim is never rewritten.
    my $PVCS = '/api/v1/namespaces/ns/persistentvolumeclaims';
    MockTransport::reset();
    MockTransport::mock_response('GET', "$PVCS/data", manifest('v1', 'PersistentVolumeClaim', 'data',
        metadata => { resourceVersion => '9' }));
    my $claim = eval { $kube->ensure(unstructured('v1', 'PersistentVolumeClaim', 'data'))->get };
    is($@, '', 'v1 PersistentVolumeClaim: ensure does not die');
    is_deeply(calls(), [ "GET $PVCS/data" ], 'v1 PersistentVolumeClaim: returned unchanged');
    is($claim && $claim->metadata->resourceVersion, '9', 'v1 PersistentVolumeClaim: the existing claim');
};

# ============================================================================
# ensure_only()
# ============================================================================

subtest 'ensure_only: Unstructured items key on their own Kind, not the class name' => sub {
    my ($kube) = make_kube(group_entry('example.com',
        [ 'v1', [ 'Widget', 'widgets' ], [ 'Gadget', 'gadgets' ] ]));
    my $WIDGETS = '/apis/example.com/v1/namespaces/ns/widgets';
    my $GADGETS = '/apis/example.com/v1/namespaces/ns/gadgets';
    my $item = sub { manifest('example.com/v1', $_[0], $_[1], metadata => { labels => { app => 'demo' } }) };

    MockTransport::mock_response('GET', "$WIDGETS/foo", $NOT_FOUND, 404);
    MockTransport::mock_response('POST', $WIDGETS, $item->('Widget', 'foo'));
    MockTransport::mock_response('GET', "$WIDGETS?labelSelector=app=demo", {
        apiVersion => 'example.com/v1', kind => 'WidgetList',
        items      => [ $item->('Widget', 'foo'), $item->('Widget', 'stale') ],
    });
    MockTransport::mock_response('GET', "$GADGETS?labelSelector=app=demo", {
        apiVersion => 'example.com/v1', kind => 'GadgetList',
        items      => [ $item->('Gadget', 'foo') ],
    });
    MockTransport::mock_response('DELETE', "$WIDGETS/stale$BG", $SUCCESS);
    MockTransport::mock_response('DELETE', "$GADGETS/foo$BG", $SUCCESS);

    my @applied = eval {
        $kube->ensure_only(
            label      => 'app=demo',
            objects    => [ $item->('Widget', 'foo') ],
            kinds      => [qw( Widget Gadget )],
            namespaces => ['ns'],
        )->get;
    };
    is($@, '', 'ensure_only does not die');
    isa_ok($applied[0], 'IO::K8s::Unstructured', 'the applied object');
    is_deeply([ sort @{ requests('DELETE') } ], [ "$GADGETS/foo$BG", "$WIDGETS/stale$BG" ],
        'the applied Widget foo stays; the stale Widget and the same-named Gadget go');
};

subtest 'ensure_only: an Unstructured item keys on the group in its own apiVersion' => sub {
    # The applied object is a typed Istio Gateway; the bare 'Gateway' entry
    # resolves through discovery to Unstructured in another group. Same Kind,
    # namespace and name - another resource.
    my ($kube) = make_kube(group_entry('gateway.example.com', [ 'v1', [ 'Gateway', 'gateways' ] ]));
    my $ISTIO_GW = '/apis/networking.istio.io/v1/namespaces/ns/gateways';
    my $OTHER_GW = '/apis/gateway.example.com/v1/namespaces/ns/gateways';
    my $web = { metadata => { name => 'web', namespace => 'ns', labels => { app => 'demo' } } };

    MockTransport::mock_response('GET', "$ISTIO_GW/web", $NOT_FOUND, 404);
    MockTransport::mock_response('POST', $ISTIO_GW,
        { apiVersion => 'networking.istio.io/v1', kind => 'Gateway', %$web });
    MockTransport::mock_response('GET', "$OTHER_GW?labelSelector=app=demo", {
        apiVersion => 'gateway.example.com/v1', kind => 'GatewayList',
        items      => [ { apiVersion => 'gateway.example.com/v1', kind => 'Gateway', %$web } ],
    });
    MockTransport::mock_response('DELETE', "$OTHER_GW/web$BG", $SUCCESS);

    eval {
        $kube->ensure_only(
            label      => 'app=demo',
            objects    => [ $kube->new_object('+My::Istio::Gateway', $web) ],
            kinds      => ['Gateway'],
            namespaces => ['ns'],
        )->get;
    };
    is($@, '', 'ensure_only does not die');
    is_deeply(requests('POST'), [ $ISTIO_GW ], 'the Istio Gateway was applied');
    is_deeply(requests('DELETE'), [ "$OTHER_GW/web$BG" ],
        'the Unstructured gateway.example.com Gateway web goes');
};

done_testing;
