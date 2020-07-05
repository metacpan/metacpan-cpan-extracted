use strict;
use warnings;

use Test::More;
use Test::Fatal;

use IO::Async::Loop;
use Ryu::Async;

use Socket qw(INADDR_LOOPBACK INADDR_NONE INADDR_ANY inet_ntoa);

my $loopback = inet_ntoa(INADDR_LOOPBACK);
note 'loopback: ' . $loopback;
my $loop = IO::Async::Loop->new;

$loop->add(
    my $ryu = Ryu::Async->new
);

my $message_content = 'test message';

ok(my $server = $ryu->udp_server(host => $loopback), 'can create new server');
isa_ok($server, 'Ryu::Async::Server');

my $f = $loop->new_future;
$server->incoming->each(sub {
    fail('multiple packets received') if $f->is_ready;
    isa_ok($_, 'Ryu::Async::Packet');
    is($_->payload, $message_content, 'payload matches original message content');
    $f->done;
});

my $port;
is(exception {
    ($port) = Future->wait_any(
        $server->port,
        $loop->timeout_future(after => 2)
    )->get;
    ok($port, 'have nonzero port');
}, undef, 'able to get port') or die 'no way to continue without a port';

note 'Will try client connection to ' . $loopback;
ok(my $client = $ryu->udp_client(
    host => $loopback,
    port => $port
), 'can create client');
isa_ok($client, 'Ryu::Async::Client');
TODO: {
    local $TODO = 'UDP host/port handling in test needs rework';
    $client->outgoing->emit($message_content);

    is(exception {
        Future->wait_any(
            $f,
            $loop->timeout_future(after => 2)
        )->get;
    }, undef, 'no exception waiting for the packet to arrive');
    ok($f->is_done, 'packet was received successfully');
}

done_testing;


