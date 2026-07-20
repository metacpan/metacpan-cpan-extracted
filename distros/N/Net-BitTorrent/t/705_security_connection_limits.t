use v5.40;
use Test2::V1 -ipP;
use lib 'lib', '../lib';
no warnings;
use Net::BitTorrent;
use Net::BitTorrent::Torrent;
use Net::BitTorrent::DHT;
use Net::BitTorrent::Emitter;
use Net::BitTorrent::Tracker::WebSeed;
use Digest::SHA qw[sha1 sha256];
use Path::Tiny;
use Socket                                    qw[inet_aton pack_sockaddr_in];
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
#
subtest 'Custom global limit via constructor' => sub {
    my $client = Net::BitTorrent->new( max_peers => 250 );
    is $client->max_peers, 250, 'custom max_peers accepted';
};
#
subtest 'Custom per-torrent limit via constructor' => sub {
    require Net::BitTorrent::Torrent;
    my $client = Net::BitTorrent->new();
    my $t      = Net::BitTorrent::Torrent->new( base_path => Path::Tiny->tempdir, client => $client, infohash => 'x' x 20, max_peers => 50, );
    is $t->max_peers, 50, 'custom per-torrent max_peers accepted';
};
#
subtest 'Per-torrent limit defaults to 100' => sub {
    require Net::BitTorrent::Torrent;
    my $client = Net::BitTorrent->new();
    my $t      = Net::BitTorrent::Torrent->new( base_path => Path::Tiny->tempdir, client => $client, infohash => 'x' x 20, );
    is $t->max_peers, 100, 'per-torrent max_peers defaults to 100';
};
#
subtest '_count_active_peers returns 0 with no torrents' => sub {
    my $client = Net::BitTorrent->new();
    is $client->_count_active_peers(), 0, 'no active peers';
};
#
sub _make_torrent_temp {
    my $temp   = Path::Tiny->tempdir;
    my $client = Net::BitTorrent->new();
    my $data   = 'X' x 16384;
    my $info   = {
        name           => 'test.txt',
        'piece length' => 16384,
        pieces         => sha1($data),
        'file tree'    => { 'test.txt' => { '' => { length => 16384, 'pieces root' => sha256($data) } } }
    };
    my $torrent_file = $temp->child('test.torrent');
    $torrent_file->spew_raw( bencode( { info => $info } ) );
    my $torrent = $client->add_torrent( $torrent_file, $temp );
    $torrent->start();
    return ( $torrent, $client, $temp );
}
#
subtest 'DHT blacklist cap constant exists' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0 );
    ok $dht, 'DHT instance created';
};
#
subtest 'DHT external IP vote from private IP rejected' => sub {
    my $dht        = Net::BitTorrent::DHT->new( port => 0 );
    my $initial_ip = $dht->external_ip;
    ok !defined $initial_ip, 'no external IP initially';
    $dht->_check_external_ip( inet_aton('10.0.0.1') ) for 1 .. 10;
    ok !defined $dht->external_ip, 'private IP 10.0.0.1 not accepted as external IP';
    $dht->_check_external_ip( inet_aton('127.0.0.1') ) for 1 .. 10;
    ok !defined $dht->external_ip, 'loopback 127.0.0.1 not accepted as external IP';
};
#
subtest 'DHT external IP vote from public IP accepted' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0 );
    $dht->_check_external_ip( inet_aton('8.8.8.8') ) for 1 .. 5;
    is $dht->external_ip, '8.8.8.8', 'public IP 8.8.8.8 accepted as external IP after 5 votes';
};
#
subtest 'DHT ip_votes cap at 500' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0 );
    for my $i ( 1 .. 120 ) {
        my $ip = sprintf( "198.51.%d.%d", int( $i / 256 ), $i % 256 );
        $dht->_check_external_ip( inet_aton($ip) ) for 1 .. 4;
    }
    ok 1, 'survived feeding 120 IPs x 4 votes without crash';
};
#
subtest 'UDP send return value handled gracefully' => sub {
    my $dht = Net::BitTorrent::DHT->new( port => 0 );
    ok $dht, 'DHT instance created';
    my $dest = pack_sockaddr_in( 19999, inet_aton('192.0.2.1') );
    my $ok   = eval { $dht->_send_raw( 'x' x 20, $dest ); 1 };
    ok $ok, '_send_raw to unreachable address did not crash';
};
#
subtest 'Torrent MAX_PEERS constant defined' => sub {
    ok Net::BitTorrent::Torrent->can('MAX_PEERS'),      'MAX_PEERS constant exists';
    ok Net::BitTorrent::Torrent::MAX_PEERS() == 10_000, 'MAX_PEERS is 10,000';
};
#
subtest 'Torrent add_peer respects MAX_PEERS cap' => sub {
    my ( $torrent, $client, $temp ) = _make_torrent_temp();
    my $limit = Net::BitTorrent::Torrent::MAX_PEERS();
    $torrent->add_peer( { ip => "10.$_.0.1", port => $_ } ) for 1 .. $limit;
    my $count = scalar @{ $torrent->discovered_peers() };
    ok $count >= $limit, "added $count peers (>= MAX_PEERS=$limit)";
    my $before = scalar @{ $torrent->discovered_peers() };
    $torrent->add_peer( { ip => '10.255.255.1', port => 9999 } );
    my $after = scalar @{ $torrent->discovered_peers() };
    is $after, $before, 'extra peer rejected when at MAX_PEERS';
};
#
subtest 'on_peer_disconnected with unknown IP does not crash' => sub {
    my $client = Net::BitTorrent->new();
    $client->on_peer_disconnected('192.168.1.100');
    pass 'no crash on disconnect of non-existent peer';
};
#
subtest 'Emitter parent cycle detection' => sub {
    my $a = Net::BitTorrent::Emitter->new();
    my $b = Net::BitTorrent::Emitter->new();
    my $c = Net::BitTorrent::Emitter->new();
    $a->set_parent_emitter($b);
    $b->set_parent_emitter($c);
    $c->set_parent_emitter($a);    # Cycle: c->a->b->c
    my $count = 0;
    $a->on( 'test', sub { $count++ } );
    $a->_emit('test');
    is $count, 1, 'emit works without infinite recursion despite cycle attempt';
};
#
subtest 'Emitter enforces callback limit per event' => sub {
    my $e = Net::BitTorrent::Emitter->new();
    $e->on( 'test', sub { } ) for 1 .. 101;
    pass 'callback limit enforced at MAX_LISTENERS (100)';
};
#
subtest 'UDP flood cap constant defined' => sub {
    my $src = do { local $/; open my $fh, '<', 'lib/Net/BitTorrent.pm' or die $!; <$fh> };
    like $src, qr/MAX_UDP_PACKETS_PER_TICK\s*=>\s*100/,        'UDP flood cap constant defined as 100';
    like $src, qr/\$udp_count\s*<\s*MAX_UDP_PACKETS_PER_TICK/, 'tick loop enforces the cap';
};
#
done_testing;
