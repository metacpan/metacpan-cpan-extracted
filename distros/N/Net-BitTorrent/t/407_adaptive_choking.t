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
subtest 'Adaptive Choking (Leecher Mode)' => sub {
    my $temp         = Path::Tiny->tempdir;
    my $client       = Net::BitTorrent->new();
    my $torrent_file = $temp->child('test.torrent');
    $torrent_file->spew_raw( bencode( { info => { name => 'test', 'piece length' => 16384, pieces => pack( 'H*', '1' x 40 ), } } ) );
    my $t = $client->add_torrent( $torrent_file, $temp );
    $t->start();
    $t->bitfield->clear(0);    # Leecher mode
    my @peers;

    for ( 1 .. 6 ) {
        my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => 'A' x 20, peer_id => 'B' x 20, features => $t->features );

        # Mock socket for registration
        my $ip        = "1.2.3.$_";
        my $mock_sock = mock {} => ( add => [ peerhost => sub {$ip}, peerport => sub {6881}, ] );
        use Net::BitTorrent::Transport::TCP;
        my $transport = Net::BitTorrent::Transport::TCP->new( socket => $mock_sock );
        my $p         = Net::BitTorrent::Peer->new( protocol => $p_handler, torrent => $t, transport => $transport, ip => $ip, port => 6881 );
        $p_handler->set_peer($p);

        # Signal interest from remote
        $p->handle_message( 2, '' );    # INTERESTED
        $t->register_peer_object($p);
        push @peers, $p;
    }

    # Simulate different download rates
    # Peer 0: 100 KB
    # Peer 1: 500 KB (Top)
    # Peer 2: 300 KB (Top)
    # Peer 3: 400 KB (Top)
    # Peer 4: 200 KB (Top)
    # Peer 5: 50 KB
    my @bytes = ( 100, 500, 300, 400, 200, 50 );
    for my $i ( 0 .. 5 ) {
        my $total  = $bytes[$i] * 1024;
        my $offset = 0;
        while ($total) {
            my $chunk = $total > 131072 ? 131072 : $total;
            $peers[$i]->handle_message( 7, pack( 'N N', 0, $offset ) . ( 'A' x $chunk ) );
            $offset += $chunk;
            $total  -= $chunk;
        }
        $peers[$i]->tick();    # Calculate rate
    }

    # Run choking evaluation
    $t->tick(10);              # Trigger every 10s

    # Top 4 (Indices 1, 3, 2, 4) should be unchoked
    ok !$peers[1]->am_choking, 'Peer 1 (500KB) unchoked';
    ok !$peers[3]->am_choking, 'Peer 3 (400KB) unchoked';
    ok !$peers[2]->am_choking, 'Peer 2 (300KB) unchoked';
    ok !$peers[4]->am_choking, 'Peer 4 (200KB) unchoked';

    # Peer 0 or 5 might be unchoked via Optimistic Unchoke
    my $choked_count = grep { $_->am_choking } @peers;
    is $choked_count, 1, 'Exactly one peer is choked (4 regular + 1 optimistic unchoked)';
};
done_testing;
