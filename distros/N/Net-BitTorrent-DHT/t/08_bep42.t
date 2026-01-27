use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT::Security;
use Net::BitTorrent::DHT;
#
my $sec = Net::BitTorrent::DHT::Security->new();
subtest 'Node ID Generation & Validation (v4)' => sub {
    my $ip = '21.75.31.238';
    my $id = $sec->generate_node_id( $ip, 86 );

    # IP 21.75.31.238, seed 86
    # Input to CRC32c: 01 0b 1f ee 06
    # CRC32c result we are getting: 0x7c237efd
    is sprintf( '%02x', unpack( 'C', substr( $id, 0, 1 ) ) ), '7c', 'First byte of ID is 0x7c';
    is sprintf( '%02x', unpack( 'C', substr( $id, 1, 1 ) ) ), '23', 'Second byte of ID is 0x23';
    is unpack( 'C', substr( $id, 2, 1 ) ) & 0xF8,             0x78, 'Third byte high 5 bits are 0x78';
    is unpack( 'C', substr( $id, 19, 1 ) ),                   86,   'Last byte is seed (86)';
    ok $sec->validate_node_id( $id,  $ip ),       'Validates correctly for correct IP';
    ok !$sec->validate_node_id( $id, '1.2.3.4' ), 'Fails validation for wrong IP';
};
subtest 'Node ID Generation & Validation (v6)' => sub {
    my $ip = '2001:470:1f18:19a::2';
    my $id = $sec->generate_node_id( $ip, 22 );

    # BEP 42 example for v6:
    # IP: 2001:470:1f18:19a::2
    # Masked: 2001:470:1f18:19a -> 01, 00, 01, 00, 01, 00, 01, 00 (wait, BEP 42 says:
    # v6 mask: 0x01, 0x03, 0x07, 0x0f, 0x1f, 0x3f, 0x7f, 0xff
    ok $sec->validate_node_id( $id,  $ip ),           'Validates correctly for correct IPv6';
    ok !$sec->validate_node_id( $id, '2001:db8::1' ), 'Fails validation for wrong IPv6';
};
subtest 'Integration in Net::BitTorrent::DHT' => sub {
    my $dht        = Net::BitTorrent::DHT->new( node_id_bin => pack( 'H*', '00' x 20 ), bep42 => 1, port => 0 );
    my $ip         = '21.75.31.238';
    my $valid_id   = $sec->generate_node_id( $ip, 86 );
    my $invalid_id = pack( 'H*', 'ff' x 20 );

    # Mock _send_raw to capture response
    no warnings 'redefine';
    my $sent = 0;
    local *Net::BitTorrent::DHT::_send_raw = sub { $sent++ };
    use warnings 'redefine';

    # Valid ID query
    $dht->_handle_query( { t => 'a', y => 'q', q => 'ping', a => { id => $valid_id } }, 'sender', $ip, 1234 );
    is $sent, 1, 'Responded to valid Node ID';

    # Invalid ID query
    $sent = 0;
    $dht->_handle_query( { t => 'a', y => 'q', q => 'ping', a => { id => $invalid_id } }, 'sender', $ip, 1234 );
    is $sent, 0, 'Ignored invalid Node ID (BEP 42)';

    # Test disabling BEP 42
    $dht  = Net::BitTorrent::DHT->new( node_id_bin => pack( 'H*', '00' x 20 ), bep42 => 0, port => 0 );
    $sent = 0;
    $dht->_handle_query( { t => 'a', y => 'q', q => 'ping', a => { id => $invalid_id } }, 'sender', $ip, 1234 );
    is $sent, 1, 'Responded to invalid Node ID when BEP 42 is disabled';
};
#
done_testing;
