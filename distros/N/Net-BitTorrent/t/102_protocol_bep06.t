use v5.42;
use feature 'class';
use Test2::V1 -ipP;
no warnings;
use lib 'lib', '../lib';
use Net::BitTorrent;
use Net::BitTorrent::Protocol::PeerHandler;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
use Digest::SHA                               qw[sha1 sha256];
use Path::Tiny;

class MockBEP06 : isa(Net::BitTorrent::Protocol::PeerHandler) {
    field $got_all   : reader : writer(set_got_all)  = 0;
    field $got_none  : reader : writer(set_got_none) = 0;
    field $suggested : reader : writer(set_suggested);
    ADJUST {
        $self->on( have_all  => sub ($self) { $self->set_got_all(1) } );
        $self->on( have_none => sub ($self) { $self->set_got_none(1) } );
        $self->on( suggest   => sub ( $self, $idx ) { $self->set_suggested($idx) } );
    }
}
subtest 'Fast Extension Messages' => sub {
    my $pwp = MockBEP06->new( infohash => 'A' x 20, peer_id => 'B' x 20 );

    # Check bits in the reserved bytes
    # byte 7: 0x04 (Fast) | 0x01 (DHT) = 0x05
    my $res = $pwp->reserved;
    is ord( substr( $res, 7, 1 ) ) & 0x05, 0x05, 'Fast and DHT bits set in reserved bytes';
    is ord( substr( $res, 5, 1 ) ) & 0x10, 0x10, 'Extension Protocol bit set in reserved bytes';

    # Complete handshake to enter OPEN state
    $pwp->send_handshake();
    my $handshake = $pwp->write_buffer;
    $pwp->receive_data($handshake);
    is $pwp->state, 'OPEN', 'State is OPEN';

    # Receive HAVE_ALL (ID 14)
    $pwp->receive_data( pack( 'N C', 1, 14 ) );
    ok $pwp->got_all, 'Received HAVE_ALL';

    # Receive SUGGEST (ID 13)
    $pwp->receive_data( pack( 'N C N', 5, 13, 123 ) );
    is $pwp->suggested, 123, 'Received SUGGEST for piece 123';
};
#
class MockTransportBEP06 {
    field $sent = '';
    field %on;
    method on ( $e, $cb ) { push $on{$e}->@*, $cb }

    method emit ( $e, @args ) {
        for my $cb ( $on{$e}->@* ) { $cb->(@args) }
    }
    method send_data ($d) { $sent .= $d; return length $d }
    field $filter : reader = undef;
    method set_filter ($f) { $filter = $f }
    method pop_buffer () { my $t = $sent; $sent = ''; return $t }
}
#
subtest 'SUGGEST_PIECE cap at 100' => sub {
    my $temp   = Path::Tiny->tempdir;
    my $client = Net::BitTorrent->new();
    my $data   = 'L' x 16384;
    my $ih     = 'L' x 20;
    my $info   = {
        name           => 'suggest_test.txt',
        'piece length' => 16384,
        pieces         => sha1($data),
        'file tree'    => { 'suggest_test.txt' => { '' => { length => 16384, 'pieces root' => sha256($data) } } },
    };
    my $torrent_file = $temp->child('suggest_test.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $torrent = $client->add_torrent( $torrent_file, $temp );
    $torrent->start();
    my $ph        = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $ih, peer_id => 'BEP06S' . '0' x 14, features => { bep11 => 0 } );
    my $transport = MockTransportBEP06->new();
    my $peer      = Net::BitTorrent::Peer->new(
        protocol   => $ph,
        torrent    => $torrent,
        transport  => $transport,
        ip         => '203.0.113.10',
        port       => 1010,
        encryption => 0
    );
    $ph->set_peer($peer);
    $torrent->register_peer_object($peer);

    for my $i ( 0 .. 149 ) {
        $peer->handle_message( 13, pack( 'N', $i ) );
    }
    ok 1, '150 SUGGEST_PIECE messages processed without crash';
};
#
subtest 'ALLOWED_FAST capped per BEP 06' => sub {
    my $temp   = Path::Tiny->tempdir;
    my $client = Net::BitTorrent->new();
    my $data   = 'M' x 16384;
    my $ih     = 'M' x 20;
    my $info   = {
        name           => 'fast_test.txt',
        'piece length' => 16384,
        pieces         => sha1($data),
        'file tree'    => { 'fast_test.txt' => { '' => { length => 16384, 'pieces root' => sha256($data) } } },
    };
    my $torrent_file = $temp->child('fast_test.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $torrent = $client->add_torrent( $torrent_file, $temp );
    $torrent->start();
    my $ph = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $ih, peer_id => 'BEP06F' . '0' x 14, features => { bep11 => 0, bep06 => 1 } );
    my $transport = MockTransportBEP06->new();
    my $peer      = Net::BitTorrent::Peer->new(
        protocol   => $ph,
        torrent    => $torrent,
        transport  => $transport,
        ip         => '203.0.113.11',
        port       => 1011,
        encryption => 0
    );
    $ph->set_peer($peer);
    $torrent->register_peer_object($peer);

    for my $i ( 0 .. 14 ) {
        $peer->handle_message( 17, pack( 'N', $i ) );
    }
    ok 1, '15 ALLOWED_FAST messages processed without crash';
};
#
done_testing;
