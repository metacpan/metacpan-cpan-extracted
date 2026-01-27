use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT;
#
unless ( eval { require IO::Async::Loop; require IO::Async::Handle; 1 } ) {
    skip_all 'IO::Async not installed';
}
#
my $loop   = IO::Async::Loop->new;
my $id     = pack( 'C*', (1) x 20 );
my $dht    = Net::BitTorrent::DHT->new( node_id_bin => $id, port => 18000, address => '127.0.0.1' );
my $handle = IO::Async::Handle->new(
    read_handle   => $dht->socket,
    on_read_ready => sub {
        my ( $new_nodes, $new_peers ) = $dht->handle_incoming();

        # In a real test, we'd check results here.
        # For this test, just proving the socket is compatible.
        $loop->stop;
    },
);
$loop->add($handle);

# Send a packet to ourselves to trigger on_read_ready
$dht->ping( '127.0.0.1', 18000 );

# Run loop with a timeout
$loop->watch_time( after => 2, code => sub { $loop->stop } );
$loop->run;
pass 'IO::Async handle accepted the DHT socket and loop ran';
#
done_testing;
