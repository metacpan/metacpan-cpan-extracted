use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use IO::Async::Stream;
use IO::Socket::INET;
use Net::Async::Kubernetes;
use FakeWebSocketClient;

# port_forward_listen: a real local TCP socket in front of fake websocket
# sessions. The fake "pod" sends the port preambles on the first write it
# sees and answers each data frame with the upper-cased bytes.

my $loop = IO::Async::Loop->new;
my $kube = Net::Async::Kubernetes->new(
    server      => { endpoint => 'https://mock.local' },
    credentials => { token => 'mock-token' },
    resource_map_from_cluster => 0,
);
$loop->add($kube);

my @ws;    # every websocket client the kube made, in order

{
    no warnings 'redefine';
    *Net::Async::Kubernetes::_make_websocket_client = sub {
        my ($self, %args) = @_;
        my $ws = FakeWebSocketClient->new(%args);
        my $greeted;
        $ws->on_send(sub {
            my ($ws, $frame) = @_;
            my $channel = ord(substr($frame, 0, 1));
            unless ($greeted++) {
                my $port = $ws->connect_args->{url} =~ /ports=(\d+)/ ? $1 : 0;
                $ws->emit_binary(chr($_) . pack('v', $port)) for 0, 1;
            }
            $ws->emit_binary(chr($channel) . uc substr($frame, 1));
        });
        push @ws, $ws;
        return $ws;
    };
}

sub wait_for {
    my ($cond, $what) = @_;
    for (1 .. 100) {
        return 1 if $cond->();
        $loop->loop_once(0.05);
    }
    fail("timeout waiting for $what");
    return 0;
}

sub tcp_client {
    my ($port) = @_;
    my $c = { got => '', closed => 0 };
    my $sock = $loop->connect(
        host => '127.0.0.1', service => $port, socktype => 'stream',
    )->get;
    $c->{stream} = IO::Async::Stream->new(
        handle  => $sock,
        on_read => sub {
            my (undef, $buffref) = @_;
            $c->{got} .= $$buffref;
            $$buffref = '';
            return 0;
        },
        on_closed => sub { $c->{closed} = 1 },
    );
    $loop->add($c->{stream});
    return $c;
}

