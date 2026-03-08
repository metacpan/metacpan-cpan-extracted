use strict;
use warnings;
use Test2::V0;

use IO::Async::Loop;
use Net::Async::NATS;

# Test that we can instantiate with custom config
my $loop = IO::Async::Loop->new;
my $nats = Net::Async::NATS->new(
    host => 'test.invalid',
    port => 14222,
    name => 'test-client',
);
$loop->add($nats);

is $nats->host, 'test.invalid', 'host configured';
is $nats->port, 14222, 'port configured';
is $nats->name, 'test-client', 'name configured';
is $nats->verbose, 0, 'verbose default off';
is $nats->pedantic, 0, 'pedantic default off';
ok !$nats->is_connected, 'not connected initially';

# Test protocol line parsing by feeding data to _on_read
# Simulate INFO from server
{
    my $info_json = '{"server_id":"TEST","version":"2.10.0","proto":1,"host":"0.0.0.0","port":4222,"max_payload":1048576}';
    my $buffer = "INFO $info_json\r\n";

    # Call _on_read directly (normally called by Stream)
    $nats->_on_read(undef, \$buffer, 0);

    is $nats->server_info->{server_id}, 'TEST', 'parsed server_id from INFO';
    is $nats->server_info->{version}, '2.10.0', 'parsed version from INFO';
    is $nats->server_info->{max_payload}, 1048576, 'parsed max_payload from INFO';
}

# Test PING handling — should produce PONG
{
    my @written;
    no warnings 'redefine';
    local *Net::Async::NATS::_write = sub {
        my ($self, $data) = @_;
        push @written, $data;
    };

    my $buffer = "PING\r\n";
    $nats->_on_read(undef, \$buffer, 0);

    ok scalar(grep { $_ eq "PONG\r\n" } @written), 'PONG sent in response to PING';
}

# Test MSG dispatch
{
    my @received;
    $nats->{_subscriptions}{7} = Net::Async::NATS::Subscription->new(
        sid      => 7,
        subject  => 'test.*',
        callback => sub { push @received, [@_] },
    );

    my $buffer = "MSG test.hello 7 11\r\nHello NATS!\r\n";
    $nats->_on_read(undef, \$buffer, 0);

    is scalar @received, 1, 'received one message';
    is $received[0][0], 'test.hello', 'message subject';
    is $received[0][1], 'Hello NATS!', 'message payload';
    is $received[0][2], undef, 'no reply-to';
}

# Test MSG with reply-to
{
    my @received;
    $nats->{_subscriptions}{8} = Net::Async::NATS::Subscription->new(
        sid      => 8,
        subject  => 'req.*',
        callback => sub { push @received, [@_] },
    );

    my $buffer = "MSG req.echo 8 _INBOX.abc123 4\r\nping\r\n";
    $nats->_on_read(undef, \$buffer, 0);

    is scalar @received, 1, 'received message with reply-to';
    is $received[0][0], 'req.echo', 'subject';
    is $received[0][1], 'ping', 'payload';
    is $received[0][2], '_INBOX.abc123', 'reply-to';
}

# Test empty payload
{
    my @received;
    $nats->{_subscriptions}{9} = Net::Async::NATS::Subscription->new(
        sid      => 9,
        subject  => 'notify',
        callback => sub { push @received, [@_] },
    );

    my $buffer = "MSG notify 9 0\r\n\r\n";
    $nats->_on_read(undef, \$buffer, 0);

    is scalar @received, 1, 'received empty message';
    is $received[0][1], '', 'empty payload';
}

# Test multiple messages in one buffer
{
    my @received;
    $nats->{_subscriptions}{10} = Net::Async::NATS::Subscription->new(
        sid      => 10,
        subject  => 'multi',
        callback => sub { push @received, [@_] },
    );

    my $buffer = "MSG multi 10 5\r\nfirst\r\nMSG multi 10 6\r\nsecond\r\n";
    $nats->_on_read(undef, \$buffer, 0);

    is scalar @received, 2, 'received two messages';
    is $received[0][1], 'first', 'first payload';
    is $received[1][1], 'second', 'second payload';
}

# Test PONG resolves ping future
{
    my $f = $loop->new_future;
    $nats->{_ping_future} = $f;

    my $buffer = "PONG\r\n";
    $nats->_on_read(undef, \$buffer, 0);

    ok $f->is_done, 'ping future resolved by PONG';
}

# Test -ERR callback
{
    my @errors;
    $nats->{on_error} = sub { push @errors, $_[1] };

    my $buffer = "-ERR 'Invalid Subject'\r\n";
    $nats->_on_read(undef, \$buffer, 0);

    is scalar @errors, 1, 'error callback called';
    like $errors[0], qr/Invalid Subject/, 'error message captured';
}

# Test +OK ignored
{
    my $buffer = "+OK\r\n";
    $nats->_on_read(undef, \$buffer, 0);
    pass('+OK handled without error');
}

done_testing;
