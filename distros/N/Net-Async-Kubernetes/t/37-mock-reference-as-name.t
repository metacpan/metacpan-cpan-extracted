use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use MockTransport;

# karr k54: patch and patch_status take a resource name or an IO::K8s object.
# An unblessed reference in that place - typically a manifest hashref - went
# through name resolution as if it were a name: expand_class stringified it
# into 'IO::K8s::HASH(0x...)' and the failure said the resource "resolves to
# class IO::K8s::HASH(0x...), which cannot be loaded". It is refused as what
# it is, in the same form as every other bad argument of the method: a failed
# Future, or a croak where the method croaks on bad arguments. The check sits
# in name resolution itself, so every method that takes a resource name says
# the same.
#
# Mock-only: nothing here reaches a request.

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

sub failure_of {
    my ($f) = @_;
    return $f && $f->is_failed ? ($f->failure)[0] : undef;
}

my $manifest = {
    apiVersion => 'v1',
    kind       => 'ConfigMap',
    metadata   => { name => 'cm', namespace => 'ns' },
};

subtest 'patch and patch_status refuse an unblessed reference in place of the name' => sub {
    my $kube = make_kube();

    for my $case (
        [ HASH  => $manifest ],
        [ ARRAY => [ 'ConfigMap' ] ],
    ) {
        my ($type, $ref) = @$case;
        for my $call (
            [ patch        => sub { $kube->patch($ref, 'cm', namespace => 'ns', patch => {}) } ],
            [ patch_status => sub { $kube->patch_status($ref, patch => { status => {} }) } ],
        ) {
            my ($method, $code) = @$call;
            my $f = eval { $code->() };
            is($@, '', "$method($type ref) does not croak");
            my $error = failure_of($f) // '';
            is($error, "resource name must be a string, got a $type reference",
                "$method($type ref) fails the Future with an argument error");
            unlike($error, qr/IO::K8s::$type/, "$method($type ref) names no made-up class");
        }
    }
    is_deeply([ MockTransport::request_log ], [], 'no request was sent');
};

subtest 'every method that takes a resource name says the same' => sub {
    my $kube = make_kube();
    my $message = 'resource name must be a string, got a HASH reference';

    for my $call (
        [ list => sub { $kube->list($manifest, namespace => 'ns') } ],
        [ get  => sub { $kube->get($manifest, 'cm', namespace => 'ns') } ],
        [ log  => sub { $kube->log($manifest, 'cm', namespace => 'ns') } ],
    ) {
        my ($method, $code) = @$call;
        my $f = eval { $code->() };
        is($@, '', "$method does not croak");
        is(failure_of($f), $message, "$method fails the Future with the argument error");
    }

    my $croak = eval { $kube->expand_class($manifest); 1 } ? '' : $@;
    like($croak, qr/\A\Q$message\E at /, 'expand_class croaks with it');
    $croak = eval { $kube->watcher($manifest, namespace => 'ns', on_added => sub { }); 1 } ? '' : $@;
    like($croak, qr/\A\Q$message\E at /, 'a watcher croaks with it when it starts');

    is_deeply([ MockTransport::request_log ], [], 'no request was sent');
};

subtest 'get and delete refuse a reference in the name position' => sub {
    my $kube = make_kube();
    # 'Pod' is a real class here - the reference is the name, not the class,
    # the gap the class-position check above never reached (karr k70). Left
    # unchecked, get() and delete() stringified it straight into the request
    # path (GET /api/v1/pods/HASH(0x...)) and only the server's 404 showed it.
    my $object = $kube->new_object(Pod =>
        { metadata => { name => 'web', namespace => 'ns' } });

    for my $case (
        [ HASH   => $manifest, 'a HASH reference' ],
        [ object => $object,   'an object of class IO::K8s::Api::Core::V1::Pod' ],
    ) {
        my ($type, $ref, $tail) = @$case;
        my $message = "resource name must be a string, got $tail";
        for my $call (
            [ 'get bare'           => sub { $kube->get('Pod', $ref) } ],
            [ 'get + namespace'    => sub { $kube->get('Pod', $ref, namespace => 'ns') } ],
            [ 'delete bare'        => sub { $kube->delete('Pod', $ref) } ],
            [ 'delete + namespace' => sub { $kube->delete('Pod', $ref, namespace => 'ns') } ],
        ) {
            my ($label, $code) = @$call;
            my $f = eval { $code->() };
            is($@, '', "$label ($type) does not croak");
            my $error = failure_of($f) // '';
            is($error, $message, "$label ($type) fails the Future with the argument error");
            unlike($error, qr/HASH\(0x|=HASH\(0x/,
                "$label ($type) leaks no stringified reference");
        }
    }
    is_deeply([ MockTransport::request_log ], [], 'no request was sent');
};

subtest 'get and delete still accept a string name' => sub {
    my $kube = make_kube();
    my $pod = { apiVersion => 'v1', kind => 'Pod',
        metadata => { name => 'web', namespace => 'ns' } };
    MockTransport::mock_response('GET', '/api/v1/namespaces/ns/pods/web', $pod);
    MockTransport::mock_response('DELETE', '/api/v1/namespaces/ns/pods/web',
        { kind => 'Status', status => 'Success' });

    my $got = eval { $kube->get('Pod', 'web', namespace => 'ns')->get };
    is($@, '', 'get by string name works');
    isa_ok($got, 'IO::K8s::Api::Core::V1::Pod', 'the fetched object');

    my $deleted = eval { $kube->delete('Pod', 'web', namespace => 'ns')->get };
    is($@, '', 'delete by string name works');
    is($deleted, 1, 'delete by string name resolves to 1');
};

subtest 'a name and an object still work' => sub {
    my $kube = make_kube();
    my $cm = { %$manifest, data => { k => 'v' } };
    MockTransport::mock_response('PATCH', '/api/v1/namespaces/ns/configmaps/cm', $cm);

    my $by_name = eval { $kube->patch('ConfigMap', 'cm', namespace => 'ns', patch => { data => { k => 'v' } })->get };
    is($@, '', 'patch by name works');
    isa_ok($by_name, 'IO::K8s::Api::Core::V1::ConfigMap', 'the patched object');

    my $object = $kube->new_object(ConfigMap => $manifest);
    my $by_object = eval { $kube->patch($object, patch => { data => { k => 'v' } })->get };
    is($@, '', 'patch by object works');
    isa_ok($by_object, 'IO::K8s::Api::Core::V1::ConfigMap', 'the patched object');
};

done_testing;
