use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Kubernetes::REST;
use Net::Async::Kubernetes;
use MockTransport;

# karr k59: with resource_map_from_cluster, Kubernetes::REST reads discovery
# (GET /api, GET /apis) through its own synchronous io on first use, blocking
# the loop and bypassing this client's transport. discover() reads it through
# the client's own transport instead, through Kubernetes::REST's seam for
# that (prepare_discovery_requests / absorb_discovery), and hands it over;
# names and the resource map then resolve without a request of Kubernetes::REST's
# own.
#
# Mock-only. Kubernetes::REST's own io is not the mocked transport: each
# client below builds its Kubernetes::REST with an io of its own that records
# every request it is asked to send (as in t/32), so a test sees which of the
# two carried discovery.

{
    package Test::RecordingIO;
    use Moo;
    use JSON::MaybeXS ();
    use Kubernetes::REST::HTTPResponse;

    # path => [ $status, $document ]; anything else is a 404.
    has documents => (is => 'ro', default => sub { {} });
    has requests  => (is => 'ro', default => sub { [] });

    my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

    sub call {
        my ($self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        push @{ $self->requests }, $req->method . ' ' . $path;
        my ($status, $document) = @{ $self->documents->{$path} // [ 404, { kind => 'Status', code => 404 } ] };
        return Kubernetes::REST::HTTPResponse->new(
            status  => $status,
            content => $json->encode($document),
        );
    }

    sub call_streaming { die "Test::RecordingIO does not stream\n" }

    with 'Kubernetes::REST::Role::IO';
}

{
    package Test::DiscoverKube;
    use parent -norequire, 'Net::Async::Kubernetes';

    sub configure {
        my ($self, %params) = @_;
        $self->{sync_io} = delete $params{sync_io} if exists $params{sync_io};
        $self->SUPER::configure(%params);
    }

    # The client's own Kubernetes::REST, with the recording io.
    sub rest {
        my ($self) = @_;
        $self->{_test_rest} //= Kubernetes::REST->new(
            server                    => $self->server,
            credentials               => $self->credentials,
            resource_map_from_cluster => $self->resource_map_from_cluster,
            io                        => $self->{sync_io},
        );
    }
}

my $loop = IO::Async::Loop->new;

# One APIGroupDiscoveryList item: $group serving $version with each
# [ Kind, plural ], namespaced.
sub group_entry {
    my ($group, $version, @resources) = @_;
    return {
        metadata => { name => $group },
        versions => [ {
            version   => $version,
            resources => [ map {
                +{
                    resource     => $_->[1],
                    responseKind => { group => $group, version => $version, kind => $_->[0] },
                    scope        => 'Namespaced',
                };
            } @resources ],
        } ],
    };
}

# Aggregated discovery: core v1 ConfigMaps, and a Widget no class ships.
my %AGGREGATED = (
    '/api' => {
        kind => 'APIGroupDiscoveryList', apiVersion => 'apidiscovery.k8s.io/v2',
        items => [ group_entry('', 'v1', [ 'ConfigMap', 'configmaps' ]) ],
    },
    '/apis' => {
        kind => 'APIGroupDiscoveryList', apiVersion => 'apidiscovery.k8s.io/v2',
        items => [ group_entry('example.org', 'v1', [ 'Widget', 'widgets' ]) ],
    },
);

# The same cluster, answering with legacy discovery (Kubernetes < 1.27).
my %LEGACY = (
    '/api'  => { kind => 'APIVersions', versions => ['v1'] },
    '/apis' => { kind => 'APIGroupList', apiVersion => 'v1', groups => [ {
        name => 'example.org',
        versions => [ { groupVersion => 'example.org/v1', version => 'v1' } ],
        preferredVersion => { groupVersion => 'example.org/v1', version => 'v1' },
    } ] },
    '/api/v1' => { kind => 'APIResourceList', groupVersion => 'v1', resources => [
        { name => 'configmaps', kind => 'ConfigMap', namespaced => JSON::MaybeXS::true() },
    ] },
    '/apis/example.org/v1' => { kind => 'APIResourceList', groupVersion => 'example.org/v1', resources => [
        { name => 'widgets', kind => 'Widget', namespaced => JSON::MaybeXS::true() },
    ] },
);

my $WIDGETS = '/apis/example.org/v1/namespaces/default/widgets';

# A client with resource_map_from_cluster (unless told otherwise) whose
# Kubernetes::REST io serves %$sync (path => [status, document]).
sub make_kube {
    my (%args) = @_;
    my $io = Test::RecordingIO->new(documents => $args{sync} // {});
    MockTransport::reset();
    my $kube = Test::DiscoverKube->new(
        server                    => { endpoint => 'https://mock.local' },
        credentials               => { token => 'mock-token' },
        resource_map_from_cluster => $args{from_cluster} // 1,
        sync_io                   => $io,
    );
    MockTransport::install($kube);
    $loop->add($kube);
    MockTransport::mock_response('GET', $WIDGETS, {
        kind => 'WidgetList', apiVersion => 'example.org/v1', metadata => {},
        items => [ { kind => 'Widget', apiVersion => 'example.org/v1',
                     metadata => { name => 'w1', namespace => 'default' } } ],
    });
    return ($kube, $io);
}

sub served { my (%docs) = @_; return { map { $_ => [ 200, $docs{$_} ] } keys %docs } }

sub transport_calls { [ map { "$_->{method} $_->{path}" } MockTransport::request_log() ] }

# discover(), which must not die: its Future, ready.
sub discover_ok {
    my ($kube, $label) = @_;
    my $f = eval { $kube->discover };
    is($@, '', "$label: discover does not die");
    return unless ok(ref $f && $f->isa('Future'), "$label: discover returns a Future");
    $f->await;
    return $f;
}

subtest 'without discover, first use reads discovery through the synchronous io' => sub {
    my ($kube, $io) = make_kube(sync => served(%AGGREGATED));
    my $list = eval { $kube->list('Widget', namespace => 'default')->get };
    is($@, '', 'the list resolves');
    is_deeply($io->requests, [ 'GET /api', 'GET /apis' ],
        'Kubernetes::REST sent discovery itself - what discover replaces');
};

subtest 'discover reads discovery through the client transport' => sub {
    my ($kube, $io) = make_kube();
    MockTransport::mock_response('GET', $_, $AGGREGATED{$_}) for keys %AGGREGATED;

    my $f = discover_ok($kube, 'aggregated') or return;
    ok($f->is_done, 'the Future is done');
    is_deeply([ $f->result ], [], 'with no value');
    is_deeply(transport_calls(), [ 'GET /api', 'GET /apis' ], 'both requests went over the client transport');
    my @log = MockTransport::request_log();
    like($log[0]{headers}{Accept} // '', qr/as=APIGroupDiscoveryList/,
        'as Kubernetes::REST builds them, asking for aggregated discovery');
    is_deeply($io->requests, [], 'nothing went over the synchronous io');

    is(eval { $kube->expand_class('example.org/v1/Widget') }, 'IO::K8s::Unstructured',
        'a Kind only discovery lists resolves');
    my $list = eval { $kube->list('Widget', namespace => 'default')->get };
    is($@, '', 'a request for it resolves');
    is($list && $list->items->[0]->metadata->name, 'w1', 'with the listed item');
    ok(eval { $kube->rest->resource_map->{ConfigMap} }, 'the resource map is built from the catalog');
    is_deeply($io->requests, [], 'still nothing over the synchronous io');
    is_deeply(transport_calls(), [ 'GET /api', 'GET /apis', "GET $WIDGETS" ],
        'no further discovery request either');
};

subtest 'discover again replaces what was read before' => sub {
    my ($kube, $io) = make_kube();
    MockTransport::mock_response('GET', $_, $AGGREGATED{$_}) for keys %AGGREGATED;
    discover_ok($kube, 'first') or return;
    ok(!eval { $kube->expand_class('example.org/v1/Gadget') }, 'a Kind the cluster does not serve yet is unknown');

    MockTransport::mock_response('GET', '/apis', {
        kind => 'APIGroupDiscoveryList', apiVersion => 'apidiscovery.k8s.io/v2',
        items => [ group_entry('example.org', 'v1', [ 'Widget', 'widgets' ], [ 'Gadget', 'gadgets' ]) ],
    });
    my $f = discover_ok($kube, 'second') or return;
    ok($f->is_done, 'the second discover is done');
    is(eval { $kube->expand_class('example.org/v1/Gadget') }, 'IO::K8s::Unstructured',
        'the Kind it added resolves');
    is(scalar @{ transport_calls() }, 4, 'both reads went over the client transport');
    is_deeply($io->requests, [], 'none over the synchronous io');
};

subtest 'legacy discovery: discover completes, first use reads it synchronously' => sub {
    my ($kube, $io) = make_kube(sync => served(%LEGACY));
    MockTransport::mock_response('GET', $_, $LEGACY{$_}) for qw(/api /apis);

    my $f = discover_ok($kube, 'legacy') or return;
    ok($f->is_done, 'the Future is done all the same');
    is_deeply($io->requests, [], 'nothing over the synchronous io yet');

    my $list = eval { $kube->list('Widget', namespace => 'default')->get };
    is($@, '', 'the list resolves');
    is($io->requests->[0], 'GET /api', 'first use read discovery through the synchronous io, as before');
};

subtest 'an HTTP error fails discover with category http and the response' => sub {
    my ($kube, $io) = make_kube();
    MockTransport::mock_response('GET', '/api', $AGGREGATED{'/api'});
    MockTransport::mock_response('GET', '/apis',
        { kind => 'Status', apiVersion => 'v1', status => 'Failure', code => 503, message => 'unavailable' }, 503);

    my $f = discover_ok($kube, '503') or return;
    ok($f->is_failed, 'the Future failed');
    my ($error, $category, $response) = $f->failure;
    is($category, 'http', 'category http');
    is($response && $response->status, 503, 'the response carries status 503');
    like("$error", qr/\AKubernetes API error \(discovery GET \/apis\): 503 /,
        'the error is what check_response throws, naming the request');
    is_deeply($io->requests, [], 'nothing over the synchronous io');
};

subtest 'a body that is not JSON fails discover instead of dying' => sub {
    my ($kube, $io) = make_kube();
    MockTransport::mock_response('GET', '/api', $AGGREGATED{'/api'});
    MockTransport::mock_response('GET', '/apis', 'this is not JSON');

    my $f = discover_ok($kube, 'garbage') or return;
    ok($f->is_failed, 'the Future failed');
    ok(length(($f->failure)[0] // ''), 'with the decode error');
};

subtest 'without resource_map_from_cluster discover sends nothing' => sub {
    my ($kube, $io) = make_kube(from_cluster => 0);
    my $f = discover_ok($kube, 'off') or return;
    ok($f->is_done, 'the Future is done');
    is_deeply(transport_calls(), [], 'nothing over the client transport');
    is_deeply($io->requests, [], 'nothing over the synchronous io');
};

done_testing;