subtest 'validation fails the future, nothing listens' => sub {
    my %base = (namespace => 'default');
    my @cases = (
        [ 'no name',        [ 'Pod', %base, ports => { 0 => 80 } ],               qr/name required for port_forward_listen/ ],
        [ 'no ports',       [ 'Pod', 'web', %base ],                              qr/ports required/ ],
        [ 'ports array',    [ 'Pod', 'web', %base, ports => [80] ],               qr/ports required/ ],
        [ 'empty ports',    [ 'Pod', 'web', %base, ports => {} ],                 qr/ports required/ ],
        [ 'bad local',      [ 'Pod', 'web', %base, ports => { 70000 => 80 } ],    qr/invalid local port '70000'/ ],
        [ 'bad local text', [ 'Pod', 'web', %base, ports => { abc => 80 } ],      qr/invalid local port 'abc'/ ],
        [ 'remote zero',    [ 'Pod', 'web', %base, ports => { 0 => 0 } ],         qr/invalid remote port '0'/ ],
        [ 'remote big',     [ 'Pod', 'web', %base, ports => { 0 => 65536 } ],     qr/invalid remote port '65536'/ ],
        [ 'duplicate',      [ 'Pod', 'web', %base, ports => { 1 => 80, 2 => 80 } ], qr/remote port '80' listed twice/ ],
        [ 'unknown option', [ 'Pod', 'web', %base, ports => { 0 => 80 }, local_port => 1 ], qr/Unknown argument 'local_port' to port_forward_listen\(\) \(allowed: / ],
        [ 'odd list',       [ 'Pod', 'web', 'orphan' ],                           qr/Invalid arguments to port_forward_listen\(\)/ ],
        [ 'unknown class',  [ 'NoSuchKind', 'web', ports => { 0 => 80 } ],        qr/unknown resource/ ],
    );
    for my $case (@cases) {
        my ($label, $args, $re) = @$case;
        my $f = eval { $kube->port_forward_listen(@$args) };
        is($@, '', "$label: does not croak");
        ok($f && $f->is_failed, "$label: failed future");
        like($f ? $f->failure : '', $re, "$label: message");
    }
    is(scalar @ws, 0, 'no websocket was opened');

    my $unlooped = Net::Async::Kubernetes->new(
        server => { endpoint => 'https://mock.local' }, credentials => { token => 't' },
    );
    my $f = $unlooped->port_forward_listen('Pod', 'web', ports => { 0 => 80 });
    ok($f->is_failed, 'no loop: failed');
    like($f->failure, qr/added to an IO::Async::Loop/, 'clear loop message');
};

subtest 'data both ways, one session per connection, close, stop' => sub {
    @ws = ();
    my @errors;
    my $l = $kube->port_forward_listen('Pod', 'web',
        namespace => 'default',
        ports     => { 0 => 8080 },
        on_error  => sub { push @errors, $_[0] },
    )->get;
    isa_ok($l, 'Net::Async::Kubernetes::PortForwardListener');
    my $port = $l->port_for(8080);
    ok($port && $port > 0, 'ephemeral local port reported') or diag "port: " . ($port // 'undef');
    is($l->port_for(1234), undef, 'unknown remote has no port');
    is($l->host, '127.0.0.1', 'binds loopback by default');
    is(scalar @ws, 0, 'no session before a connection');

    my $c1 = tcp_client($port);
    $c1->{stream}->write('hello');
    wait_for(sub { $c1->{got} eq 'HELLO' }, 'echo on connection 1');
    is($c1->{got}, 'HELLO', 'bytes went TCP -> pod -> TCP, preamble stripped');
    is(scalar @ws, 1, 'one session');
    like($ws[0]->connect_args->{url}, qr{/pods/web/portforward\?ports=8080$}, 'this connection asks for exactly the remote port');
    is_deeply($ws[0]->sent_binary, [chr(0) . 'hello'], 'sent on the data channel of the port');

    my $c2 = tcp_client($port);
    $c2->{stream}->write('abc');
    wait_for(sub { $c2->{got} eq 'ABC' }, 'echo on connection 2');
    is(scalar @ws, 2, 'second connection has its own session');
    isnt($ws[1], $ws[0], 'distinct websocket clients');
    is($l->connection_count, 2, 'two open connections');
    is($c1->{got}, 'HELLO', 'connections do not mix');

    # the pod side ends connection 1
    $ws[0]->emit_close('');
    wait_for(sub { $c1->{closed} }, 'connection 1 closed after websocket close');
    ok($c1->{closed}, 'remote close closes the TCP connection');
    ok(!$c2->{closed}, 'other connection stays');
    is($l->connection_count, 1, 'one connection left');
    $c2->{stream}->write('x');
    wait_for(sub { $c2->{got} eq 'ABCX' }, 'connection 2 still works');
    is($c2->{got}, 'ABCX', 'still forwarding');

    # the TCP client goes away: the session is closed
    $c2->{stream}->close_when_empty;
    wait_for(sub { @{$ws[1]->sent_close} }, 'close frame to the pod');
    is(scalar @{$ws[1]->sent_close}, 1, 'client close closes the websocket session');
    is($l->connection_count, 0, 'no connections left');

    # stop closes live connections and the listener
    my $c3 = tcp_client($port);
    $c3->{stream}->write('q');
    wait_for(sub { $c3->{got} eq 'Q' }, 'connection 3');
    $l->stop;
    wait_for(sub { $c3->{closed} }, 'connection 3 closed by stop');
    ok($c3->{closed}, 'stop closes open connections');
    is(scalar @{$ws[2]->sent_close}, 1, 'stop closes the session');
    my $refused = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp');
    ok(!$refused, 'stop closes the listening socket');
    $l->stop;
    pass('stop twice is fine');
    is_deeply(\@errors, [], 'no errors reported on the normal path');
};

subtest 'data before the session is open is held' => sub {
    @ws = ();
    local $FakeWebSocketClient::HOLD = 1;
    @FakeWebSocketClient::PENDING = ();
    my $l = $kube->port_forward_listen('Pod', 'web', ports => { 0 => 8080 })->get;
    my $c = tcp_client($l->port_for(8080));
    $c->{stream}->write('early ');
    $c->{stream}->write('bird');
    wait_for(sub { @FakeWebSocketClient::PENDING }, 'session requested');
    $loop->loop_once(0.1);
    is(scalar @{$ws[0]->sent_binary}, 0, 'nothing sent while the session is not open');

    my ($client, $f) = @{shift @FakeWebSocketClient::PENDING};
    $f->done($client);
    wait_for(sub { $c->{got} ne '' }, 'buffered bytes answered');
    is_deeply($ws[0]->sent_binary, [chr(0) . 'early bird'], 'buffered bytes sent in order once open');
    is($c->{got}, 'EARLY BIRD', 'and answered');
    $l->stop;
};

subtest 'pod-side error closes the connection and is reported' => sub {
    @ws = ();
    my @errors;
    my $l = $kube->port_forward_listen('Pod', 'web',
        ports    => { 0 => 8080 },
        on_error => sub { push @errors, $_[0] },
    )->get;
    my $c = tcp_client($l->port_for(8080));
    $c->{stream}->write('hi');
    wait_for(sub { $c->{got} eq 'HI' }, 'connection works');
    $ws[0]->emit_binary(chr(1) . 'connection refused');
    wait_for(sub { $c->{closed} }, 'closed on port error');
    ok($c->{closed}, 'TCP connection closed');
    is_deeply(\@errors, ['port 8080: connection refused'], 'reported once with the port');
    is(scalar @{$ws[0]->sent_close}, 1, 'session closed');

    # a protocol error (wrong preamble on a fresh session) ends it too
    @errors = ();
    {
        no warnings 'redefine';
        local *FakeWebSocketClient::send_binary_frame = sub {
            my ($ws) = @_;
            $ws->emit_binary(chr(0) . pack('v', 1111));
            return Future->done(1);
        };
        my $c2 = tcp_client($l->port_for(8080));
        $c2->{stream}->write('hi');
        wait_for(sub { $c2->{closed} }, 'closed on bad preamble');
        ok($c2->{closed}, 'bad preamble closes the connection');
        like($errors[0], qr/port 8080: channel 0.*1111/, 'reported');
        is($c2->{got}, '', 'nothing leaked as data');
    }
    $l->stop;
};

subtest 'failing session request closes the connection' => sub {
    @ws = ();
    local $FakeWebSocketClient::HOLD = 1;
    @FakeWebSocketClient::PENDING = ();
    my @errors;
    my $l = $kube->port_forward_listen('Pod', 'web',
        ports    => { 0 => 8080 },
        on_error => sub { push @errors, $_[0] },
    )->get;
    my $c = tcp_client($l->port_for(8080));
    $c->{stream}->write('x');
    wait_for(sub { @FakeWebSocketClient::PENDING }, 'session requested');
    my (undef, $f) = @{shift @FakeWebSocketClient::PENDING};
    $f->fail('403 forbidden');
    wait_for(sub { $c->{closed} }, 'closed');
    ok($c->{closed}, 'connection closed');
    like($errors[0], qr/port 8080: .*403 forbidden/, 'failure reported');
    $l->stop;
};

subtest 'two mappings, one port each' => sub {
    @ws = ();
    my $probe = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp');
    my $fixed = $probe->sockport;
    close $probe;
    my $l = $kube->port_forward_listen('Pod', name => 'web',
        ports => { 0 => 8080, $fixed => 8443 },
    )->get;
    is($l->port_for(8443), $fixed, 'fixed local port kept');
    ok($l->port_for(8080) && $l->port_for(8080) != $fixed, 'other one ephemeral');

    my $c = tcp_client($l->port_for(8443));
    $c->{stream}->write('t');
    wait_for(sub { $c->{got} eq 'T' }, 'echo');
    like($ws[0]->connect_args->{url}, qr/ports=8443$/, 'local port maps to its own remote port');
    $l->stop;
};

done_testing;
