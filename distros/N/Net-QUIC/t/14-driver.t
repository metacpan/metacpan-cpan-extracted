use strict;
use warnings;

use Scalar::Util qw(refaddr);
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;

use Net::QUIC::Datagram;
use Net::QUIC::Driver;
use Net::QUIC::Stream;

{
    package T::Driver::Connection;

    sub new {
        my ($class, $endpoint) = @_;
        return bless {
            endpoint => $endpoint,
            callback => undef,
        }, $class;
    }

    sub _set_output_callback {
        my ($self, $callback) = @_;
        $self->{callback} = $callback;
        return;
    }

    sub application_output {
        my ($self, $datagram) = @_;
        push @{$self->{endpoint}{out}}, $datagram;
        $self->{callback}->() if $self->{callback};
        return;
    }
}

{
    package T::Driver::Endpoint;

    sub new {
        my ($class) = @_;
        my $self = bless {
            out          => [],
            received     => [],
            timeout_after => undef,
            timeouts     => 0,
            connection   => undef,
        }, $class;
        $self->{connection} = T::Driver::Connection->new($self);
        return $self;
    }

    sub receive_datagram {
        my ($self, @args) = @_;
        push @{$self->{received}}, \@args;
        return;
    }

    sub next_datagram {
        my ($self) = @_;
        return shift @{$self->{out}};
    }

    sub timeout_after {
        my ($self) = @_;
        return $self->{timeout_after};
    }

    sub handle_timeout {
        my ($self) = @_;
        $self->{timeouts}++;
        return;
    }

    sub connection {
        my ($self) = @_;
        return $self->{connection};
    }

    sub next_connection {
        return;
    }
}

{
    package T::Driver::StreamConnection;

    sub new {
        my ($class) = @_;
        return bless {
            notified => 0,
            data     => [],
            released => 0,
        }, $class;
    }

    sub _stream_retain { return }
    sub _stream_release {
        my ($self) = @_;
        $self->{released}++;
        return;
    }
    sub _stream_send {
        my ($self, $id, $bytes) = @_;
        $self->{sent} = [$id, $bytes];
        return;
    }
    sub _stream_finish {
        my ($self, $id) = @_;
        $self->{finished} = $id;
        return;
    }
    sub _stream_take_data {
        my ($self) = @_;
        return shift @{$self->{data}};
    }
    sub _stream_reset {
        my ($self, $id, $code) = @_;
        $self->{reset} = [$id, $code];
        return;
    }
    sub _stream_stop_sending {
        my ($self, $id, $code) = @_;
        $self->{stop_sending} = [$id, $code];
        return;
    }
    sub _notify_output {
        my ($self) = @_;
        $self->{notified}++;
        return;
    }
}

my $stream_connection = T::Driver::StreamConnection->new;
my $stream = Net::QUIC::Stream->_new(
    $stream_connection,
    4,
    1,
    1,
);

$stream->send('stream-data');
is($stream_connection->{notified}, 1,
    'Stream send notifies integration output');

$stream->finish;
is($stream_connection->{notified}, 2,
    'Stream finish notifies integration output');

push @{$stream_connection->{data}}, ['received-data'];
is($stream->next_data, 'received-data',
    'Stream test connection returns received data');
is($stream_connection->{notified}, 3,
    'consuming stream data notifies integration output');

$stream->reset(9);
is($stream_connection->{notified}, 4,
    'Stream reset notifies integration output');

$stream->stop_sending(10);
is($stream_connection->{notified}, 5,
    'Stream stop_sending notifies integration output');

undef $stream;
is($stream_connection->{released}, 1,
    'Stream test object releases its retained stream state');

my $local = pack_sockaddr_in(40000, inet_aton('127.0.0.1'));
my $peer  = pack_sockaddr_in(4433, inet_aton('127.0.0.1'));

my $fake = T::Driver::Endpoint->new;
my @sent;
my @scheduled;

my $plain_datagram =
    Net::QUIC::Datagram->_new('plain', $local, $peer);
