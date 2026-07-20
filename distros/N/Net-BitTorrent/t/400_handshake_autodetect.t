use v5.42;
use lib 'lib';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent::Protocol::HandshakeOnly;
subtest 'v1 Autodetect' => sub {
    my $ih = '1' x 20;
    my $id = 'A' x 20;
    my $detected_ih;
    my $ho = Net::BitTorrent::Protocol::HandshakeOnly->new(
        infohash        => undef,
        peer_id         => 'CLIENT12345678901234',
        on_handshake_cb => sub { $detected_ih = shift }
    );

    # Generate a v1 handshake manually
    my $handshake = pack( 'C A19 a8 a20 a20', 19, 'BitTorrent protocol', "\0" x 8, $ih, $id );
    $ho->receive_data($handshake);
    is $ho->state,   'OPEN', 'Handshake state is OPEN';
    is $detected_ih, $ih,    'Detected v1 infohash correctly';
};
subtest 'v2 Autodetect' => sub {
    my $ih = '2' x 32;
    my $id = 'B' x 20;
    my $detected_ih;
    my $ho = Net::BitTorrent::Protocol::HandshakeOnly->new(
        infohash        => undef,
        peer_id         => 'CLIENT12345678901234',
        on_handshake_cb => sub { $detected_ih = shift }
    );

    # Generate a v2 handshake manually
    my $handshake = pack( 'C A19 a8 a32 a20', 19, 'BitTorrent protocol', "\0" x 8, $ih, $id );
    $ho->receive_data($handshake);
    is $ho->state,   'OPEN', 'Handshake state is OPEN';
    is $detected_ih, $ih,    'Detected v2 infohash correctly';
};
done_testing;
