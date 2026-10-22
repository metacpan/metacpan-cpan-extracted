use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use FakeWebSocketClient;

# port_forward on the real transport code with a fake websocket client:
# channel -> port mapping, preamble stripping and checking, error channel.

my $loop = IO::Async::Loop->new;

sub setup {
    my %cb = @_;
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
    );
    $loop->add($kube);
    my $ws;
    no warnings 'redefine';
    local *Net::Async::Kubernetes::_make_websocket_client = sub {
        my ($self, %args) = @_;
        return $ws = FakeWebSocketClient->new(%args);
    };
    my $session = $kube->port_forward('Pod', 'web',
        namespace => 'default',
        ports     => [8080, 8443],
        %cb,
    )->get;
    return ($session, $ws);
}

sub pre { chr($_[0] & 255) . chr($_[0] >> 8) }

subtest 'channels map to ports, preamble is stripped' => sub {
    my (@data, @perr, @err, @raw);
    my ($s, $ws) = setup(
        on_data       => sub { push @data, [@_[1, 2]] },
        on_port_error => sub { push @perr, [@_[1, 2]] },
        on_error      => sub { push @err, $_[0] },
        on_frame      => sub { push @raw, [@_] },
    );
    ok($s->is_port_forward, 'port-forward session');
    is_deeply($s->ports, [8080, 8443], 'ports kept in order');

    $ws->emit_binary(chr(0) . pre(8080));
    $ws->emit_binary(chr(1) . pre(8080));
    $ws->emit_binary(chr(2) . pre(8443));
    $ws->emit_binary(chr(3) . pre(8443));
    is_deeply(\@data, [], 'preambles are not data');
    is_deeply(\@perr, [], 'preambles are not port errors');
    is_deeply(\@err, [], 'correct preambles are no error');

    $ws->emit_binary(chr(0) . 'one');
    $ws->emit_binary(chr(2) . 'two');
    $ws->emit_binary(chr(0) . 'three');
    is_deeply(\@data, [[8080, 'one'], [8443, 'two'], [8080, 'three']],
        'data channel 2*i belongs to the i-th port');

    $ws->emit_binary(chr(1) . 'no route');
    $ws->emit_binary(chr(3) . 'refused');
    is_deeply(\@perr, [[8080, 'no route'], [8443, 'refused']],
        'error channel 2*i+1 reaches on_port_error with its port');
    is_deeply(\@data, [[8080, 'one'], [8443, 'two'], [8080, 'three']],
        'error payload is not data');

    is(scalar @raw, 9, 'on_frame still sees every frame');
    is_deeply($raw[0], [0, pre(8080)], 'on_frame is raw: preamble included');
    is_deeply($raw[4], [0, 'one'], 'on_frame also called with on_data set');
};

subtest 'wrong preamble is an error and the frame is not data' => sub {
    my (@data, @err);
    my ($s, $ws) = setup(
        on_data  => sub { push @data, [@_[1, 2]] },
        on_error => sub { push @err, $_[0] },
    );
    $ws->emit_binary(chr(0) . pre(9999));
    is(scalar @err, 1, 'one error');
    like($err[0], qr/channel 0.*port 8080.*9999/, 'names channel, port and the number seen');
    $ws->emit_binary(chr(0) . 'late');
    is_deeply(\@data, [], 'nothing delivered on a channel with a bad preamble');
    is(scalar @err, 1, 'not reported again');

    $ws->emit_binary(chr(2) . pre(8443));
    $ws->emit_binary(chr(2) . 'fine');
    is_deeply(\@data, [[8443, 'fine']], 'other channel unaffected');
};

subtest 'preamble together with data is an error' => sub {
    my (@data, @err);
    my ($s, $ws) = setup(
        on_data  => sub { push @data, [@_[1, 2]] },
        on_error => sub { push @err, $_[0] },
    );
    $ws->emit_binary(chr(0) . pre(8080) . 'HTTP/1.1 200');
    is(scalar @err, 1, 'error');
    like($err[0], qr/carries data after the port number/, 'clear message');
    is_deeply(\@data, [], 'nothing delivered');

    $ws->emit_binary(chr(2) . 'x');
    is(scalar @err, 2, 'one-byte first frame is an error');
    like($err[1], qr/not a 2-byte port number/, 'message');
};

subtest 'channel beyond the requested ports is an error' => sub {
    my (@data, @perr, @err);
    my ($s, $ws) = setup(
        on_data       => sub { push @data, 1 },
        on_port_error => sub { push @perr, 1 },
        on_error      => sub { push @err, $_[0] },
    );
    $ws->emit_binary(chr(4) . pre(1234));
    is(scalar @err, 1, 'error');
    like($err[0], qr/channel 4.*0 to 3/, 'message names channel and range');
    is(scalar(@data) + scalar(@perr), 0, 'nothing delivered');
};

subtest 'write_port frames on the port data channel' => sub {
    my ($s, $ws) = setup();
    $s->write_port(8080, 'a')->get;
    $s->write_port(8443, 'b')->get;
    is_deeply($ws->sent_binary, [chr(0) . 'a', chr(2) . 'b'],
        'write_port uses channel 2*i of the port');

    eval { $s->write_port(9, 'x') };
    like($@, qr/port '9' is not forwarded/, 'unknown port croaks');
    eval { $s->write_port(undef, 'x') };
    like($@, qr/port required/, 'missing port croaks');

    eval { $s->write_stdin('x') };
    like($@, qr/write_stdin is not available on a port-forward session/, 'write_stdin croaks');
    eval { $s->resize(width => 10, height => 10) };
    like($@, qr/resize is not available on a port-forward session/, 'resize croaks');
    eval { $s->stdin('x') };
    like($@, qr/not available/, 'stdin alias croaks too');

    $s->write_channel(1, 'raw')->get;
    is($ws->sent_binary->[-1], chr(1) . 'raw', 'write_channel stays raw');
    is(scalar @{$ws->sent_binary}, 3, 'refused writes sent nothing');
};

subtest 'exec session is unaffected' => sub {
    my $session = Net::Async::Kubernetes::PortForwardSession->new(
        ws_client => FakeWebSocketClient->new,
    );
    ok(!$session->is_port_forward, 'not a port-forward session');
    is($session->ports, undef, 'no ports');
    eval { $session->write_port(80, 'x') };
    like($@, qr/only for port-forward sessions/, 'write_port refused');
    $session->write_stdin('id')->get;
    is($session->ws_client->sent_binary->[0], chr(0) . 'id', 'write_stdin works');
    $session->resize(width => 120, height => 40)->get;
    is($session->ws_client->sent_binary->[1], chr(4) . '{"Width":120,"Height":40}', 'resize works');
};

done_testing;
