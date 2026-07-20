use v5.42;
use lib 'lib';
use feature 'class';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent;
use Net::BitTorrent::Protocol::PeerHandler;
subtest 'Default Features' => sub {
    my $client   = Net::BitTorrent->new();
    my $features = $client->features;
    is $features->{bep06}, 1, 'BEP 06 enabled by default';
    is $features->{bep10}, 1, 'BEP 10 enabled by default';
};
subtest 'Feature Toggles' => sub {
    my $client   = Net::BitTorrent->new( bep06 => 0, bep10 => 0 );
    my $features = $client->features;
    is $features->{bep06}, 0, 'BEP 06 disabled';
    is $features->{bep10}, 0, 'BEP 10 disabled';
    is $features->{bep05}, 1, 'BEP 05 still enabled';

    # Test PeerHandler reserved bits
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => 'A' x 20, peer_id => 'B' x 20, features => $features );
    my $reserved  = $p_handler->reserved;

    # byte 5, bit 0x10 should NOT be set
    ok !( vec( $reserved, 5, 8 ) & 0x10 ), 'Extension Protocol bit NOT set';

    # byte 7, bit 0x04 should NOT be set
    ok !( vec( $reserved, 7, 8 ) & 0x04 ), 'Fast Extension bit NOT set';

    # byte 7, bit 0x01 SHOULD be set (DHT)
    ok vec( $reserved, 7, 8 ) & 0x01, 'DHT bit IS set';
};
subtest 'Message Blocking' => sub {
    my $client    = Net::BitTorrent->new( bep06 => 0 );
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => 'A' x 20, peer_id => 'B' x 20, features => $client->features );
    my $called    = 0;

    # Mock peer to see if handle_message is called
    use Net::BitTorrent::Transport::TCP;
    my $mock_peer = mock {} => ( add =>
            [ handle_message => sub { $called++ }, _emit => sub { }, transport => sub { Net::BitTorrent::Transport::TCP->new( socket => undef ) } ] );
    $p_handler->set_peer($mock_peer);

    # Put handler in OPEN state by simulating handshake
    # 19 + 'BitTorrent protocol' + 8 reserved + 20 infohash + 20 peer_id
    my $ih        = 'A' x 20;
    my $id        = 'B' x 20;
    my $handshake = pack( 'C A19 a8 a20 a20', 19, 'BitTorrent protocol', "\0" x 8, $ih, $id );
    $p_handler->receive_data($handshake);
    is $p_handler->state, 'OPEN', 'Handler is now OPEN';

    # ID 14 is HAVE_ALL (Fast Extension)
    $p_handler->receive_data( pack( 'N C', 1, 14 ) );
    is $called, 0, 'HAVE_ALL blocked when BEP 06 disabled';

    # ID 4 is HAVE (Core)
    $p_handler->receive_data( pack( 'N C N', 5, 4, 0 ) );
    is $called, 1, 'HAVE allowed when BEP 06 disabled';
};
done_testing;
