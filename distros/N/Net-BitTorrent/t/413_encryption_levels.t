use v5.40;
use lib 'lib';
use feature 'class';
no warnings 'experimental::class';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent;
use Net::BitTorrent::Peer;
use Net::BitTorrent::Protocol::PeerHandler;
use Path::Tiny;
use Net::BitTorrent::Emitter;
use Net::BitTorrent::Types;

class MockTransport : isa(Net::BitTorrent::Emitter) {
    field $buffer = '';
    method send_data ($d) { $buffer .= $d; return length $d }
    field $filter : reader = undef;
    method set_filter ($f) { $filter = $f }
    method pop_buffer () { my $tmp = $buffer; $buffer = ''; return $tmp }
    method close ()  { }
    method socket () { return undef }

    method tick () {
        if ( $filter && $filter->can('write_buffer') ) {
            my $out = $filter->write_buffer();
            $buffer .= $out if length $out;
        }
    }
}
subtest 'Encryption Level: none' => sub {
    my $temp      = Path::Tiny->tempdir;
    my $client    = Net::BitTorrent->new();
    my $ih        = '1' x 20;
    my $torrent   = $client->add( "magnet:?xt=urn:btih:" . unpack( 'H*', $ih ), $temp );
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $ih, peer_id => 'P' x 20 );
    my $transport = MockTransport->new();
    my $peer      = Net::BitTorrent::Peer->new(
        protocol   => $p_handler,
        torrent    => $torrent,
        transport  => $transport,
        ip         => '1.1.1.1',
        port       => 1111,
        encryption => ENCRYPTION_NONE
    );
    ok !defined $transport->filter, 'No filter set for encryption=none';
    $transport->_emit('connected');
    $peer->tick();
    my $out = $transport->pop_buffer;
    ok $out =~ /^\x13BitTorrent protocol/, 'Handshake sent immediately (plaintext)';
};
subtest 'Encryption Level: required' => sub {
    my $temp      = Path::Tiny->tempdir;
    my $client    = Net::BitTorrent->new();
    my $ih        = '1' x 20;
    my $torrent   = $client->add( "magnet:?xt=urn:btih:" . unpack( 'H*', $ih ), $temp );
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $ih, peer_id => 'P' x 20 );
    my $transport = MockTransport->new();
    my $peer      = Net::BitTorrent::Peer->new(
        protocol   => $p_handler,
        torrent    => $torrent,
        transport  => $transport,
        ip         => '1.1.1.1',
        port       => 1111,
        encryption => ENCRYPTION_REQUIRED
    );
    ok defined $transport->filter, 'Filter set for encryption=required';
    isa_ok $transport->filter, 'Net::BitTorrent::Protocol::MSE';
    $transport->_emit('connected');
    $peer->tick();
    my $out = $transport->pop_buffer;
    ok $out !~ /^\x13BitTorrent protocol/, 'No plaintext handshake sent';
    ok( ( length($out) >= 96 && length($out) <= 608 ), 'Sent PubKeyA + Padding instead of plaintext' );

    # Simulate filter failure (remote doesn't support MSE)
    $transport->_emit( 'filter_failed', '' );
    $peer->tick();
    $out = $transport->pop_buffer;
    is $out, '', 'No plaintext fallback when encryption=required';
};
subtest 'Encryption Level: preferred' => sub {
    my $temp      = Path::Tiny->tempdir;
    my $client    = Net::BitTorrent->new();
    my $ih        = '1' x 20;
    my $torrent   = $client->add( "magnet:?xt=urn:btih:" . unpack( 'H*', $ih ), $temp );
    my $p_handler = Net::BitTorrent::Protocol::PeerHandler->new( infohash => $ih, peer_id => 'P' x 20 );
    my $transport = MockTransport->new();
    my $peer      = Net::BitTorrent::Peer->new(
        protocol   => $p_handler,
        torrent    => $torrent,
        transport  => $transport,
        ip         => '1.1.1.1',
        port       => 1111,
        encryption => ENCRYPTION_PREFERRED
    );
    ok defined $transport->filter, 'Filter set for encryption=preferred';
    $transport->_emit('connected');
    $peer->tick();
    my $out = $transport->pop_buffer;
    ok( ( length($out) >= 96 && length($out) <= 608 ), 'Sent PubKeyA + Padding initially' );

    # Simulate filter failure (remote doesn't support MSE)
    $transport->_emit( 'filter_failed', '' );
    $peer->tick();
    $out = $transport->pop_buffer;
    ok $out =~ /^\x13BitTorrent protocol/, 'Fell back to plaintext handshake';
};
done_testing;
