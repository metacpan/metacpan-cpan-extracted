use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use lib 't/lib';

use IO::Async::Loop;
use JSON::MaybeXS;
use Net::Async::Kubernetes;
use MockTransport;

# karr k65: the k63 refusal of unknown options, carried on to the methods
# that still dropped them. port_forward, exec and attach handed every key
# they did not take on to build_path, which ignored most of them and read a
# stray subresource into the path (.../pods/web/log/exec); cp_to_pod and
# cp_from_pod dropped them; the controller's patch_status builds its own
# patch from status and type and dropped the rest (typ => 'json' sent a
# merge patch, namespace in the object form was ignored). All six now refuse
# an unknown option before any request and fail their Future, as they do for
# their other argument errors, with Kubernetes::REST's message: Unknown
# argument 'KEY' to METHOD() (allowed: ...), naming the first unknown key in
# sort order. What each allows is what it used before. Mock mode only.

my $loop = IO::Async::Loop->new;
my $JSON = JSON::MaybeXS->new(utf8 => 1);

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

# A duplex session that records what cp_to_pod writes to stdin.
{
    package Test::Duplex::Session;
    use Future;
    sub new { bless { writes => [] }, shift }
    sub write_stdin { push @{ $_[0]{writes} }, $_[1]; Future->done }
}

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

my $CB = join(', ', qw( subprotocol on_open on_frame on_close on_error ));
my %CB = map { $_ => sub {} } qw( on_open on_frame on_close on_error );
my $PF     = "(allowed: name, namespace, ports, $CB)";
my $EXEC   = "(allowed: name, namespace, command, container, stdin, stdout, stderr, tty, $CB)";
my $ATTACH = "(allowed: name, namespace, container, stdin, stdout, stderr, tty, $CB)";
my $CP_TO   = '(allowed: name, namespace, container, local, remote, chunk_size)';
my $CP_FROM = '(allowed: name, namespace, container, local, remote)';

my $POD_PATH = '/api/v1/namespaces/default/pods/web';

subtest 'port_forward refuses an unknown option' => sub {
    my $kube = make_kube();
    refused('short form', sub {
        $kube->port_forward('Pod', 'web', namespace => 'default', ports => [8080], onFrame => sub {});
    }, "Unknown argument 'onFrame' to port_forward() $PF");
    refused('keyed form, before the missing ports', sub {
        $kube->port_forward('Pod', name => 'web', port => 8080);
    }, "Unknown argument 'port' to port_forward() $PF");
    refused('a subresource that would reach the path', sub {
        $kube->port_forward('Pod', 'web', namespace => 'default', ports => [8080], subresource => 'status');
    }, "Unknown argument 'subresource' to port_forward() $PF");

    my $session = eval { $kube->port_forward('Pod', 'web', namespace => 'default',
        ports => [8080, 8443], subprotocol => 'v4.channel.k8s.io', %CB)->get };
    is($@, '', 'the allowed options still go out');
    my $req = MockTransport::last_request();
    is($req->{path}, "$POD_PATH/portforward", 'path');
    like($req->{url}, qr/\?ports=8080&ports=8443\z/, 'ports');
    is_deeply($req->{callbacks}, { on_open => 1, on_frame => 1, on_close => 1, on_error => 1 },
        'callbacks handed on');
};

subtest 'exec refuses an unknown option' => sub {
    my $kube = make_kube();
    refused('short form', sub {
        $kube->exec('Pod', 'web', namespace => 'default', command => ['id'], contianer => 'app');
    }, "Unknown argument 'contianer' to exec() $EXEC");
    refused('keyed form, a subresource that would reach the path', sub {
        $kube->exec('Pod', name => 'web', command => ['id'], subresource => 'log');
    }, "Unknown argument 'subresource' to exec() $EXEC");
    refused('before the missing command', sub {
        $kube->exec('Pod', 'web', namespace => 'default', cmd => ['id']);
    }, "Unknown argument 'cmd' to exec() $EXEC");

    my $session = eval { $kube->exec('Pod', 'web', namespace => 'default', command => ['sh', '-c', 'id'],
        container => 'app', stdin => 1, stdout => 0, stderr => 1, tty => 1,
        subprotocol => 'v4.channel.k8s.io', %CB)->get };
    is($@, '', 'the allowed options still go out');
    my $req = MockTransport::last_request();
    is($req->{path}, "$POD_PATH/exec", 'path');
    like($req->{url}, qr/[?&]$_(?:&|\z)/, "query has $_")
        for qw( command=sh command=-c command=id container=app stdin=true stdout=false
                stderr=true tty=true );
    is_deeply($req->{callbacks}, { on_open => 1, on_frame => 1, on_close => 1, on_error => 1 },
        'callbacks handed on');
};

subtest 'attach refuses an unknown option' => sub {
    my $kube = make_kube();
    refused('short form, an exec option', sub {
        $kube->attach('Pod', 'web', namespace => 'default', command => ['sh']);
    }, "Unknown argument 'command' to attach() $ATTACH");
    refused('keyed form', sub {
        $kube->attach('Pod', name => 'web', stdn => 1);
    }, "Unknown argument 'stdn' to attach() $ATTACH");

    my $session = eval { $kube->attach('Pod', 'web', namespace => 'default', container => 'app',
        stdin => 1, stdout => 1, stderr => 0, tty => 1, subprotocol => 'v4.channel.k8s.io', %CB)->get };
    is($@, '', 'the allowed options still go out');
    my $req = MockTransport::last_request();
    is($req->{path}, "$POD_PATH/attach", 'path');
    like($req->{url}, qr/[?&]$_(?:&|\z)/, "query has $_")
        for qw( container=app stdin=true stdout=true stderr=false tty=true );
    is_deeply($req->{callbacks}, { on_open => 1, on_frame => 1, on_close => 1, on_error => 1 },
        'callbacks handed on');
};

