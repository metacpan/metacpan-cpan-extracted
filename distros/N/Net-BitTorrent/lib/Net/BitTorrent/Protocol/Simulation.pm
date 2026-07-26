use v5.40;
use feature 'class';
no warnings 'experimental::class';
class Net::BitTorrent::Protocol::Simulation v2.1.1 : isa(Net::BitTorrent::Protocol::BEP11) {
    field $peer : reader : writer;

    method _handle_message ( $id, $payload ) {
        if ($peer) {
            $peer->handle_message( $id, $payload );
        }
        $self->next::method( $id, $payload );
    }
} 1;
