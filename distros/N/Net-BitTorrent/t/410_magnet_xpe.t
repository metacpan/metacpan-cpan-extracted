use v5.42;
use lib 'lib';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent;
use Digest::SHA qw[sha1 sha256];
subtest 'Magnet x.pe support' => sub {
    my $ih1   = '1' x 20;
    my $ih2   = '2' x 32;
    my $peer1 = '1.2.3.4:5678';
    my $peer2 = '5.6.7.8:9012';

    # Construct magnet URI with v1, v2, and x.pe
    my $uri    = 'magnet:?xt=urn:btih:' . unpack( 'H*', $ih1 ) . '&xt=urn:btmh:1220' . unpack( 'H*', $ih2 ) . "&x.pe=$peer1&x.pe=$peer2";
    my $client = Net::BitTorrent->new();
    my $t      = $client->add_magnet( $uri, '.' );
    is $t->infohash_v1, $ih1, 'v1 hash correct';
    is $t->infohash_v2, $ih2, 'v2 hash correct';
    my $discovered = $t->discovered_peers;
    is scalar @$discovered, 2, 'Found 2 peers from x.pe';
    my %found;

    for my $p (@$discovered) {
        $found{"$p->{ip}:$p->{port}"} = 1;
    }
    ok $found{$peer1}, 'Peer 1 found';
    ok $found{$peer2}, 'Peer 2 found';
};
done_testing;
