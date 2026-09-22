use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';

use Future;
use Scalar::Util ();
use TestKube qw(is_live make_kube loop);

diag(is_live() ? "LIVE mode: testing against real cluster" : "MOCK mode: using MockTransport");

# IO::K8s::expand_class fails closed: an unknown/malformed/mismatched
# apiVersion resolves to undef rather than a bare-name guess. Handing that
# undef to build_path dies with "argument is not a module name" -- naming
# neither the resource nor the reason, and doing so as a synchronous die from
# methods whose contract is to return a Future.
#
# Nothing here reaches the network: every assertion is about the guard that
# runs before a request is built, so mock and live mode behave identically.

my $kube = make_kube();

# A *qualified* name is the only version-stable trigger. A bare name like
# 'Bogus' falls back to IO::K8s::Bogus and does NOT return undef, which would
# make this whole file silently pass for the wrong reason.
my $BAD = 'bogus.io/v9/Pod';

my $rx = qr/unknown resource '\Q$BAD\E'/;

subtest 'premise: expand_class fails closed on a qualified unknown name' => sub {
    is($kube->_rest->expand_class($BAD), undef,
        "IO::K8s resolves '$BAD' to undef");
    isnt($kube->_rest->expand_class('Pod'), undef,
        'a known resource still resolves');
};

subtest 'Future-returning methods fail the Future, not the call' => sub {
    my %call = (
        list         => [],
        get          => ['some-name'],
        delete       => ['some-name'],
        patch        => ['some-name', patch => { metadata => {} }],
        log          => ['some-name'],
        port_forward => ['some-name', ports => [8080]],
        exec         => ['some-name', command => ['true']],
        attach       => ['some-name'],
    );

    for my $method (sort keys %call) {
        my $f = eval { $kube->$method($BAD, @{ $call{$method} }) };
        my $err = $@;

        ok(!$err, "$method() does not die synchronously")
            or diag("died: $err");

        # Guarded so an unguarded call site cannot abort the whole file and
        # leave the remaining claims untested.
        unless (Scalar::Util::blessed($f) && $f->isa('Future')) {
            fail("$method() returns a failed Future");
            fail("$method() failure names the resource");
            next;
        }

        ok($f->is_failed, "$method() Future is failed");
        like(($f->failure)[0], $rx, "$method() failure names the resource");
    }
};

subtest 'Controller patch_status fails the Future' => sub {
    my $controller = $kube->controller(on_reconcile => sub { Future->done });

    my $f = eval { $controller->patch_status($BAD, 'some-name', status => { phase => 'X' }) };
    my $err = $@;

    ok(!$err, 'patch_status() does not die synchronously')
        or diag("died: $err");

    if (Scalar::Util::blessed($f) && $f->isa('Future')) {
        ok($f->is_failed, 'patch_status() Future is failed');
        like(($f->failure)[0], $rx, 'patch_status() failure names the resource');
    } else {
        fail('patch_status() returns a failed Future');
        fail('patch_status() failure names the resource');
    }

    $controller->remove_from_parent;
};

subtest 'genuinely synchronous paths croak with the same message' => sub {
    throws_ok { $kube->expand_class($BAD) } $rx,
        'expand_class() croaks naming the resource';

    # watcher() registers the child, which starts the watch synchronously.
    throws_ok { $kube->watcher($BAD, on_event => sub { }) } $rx,
        'watcher() croaks naming the resource';
};

subtest 'a resolvable resource is unaffected' => sub {
    is($kube->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'expand_class still resolves Pod');

    # Unlike the unresolvable case above, this one gets past the guard and
    # opens a real watch stream, so it stays in mock mode.
  SKIP: {
        skip 'watcher for a known resource would hit the cluster', 1 if is_live();
        my $watcher = $kube->watcher('Pod', on_event => sub { });
        ok($watcher, 'watcher for a known resource is created');
        $watcher->remove_from_parent;
    }
};

done_testing;
