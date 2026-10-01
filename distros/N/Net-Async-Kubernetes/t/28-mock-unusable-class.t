use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';

use Future;
use Scalar::Util ();
use File::Temp ();
use File::Spec;
use IO::Async::Loop;
use IO::K8s;
use Net::Async::Kubernetes;
use MockTransport;

# A resource name can resolve to a class that is still no use for a request:
# a resource_map entry whose class does not load or does not compile (a typo
# in a '+Class' name), or a bare name that lands on one of IO::K8s's helper
# classes (List, Resource, Types, Unstructured), which load fine but are no
# resource. build_path dies on either, synchronously and without naming the
# resource. The Future-returning methods must fail their Future instead, and
# with the real cause -- the load error, or "not a resource class" -- rather
# than claiming the resource is unknown. The synchronous paths (expand_class,
# watcher, ensure's input) croak with that same cause.
#
# t/17-unknown-resource.t covers names nothing resolves at all.
#
# Mock-only: every assertion is about the guard in front of the request.

# A module that is found but does not compile, kept out of t/lib so no
# tooling ever trips over a broken .pm in the distribution.
my $inc_dir = File::Temp::tempdir(CLEANUP => 1);
mkdir File::Spec->catdir($inc_dir, 'My');
mkdir File::Spec->catdir($inc_dir, 'My', 'Broken');
{
    open my $fh, '>', File::Spec->catfile($inc_dir, 'My', 'Broken', 'Thing.pm')
        or die "cannot write fixture: $!";
    print {$fh} "package My::Broken::Thing;\nsub oops { 1 + ; }\n1;\n";
    close $fh;
}
unshift @INC, $inc_dir;

my $loop = IO::Async::Loop->new;

MockTransport::reset();
my $kube = Net::Async::Kubernetes->new(
    server      => { endpoint => 'https://mock.local' },
    credentials => { token => 'mock-token' },
    resource_map_from_cluster => 0,
    resource_map => {
        %{ IO::K8s->default_resource_map },
        Missing                 => '+My::Missing::Thing',
        Broken                  => '+My::Broken::Thing',
        'example.com/v1/Gizmo'  => '+My::Missing::Gizmo',
    },
);
MockTransport::install($kube);
$loop->add($kube);

my %cause = (
    Missing                => qr/^resource 'Missing' resolves to class My::Missing::Thing, which cannot be loaded: Can't locate My\/Missing\/Thing\.pm/,
    '+My::Missing::Thing'  => qr/^resource '\+My::Missing::Thing' resolves to class My::Missing::Thing, which cannot be loaded: Can't locate My\/Missing\/Thing\.pm/,
    # The first require reports the syntax error, every later one that the
    # compilation failed -- both are the load error, neither is "unknown".
    Broken                 => qr/^resource 'Broken' resolves to class My::Broken::Thing, which cannot be loaded: .*(?:syntax error|Compilation failed)/s,
    map {
        $_ => qr/^resource '$_' resolves to IO::K8s::$_, which is not a Kubernetes resource class/
    } qw(List Resource Types Unstructured),
);

subtest 'premise: each name resolves to a class, so none of this is "unknown"' => sub {
    for my $name (sort keys %cause) {
        my $class = $kube->_rest->expand_class($name);
        ok(defined $class, "Kubernetes::REST resolves '$name' to a class name");
    }
    ok(!eval { require My::Missing::Thing; 1 }, 'My::Missing::Thing does not exist');
    ok(IO::K8s::List->can('new'), 'IO::K8s::List loads');
};

