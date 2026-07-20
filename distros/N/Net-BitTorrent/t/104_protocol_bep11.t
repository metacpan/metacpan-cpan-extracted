use v5.42;
use lib 'lib';
use feature 'class';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent::Protocol::BEP11;

class MockPEX : isa(Net::BitTorrent::Protocol::BEP11) {
    field $got_pex : reader : writer(set_got_pex);
    ADJUST {
        $self->on( pex => sub ( $self, $a, $d, $a6, $d6 ) { $self->set_got_pex( { added => $a, dropped => $d, added6 => $a6, dropped6 => $d6 } ) } );
    }
}
subtest 'PEX Packing and Unpacking' => sub {
    my $pwp = MockPEX->new( infohash => 'A' x 20, peer_id => 'B' x 20, local_extensions => { ut_pex => 1 } );
    $pwp->send_handshake();
    $pwp->receive_data( $pwp->write_buffer );    # Open

    # Set ut_pex ID to 1 via fake handshake
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
    my $h_payload = bencode( { m => { ut_pex => 1 } } );
    $pwp->receive_data( pack( 'N C C a*', length($h_payload) + 2, 20, 0, $h_payload ) );
    my @v4_added = ( { ip => '1.2.3.4', port => 1234, flags => 0 } );
    my @v6_added = ( { ip => '::1',     port => 5678, flags => 0 } );
    $pwp->send_pex( \@v4_added, [], \@v6_added, [] );
    my $out = $pwp->write_buffer;

    # Feed it back to verify
    $pwp->receive_data($out);
    my $res = $pwp->got_pex;
    ok $res, 'Received PEX callback';
    is $res->{added},  \@v4_added, 'IPv4 added matches';
    is $res->{added6}, \@v6_added, 'IPv6 added matches';
};
done_testing;
