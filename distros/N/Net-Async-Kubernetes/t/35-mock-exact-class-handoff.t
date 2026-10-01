use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use IO::K8s;
use JSON::MaybeXS;
use Kubernetes::REST;
use Net::Async::Kubernetes;
use MockTransport;

# karr k50 (Kubernetes::REST k42): ensure() and ensure_only() resolve a
# hashref manifest's class themselves and must hand that class to IO::K8s's
# struct_to_object exactly, with a '+'. expand_class returns a plain class
# name - a resource_map value of '+Gizmo' comes back as 'Gizmo' - and
# struct_to_object resolves a name again, to which a single-segment 'Gizmo'
# is a Kind: IO::K8s::Gizmo, which does not exist, so ensure croaked; or,
# when the short key Gizmo maps to another class, that class, and the
# manifest went to that class's endpoint.
#
# karr k57: inflating the server's answer is Kubernetes::REST's
# inflate_object, inflate_list and process_watch_chunk, which resolved the
# name again the same way before 1.109 (its own k42) - a listed Gizmo became
# whatever the short key Gizmo names, and ensure_only deleted it in that
# other group. The client hands them the resolved class with a '+' as well,
# so the class of what comes back is the one the client resolved.
#
# Mock-only: everything here is request routing, nothing needs a cluster.

my $loop = IO::Async::Loop->new;
my $JSON = JSON::MaybeXS->new(utf8 => 1);

my $GIZMOS = '/apis/k42.example.com/v1/namespaces/ns/gizmos';
my $GVK    = 'k42.example.com/v1/Gizmo';

# The Gizmo entry is keyed by its GVK only, as a provider registers a Kind
# whose short name is taken. %extra adds further map entries.
sub make_kube {
    my (%extra) = @_;
    MockTransport::reset();
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
        resource_map => {
            %{ IO::K8s->default_resource_map },
            $GVK => '+Gizmo',
            %extra,
        },
    );
    MockTransport::install($kube);
    $loop->add($kube);
    return $kube;
}

sub calls {
    return [ map { "$_->{method} $_->{path}" } MockTransport::request_log ];
}

sub gizmo {
    my ($name, %extra) = @_;
    return {
        apiVersion => 'k42.example.com/v1',
        kind       => 'Gizmo',
        metadata   => { name => $name, namespace => 'ns' },
        spec       => { size => 'large' },
        %extra,
    };
}

# The manifest is absent, so ensure POSTs it: the request goes out whether or
# not the answer then inflates.
sub mock_absent_gizmo {
    MockTransport::mock_response('GET', "$GIZMOS/g1",
        { kind => 'Status', status => 'Failure', message => 'not found', code => 404 }, 404);
    MockTransport::mock_response('POST', $GIZMOS,
        gizmo('g1', metadata => { name => 'g1', namespace => 'ns', resourceVersion => '1' }));
}

sub posted_body {
    my ($post) = grep { $_->{method} eq 'POST' } MockTransport::request_log;
    return $post ? $JSON->decode($post->{content}) : undef;
}

sub check_result {
    my ($f) = @_;
    isa_ok($f && eval { $f->get }, 'Gizmo', 'the result');
}

subtest 'ensure: a manifest resolved through a +single-segment GVK entry is a Gizmo' => sub {
    my $kube = make_kube();
    is($kube->expand_class('Gizmo', 'k42.example.com/v1'), 'Gizmo', 'premise: expand_class drops the +');
    mock_absent_gizmo();

    my $f = eval { $kube->ensure(gizmo('g1')) };
    is($@, '', 'ensure does not croak');
    is_deeply(calls(), [ "GET $GIZMOS/g1", "POST $GIZMOS" ], 'the manifest went to the Gizmo endpoint');
    my $body = posted_body();
    is($body && $body->{apiVersion}, 'k42.example.com/v1', 'the body is the Gizmo apiVersion');
    is($body && $body->{spec}{size}, 'large', 'the body carries the spec');
    check_result($f);
};

subtest 'ensure: the short key Gizmo mapped to another class does not hijack the manifest' => sub {
    # A resolved 'Gizmo' re-read as a Kind would land on the Istio Gateway -
    # silently, with its endpoint.
    my $kube = make_kube(Gizmo => '+My::Istio::Gateway');
    mock_absent_gizmo();

    my $f = eval { $kube->ensure(gizmo('g1')) };
    is($@, '', 'ensure does not croak');
    is_deeply(calls(), [ "GET $GIZMOS/g1", "POST $GIZMOS" ], 'the manifest went to the Gizmo endpoint');
    is_deeply([ grep { /istio/ } @{ calls() } ], [], 'nothing was sent to the other group');
    check_result($f);
};