subtest 'Future-returning methods fail the Future with the real cause' => sub {
    my ($fh, $local) = File::Temp::tempfile(UNLINK => 1);
    print {$fh} "payload\n";
    close $fh;

    my $controller = $kube->controller(on_reconcile => sub { Future->done });

    my %call = (
        list          => [$kube, 'list'],
        get           => [$kube, 'get', 'some-name'],
        delete        => [$kube, 'delete', 'some-name'],
        patch         => [$kube, 'patch', 'some-name', patch => { metadata => {} }],
        patch_status  => [$kube, 'patch_status', 'some-name', patch => { status => {} }],
        log           => [$kube, 'log', 'some-name'],
        port_forward  => [$kube, 'port_forward', 'some-name', ports => [8080]],
        exec          => [$kube, 'exec', 'some-name', command => ['true']],
        attach        => [$kube, 'attach', 'some-name'],
        cp_to_pod     => [$kube, 'cp_to_pod', 'some-name', local => $local, remote => '/tmp/x'],
        cp_from_pod   => [$kube, 'cp_from_pod', 'some-name', local => "$local.out", remote => '/tmp/x'],
        get_object    => [$controller, 'get_object', 'some-name'],
        list_objects  => [$controller, 'list_objects'],
        'controller patch_status' =>
            [$controller, 'patch_status', 'some-name', status => { phase => 'X' }],
    );

    for my $name (sort keys %cause) {
        for my $label (sort keys %call) {
            my ($invocant, $method, @args) = @{ $call{$label} };
            MockTransport::reset();
            my $f = eval { $invocant->$method($name, @args) };
            my $err = $@;

            ok(!$err, "$name: $label() does not die synchronously")
                or diag("died: $err");

            # Guarded so one unguarded call site cannot abort the whole file.
            unless (Scalar::Util::blessed($f) && $f->isa('Future')) {
                fail("$name: $label() returns a failed Future");
                next;
            }

            ok($f->is_failed, "$name: $label() Future is failed");
            my $failure = ($f->failure)[0] // '';
            like($failure, $cause{$name}, "$name: $label() failure names the real cause");
            unlike($failure, qr/unknown resource/, "$name: $label() does not claim an unknown resource");
            is(scalar(MockTransport::request_log), 0, "$name: $label() sent no request");
        }
    }

    $controller->remove_from_parent;
};

subtest 'synchronous paths croak with the same cause' => sub {
    for my $name (sort keys %cause) {
        throws_ok { $kube->expand_class($name) } $cause{$name},
            "$name: expand_class() croaks with the real cause";
        throws_ok { $kube->watcher($name, on_event => sub { }) } $cause{$name},
            "$name: watcher() croaks with the real cause";
    }

    for my $name (qw(Missing Broken List Unstructured)) {
        MockTransport::reset();
        throws_ok { $kube->ensure({ kind => $name, metadata => { name => 'x' } }) }
            $cause{$name}, "$name: ensure() on a hashref croaks with the real cause";
        is(scalar(MockTransport::request_log), 0, "$name: ensure() sent no request");
    }

    # With an apiVersion the manifest resolves through the exact
    # group/version/Kind -- here a map entry whose class does not exist.
    MockTransport::reset();
    throws_ok {
        $kube->ensure({ apiVersion => 'example.com/v1', kind => 'Gizmo', metadata => { name => 'x' } })
    } qr{^ensure: resource 'example\.com/v1/Gizmo' resolves to class My::Missing::Gizmo, which cannot be loaded: Can't locate My/Missing/Gizmo\.pm},
        'ensure() on an apiVersion hashref croaks with the real cause';
    is(scalar(MockTransport::request_log), 0, 'ensure() with apiVersion sent no request');
};

subtest 'resolvable resources are unaffected' => sub {
    is($kube->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod', 'a built-in Kind');
    is($kube->expand_class('+IO::K8s::Api::Core::V1::ConfigMap'),
        'IO::K8s::Api::Core::V1::ConfigMap', 'an explicit +Class that is a resource');
    like($kube->_rest->expand_class('Bogus') // '', qr/^IO::K8s::Bogus$/,
        'premise: a bare unknown Kind is fabricated');
    throws_ok { $kube->expand_class('Bogus') } qr/^unknown resource 'Bogus'/,
        'and still reported as unknown, not as a load error';
};

done_testing;
