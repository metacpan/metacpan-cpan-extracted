use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use IO::K8s::Unstructured;
use Net::Async::Kubernetes;
use MockTransport;

# karr k58: IO::K8s::Unstructured has no path of its own. Kubernetes::REST's
# build_path takes Kind and apiVersion from the caller and plural and scope
# from the discovery catalog, and croaks when it cannot: without discovery
# (resource_map_from_cluster is off by default), for the explicit class name
# IO::K8s::Unstructured (a class name carries no Kind), and for an
# Unstructured object without a kind. That croak escaped the Future-returning
# methods synchronously. They report it like every other error known before
# a request - a failed Future - and the methods whose contract is to croak on
# such errors (update, update_status, ensure, the watcher) still croak, from
# the caller's line.
#
# Mock-only: every case below fails before a request is sent.

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

sub widget {
    my (%fields) = @_;
    return IO::K8s::Unstructured->FROM_HASH({
        metadata => { name => 'w1', namespace => 'ns', resourceVersion => '1' },
        spec     => { color => 'blue' },
        %fields,
    });
}

sub failure_of {
    my ($f) = @_;
    return $f && $f->is_failed ? ($f->failure)[0] : undef;
}

# The object forms. $reason is what build_path gives up on.
sub check_object_forms {
    my ($kube, $object, $reason) = @_;

    for my $call (
        [ create       => sub { $kube->create($object) } ],
        [ patch        => sub { $kube->patch($object, patch => {}, type => 'merge') } ],
        [ patch_status => sub { $kube->patch_status($object, patch => { status => {} }) } ],
        [ delete       => sub { $kube->delete($object) } ],
        [ ensure_all   => sub { $kube->ensure_all($object) } ],
    ) {
        my ($method, $code) = @$call;
        my $f = eval { $code->() };
        is($@, '', "$method does not croak");
        like(failure_of($f) // '', $reason, "$method returns a failed Future with the reason");
    }

    for my $call (
        [ update        => sub { $kube->update($object) } ],
        [ update_status => sub { $kube->update_status($object) } ],
        [ ensure        => sub { $kube->ensure($object) } ],
    ) {
        my ($method, $code) = @$call;
        my $croak = eval { $code->(); 1 } ? '' : $@;
        like($croak, $reason, "$method croaks with the reason");
        like($croak, qr/ at \Q$0\E line \d+\.$/, "$method croaks from the caller's line");
    }
}

subtest 'an Unstructured object without discovery' => sub {
    my $kube = make_kube();
    check_object_forms($kube,
        widget(apiVersion => 'example.com/v1', kind => 'Widget'),
        qr/cannot build a path for IO::K8s::Unstructured/);
    is_deeply([ MockTransport::request_log ], [], 'no request was sent');
};

subtest 'an Unstructured object without a kind' => sub {
    my $kube = make_kube();
    check_object_forms($kube,
        widget(apiVersion => 'example.com/v1'),
        qr/IO::K8s::Unstructured needs a Kind to build a path/);
    is_deeply([ MockTransport::request_log ], [], 'no request was sent');
};

subtest 'the explicit class name IO::K8s::Unstructured' => sub {
    my $kube = make_kube();
    my $reason = qr/IO::K8s::Unstructured needs a Kind to build a path/;

    for my $name ('IO::K8s::Unstructured', '+IO::K8s::Unstructured') {
        for my $call (
            [ list         => sub { $kube->list($name, namespace => 'ns') } ],
            [ get          => sub { $kube->get($name, 'w1', namespace => 'ns') } ],
            [ patch        => sub { $kube->patch($name, 'w1', namespace => 'ns', patch => {}, type => 'merge') } ],
            [ patch_status => sub { $kube->patch_status($name, 'w1', namespace => 'ns', patch => { status => {} }) } ],
            [ delete       => sub { $kube->delete($name, 'w1', namespace => 'ns') } ],
            [ log          => sub { $kube->log($name, 'w1', namespace => 'ns') } ],
            [ port_forward => sub { $kube->port_forward($name, 'w1', namespace => 'ns', ports => [80]) } ],
            [ exec         => sub { $kube->exec($name, 'w1', namespace => 'ns', command => ['true']) } ],
            [ attach       => sub { $kube->attach($name, 'w1', namespace => 'ns') } ],
        ) {
            my ($method, $code) = @$call;
            my $f = eval { $code->() };
            is($@, '', "$method('$name') does not croak");
            like(failure_of($f) // '', $reason, "$method('$name') returns a failed Future with the reason");
        }

        my $croak = eval { $kube->watcher($name, namespace => 'ns', on_added => sub { }); 1 } ? '' : $@;
        like($croak, $reason, "watcher('$name') croaks when it starts");

        my @warnings;
        my $f = eval {
            local $SIG{__WARN__} = sub { push @warnings, $_[0] };
            $kube->ensure_only(label => 'app=demo', objects => [], kinds => [$name], namespaces => ['ns'])->get;
            1;
        };
        is($@, '', "ensure_only(kinds => ['$name']) does not die");
        like($warnings[0] // '', qr/cannot list \Q$name\E in namespace 'ns', nothing pruned there: $reason/,
            "ensure_only(kinds => ['$name']) warns with the reason");
    }
    is_deeply([ MockTransport::request_log ], [], 'no request was sent');
};

done_testing;
