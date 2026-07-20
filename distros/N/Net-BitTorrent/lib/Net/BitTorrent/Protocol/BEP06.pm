use v5.40;
use feature 'class';
no warnings 'experimental::class';
class Net::BitTorrent::Protocol::BEP06 v2.0.0 : isa(Net::BitTorrent::Protocol::BEP55) {

    # BEP 06 Message IDs
    use constant {
        HAVE_ALL       => 0x0E,    # 14
        HAVE_NONE      => 0x0F,    # 15
        SUGGEST_PIECE  => 0x0D,    # 13
        REJECT_REQUEST => 0x10,    # 16
        ALLOWED_FAST   => 0x11,    # 17
    };
    method send_have_all ()  { $self->send_message(HAVE_ALL) }
    method send_have_none () { $self->send_message(HAVE_NONE) }

    method send_suggest ($index) {
        $self->send_message( SUGGEST_PIECE, pack( 'N', $index ) );
    }

    method send_reject ( $index, $begin, $length ) {
        $self->send_message( REJECT_REQUEST, pack( 'N N N', $index, $begin, $length ) );
    }

    method send_allowed_fast ($index) {
        $self->send_message( ALLOWED_FAST, pack( 'N', $index ) );
    }

    method _handle_message ( $id, $payload ) {
        if ( $id == HAVE_ALL ) {
            $self->_emit('have_all');
        }
        elsif ( $id == HAVE_NONE ) {
            $self->_emit('have_none');
        }
        elsif ( $id == SUGGEST_PIECE ) {
            return $self->_emit_log( 'warn', 'SUGGEST_PIECE payload too short' ) if length($payload) != 4;
            $self->_emit( suggest => unpack( 'N', $payload ) );
        }
        elsif ( $id == REJECT_REQUEST ) {
            return $self->_emit_log( 'warn', 'REJECT payload too short' ) if length($payload) != 12;
            $self->_emit( reject => unpack( 'N N N', $payload ) );
        }
        elsif ( $id == ALLOWED_FAST ) {
            return $self->_emit_log( 'warn', 'ALLOWED_FAST payload too short' ) if length($payload) != 4;
            $self->_emit( allowed_fast => unpack( 'N', $payload ) );
        }
        else {
            $self->SUPER::_handle_message( $id, $payload );
        }
    }
} 1;
