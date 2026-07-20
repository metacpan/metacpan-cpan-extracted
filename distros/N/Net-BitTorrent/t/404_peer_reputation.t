use v5.42;
use lib 'lib';
use feature 'class';
no warnings 'experimental::class';
use Test2::V1 -ipP;
no warnings;
no warnings 'once';
use Net::BitTorrent;
use Net::BitTorrent::Peer;
use Net::BitTorrent::Protocol::PeerHandler;
use Path::Tiny;
use Digest::SHA                               qw[sha1];
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
use Net::BitTorrent::Emitter;
use Net::BitTorrent::Types;

class MockTransport : isa(Net::BitTorrent::Emitter) {
    field $buffer = '';
    method send_data ($d) { $buffer .= $d; return length $d }
    field $filter : reader = undef;
    method set_filter ($f) { $filter = $f }
    method pop_buffer () { my $tmp = $buffer; $buffer = ''; return $tmp }
    method socket () { return undef }
    method close ()  { }
}
subtest 'Peer Reputation Tracking' => sub {
    my $temp         = Path::Tiny->tempdir;
    my $data         = 'R' x 16384;
    my $torrent_file = $temp->child('test.torrent');
    $torrent_file->spew_raw( bencode( { info => { name => 'test', 'piece length' => 16384, pieces => sha1($data) } } ) );
    my $client = Net::BitTorrent->new();
    my $t      = $client->add( $torrent_file, $temp );
    $t->start();

    # Mock a peer
    my $ih        = $t->infohash_v1;
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $ih, peer_id => 'PEER1' . ( '0' x 15 ), );
    my $transport = MockTransport->new();
    my $peer      = Net::BitTorrent::Peer->new( protocol => $p_handler, torrent => $t, transport => $transport, ip => '1.1.1.1', port => 1111 );
    $p_handler->set_peer($peer);
    $t->register_peer_object($peer);
    is $peer->reputation, 100, 'Initial reputation is 100';

    # Receive a VALID block
    $t->receive_block( $peer, 0, 0, $data );
    $client->tick(0.1);    # Process hashing queue
    ok $t->bitfield->get(0), 'Piece verified';
    is $peer->reputation, 100, 'Reputation capped at 100 after valid piece';

    # Test failure and blacklisting
    my $bad_data      = 'B' x 16384;
    my $torrent_file2 = $temp->child('test2.torrent');
    $torrent_file2->spew_raw(
        bencode(
            {   info => {
                    name           => 'test2',
                    'piece length' => 16384,
                    pieces         => sha1($data)    # Expecting 'R' but we'll send 'B'
                }
            }
        )
    );
    my $t2 = $client->add_torrent( $torrent_file2, $temp );
    $t2->start();
    my $transport2 = MockTransport->new();
    my $peer2      = Net::BitTorrent::Peer->new( protocol => $p_handler, torrent => $t2, transport => $transport2, ip => '2.2.2.2', port => 2222 );
    $t2->register_peer_object($peer2);

    # Send bad data
    $t2->receive_block( $peer2, 0, 0, $bad_data );
    $client->tick(0.1);
    ok !$t2->bitfield->get(0), 'Piece failed verification';
    is $peer2->reputation, 80, 'Reputation decreased significantly after bad data (-20)';

    # Drop reputation until blacklist threshold (20)
    $peer2->adjust_reputation(-60);
    is $peer2->reputation, 20, 'Reputation at threshold';
    my $key = '2.2.2.2:2222';
    ok !exists $t2->peer_objects_hash->{$key}, 'Peer blacklisted and removed from torrent';
};
done_testing;
