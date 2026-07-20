use v5.42;
use Test2::V1 -ipP;
no warnings;
use blib;
use Net::BitTorrent::Protocol::BEP23;
subtest 'IPv4 Packing' => sub {
    my @peers  = ( { ip => '127.0.0.1', port => 6881 }, { ip => '192.168.0.1', port => 8080 } );
    my $packed = Net::BitTorrent::Protocol::BEP23::pack_peers_ipv4(@peers);
    is length($packed), 12, 'Packed length is 12 bytes (2 * 6)';
    my $unpacked = Net::BitTorrent::Protocol::BEP23::unpack_peers_ipv4($packed);
    is $unpacked, \@peers, 'Unpacked peers match original';
};
subtest 'Validation' => sub {
    like dies { Net::BitTorrent::Protocol::BEP23::unpack_peers_ipv4('abc') }, qr/multiple of 6 bytes/, 'Dies on invalid length';
    like dies { Net::BitTorrent::Protocol::BEP23::pack_peers_ipv4( { ip => 'invalid', port => 80 } ) }, qr/Invalid IPv4 address/,
        'Dies on invalid IP';
};
done_testing;
