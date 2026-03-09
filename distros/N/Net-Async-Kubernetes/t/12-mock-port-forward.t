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

subtest 'default transport requires notifier to be in loop for port_forward' => sub {
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
    );

    my $f = $kube->port_forward('Pod', 'nginx',
        namespace => 'default',
        ports     => [8080],
    );
    ok($f->is_failed, 'default port_forward future failed');
    like($f->failure, qr/added to an IO::Async::Loop/i, 'clear loop requirement message');
};

subtest 'port_forward validation' => sub {
    my $kube = make_kube();

    my $f1 = $kube->port_forward('Pod', namespace => 'default', ports => [8080]);
    ok($f1->is_failed, 'name required');
    like($f1->failure, qr/name required for port_forward/, 'missing name message');

    my $f2 = $kube->port_forward('Pod', 'nginx', namespace => 'default');
    ok($f2->is_failed, 'ports required');
    like($f2->failure, qr/ports required for port_forward/, 'missing ports message');

    my $f3 = $kube->port_forward('Pod', 'nginx', namespace => 'default', ports => ['abc']);
    ok($f3->is_failed, 'invalid port rejected');
    like($f3->failure, qr/invalid port/, 'invalid port message');

    my $f4 = $kube->port_forward('Pod', 'nginx', 'orphan');
    ok($f4->is_failed, 'invalid argument structure rejected');
    like($f4->failure, qr/Invalid arguments to port_forward\(\)/, 'invalid args message');
};

subtest 'port_forward request and callbacks' => sub {
    my $kube = make_kube();
    MockTransport::mock_duplex_session({ ok => 1, session => 'pf-1' });

    my $f = $kube->port_forward('Pod', 'nginx',
        namespace   => 'default',
        ports       => [8080, 8443],
        subprotocol => 'v4.channel.k8s.io',
        on_open     => sub { },
        on_frame    => sub { },
        on_close    => sub { },
        on_error    => sub { },
    );

    my $session = $f->get;
    is($session->{session}, 'pf-1', 'duplex session returned');

    my $req = MockTransport::last_request();
    is($req->{method}, 'GET', 'used GET');
    ok($req->{duplex}, 'used duplex transport hook');
    like($req->{path}, qr{/api/v1/namespaces/default/pods/nginx/portforward}, 'uses portforward path');
    like($req->{url}, qr/ports=8080/, 'first port query param');
    like($req->{url}, qr/ports=8443/, 'second port query param');

    my $callbacks = $req->{callbacks};
    is($callbacks->{on_open}, 1, 'on_open callback passed');
    is($callbacks->{on_frame}, 1, 'on_frame callback passed');
    is($callbacks->{on_close}, 1, 'on_close callback passed');
    is($callbacks->{on_error}, 1, 'on_error callback passed');
};

done_testing;
