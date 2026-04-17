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

subtest 'attach validation' => sub {
    my $kube = make_kube();

    my $f1 = $kube->attach('Pod', namespace => 'default');
    ok($f1->is_failed, 'name required');
    like($f1->failure, qr/name required for attach/, 'missing name message');

    my $f2 = $kube->attach('Pod', 'nginx', 'orphan');
    ok($f2->is_failed, 'invalid argument structure rejected');
    like($f2->failure, qr/Invalid arguments to attach\(\)/, 'invalid args message');
};

subtest 'attach request and callbacks' => sub {
    my $kube = make_kube();
    MockTransport::mock_duplex_session({ ok => 1, session => 'attach-1' });

    my $f = $kube->attach('Pod', 'nginx',
        namespace   => 'default',
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
    is($session->{session}, 'attach-1', 'duplex session returned');

    my $req = MockTransport::last_request();
    is($req->{method}, 'GET', 'used GET');
    ok($req->{duplex}, 'used duplex transport hook');
    like($req->{path}, qr{/api/v1/namespaces/default/pods/nginx/attach}, 'uses attach path');
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

subtest 'attach default stream flags' => sub {
    my $kube = make_kube();
    MockTransport::mock_duplex_session({ ok => 1, session => 'attach-2' });

    my $session = $kube->attach('Pod', 'nginx',
        namespace => 'default',
    )->get;
    is($session->{session}, 'attach-2', 'duplex session returned');

    my $req = MockTransport::last_request();
    like($req->{url}, qr/stdin=false/, 'stdin defaults false');
    like($req->{url}, qr/stdout=true/, 'stdout defaults true');
    like($req->{url}, qr/stderr=true/, 'stderr defaults true');
    like($req->{url}, qr/tty=false/, 'tty defaults false');
};

done_testing;
