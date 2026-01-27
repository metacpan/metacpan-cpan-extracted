use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
use Socket qw[AF_INET AF_INET6 inet_pton];
#
my $sec = Net::BitTorrent::DHT::Security->new();
my $id  = $sec->generate_node_id('127.0.0.1');
my $dht = Net::BitTorrent::DHT->new(
    node_id_bin => $id,
    want_v4     => 1,
    want_v6     => 1,
    bep32       => 1,
    port        => 0      # Don't actually bind for this test
);

# Add a v4 node
my $v4_ip = '1.2.3.4';
my $v4_id = $sec->generate_node_id($v4_ip);
$dht->routing_table_v4->add_peer( $v4_id, { ip => $v4_ip, port => 1234 } );

# Add a v6 node
my $v6_ip = '2001:db8::1';
my $v6_id = $sec->generate_node_id($v6_ip);
$dht->routing_table_v6->add_peer( $v6_id, { ip => $v6_ip, port => 5678 } );

# Test find_node query handling (internal)
my $msg = {
    t => 'aa',
    y => 'q',
    q => 'find_node',

    # Sender must be valid if bep42 is on by default
    a => { id => $v4_id, target => $id }
};

# Mock _send_raw to capture response
my $sent_data;
no warnings 'redefine';
local *Net::BitTorrent::DHT::_send_raw = sub {
    my ( $self, $data, $dest ) = @_;
    $sent_data = $data;
};
use warnings 'redefine';
$dht->_handle_query( $msg, 'dummy_sender', $v4_ip, 1234 );
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bdecode];
my $res = bdecode($sent_data);
ok exists $res->{r}{nodes},  'Response contains nodes (v4)';
ok exists $res->{r}{nodes6}, 'Response contains nodes6 (v6)';
is length( $res->{r}{nodes} ),  26, 'v4 nodes length correct';
is length( $res->{r}{nodes6} ), 38, 'v6 nodes length correct';

# Test disabling BEP 32
$dht = Net::BitTorrent::DHT->new( node_id_bin => $id, want_v4 => 1, want_v6 => 1, bep32 => 0, port => 0 );
$dht->routing_table_v4->add_peer( $v4_id, { ip => '1.2.3.4',     port => 1234 } );
$dht->routing_table_v6->add_peer( $v6_id, { ip => '2001:db8::1', port => 5678 } );
$sent_data = undef;
$dht->_handle_query( $msg, 'dummy_sender', '1.2.3.4', 1234 );
$res = bdecode($sent_data);
ok exists $res->{r}{nodes},   'Response contains nodes (v4)';
ok !exists $res->{r}{nodes6}, 'Response does NOT contain nodes6 when BEP 32 is disabled';
#
done_testing;
