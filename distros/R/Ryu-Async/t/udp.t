use strict;
use warnings;

use Test::More;
use Test::Fatal;

use IO::Async::Loop;
use Ryu::Async;

my $loop = IO::Async::Loop->new;

$loop->add(
    my $ryu = Ryu::Async->new
);

my $message_content = 'test message';

ok(my $server = $ryu->udp_server(host => '127.0.0.1'), 'can create new server');
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

ok(my $client = $ryu->udp_client(
    host => '127.0.0.1',
    port => $port
), 'can create client');
isa_ok($client, 'Ryu::Async::Client');
$client->outgoing->emit($message_content);

is(exception {
    Future->wait_any(
        $f,
        $loop->timeout_future(after => 2)
    )->get;
}, undef, 'no exception waiting for the packet to arrive');
ok($f->is_done, 'packet was received successfully');

done_testing;