my $ecn_datagram =
    Net::QUIC::Datagram->_new('marked', $local, $peer, 2);

is($plain_datagram->ecn, 0, 'Datagram defaults to Not-ECT');
is($ecn_datagram->ecn, 2, 'Datagram exposes supplied ECN codepoint');

push @{$fake->{out}}, Net::QUIC::Datagram->_new('first', $local, $peer);
push @{$fake->{out}}, Net::QUIC::Datagram->_new('second', $local, $peer);
$fake->{timeout_after} = 0.25;

my $allow = 0;
my $driver = Net::QUIC::Driver->new(
    endpoint => $fake,

    send => sub {
        my ($datagram) = @_;
        push @sent, $datagram->data;
        return $allow;
    },

    set_timeout => sub {
        my ($after) = @_;
        push @scheduled, $after;
        return;
    },
);

isa_ok($driver, ['Net::QUIC::Driver'], 'driver is created');
ok(!$driver->started, 'driver is not started by construction');

like(
    dies { $driver->receive('x', $local, $peer) },
    qr/receive called before start/,
    'receive before transport readiness is rejected',
);

is(refaddr($driver->start), refaddr($driver),
    'start returns the driver');
ok($driver->started, 'start marks driver started');
is(\@sent, ['first'], 'start sends until adapter reports backpressure');
is(\@scheduled, [0.25], 'start requests the current QUIC timeout');

$allow = 1;
$driver->writable;

is(\@sent, ['first', 'second'], 'writable resumes pending QUIC output');
is(\@scheduled, [0.25, 0.25], 'writable refreshes the QUIC timeout');

$fake->{timeout_after} = 0.5;
$driver->receive('incoming', $local, $peer);

is(
    $fake->{received},
    [['incoming', $local, $peer]],
    'receive forwards one UDP datagram to the endpoint',
);
is($scheduled[-1], 0.5, 'receive replaces the requested QUIC timeout');

$driver->receive('incoming-ecn', $local, $peer, 3);

is(
    $fake->{received},
    [
        ['incoming', $local, $peer],
        ['incoming-ecn', $local, $peer, 3],
    ],
    'receive forwards ECN metadata only when supplied',
);

$fake->{timeout_after} = undef;
$driver->timeout;

is($fake->{timeouts}, 1, 'timeout reports one expiry to the endpoint');
ok(!defined $scheduled[-1], 'undef timeout requests timer cancellation');

my $connection = $driver->connection;
isa_ok(
    $connection,
    ['T::Driver::Connection'],
    'connection is returned through the driver',
);

$fake->{timeout_after} = 0.75;
$connection->application_output(
    Net::QUIC::Datagram->_new('application', $local, $peer),
);

is($sent[-1], 'application',
    'application output is serviced without an explicit driver call');
is($scheduled[-1], 0.75,
    'application output also refreshes the QUIC timeout');

my @real_sent;
my @real_timeout;
my $real = Net::QUIC::Driver->client(
    local       => $local,
    peer        => $peer,
    alpn        => 'net-quic-driver-test',
    server_name => 'localhost',

    send => sub {
        my ($datagram) = @_;
        push @real_sent, $datagram;
        return 1;
    },

    set_timeout => sub {
        my ($after) = @_;
        push @real_timeout, $after;
        return;
    },
);

isa_ok($real->connection, ['Net::QUIC::Connection'],
    'client driver exposes the real client connection');
is(scalar @real_sent, 0,
    'client construction performs no UDP output before start');

$real->start;

ok(@real_sent >= 1, 'client start produces the QUIC Initial datagram');
ok(length($real_sent[0]->data) >= 1200,
    'driver carries the real QUIC Initial datagram');
ok(defined $real_timeout[-1],
    'client start requests the first real QUIC timeout');
ok($real_timeout[-1] >= 0,
    'real QUIC timeout is non-negative');

like(
    dies {
        Net::QUIC::Driver->new(
            endpoint => $fake,
            send => sub { 1 },
        );
    },
    qr/missing required set_timeout callback/,
    'driver requires timeout integration',
);

done_testing;
