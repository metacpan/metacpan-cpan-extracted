use v5.42;
use lib 'lib';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
use Digest::SHA                               qw[sha1 sha256];
use Path::Tiny;
subtest 'Hybrid Registration and Handshake' => sub {
    my $temp = Path::Tiny->tempdir;

    # Create a dummy hybrid torrent file
    my $info = {
        name           => 'hybrid.txt',
        'piece length' => 16384,
        pieces         => 'P' x 20,
        length         => 16384,
        'file tree'    => { 'hybrid.txt' => { '' => { length => 16384, 'pieces root' => 'R' x 32 } } },
    };
    my $torrent_path = $temp->child('hybrid.torrent');
    $torrent_path->spew_raw( bencode( { info => $info } ) );
    my $client = Net::BitTorrent->new();
    my $t      = $client->add_torrent( $torrent_path, $temp );
    my $ih_v1  = $t->infohash_v1;
    my $ih_v2  = $t->infohash_v2;
    ok $ih_v1, 'Has v1 info hash';
    ok $ih_v2, 'Has v2 info hash';
    is length($ih_v1), 20, 'v1 length is 20';
    is length($ih_v2), 32, 'v2 length is 32';

    # Mock upgrade method to verify it was called
    my $upgraded_ih;
    no warnings 'redefine';
    my $orig_upgrade = $client->can('_upgrade_pending_peer');
    *Net::BitTorrent::_upgrade_pending_peer = sub {
        my ( $self, $transport, $ih, $peer_id, $ip, $port ) = @_;
        $upgraded_ih = $ih;
    };

    # Let's test _upgrade_pending_peer directly to see if it finds the torrent
    $upgraded_ih = undef;
    $client->_upgrade_pending_peer( 'mock_transport', $ih_v1, 'PEER1' x 4, '1.1.1.1', 1111 );
    is $upgraded_ih, $ih_v1, 'Correctly found and upgraded v1 IH';
    $upgraded_ih = undef;
    $client->_upgrade_pending_peer( 'mock_transport', $ih_v2, 'PEER2' x 4, '2.2.2.2', 2222 );
    is $upgraded_ih, $ih_v2, 'Correctly found and upgraded v2 IH';
};
done_testing;
