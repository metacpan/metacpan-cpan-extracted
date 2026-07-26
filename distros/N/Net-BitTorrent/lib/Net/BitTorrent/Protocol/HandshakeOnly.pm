use v5.40;
use feature 'class';
no warnings 'experimental::class';
class Net::BitTorrent::Protocol::HandshakeOnly v2.1.1 : isa(Net::BitTorrent::Protocol::BEP03) {
    field $on_handshake_cb : param;
    ADJUST {
        $self->on( handshake => sub ( $self, $ih, $id ) { $on_handshake_cb->( $ih, $id ) } );
    }
} 1;
