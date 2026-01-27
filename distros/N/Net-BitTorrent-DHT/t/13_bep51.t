use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT;
use Net::BitTorrent::DHT::Security;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bdecode bencode];
use Digest::SHA                               qw[sha1];
#
my $sec = Net::BitTorrent::DHT::Security->new();
my $id  = $sec->generate_node_id('127.0.0.1');
my $dht = Net::BitTorrent::DHT->new( node_id_bin => $id, port => 0 );

# Mock _send_raw
my $sent_data;
no warnings 'redefine';
local *Net::BitTorrent::DHT::_send_raw = sub {
    my ( $self, $data, $dest ) = @_;
    $sent_data = $data;
};
use warnings 'redefine';

# Populate peer_storage with some dummy info-hashes
my @hashes;
for ( 1 .. 30 ) {
    my $h = sha1( 'hash ' . $_ );
    push @hashes, $h;
    $dht->peer_storage->put( $h, [ { ip => '1.2.3.4', port => 1234 } ] );
}
subtest 'Handle sample_infohashes query' => sub {
    my $target = sha1('target');
    $dht->_handle_query( { t => 'si1', y => 'q', q => 'sample_infohashes', a => { id => $sec->generate_node_id('1.2.3.4'), target => $target } },
        'dummy', '1.2.3.4', 1234 );
    my $res = bdecode($sent_data);
    is $res->{y},      'r', 'Response type is "r"';
    is $res->{r}{num}, 30,  'Total number of hashes is correct';
    ok exists $res->{r}{samples}, 'Samples field exists';
    is length( $res->{r}{samples} ), 20 * 20, 'Returned 20 samples (max)';

    # Verify samples are returned as a flat string
    my $samples_blob = $res->{r}{samples};
    my @returned_hashes;
    while ( length($samples_blob) >= 20 ) {
        push @returned_hashes, substr( $samples_blob, 0, 20, '' );
    }
    is scalar @returned_hashes, 20, 'Extracted 20 hashes from blob';
};
subtest 'Handle sample_infohashes response' => sub {
    my $samples = join( '', @hashes[ 0 .. 4 ] );
    my $msg     = { t => 'si', y => 'r', r => { id => $sec->generate_node_id('1.2.3.4'), samples => $samples, num => 5, interval => 3600 } };
    my ( $nodes, $peers, $data ) = $dht->_handle_response( $msg, 'dummy', '1.2.3.4', 1234 );
    ok $data, 'Got data from response';
    is $data->{num},                5,          'Number of hashes is correct';
    is scalar $data->{samples}->@*, 5,          'Number of samples extracted is correct';
    is $data->{samples}[0],         $hashes[0], 'First sample matches';
};
#
done_testing;
