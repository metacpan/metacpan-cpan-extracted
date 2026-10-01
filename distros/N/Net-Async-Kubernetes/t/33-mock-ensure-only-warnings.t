use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Future;
use IO::Async::Loop;
use Net::Async::Kubernetes;
use MockTransport;

# karr k48 (Kubernetes::REST k37): a prune that did nothing must not look
# like one that worked. ensure_only() warns when it cannot list a kinds entry
# in a namespace or cannot delete a stale object - naming the Kind, the
# namespace (or cluster scope), the name and the reason - and goes on with
# the rest. A 404 stays silent: on the list the cluster does not serve the
# Kind, on the delete the object is already gone. The status comes from the
# response, not from the text of an error. The Future still resolves to the
# applied objects.
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

sub requests {
    my ($method) = @_;
    return [ map { $_->{path} } grep { $_->{method} eq $method } MockTransport::request_log ];
}

my $SEL        = '?labelSelector=app=demo';
my $BG         = '?propagationPolicy=Background';
my $CM_DEFAULT = '/api/v1/namespaces/default/configmaps';
my $CM_OTHER   = '/api/v1/namespaces/other/configmaps';
my $DELETED    = { kind => 'Status', apiVersion => 'v1', status => 'Success' };

sub refuse {
    my ($method, $path, $status) = @_;
    MockTransport::mock_response($method, $path, {
        kind => 'Status', apiVersion => 'v1', status => 'Failure',
        code => $status, message => "mock refuses with $status",
    }, $status);
}

