use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use MockTransport;

# karr k63: an option a method does not take was dropped silently -
# namespace for namespaces made ensure_only prune at cluster scope only,
# labelselector made list return every object, tail_lines fetched the whole
# log. ensure_only, list, get, log, patch and patch_status now refuse it before
# any request, each by its own convention: ensure_only croaks, as for its
# other argument errors; the others fail their Future. The message is
# Kubernetes::REST's: Unknown argument 'KEY' to METHOD() (allowed: ...),
# naming the first unknown key in sort order. Mock mode only.

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

my $POD = { kind => 'Pod', apiVersion => 'v1',
    metadata => { name => 'web', namespace => 'default', resourceVersion => '1' } };

sub pod { $_[0]->new_object(Pod => { metadata => { name => 'web', namespace => 'default' } }) }

# The failure of the Future $code returns, which must not die; and that
# nothing was sent.
sub refused {
    my ($label, $code, $message) = @_;
    my $sent = () = MockTransport::request_log();
    my $f = eval { $code->() };
    is($@, '', "$label: does not croak");
    ok($f && $f->is_failed, "$label: the Future failed");
    is($f && $f->is_failed ? ($f->failure)[0] : undef, $message, "$label: message");
    is(scalar(() = MockTransport::request_log()), $sent, "$label: nothing was sent");
}

my $LIST = '(allowed: namespace, labelSelector, fieldSelector)';
my $GET  = '(allowed: name, namespace)';
my $LOG  = '(allowed: name, namespace, container, follow, tailLines, sinceSeconds,'
         . ' sinceTime, timestamps, previous, limitBytes, on_line)';

subtest 'list refuses an unknown option' => sub {
    my $kube = make_kube();
    refused('misspelt selector', sub { $kube->list('Pod', namespace => 'default', labelselector => 'app=web') },
        "Unknown argument 'labelselector' to list() $LIST");
    refused('name', sub { $kube->list('Pod', name => 'web') },
        "Unknown argument 'name' to list() $LIST");
    refused('several', sub { $kube->list('Pod', zeta => 1, alpha => 2) },
        "Unknown argument 'alpha' to list() $LIST");
    refused('before resolving the resource', sub { $kube->list('Bogus', labelselector => 'x') },
        "Unknown argument 'labelselector' to list() $LIST");

    MockTransport::mock_response('GET',
        '/api/v1/namespaces/default/pods?fieldSelector=status.phase=Running&labelSelector=app=web',
        { kind => 'PodList', apiVersion => 'v1', metadata => {}, items => [] });
    my $list = eval { $kube->list('Pod', namespace => 'default', labelSelector => 'app=web',
        fieldSelector => 'status.phase=Running')->get };
    is($@, '', 'the allowed options still go out');
    isa_ok($list, 'IO::K8s::List');
};

subtest 'get refuses an unknown option' => sub {
    my $kube = make_kube();
    refused('short form', sub { $kube->get('Pod', 'web', namespace => 'default', namspace => 'x') },
        "Unknown argument 'namspace' to get() $GET");
    refused('keyed form', sub { $kube->get('Pod', name => 'web', labelSelector => 'app=web') },
        "Unknown argument 'labelSelector' to get() $GET");

    MockTransport::mock_response('GET', '/api/v1/namespaces/default/pods/web', $POD);
    my $pod = eval { $kube->get('Pod', name => 'web', namespace => 'default')->get };
    is($@, '', 'the allowed options still work');
    is($pod && $pod->metadata->name, 'web', 'and the object comes back');
};

subtest 'log refuses an unknown option' => sub {
    my $kube = make_kube();
    refused('short form', sub { $kube->log('Pod', 'web', namespace => 'default', tail_lines => 10) },
        "Unknown argument 'tail_lines' to log() $LOG");
    refused('keyed form', sub { $kube->log('Pod', name => 'web', onLine => sub {}) },
        "Unknown argument 'onLine' to log() $LOG");
    refused('before a missing name', sub { $kube->log('Pod', namespace => 'default', tail_lines => 1) },
        "Unknown argument 'tail_lines' to log() $LOG");

    MockTransport::mock_response('GET',
        '/api/v1/namespaces/default/pods/web/log?container=app&limitBytes=100&previous=true'
            . '&sinceSeconds=5&tailLines=10&timestamps=true',
        'line');
    my $text = eval { $kube->log('Pod', 'web', namespace => 'default', container => 'app',
        tailLines => 10, sinceSeconds => 5, timestamps => 1, previous => 1, limitBytes => 100)->get };
    is($@, '', 'the allowed options still go out');
    is($text, 'line', 'and the log comes back');
};

subtest 'patch and patch_status refuse an unknown option' => sub {
    my $kube = make_kube();
    for my $method (qw(patch patch_status)) {
        refused("$method, class form", sub {
            $kube->$method('Pod', 'web', namespace => 'default', patch => {}, typ => 'merge');
        }, "Unknown argument 'typ' to $method() (allowed: name, namespace, patch, type)");
        refused("$method, keyed form", sub {
            $kube->$method('Pod', name => 'web', patch => {}, strategy => 'merge');
        }, "Unknown argument 'strategy' to $method() (allowed: name, namespace, patch, type)");
        refused("$method, object form", sub {
            $kube->$method(pod($kube), patch => {}, namespace => 'other');
        }, "Unknown argument 'namespace' to $method() (allowed: patch, type)");
    }
};

subtest 'ensure_only croaks on an unknown option before anything is applied' => sub {
    my $kube = make_kube();
    my $ALLOWED = '(allowed: label, objects, kinds, namespaces, propagationPolicy)';
    my $croak = eval {
        $kube->ensure_only(label => 'app=demo', objects => [ pod($kube) ], kinds => ['Pod'],
            namespace => 'default');
        1;
    } ? '' : $@;
    like($croak, qr/\AUnknown argument 'namespace' to ensure_only\(\) \Q$ALLOWED\E at /,
        'namespace for namespaces croaks');
    is(scalar MockTransport::request_log(), 0, 'nothing was sent');

    $croak = eval { $kube->ensure_only(labels => 'app=demo', objects => []); 1 } ? '' : $@;
    like($croak, qr/\AUnknown argument 'labels' to ensure_only\(\) \Q$ALLOWED\E at /,
        'named before the missing label');
};

subtest 'watcher already refuses an unknown option' => sub {
    my $kube = make_kube();
    my $ok = eval { $kube->watcher('Pod', labelSelector => 'app=web', on_event => sub {}); 1 };
    ok(!$ok, 'watcher croaks');
    like($@, qr/Unrecognised configuration keys for Net::Async::Kubernetes::Watcher - labelSelector/,
        'IO::Async::Notifier names the key');
};

done_testing;
