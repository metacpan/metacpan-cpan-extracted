use v5.42;
use lib 'lib';
use feature 'class';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent;
use Net::BitTorrent::Peer;
use Net::BitTorrent::Protocol::PeerHandler;
use Path::Tiny;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
use Digest::SHA                               qw[sha1];
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
subtest 'Superseeding (BEP 16)' => sub {
    my $temp         = Path::Tiny->tempdir;
    my $client       = Net::BitTorrent->new();
    my $torrent_file = $temp->child('test.torrent');
    my $data1        = 'A' x 16384;
    my $data2        = 'B' x 16384;
    $torrent_file->spew_raw(
        bencode(
            {   info => {
                    name           => 'test',
                    'piece length' => 16384,
                    length         => 32768,
                    pieces         => sha1($data1) . sha1($data2),    # 2 pieces
                }
            }
        )
    );
    my $t = $client->add( $torrent_file, $temp );
    $t->bitfield->fill();
    $t->set_superseed(1);
    $t->start();
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $t->infohash_v1, peer_id => 'B' x 20, features => $t->features );
    my $transport = MockTransport->new();
    my $peer      = Net::BitTorrent::Peer->new(
        protocol   => $p_handler,
        torrent    => $t,
        transport  => $transport,
        ip         => '1.2.3.4',
        port       => 6881,
        encryption => ENCRYPTION_NONE
    );
    $p_handler->set_peer($peer);

    # Trigger connection and handshake
    $transport->_emit('connected');

    # Open by receiving our own handshake (mocking remote)
    my $hs = $p_handler->write_buffer;
    $p_handler->receive_data($hs);

    # Receive Leecher Bitfield (None)
    # BEP 03: Bitfield must be sent immediately after handshake
    $p_handler->receive_data( pack( 'N C C', 2, 5, 0 ) );

    # Check for offered piece (HAVE message)
    my $out = $p_handler->write_buffer;
    ok $out =~ /\x04/, 'Seeder offered a piece via HAVE message';

    # Extract piece index from HAVE message (\0\0\0\x05\x04 + 4 bytes index)
    my $idx     = index( $out, "\x04" );
    my $offered = unpack( 'N', substr( $out, $idx + 1, 4 ) );
    ok $offered == 0 || $offered == 1, 'Offered piece 0 or 1';

    # Peer acknowledges (sends HAVE for same piece)
    $p_handler->receive_data( pack( 'N C N', 5, 4, $offered ) );

    # Seeder should offer the NEXT piece
    $out = $p_handler->write_buffer;
    ok $out =~ /\x04/, 'Seeder offered another piece';
    $idx = index( $out, "\x04" );
    my $next = unpack( 'N', substr( $out, $idx + 1, 4 ) );
    isnt $next, $offered, 'Next offered piece is different';
};
done_testing;