sub cm_item {
    my ($name, $namespace) = @_;
    return {
        kind => 'ConfigMap', apiVersion => 'v1',
        metadata => { name => $name, namespace => $namespace // 'default', labels => { app => 'demo' } },
    };
}

# keep-me is created in default; each given collection lists the given items.
sub mock_cm_cluster {
    my (%items_in) = @_;
    MockTransport::mock_response('GET', "$CM_DEFAULT/keep-me",
        { kind => 'Status', status => 'Failure', message => 'not found', code => 404 }, 404);
    MockTransport::mock_response('POST', $CM_DEFAULT, cm_item('keep-me'));
    for my $collection (sort keys %items_in) {
        MockTransport::mock_response('GET', $collection . $SEL,
            { kind => 'ConfigMapList', apiVersion => 'v1', items => $items_in{$collection} });
    }
}

sub keep_me_cm {
    my ($kube) = @_;
    return $kube->new_object('ConfigMap', cm_item('keep-me'));
}

# Runs ensure_only to the end, collecting its warnings.
sub ensure_only_warnings {
    my ($kube, %args) = @_;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my @applied = eval { $kube->ensure_only(label => 'app=demo', %args)->get };
    is($@, '', 'ensure_only resolves');
    return (\@warnings, \@applied);
}

subtest 'a Kind the cluster does not serve (list 404) is skipped silently' => sub {
    my $kube = make_kube();
    mock_cm_cluster($CM_DEFAULT => [ cm_item('keep-me'), cm_item('stale') ]);
    MockTransport::mock_response('DELETE', "$CM_DEFAULT/stale$BG", $DELETED);
    # No Role list registered: the mock answers 404, like a cluster that does
    # not serve the Kind.

    my ($warnings, $applied) = ensure_only_warnings($kube,
        objects    => [ keep_me_cm($kube) ],
        kinds      => [qw( Role ConfigMap )],
        namespaces => ['default'],
    );
    is_deeply($warnings, [], 'no warning for a 404 list');
    is(scalar @$applied, 1, 'the applied object is returned');
    ok((grep { $_ eq "/apis/rbac.authorization.k8s.io/v1/namespaces/default/roles$SEL" }
        @{ requests('GET') }), 'the Role list was attempted');
    is_deeply(requests('DELETE'), [ "$CM_DEFAULT/stale$BG" ], 'the next kinds entry is still pruned');
};

subtest 'a failed list warns with Kind, namespace and reason; the rest still runs' => sub {
    my $kube = make_kube();
    mock_cm_cluster($CM_OTHER => [ cm_item('stale', 'other') ]);
    refuse('GET', $CM_DEFAULT . $SEL, 403);
    MockTransport::mock_response('DELETE', "$CM_OTHER/stale$BG", $DELETED);

    my ($warnings, $applied) = ensure_only_warnings($kube,
        objects    => [ keep_me_cm($kube) ],
        kinds      => ['ConfigMap'],
        namespaces => [qw( default other )],
    );
    is(scalar @$warnings, 1, 'one warning') or diag explain $warnings;
    my $w = $warnings->[0] // '';
    like($w, qr/\Aensure_only: cannot list ConfigMap in namespace 'default', nothing pruned there: /,
        'it names the Kind and the namespace');
    like($w, qr/\b403\b/, 'it names the status');
    like($w, qr/mock refuses with 403/, 'it carries the server message');
    like($w, qr/ line \d+\.\n\z/, 'it ends with a location');
    unlike($w, qr/ line \d+\..* line \d+\./s, 'one location, not a second from the caught croak');

    is(scalar @$applied, 1, 'the applied object is still returned');
    is_deeply(requests('DELETE'), [ "$CM_OTHER/stale$BG" ], 'the other namespace is still pruned');
};

subtest 'a failed cluster-scoped list says so' => sub {
    my $kube = make_kube();
    my $CLUSTER_ROLES = '/apis/rbac.authorization.k8s.io/v1/clusterroles';
    refuse('GET', $CLUSTER_ROLES . $SEL, 500);

    my ($warnings, $applied) = ensure_only_warnings($kube,
        objects => [],
        kinds   => ['ClusterRole'],
    );
    is(scalar @$warnings, 1, 'one warning') or diag explain $warnings;
    like($warnings->[0] // '', qr/\Aensure_only: cannot list ClusterRole at cluster scope/,
        'it names the Kind and cluster scope');
    like($warnings->[0] // '', qr/\b500\b/, 'it names the status');
    is_deeply($applied, [], 'the return value is still the (empty) applied list');
};

subtest 'a kinds entry no class resolves warns, it is not taken for a 404' => sub {
    my $kube = make_kube();

    my ($warnings) = ensure_only_warnings($kube,
        objects    => [],
        kinds      => ['NoSuchKind'],
        namespaces => ['default'],
    );
    is(scalar @$warnings, 1, 'one warning') or diag explain $warnings;
    like($warnings->[0] // '',
        qr/\Aensure_only: cannot list NoSuchKind in namespace 'default', nothing pruned there: unknown resource 'NoSuchKind'/,
        'it names the kinds entry and why it resolves to nothing');
    is_deeply([ MockTransport::request_log ], [], 'nothing was sent');
};

subtest 'a list that fails without a response warns with the transport error' => sub {
    my $kube = make_kube();
    mock_cm_cluster($CM_OTHER => []);

    my $mocked = \&Net::Async::Kubernetes::_do_request;
    no warnings 'redefine';
    local *Net::Async::Kubernetes::_do_request = sub {
        my ($self, $req) = @_;
        return Future->fail("Connection refused\n", 'io')
            if $req->url =~ m{\Q$CM_DEFAULT\E\?};
        return $self->$mocked($req);
    };

    my ($warnings, $applied) = ensure_only_warnings($kube,
        objects    => [ keep_me_cm($kube) ],
        kinds      => ['ConfigMap'],
        namespaces => [qw( default other )],
    );
    is(scalar @$warnings, 1, 'one warning') or diag explain $warnings;
    like($warnings->[0] // '',
        qr/\Aensure_only: cannot list ConfigMap in namespace 'default', nothing pruned there: Connection refused at /,
        'it carries the transport error');
    is(scalar @$applied, 1, 'the applied object is returned');
    ok((grep { $_ eq $CM_OTHER . $SEL } @{ requests('GET') }), 'the other namespace is still listed');
};

subtest 'a delete 404 is silent, a failed delete warns and the prune goes on' => sub {
    my $kube = make_kube();
    mock_cm_cluster($CM_DEFAULT => [ map { cm_item($_) } qw( keep-me gone locked stale ) ]);
    # No DELETE registered for gone: the mock answers 404 - already deleted.
    refuse('DELETE', "$CM_DEFAULT/locked$BG", 403);
    MockTransport::mock_response('DELETE', "$CM_DEFAULT/stale$BG", $DELETED);

    my ($warnings, $applied) = ensure_only_warnings($kube,
        objects    => [ keep_me_cm($kube) ],
        kinds      => ['ConfigMap'],
        namespaces => ['default'],
    );
    is(scalar @$warnings, 1, 'one warning, for locked only') or diag explain $warnings;
    my $w = $warnings->[0] // '';
    like($w, qr/\Aensure_only: cannot delete ConfigMap 'locked' in namespace 'default': /,
        'it names the Kind, the name and the namespace');
    like($w, qr/\b403\b/, 'it names the status');
    like($w, qr/mock refuses with 403/, 'it carries the server message');
    unlike($w, qr/ line \d+\..* line \d+\./s, 'one location, not a second from the caught croak');

    is_deeply(requests('DELETE'), [ map { "$CM_DEFAULT/$_$BG" } qw( gone locked stale ) ],
        'every unexpected item was tried, stale after the failed locked');
    is(scalar @$applied, 1, 'the applied object is returned');
};

subtest 'a warning handler that dies fails the Future' => sub {
    my $kube = make_kube();
    mock_cm_cluster();
    refuse('GET', $CM_DEFAULT . $SEL, 403);

    my @applied = eval {
        local $SIG{__WARN__} = sub { die @_ };
        $kube->ensure_only(
            label      => 'app=demo',
            objects    => [ keep_me_cm($kube) ],
            kinds      => ['ConfigMap'],
            namespaces => ['default'],
        )->get;
    };
    like($@, qr/cannot list ConfigMap in namespace 'default'/, 'the Future fails with the warning');
    is(scalar @applied, 0, 'and resolves to nothing');
};

done_testing;
