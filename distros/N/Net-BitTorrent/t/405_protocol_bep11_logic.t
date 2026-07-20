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

class MockTransport {
    field %on;
    field $buffer = '';
    method on ( $e, $cb ) { push $on{$e}->@*, $cb }

    method emit ( $e, @args ) {
        for my $cb ( $on{$e}->@* ) { $cb->(@args) }
    }
    method send_data ($d) { $buffer .= $d; return length $d }
    field $filter : reader = undef;
    method set_filter ($f) { $filter = $f }
    method pop_buffer () { my $tmp = $buffer; $buffer = ''; return $tmp }
}
subtest 'PEX Logic Verification' => sub {
    my $temp   = Path::Tiny->tempdir;
    my $client = Net::BitTorrent->new();

    # Create a torrent
    my $ih      = '1' x 20;
    my $torrent = $client->add_magnet( 'magnet:?xt=urn:btih:' . unpack( 'H*', $ih ), $temp );
    $torrent->start();

    # Mock a PEX-supporting peer
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $ih, peer_id => 'PEER1' . ( '0' x 15 ), features => { bep11 => 1 } );
    my $transport = MockTransport->new();
    my $peer      = Net::BitTorrent::Peer->new( protocol => $p_handler, torrent => $torrent, transport => $transport, ip => '1.1.1.1', port => 1111 );
    $p_handler->set_peer($peer);
    $torrent->register_peer_object($peer);

    # Add a new peer to the torrent
    my $new_peer = { ip => '2.2.2.2', port => 2222 };
    $torrent->add_peer($new_peer);

    # Tick forward 60 seconds to trigger PEX broadcast
    my @sent_messages;
    local *Net::BitTorrent::Protocol::BEP11::send_pex = sub {
        my ( $self, $added, $dropped, $added6, $dropped6 ) = @_;
        push @sent_messages, { added => $added };
    };
    $torrent->tick(60);
    is scalar @sent_messages,             1,         'PEX broadcast triggered after 60s';
    is $sent_messages[0]->{added}[0]{ip}, '2.2.2.2', 'New peer was shared via PEX';

    # Simulate receiving a PEX message
    my $pex_peer = { ip => '3.3.3.3', port => 3333 };
    $p_handler->_emit( pex => [$pex_peer], [], [], [] );
    my $discovered = $torrent->discovered_peers;
    my %found;
    for my $p (@$discovered) {
        $found{"$p->{ip}:$p->{port}"} = 1;
    }
    ok $found{'3.3.3.3:3333'}, 'Peer discovered via incoming PEX';
};
#
subtest 'Malformed PEX compact data handled gracefully' => sub {
    my $temp    = Path::Tiny->tempdir;
    my $client  = Net::BitTorrent->new();
    my $ih      = '2' x 20;
    my $torrent = $client->add_magnet( 'magnet:?xt=urn:btih:' . unpack( 'H*', $ih ), $temp );
    $torrent->start();
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $ih, peer_id => 'PEER_M3' . ( '0' x 11 ), features => { bep11 => 1 } );
    my $transport = MockTransport->new();
    my $peer      = Net::BitTorrent::Peer->new( protocol => $p_handler, torrent => $torrent, transport => $transport, ip => '9.9.9.9', port => 9999 );
    $p_handler->set_peer($peer);
    $torrent->register_peer_object($peer);

    # Build malformed PEX compact data (not multiple of 6 bytes)
    my $malformed_data = 'A' x 7;    # 7 bytes = invalid for IPv4 unpack
    require Net::BitTorrent::Protocol::BEP03::Bencode;
    my $payload = Net::BitTorrent::Protocol::BEP03::Bencode::bencode( { added => $malformed_data } );

    # Capture pex events
    my @pex_events;
    $p_handler->on( pex => sub ( $self, $added, $dropped, $added6, $dropped6 ) { push @pex_events, { added => $added, dropped => $dropped } } );

    # Trigger the PEX handler via extended_message event
    my $ok = eval { $p_handler->_emit( 'extended_message', 'ut_pex', $payload ); 1 };
    ok $ok, 'malformed PEX compact data did not crash';
    is scalar @pex_events, 0, 'no pex event emitted for malformed data';
};
#
subtest 'PEX truncation caps peers at MAX_PEX_PEERS' => sub {
    my $temp    = Path::Tiny->tempdir;
    my $client  = Net::BitTorrent->new();
    my $ih      = '3' x 20;
    my $torrent = $client->add_magnet( 'magnet:?xt=urn:btih:' . unpack( 'H*', $ih ), $temp );
    $torrent->start();
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $ih, peer_id => 'PEER_M4' . ( '0' x 11 ), features => { bep11 => 1 } );
    my $transport = MockTransport->new();
    my $peer = Net::BitTorrent::Peer->new( protocol => $p_handler, torrent => $torrent, transport => $transport, ip => '10.10.10.10', port => 10101 );
    $p_handler->set_peer($peer);
    $torrent->register_peer_object($peer);

    # Build PEX compact data with 150 IPv4 peers (150 * 6 = 900 bytes)
    require Net::BitTorrent::Protocol::BEP23;
    my @peers  = map { { ip => "10.0.$_.1", port => 6881 + $_ } } 1 .. 150;
    my $packed = Net::BitTorrent::Protocol::BEP23::pack_peers_ipv4(@peers);
    is length($packed), 150 * 6, 'packed 150 IPv4 peers correctly';
    require Net::BitTorrent::Protocol::BEP03::Bencode;
    my $payload = Net::BitTorrent::Protocol::BEP03::Bencode::bencode( { added => $packed } );
    my @pex_events;
    $p_handler->on( pex => sub ( $self, $added, $dropped, $added6, $dropped6 ) { push @pex_events, { added => $added } } );
    $p_handler->_emit( 'extended_message', 'ut_pex', $payload );
    is scalar @pex_events, 1, 'one pex event emitted';
    ok scalar @{ $pex_events[0]{added} } <= 100, 'added peers capped at MAX_PEX_PEERS (100)';
    ok scalar @{ $pex_events[0]{added} } > 0,    'some peers were still parsed';
};
#
done_testing;