my $tmp = tempdir(CLEANUP => 1);
my $local = "$tmp/in.txt";
{
    open my $fh, '>:raw', $local or die "cannot write $local: $!";
    print {$fh} 'hello world';
    close $fh;
}

subtest 'cp_to_pod refuses an unknown option' => sub {
    my $kube = make_kube();
    refused('short form', sub {
        $kube->cp_to_pod('Pod', 'web', namespace => 'default', local => $local, remote => '/tmp/out',
            chunksize => 4);
    }, "Unknown argument 'chunksize' to cp_to_pod() $CP_TO");
    refused('keyed form', sub {
        $kube->cp_to_pod('Pod', name => 'web', local => $local, remote => '/tmp/out', containr => 'app');
    }, "Unknown argument 'containr' to cp_to_pod() $CP_TO");
    refused('before the missing local path', sub {
        $kube->cp_to_pod('Pod', 'web', src => $local, remote => '/tmp/out');
    }, "Unknown argument 'src' to cp_to_pod() $CP_TO");

    my $session = Test::Duplex::Session->new;
    MockTransport::mock_duplex_session($session);
    # Pending until the session closes, which the mock transport never does.
    my $f = eval { $kube->cp_to_pod('Pod', 'web', namespace => 'default', container => 'app',
        local => $local, remote => '/tmp/out', chunk_size => 4) };
    is($@, '', 'the allowed options do not croak');
    ok($f && !$f->is_failed, 'and do not fail');
    my $req = MockTransport::last_request();
    is($req && $req->{path}, "$POD_PATH/exec", 'the exec request went out');
    like($req && $req->{url}, qr/[?&]$_(?:&|\z)/, "query has $_")
        for qw( container=app command=/tmp/out command=11 );
    is_deeply($session->{writes}, ['hell', 'o wo', 'rld'], 'stdin written in chunk_size pieces');
};

subtest 'cp_from_pod refuses an unknown option' => sub {
    my $kube = make_kube();
    refused('short form, a cp_to_pod option', sub {
        $kube->cp_from_pod('Pod', 'web', namespace => 'default', remote => '/tmp/in', local => "$tmp/out",
            chunk_size => 4);
    }, "Unknown argument 'chunk_size' to cp_from_pod() $CP_FROM");
    refused('keyed form', sub {
        $kube->cp_from_pod('Pod', name => 'web', remote => '/tmp/in', local => "$tmp/out", namepsace => 'x');
    }, "Unknown argument 'namepsace' to cp_from_pod() $CP_FROM");

    # Pending until the session closes, which the mock transport never does.
    my $f = eval { $kube->cp_from_pod('Pod', 'web', namespace => 'default', container => 'app',
        remote => '/tmp/in', local => "$tmp/out") };
    is($@, '', 'the allowed options do not croak');
    ok($f && !$f->is_failed, 'and do not fail');
    my $req = MockTransport::last_request();
    is($req && $req->{path}, "$POD_PATH/exec", 'the exec request went out');
    like($req && $req->{url}, qr/[?&]$_(?:&|\z)/, "query has $_")
        for qw( container=app command=cat command=/tmp/in );
};

subtest 'the controller patch_status refuses an unknown option' => sub {
    my $kube = make_kube();
    my $controller = $kube->controller(on_reconcile => sub { Future->done });
    my $pod = $kube->new_object(Pod => { metadata => { name => 'web', namespace => 'default' } });
    my $CLASS  = '(allowed: name, namespace, status, type)';
    my $OBJECT = '(allowed: status, type)';

    refused('class form, a misspelt type', sub {
        $controller->patch_status('Pod', 'web', namespace => 'default', status => {}, typ => 'json');
    }, "Unknown argument 'typ' to patch_status() $CLASS");
    refused('class form, a misspelt status', sub {
        $controller->patch_status('Pod', 'web', namespace => 'default', statuss => {});
    }, "Unknown argument 'statuss' to patch_status() $CLASS");
    refused('keyed form', sub {
        $controller->patch_status('Pod', name => 'web', namspace => 'default', status => {});
    }, "Unknown argument 'namspace' to patch_status() $CLASS");
    refused('object form, namespace comes from the object', sub {
        $controller->patch_status($pod, status => {}, namespace => 'other');
    }, "Unknown argument 'namespace' to patch_status() $OBJECT");

    my $POD_STATUS = "$POD_PATH/status";
    MockTransport::mock_response('PATCH', $POD_STATUS, { kind => 'Pod', apiVersion => 'v1',
        metadata => { name => 'web', namespace => 'default' }, status => { phase => 'Running' } });
    for my $form (
        [ 'class form'  => sub { $controller->patch_status('Pod', name => 'web', namespace => 'default',
              status => { phase => 'Running' }, type => 'strategic') } ],
        [ 'object form' => sub { $controller->patch_status($pod,
              status => { phase => 'Running' }, type => 'strategic') } ],
    ) {
        my ($label, $call) = @$form;
        my $patched = eval { $call->()->get };
        is($@, '', "$label: the allowed options still go out");
        my $req = MockTransport::last_request();
        is($req->{path}, $POD_STATUS, "$label: path");
        is($req->{headers}{'Content-Type'}, 'application/strategic-merge-patch+json',
            "$label: the type went out");
        is_deeply($JSON->decode($req->{content}), { status => { phase => 'Running' } },
            "$label: the status went out");
    }
};

done_testing;
