use v5.42;
use feature 'class';
use Test2::V1 -ipP;
no warnings;
use lib 'lib';
use Net::BitTorrent;
use Net::BitTorrent::Peer;
use Net::BitTorrent::Protocol::PeerHandler;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
use Path::Tiny;
use Digest::SHA qw[sha1];
#
use Net::BitTorrent::Emitter;
use Net::BitTorrent::Types;

class MockTransport : isa(Net::BitTorrent::Emitter) {
    field $buffer = '';
    method send_data ($d) { $buffer .= $d; return length $d }
    field $filter : reader = undef;
    method set_filter ($f) { $filter = $f }
    method pop_buffer () { my $tmp = $buffer; $buffer = ''; return $tmp }
    method close ()  { }
    method socket () { return undef }
}
subtest 'Rarest-First Piece Selection' => sub {
    my $temp = Path::Tiny->tempdir;
    my $info = {
        name           => 'rarest_test',
        'piece length' => 16384,
        length         => 16384 * 3,
        pieces         => sha1( 'A' x 16384 ) . sha1( 'B' x 16384 ) . sha1( 'C' x 16384 ),
    };
    my $torrent_file = $temp->child('test.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $client = Net::BitTorrent->new();
    my $t      = $client->add( $torrent_file, $temp );
    $t->start();

    # 4 peers
    # Peer 1 has pieces 0, 1
    # Peer 2 has pieces 1, 2
    # Peer 3 has pieces 1
    # Peer 4 has pieces 1, 2
    # Rarity: 0 (1), 1 (4), 2 (2)
    # Rarest is 0.
    my @p_objs;
    for my $i ( 1 .. 4 ) {
        my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $t->infohash_v1, peer_id => "PEER$i" . ( '0' x 15 ) );
        my $peer      = Net::BitTorrent::Peer->new(
            protocol   => $p_handler,
            torrent    => $t,
            transport  => MockTransport->new(),
            ip         => "1.1.1.$i",
            port       => 6881,
            encryption => ENCRYPTION_NONE
        );
        $p_handler->set_peer($peer);
        $t->register_peer_object($peer);
        push @p_objs, $peer;
    }
    $t->set_peer_bitfield( $p_objs[0], pack( 'B*', '11000000' ) );    # 0, 1
    $t->set_peer_bitfield( $p_objs[1], pack( 'B*', '01100000' ) );    # 1, 2
    $t->set_peer_bitfield( $p_objs[2], pack( 'B*', '01000000' ) );    # 1
    $t->set_peer_bitfield( $p_objs[3], pack( 'B*', '01100000' ) );    # 1, 2

    # Check availability
    is $t->picker->get_availability(0), 1, 'Piece 0 availability is 1';
    is $t->picker->get_availability(1), 4, 'Piece 1 availability is 4';
    is $t->picker->get_availability(2), 2, 'Piece 2 availability is 2';

    # Pick piece for a peer that has piece 1 (common) and piece 0 (rare)
    my $picked = $t->picker->pick_piece( $t->peer_bitfields->{ $p_objs[0] }, {} );
    is $picked, 0, 'Picked rarest piece (0)';

    # Pick piece for a peer that has piece 1 (common) and piece 2 (rare-ish)
    $picked = $t->picker->pick_piece( $t->peer_bitfields->{ $p_objs[1] }, {} );
    is $picked, 2, 'Picked rarest piece (2) available from this peer';
};
subtest 'End-Game Mode Entry' => sub {
    my $temp = Path::Tiny->tempdir;
    my $info = {
        name           => 'endgame_test',
        'piece length' => 16384,
        length         => 16384 * 5,
        pieces         => sha1('1') . sha1('2') . sha1('3') . sha1('4') . sha1('5'),
    };
    my $torrent_file = $temp->child('test.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $client = Net::BitTorrent->new();
    my $t      = $client->add( $torrent_file, $temp );
    $t->start();
    ok !$t->picker->end_game, 'Not in end-game initially';

    # Set 1 piece verified, 4 left
    $t->bitfield->set(0);
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $t->infohash_v1, peer_id => 'PEER1' . ( '0' x 15 ) );
    my $peer      = Net::BitTorrent::Peer->new(
        protocol   => $p_handler,
        torrent    => $t,
        transport  => MockTransport->new(),
        ip         => '1.1.1.1',
        port       => 6881,
        encryption => ENCRYPTION_NONE
    );
    $t->register_peer_object($peer);
    $t->set_peer_have_all($peer);
    $t->get_next_request($peer);
    ok !$t->picker->end_game, 'Still not in end-game with 4 pieces left';

    # Set 2 pieces verified, 3 left
    $t->bitfield->set(1);

    # To trigger endgame check, we need to request a piece.
    $t->get_next_request($peer);
    ok $t->picker->end_game, 'Entered end-game with 3 pieces left';
};
subtest 'Peer Reputation (Bad Requests)' => sub {
    my $temp         = Path::Tiny->tempdir;
    my $info         = { name => 'rep_test', 'piece length' => 16384, length => 16384 * 2, pieces => sha1('1') . sha1('2') };
    my $torrent_file = $temp->child('test.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $client = Net::BitTorrent->new();
    my $t      = $client->add( $torrent_file, $temp );
    $t->bitfield->set(0);    # We have piece 0, but not 1
    $t->start();
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $t->infohash_v1, peer_id => 'PEER1' . ( '0' x 15 ) );
    my $peer      = Net::BitTorrent::Peer->new(
        protocol   => $p_handler,
        torrent    => $t,
        transport  => MockTransport->new(),
        ip         => '1.1.1.1',
        port       => 6881,
        encryption => ENCRYPTION_NONE
    );
    $t->register_peer_object($peer);

    # Process handshake; feed a fake remote handshake with a DIFFERENT peer_id
    # to avoid self-connection detection (which would call disconnected() and set $_disconnected)
    $peer->transport->_emit('connected');
    my $pstr      = 'BitTorrent protocol';
    my $remote_id = 'REMOTE' . ( '0' x 14 );    # Exactly 20 bytes
    $p_handler->receive_data( pack( 'C', length($pstr) ) . $pstr . ( "\0" x 8 ) . $t->infohash_v1 . $remote_id );
    $peer->unchoke();                           # We must unchoke them to receive requests
    is $peer->reputation, 100, 'Initial reputation is 100';

    # Peer requests a piece we don't have
    # Message ID 6 = REQUEST
    $p_handler->receive_data( pack( 'N C N N N', 13, 6, 1, 0, 16384 ) );
    is $peer->reputation, 95, 'Reputation decreased for requesting missing piece';

    # Peer requests a piece it claims to already have (it sends BITFIELD/HAVE)
    $t->set_peer_bitfield( $peer, pack( 'B*', '10000000' ) );    # Peer says it has piece 0
    $p_handler->receive_data( pack( 'N C N N N', 13, 6, 0, 0, 16384 ) );
    is $peer->reputation, 90, 'Reputation decreased for redundant request (already has it)';
};
#
done_testing;
