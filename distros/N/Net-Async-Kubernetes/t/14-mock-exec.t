use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use MockTransport;

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

subtest 'exec validation' => sub {
    my $kube = make_kube();

    my $f1 = $kube->exec('Pod', namespace => 'default', command => ['sh']);
    ok($f1->is_failed, 'name required');
    like($f1->failure, qr/name required for exec/, 'missing name message');

    my $f2 = $kube->exec('Pod', 'nginx', namespace => 'default');
    ok($f2->is_failed, 'command required');
    like($f2->failure, qr/command required for exec/, 'missing command message');

    my $f3 = $kube->exec('Pod', 'nginx', namespace => 'default', command => []);
    ok($f3->is_failed, 'empty command rejected');
    like($f3->failure, qr/command required for exec/, 'empty command message');

    my $f4 = $kube->exec('Pod', 'nginx', namespace => 'default', command => [undef]);
    ok($f4->is_failed, 'invalid command element rejected');
    like($f4->failure, qr/invalid command element/, 'invalid command element message');

    my $f5 = $kube->exec('Pod', 'nginx', 'orphan');
    ok($f5->is_failed, 'invalid argument structure rejected');
    like($f5->failure, qr/Invalid arguments to exec\(\)/, 'invalid args message');
};

subtest 'exec request and callbacks' => sub {
    my $kube = make_kube();
    MockTransport::mock_duplex_session({ ok => 1, session => 'exec-1' });

    my $f = $kube->exec('Pod', 'nginx',
        namespace   => 'default',
        command     => ['sh', '-c', 'echo hello'],
        container   => 'app',
        stdin       => 1,
        stdout      => 1,
        stderr      => 0,
        tty         => 1,
        subprotocol => 'v4.channel.k8s.io',
        on_open     => sub { },
        on_frame    => sub { },
        on_close    => sub { },
        on_error    => sub { },
    );

    my $session = $f->get;
    is($session->{session}, 'exec-1', 'duplex session returned');

    my $req = MockTransport::last_request();
    is($req->{method}, 'GET', 'used GET');
    ok($req->{duplex}, 'used duplex transport hook');
    like($req->{path}, qr{/api/v1/namespaces/default/pods/nginx/exec}, 'uses exec path');
    like($req->{url}, qr/command=sh/, 'first command query param');
    like($req->{url}, qr/command=-c/, 'second command query param');
    like($req->{url}, qr/command=echo/, 'third command query param');
    like($req->{url}, qr/container=app/, 'container query param');
    like($req->{url}, qr/stdin=true/, 'stdin query param');
    like($req->{url}, qr/stdout=true/, 'stdout query param');
    like($req->{url}, qr/stderr=false/, 'stderr query param');
    like($req->{url}, qr/tty=true/, 'tty query param');

    my $callbacks = $req->{callbacks};
    is($callbacks->{on_open}, 1, 'on_open callback passed');
    is($callbacks->{on_frame}, 1, 'on_frame callback passed');
    is($callbacks->{on_close}, 1, 'on_close callback passed');
    is($callbacks->{on_error}, 1, 'on_error callback passed');
};

subtest 'exec supports scalar command and default stream flags' => sub {
    my $kube = make_kube();
    MockTransport::mock_duplex_session({ ok => 1, session => 'exec-2' });

    my $session = $kube->exec('Pod', 'nginx',
        namespace => 'default',
        command   => 'id',
    )->get;
    is($session->{session}, 'exec-2', 'duplex session returned');

    my $req = MockTransport::last_request();
    like($req->{url}, qr/command=id/, 'scalar command converted to command parameter');
    like($req->{url}, qr/stdin=false/, 'stdin defaults false');
    like($req->{url}, qr/stdout=true/, 'stdout defaults true');
    like($req->{url}, qr/stderr=true/, 'stderr defaults true');
    like($req->{url}, qr/tty=false/, 'tty defaults false');
};

done_testing;
