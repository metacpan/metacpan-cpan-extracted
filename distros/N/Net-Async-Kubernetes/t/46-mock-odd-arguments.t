use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Future;
use IO::Async::Loop;
use Net::Async::Kubernetes;
use MockTransport;

# karr k69: an odd list of options was assigned to a hash anyway. Perl warned
# "Odd number of elements in hash assignment", the stray key's value was
# undef, and the call went on without it: get('Pod', 'web', namespace =>
# 'default', 'namespace') fetched the Pod at cluster scope, a trailing 'type'
# patched with the default type, list('Pod', 'namespace') listed every
# namespace, a trailing 'objects' left ensure_only pruning everything that
# carries its label, a trailing 'namespace' made a watch cover the whole
# cluster. Every method taking options now refuses an odd list before any
# request and without a warning, as delete() and the controller's
# patch_status already did: Invalid arguments to METHOD(). The
# Future-returning methods fail their Future; ensure_only, watcher,
# controller and watch_resource croak, as for their other argument errors.
# Mock mode only.

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

sub pod { $_[0]->new_object(Pod => { metadata => { name => 'web', namespace => 'default' } }) }

my $PATCH = { metadata => { labels => { env => 'prod' } } };

sub sent { scalar(() = MockTransport::request_log()) }

# $code returns a Future failed with $message - no croak, no warning, and
# nothing was sent.
sub refused {
    my ($label, $code, $message) = @_;
    my $sent = sent();
    my @warnings;
    my $f = do {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval { $code->() };
    };
    is($@, '', "$label: does not croak");
    ok($f && $f->is_failed, "$label: the Future failed");
    is($f && $f->is_failed ? ($f->failure)[0] : undef, $message, "$label: message");
    is_deeply(\@warnings, [], "$label: no warning");
    is(sent(), $sent, "$label: nothing was sent");
}

# $code croaks with $message, reported at the caller's line - no warning, and
# nothing was sent.
sub croaked {
    my ($label, $code, $message) = @_;
    my $sent = sent();
    my @warnings;
    my $croak = do {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval { $code->(); 1 } ? '' : $@;
    };
    like($croak, qr/\A\Q$message\E at \Q${\ __FILE__ }\E line \d+\.\n\z/,
        "$label: croaks at the caller's line");
    is_deeply(\@warnings, [], "$label: no warning");
    is(sent(), $sent, "$label: nothing was sent");
}

subtest 'get: the name, then an odd list' => sub {
    my $kube = make_kube();
    refused('a stray key after the options',
        sub { $kube->get('Pod', 'web', namespace => 'default', 'namespace') },
        'Invalid arguments to get()');
    refused('a lone key after the name',
        sub { $kube->get('Pod', 'web', 'namespace') },
        'Invalid arguments to get()');
    refused('the keyed form, as before',
        sub { $kube->get('Pod', name => 'web', 'namespace') },
        'Invalid arguments to get()');

    # A lone argument stays the name, even one spelled like an option: a
    # Namespace may well be called namespace.
    MockTransport::mock_response('GET', '/api/v1/namespaces/namespace',
        { kind => 'Namespace', apiVersion => 'v1', metadata => { name => 'namespace' } });
    my $ns = eval { $kube->get('Namespace', 'namespace')->get };
    is($@, '', 'a lone argument spelled like an option is still the name');
    is($ns && $ns->metadata->name, 'namespace', 'and that object comes back');
};

subtest 'patch and patch_status: an odd list after the object or the name' => sub {
    my $kube = make_kube();
    for my $method (qw(patch patch_status)) {
        my $invalid = "Invalid arguments to $method()";
        refused("$method, object form, a stray key",
            sub { $kube->$method(pod($kube), patch => $PATCH, 'type') }, $invalid);
        refused("$method, object form, a lone key",
            sub { $kube->$method(pod($kube), 'patch') }, $invalid);
        refused("$method, the name, then options and a stray key",
            sub { $kube->$method('Pod', 'web', namespace => 'default', patch => $PATCH, 'type') },
            $invalid);
        refused("$method, the name, then a stray namespace",
            sub { $kube->$method('Pod', 'web', patch => $PATCH, 'namespace') }, $invalid);
        refused("$method, the keyed form, as before",
            sub { $kube->$method('Pod', name => 'web', patch => $PATCH, 'type') }, $invalid);
    }
};

subtest 'list: an odd list' => sub {
    my $kube = make_kube();
    refused('a lone key', sub { $kube->list('Pod', 'namespace') }, 'Invalid arguments to list()');
    refused('a stray key after the options',
        sub { $kube->list('Pod', namespace => 'default', 'labelSelector') },
        'Invalid arguments to list()');
    refused('a namespace without its key', sub { $kube->list('Pod', 'default') },
        'Invalid arguments to list()');
};

subtest 'ensure_only: an odd list croaks before anything is applied' => sub {
    my $kube = make_kube();
    croaked('a stray objects',
        sub { $kube->ensure_only(label => 'app=demo', kinds => ['ConfigMap'],
            namespaces => ['default'], 'objects') },
        'Invalid arguments to ensure_only()');
    croaked('a stray namespaces',
        sub { $kube->ensure_only(label => 'app=demo', objects => [ pod($kube) ],
            kinds => ['Pod'], 'namespaces') },
        'Invalid arguments to ensure_only()');
};

subtest 'watcher and controller: an odd list croaks before anything is attached' => sub {
    my $kube = make_kube();
    my $children = () = $kube->children;
    croaked('watcher, a stray key',
        sub { $kube->watcher('Pod', on_event => sub {}, 'namespace') },
        'Invalid arguments to watcher()');
    croaked('controller, a stray key',
        sub { $kube->controller(on_reconcile => sub { Future->done }, 'retry_delay') },
        'Invalid arguments to controller()');
    is(scalar(() = $kube->children), $children, 'nothing was attached to the client');
};

subtest 'the controller: watch_resource croaks, get_object and list_objects fail' => sub {
    my $kube = make_kube();
    my $controller = $kube->controller(on_reconcile => sub { Future->done });
    croaked('watch_resource, a stray key',
        sub { $controller->watch_resource('Pod', namespace => 'default', 'key_for') },
        'Invalid arguments to watch_resource()');
    croaked('watch_resource, a lone key',
        sub { $controller->watch_resource('Pod', 'namespace') },
        'Invalid arguments to watch_resource()');
    is(scalar(grep { $_->isa('Net::Async::Kubernetes::Watcher') } $kube->children), 0,
        'no watch was attached to the client');

    refused('get_object',
        sub { $controller->get_object('Pod', 'web', namespace => 'default', 'namespace') },
        'Invalid arguments to get()');
    refused('list_objects',
        sub { $controller->list_objects('Pod', namespace => 'default', 'labelSelector') },
        'Invalid arguments to list()');

    $controller->remove_from_parent;
};

done_testing;
