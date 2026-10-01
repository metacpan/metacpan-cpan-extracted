use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';

use Scalar::Util ();
use IO::Async::Loop;
use IO::K8s::List;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta;
use Net::Async::Kubernetes;
use MockTransport;

# The object forms -- create, update, update_status, patch and patch_status
# with an object, delete with an object, ensure -- take the request path from
# the object's class. An object that is no resource has no such path: an
# IO::K8s::List (what list() resolves to), a nested type such as a PodSpec,
# or no IO::K8s object at all. build_path died on those synchronously, or the
# metadata lookup before it did. Each method now reports it the way it
# reports its other argument errors -- a failed Future, or a croak for
# update, update_status and ensure -- before any request is sent.
#
# t/28-mock-unusable-class.t covers the same check for resource names.
#
# Mock-only: every assertion is about the guard in front of the request.

my $loop = IO::Async::Loop->new;

MockTransport::reset();
my $kube = Net::Async::Kubernetes->new(
    server      => { endpoint => 'https://mock.local' },
    credentials => { token => 'mock-token' },
    resource_map_from_cluster => 0,
);
MockTransport::install($kube);
$loop->add($kube);

my $k8s = $kube->_rest->k8s;

# With a ListMeta, whose missing name was the next thing to die.
my $list = IO::K8s::List->new(
    items    => [],
    metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta->new(resourceVersion => '1'),
);
my $spec = $k8s->struct_to_object('IO::K8s::Api::Core::V1::PodSpec', {
    containers => [{ name => 'app', image => 'nginx' }],
});

sub not_a_resource {
    my ($label, $class) = @_;
    return qr/^\Q$label\E: resource '\Q$class\E' resolves to \Q$class\E, which is not a Kubernetes resource class/;
}

my %objects = (
    'IO::K8s::List' => $list,
    'PodSpec'       => $spec,
);

subtest 'premise: neither object is a resource' => sub {
    isa_ok($list, 'IO::K8s::List');
    isa_ok($spec, 'IO::K8s::Api::Core::V1::PodSpec');
    ok(!defined eval { IO::K8s::List->api_version }, 'IO::K8s::List has no class-level api_version');
    ok(!IO::K8s::Api::Core::V1::PodSpec->can('api_version'), 'PodSpec has no api_version');
};

subtest 'Future-returning object forms fail the Future' => sub {
    my %call = (
        create       => [],
        delete       => [],
        patch        => [patch => { metadata => { labels => { a => 'b' } } }],
        patch_status => [patch => { status => { phase => 'X' } }],
    );

    for my $name (sort keys %objects) {
        my $object = $objects{$name};
        for my $method (sort keys %call) {
            MockTransport::reset();
            my $f = eval { $kube->$method($object, @{ $call{$method} }) };
            my $err = $@;

            ok(!$err, "$name: $method() does not die synchronously") or diag("died: $err");
            unless (Scalar::Util::blessed($f) && $f->isa('Future')) {
                fail("$name: $method() returns a failed Future");
                next;
            }
            ok($f->is_failed, "$name: $method() Future is failed");
            like(($f->failure)[0] // '', not_a_resource($method, ref $object),
                "$name: $method() names the class and why it is no use");
            is(scalar(MockTransport::request_log), 0, "$name: $method() sent no request");
        }
    }
};

subtest 'update, update_status and ensure croak' => sub {
    for my $name (sort keys %objects) {
        my $object = $objects{$name};
        for my $method (qw(update update_status ensure)) {
            MockTransport::reset();
            throws_ok { $kube->$method($object) } not_a_resource($method, ref $object),
                "$name: $method() croaks naming the class";
            is(scalar(MockTransport::request_log), 0, "$name: $method() sent no request");
        }
    }
};

subtest 'something that is no IO::K8s object at all' => sub {
    for my $value ({ kind => 'Pod' }, 'Pod') {
        my $shown = ref $value ? 'a hashref' : "'$value'";
        MockTransport::reset();
        my $f = eval { $kube->create($value) };
        ok(!$@, "create($shown) does not die synchronously") or diag("died: $@");
        ok(Scalar::Util::blessed($f) && $f->is_failed, "create($shown) Future is failed");
        like(Scalar::Util::blessed($f) && $f->is_failed ? ($f->failure)[0] : '',
            qr/^create requires an IO::K8s object/, "create($shown) says what it needs");
    }

    my $f = eval { $kube->delete({ metadata => { name => 'x' } }) };
    ok(!$@, 'delete(hashref) does not die synchronously') or diag("died: $@");
    like(Scalar::Util::blessed($f) && $f->is_failed ? ($f->failure)[0] : '',
        qr/^delete requires an IO::K8s object/, 'delete(hashref) fails the Future');

    for my $method (qw(update update_status)) {
        throws_ok { $kube->$method({ metadata => { name => 'x' } }) }
            qr/^\Q$method\E requires an IO::K8s object/, "$method(hashref) croaks";
    }
    is(scalar(MockTransport::request_log), 0, 'no request was sent');
};

subtest 'controller status helpers fail the Future, never die' => sub {
    my $controller = $kube->controller(on_reconcile => sub { Future->done });

    for my $name (sort keys %objects) {
        my $object = $objects{$name};
        MockTransport::reset();

        my $f = eval { $controller->update_status($object) };
        ok(!$@, "$name: controller update_status() does not die") or diag("died: $@");
        like(Scalar::Util::blessed($f) && $f->is_failed ? ($f->failure)[0] : '',
            not_a_resource('update_status', ref $object),
            "$name: controller update_status() fails the Future naming the class");

        $f = eval { $controller->patch_status($object, status => { phase => 'X' }) };
        ok(!$@, "$name: controller patch_status() does not die") or diag("died: $@");
        like(Scalar::Util::blessed($f) && $f->is_failed ? ($f->failure)[0] : '',
            not_a_resource('patch_status', ref $object),
            "$name: controller patch_status() fails the Future naming the class");

        is(scalar(MockTransport::request_log), 0, "$name: no request was sent");
    }

    $controller->remove_from_parent;
};

subtest 'resource objects are unaffected' => sub {
    MockTransport::reset();
    my $pod = $kube->_rest->new_object('Pod',
        metadata => { name => 'p1', namespace => 'default' },
        spec     => { containers => [{ name => 'app', image => 'nginx' }] },
    );
    MockTransport::mock_response('POST', '/api/v1/namespaces/default/pods', $pod->TO_JSON, 201);
    my $created = $kube->create($pod)->get;
    is($created->metadata->name, 'p1', 'create() of a Pod still goes through');
    is(MockTransport::last_request()->{path}, '/api/v1/namespaces/default/pods',
        'to the collection path of its class');
};

done_testing;