subtest 'ensure: a manifest without apiVersion keeps the class its Kind resolved to' => sub {
    # The same hand-off without an apiVersion: the Kind's short key names
    # Gizmo under another name, and Gizmo re-read as a Kind is the Istio
    # Gateway.
    my $kube = make_kube(Gadget => '+Gizmo', Gizmo => '+My::Istio::Gateway');
    mock_absent_gizmo();

    my %manifest = %{ gizmo('g1') };
    delete $manifest{apiVersion};
    $manifest{kind} = 'Gadget';
    my $f = eval { $kube->ensure(\%manifest) };
    is($@, '', 'ensure does not croak');
    is_deeply(calls(), [ "GET $GIZMOS/g1", "POST $GIZMOS" ], 'the manifest went to the Gizmo endpoint');
    check_result($f);
};

subtest 'ensure_only: the applied manifest is a Gizmo, and it is kept' => sub {
    my $kube = make_kube(Gizmo => '+My::Istio::Gateway');
    mock_absent_gizmo();
    MockTransport::mock_response('GET', "$GIZMOS?labelSelector=app=demo", {
        apiVersion => 'k42.example.com/v1', kind => 'GizmoList',
        items      => [ gizmo('g1') ],
    });

    my $f = eval {
        $kube->ensure_only(
            label      => 'app=demo',
            objects    => [ gizmo('g1') ],
            kinds      => [ $GVK ],
            namespaces => ['ns'],
        );
    };
    is($@, '', 'ensure_only does not croak');
    is_deeply([ grep { /^(?:GET|POST) / && !/labelSelector/ } @{ calls() } ],
        [ "GET $GIZMOS/g1", "POST $GIZMOS" ], 'the manifest went to the Gizmo endpoint');
    # A listed g1 re-read as the Kind Gizmo would be the Istio Gateway, match
    # nothing applied, and be deleted - in networking.istio.io.
    is_deeply([ grep { /^DELETE/ } @{ calls() } ], [], 'nothing was deleted');
};

subtest 'list, get and the object forms answer with the resolved class, not the short key' => sub {
    my $kube = make_kube(Gizmo => '+My::Istio::Gateway');
    my $g1 = gizmo('g1', metadata => { name => 'g1', namespace => 'ns', resourceVersion => '2' });
    MockTransport::mock_response('GET', $GIZMOS,
        { apiVersion => 'k42.example.com/v1', kind => 'GizmoList', items => [ $g1 ] });
    MockTransport::mock_response($_, "$GIZMOS/g1", $g1) for qw(GET PUT PATCH);
    MockTransport::mock_response($_, "$GIZMOS/g1/status", $g1) for qw(PUT PATCH);
    MockTransport::mock_response('POST', $GIZMOS, $g1);

    my $object = $kube->new_object('+Gizmo', gizmo('g1'));
    my $patch  = { spec => { size => 'small' } };
    for my $call (
        [ list          => sub { $kube->list($GVK, namespace => 'ns')->get->items->[0] } ],
        [ get           => sub { $kube->get($GVK, 'g1', namespace => 'ns')->get } ],
        [ create        => sub { $kube->create($object)->get } ],
        [ update        => sub { $kube->update($object)->get } ],
        [ update_status => sub { $kube->update_status($object)->get } ],
        [ patch         => sub { $kube->patch($GVK, 'g1', namespace => 'ns', patch => $patch)->get } ],
        [ patch_status  => sub { $kube->patch_status($object, patch => { status => {} })->get } ],
        [ ensure        => sub { $kube->ensure($object)->get } ],
    ) {
        my ($method, $code) = @$call;
        my $result = eval { $code->() };
        is($@, '', "$method does not die");
        isa_ok($result, 'Gizmo', "the $method result");
    }
    is_deeply([ grep { /istio/ } @{ calls() } ], [], 'nothing was sent to the other group');
};

subtest 'a watched object is the resolved class, not the short key' => sub {
    my $kube = make_kube(Gizmo => '+My::Istio::Gateway');
    MockTransport::mock_watch_events($GIZMOS, [ { type => 'ADDED', object => gizmo('g1') } ]);

    my @added;
    my $watcher = eval {
        $kube->watcher($GVK,
            namespace => 'ns',
            on_added  => sub { push @added, $_[0]; $loop->stop },
        );
    };
    is($@, '', 'the watcher starts');
    my $timer = $loop->watch_time(after => 2, code => sub { $loop->stop });
    $loop->run if $watcher;
    $loop->unwatch_time($timer);
    $watcher->stop if $watcher;

    is(scalar @added, 1, 'one ADDED event');
    isa_ok($added[0], 'Gizmo', 'the watched object');
};

done_testing;
