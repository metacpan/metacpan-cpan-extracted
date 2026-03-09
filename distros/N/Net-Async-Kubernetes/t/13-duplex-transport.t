use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

use IO::Async::Loop;
use Future;

use Net::Async::Kubernetes;

{
    package Test::WSClient;
    use strict;
    use warnings;
    use parent 'IO::Async::Notifier';
    use Future;

    sub configure {
        my ($self, %params) = @_;
        for my $name (qw(
            on_binary_frame on_text_frame on_close_frame
            on_read_error on_write_error on_closed
        )) {
            $self->{$name} = delete $params{$name} if exists $params{$name};
        }
        $self->SUPER::configure(%params);
    }

    sub connect {
        my ($self, %args) = @_;
        $self->{connect_args} = \%args;
        return Future->fail($self->{connect_fail}) if $self->{connect_fail};
        return Future->done($self);
    }

    sub connect_args { $_[0]->{connect_args} }
    sub connect_fail { $_[0]->{connect_fail} = $_[1] }

    sub send_binary_frame {
        my ($self, $bytes) = @_;
        push @{$self->{sent_binary}}, $bytes;
        return Future->done(1);
    }

    sub send_close_frame {
        my ($self, $bytes) = @_;
        push @{$self->{sent_close}}, $bytes;
        return Future->done(1);
    }

    sub close_when_empty { $_[0]->{closed_when_empty}++ }

    sub sent_binary { $_[0]->{sent_binary} || [] }
    sub sent_close  { $_[0]->{sent_close}  || [] }
    sub closed_when_empty { $_[0]->{closed_when_empty} || 0 }

    sub emit_binary {
        my ($self, $bytes) = @_;
        $self->{on_binary_frame}->($self, $bytes) if $self->{on_binary_frame};
    }

    sub emit_read_error {
        my ($self, $errno, $msg) = @_;
        $self->{on_read_error}->($self, $errno, $msg) if $self->{on_read_error};
    }
}

sub make_kube {
    my ($loop) = @_;
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
    );
    $loop->add($kube);
    return $kube;
}

subtest 'duplex websocket transport returns active session' => sub {
    my $loop = IO::Async::Loop->new;
    my $kube = make_kube($loop);
    my $last_ws;

    no warnings 'redefine';
    local *Net::Async::Kubernetes::_make_websocket_client = sub {
        my ($self, %args) = @_;
        $last_ws = Test::WSClient->new(%args);
        return $last_ws;
    };

    my @frames;
    my @errors;
    my $opened_session;

    my $session = $kube->port_forward('Pod', 'nginx',
        namespace   => 'default',
        ports       => [8080, 8443],
        subprotocol => 'v4.channel.k8s.io',
        on_open     => sub { ($opened_session) = @_ },
        on_frame    => sub { push @frames, [@_] },
        on_error    => sub { push @errors, $_[0] },
    )->get;

    isa_ok($session, 'Net::Async::Kubernetes::PortForwardSession');
    ok(defined $opened_session, 'on_open called with session');
    is(refaddr($opened_session), refaddr($session), 'on_open received returned session');

    my $connect = $last_ws->connect_args;
    like($connect->{url}, qr{^wss://mock\.local/}, 'https endpoint converted to wss');
    like($connect->{url}, qr/ports=8080/, 'first port query set');
    like($connect->{url}, qr/ports=8443/, 'second port query set');

    is($connect->{req}->subprotocol, 'v4.channel.k8s.io', 'subprotocol passed to handshake');
    my %extra_headers = @{$connect->{req}->{headers} || []};
    is($extra_headers{Authorization}, 'Bearer mock-token', 'authorization header forwarded');

    $last_ws->emit_binary(chr(1) . "hello");
    is_deeply(\@frames, [[1, 'hello']], 'binary frame decoded to channel and payload');

    $session->write_channel(2, 'abc')->get;
    is($last_ws->sent_binary->[0], chr(2) . 'abc', 'write_channel encodes first byte as channel');

    $session->close(code => 1000, payload => 'bye')->get;
    is($last_ws->sent_close->[0], pack('n', 1000) . 'bye', 'close sends websocket close payload');
    is($last_ws->closed_when_empty, 1, 'close requests graceful socket close');

    $last_ws->emit_read_error(undef, 'boom');
    like($errors[-1], qr/boom/, 'transport errors forwarded to on_error');
};

subtest 'connect failure is propagated and reported to on_error' => sub {
    my $loop = IO::Async::Loop->new;
    my $kube = make_kube($loop);
    my $last_ws;

    no warnings 'redefine';
    local *Net::Async::Kubernetes::_make_websocket_client = sub {
        my ($self, %args) = @_;
        $last_ws = Test::WSClient->new(%args);
        $last_ws->connect_fail('ws connect failed');
        return $last_ws;
    };

    my @errors;
    my $f = $kube->port_forward('Pod', 'nginx',
        namespace => 'default',
        ports     => [8080],
        on_error  => sub { push @errors, $_[0] },
    );

    ok($f->is_failed, 'port_forward future failed');
    like($f->failure, qr/ws connect failed/, 'connect failure propagated');
    like($errors[0], qr/ws connect failed/, 'connect failure sent to on_error callback');
    ok(!$last_ws->parent, 'failed websocket client detached from notifier');
};

subtest 'exec uses websocket transport and command query params' => sub {
    my $loop = IO::Async::Loop->new;
    my $kube = make_kube($loop);
    my $last_ws;

    no warnings 'redefine';
    local *Net::Async::Kubernetes::_make_websocket_client = sub {
        my ($self, %args) = @_;
        $last_ws = Test::WSClient->new(%args);
        return $last_ws;
    };

    my $session = $kube->exec('Pod', 'nginx',
        namespace => 'default',
        command   => ['sh', '-c', 'id'],
        stdin     => 1,
        stderr    => 0,
    )->get;

    isa_ok($session, 'Net::Async::Kubernetes::PortForwardSession');
    my $connect = $last_ws->connect_args;
    like($connect->{url}, qr{/api/v1/namespaces/default/pods/nginx/exec}, 'exec path used');
    like($connect->{url}, qr/command=sh/, 'first command parameter');
    like($connect->{url}, qr/command=-c/, 'second command parameter');
    like($connect->{url}, qr/command=id/, 'third command parameter');
    like($connect->{url}, qr/stdin=true/, 'stdin set');
    like($connect->{url}, qr/stdout=true/, 'stdout default set');
    like($connect->{url}, qr/stderr=false/, 'stderr override set');
    like($connect->{url}, qr/tty=false/, 'tty default set');
};

done_testing;
