use v5.40;
use feature 'class';
no warnings 'experimental::class';
class Net::BitTorrent::Protocol::BEP52 v2.0.0 : isa(Net::BitTorrent::Protocol::BEP03) {

    # BEP 52 Hash Request
    # infohash (v2 only), pieces root, proof layer, base layer, index, length
    method send_hash_request ( $pieces_root, $proof_layer, $base_layer, $index, $length ) {
        $self->send_message( $self->HASH_REQUEST, pack( 'a32 C C N N', $pieces_root, $proof_layer, $base_layer, $index, $length ) );
    }

    # BEP 52 Hashes
    # pieces root, proof layer, base layer, index, length, hashes
    method send_hashes ( $pieces_root, $proof_layer, $base_layer, $index, $length, $hashes ) {
        $self->send_message( $self->HASHES, pack( 'a32 C C N N a*', $pieces_root, $proof_layer, $base_layer, $index, $length, $hashes ) );
    }

    # BEP 52 Hash Reject
    method send_hash_reject ( $pieces_root, $proof_layer, $base_layer, $index, $length ) {
        $self->send_message( $self->HASH_REJECT, pack( 'a32 C C N N', $pieces_root, $proof_layer, $base_layer, $index, $length ) );
    }

    method _handle_message ( $id, $payload ) {
        if ( $id == $self->HASH_REQUEST ) {
            return $self->_emit_log( 'warn', 'HASH_REQUEST payload too short' ) if length($payload) != 42;
            $self->_emit( hash_request => unpack( 'a32 C C N N', $payload ) );
        }
        elsif ( $id == $self->HASHES ) {
            my $plen = length($payload);
            return $self->_emit_log( 'warn', 'HASHES payload too short' ) if $plen < 42;
            my ( $root, $proof, $base, $idx, $len, $hashes ) = unpack( 'a32 C C N N a*', $payload );
            $self->_emit( hashes => $root, $proof, $base, $idx, $len, $hashes );
        }
        elsif ( $id == $self->HASH_REJECT ) {
            return $self->_emit_log( 'warn', 'HASH_REJECT payload too short' ) if length($payload) != 42;
            $self->_emit( hash_reject => unpack( 'a32 C C N N', $payload ) );
        }
        else {
            $self->SUPER::_handle_message( $id, $payload );
        }
    }
} 1;
