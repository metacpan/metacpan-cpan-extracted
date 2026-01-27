use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
use Socket                                    qw[AF_INET6 pack_sockaddr_in6 inet_pton];
#
my $id      = pack( 'C*', (1) x 20 );
my $node    = Net::BitTorrent::DHT->new( node_id_bin => $id, port => 6881 );
my $peer_id = pack( 'C*', (2) x 20 );
my $ip6_str = '2001:db8::1';
my $ip6_bin = inet_pton( AF_INET6, $ip6_str );
my $port    = 1234;

# Test _pack_nodes
my ( $v4, $v6 ) = $node->_pack_nodes( [ { id => $peer_id, data => { ip => $ip6_str, port => $port } } ] );
is $v4,                   '',       'No IPv4 nodes packed';
is length($v6),           38,       'IPv6 node packed to 38 bytes';
is substr( $v6, 0, 20 ),  $peer_id, 'ID correct in packed IPv6';
is substr( $v6, 20, 16 ), $ip6_bin, 'IP correct in packed IPv6';

# Test _unpack_nodes
my $unpacked = $node->_unpack_nodes( $v6, AF_INET6 );
is $unpacked->[0]{ip},   $ip6_str, 'Unpacked IPv6 address correct';
is $unpacked->[0]{port}, $port,    'Unpacked IPv6 port correct';

# Test _unpack_peers (IPv6)
my $peer_compact   = $ip6_bin . pack( 'n', $port );
my $unpacked_peers = $node->_unpack_peers($peer_compact);
is $unpacked_peers->[0]->ip,     $ip6_str, 'Unpacked IPv6 peer address correct';
is $unpacked_peers->[0]->family, 6,        'Peer family is correctly flagged as 6';
#
done_testing;
