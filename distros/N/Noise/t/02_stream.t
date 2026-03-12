use v5.42.0;
use lib 'lib';
use Test2::V0;
use Noise::Stream;
use Noise::CipherState;
use IO::Socket::INET;
#
my $listener = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1 ) or
    die 'Failed to create listener: ' . $!;
my $port = $listener->sockport;

# Client socket
my $client_sock = IO::Socket::INET->new( PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Blocking => 0 ) or die 'Client failed: ' . $!;

# Server socket
my $server_sock = $listener->accept() or die 'Accept failed: ' . $!;
$server_sock->blocking(0);

# Simple keys for testing
my $key_a        = 'A' x 32;
my $key_b        = 'B' x 32;
my $c_alice_send = Noise::CipherState->new();
$c_alice_send->set_key($key_a);
my $c_alice_recv = Noise::CipherState->new();
$c_alice_recv->set_key($key_b);
my $c_bob_send = Noise::CipherState->new();
$c_bob_send->set_key($key_b);
my $c_bob_recv = Noise::CipherState->new();
$c_bob_recv->set_key($key_a);
my $alice = Noise::Stream->new( socket => $client_sock, c_send => $c_alice_send, c_recv => $c_alice_recv, );
my $bob   = Noise::Stream->new( socket => $server_sock, c_send => $c_bob_send,   c_recv => $c_bob_recv, );

# Alice sends to Bob
$alice->write_bin('Hello Bob');

# Wait for Bob to receive
my $msg;
my $start = time();
while ( time() - $start < 5 ) {
    $msg = $bob->read_bin(9);
    last if defined $msg;
    select( undef, undef, undef, 0.1 );
}
is $msg, 'Hello Bob', 'Bob received message from Alice';

# Bob sends to Alice
$bob->write_bin('Hi Alice');

# Wait for Alice to receive
my $reply;
$start = time();
while ( time() - $start < 5 ) {
    $reply = $alice->read_bin(8);
    last if defined $reply;
    select( undef, undef, undef, 0.1 );
}
is $reply, 'Hi Alice', 'Alice received reply from Bob';
#
done_testing;
