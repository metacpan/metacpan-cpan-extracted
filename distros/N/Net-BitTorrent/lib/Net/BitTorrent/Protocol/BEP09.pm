use v5.40;
use feature 'class', 'try';
no warnings 'experimental::class', 'experimental::try';
class Net::BitTorrent::Protocol::BEP09 v2.0.0 : isa(Net::BitTorrent::Protocol::BEP10) {
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];

    # BEP 09 Message Types
    use constant { METADATA_REQUEST => 0, METADATA_DATA => 1, METADATA_REJECT => 2, };
    ADJUST {
        $self->on(
            extended_message => sub ( $self, $name, $payload ) {
                return unless $name eq 'ut_metadata';
                my ( $dict, $remaining );
                try {
                    my @res = bdecode( $payload, 1 );
                    if ( ref $res[0] eq 'HASH' ) {
                        ( $dict, $remaining ) = @res;
                    }
                    else {    # Odd number of elements: KV pairs + leftover
                        $remaining = pop @res;
                        $dict      = {@res};
                    }
                }
                catch ($e) {
                    $self->_emit_log( 'error', "Malformed ut_metadata message: $e" );
                    return;
                }
                if ( ref $dict ne 'HASH' ) {
                    $self->_emit_log( 'error', 'Malformed ut_metadata message: dict is not a hash' );
                    return;
                }
                my $type = $dict->{msg_type};
                if ( !defined $type ) {
                    $self->_emit_log( 'error', 'ut_metadata message missing msg_type' );
                    return;
                }
                if ( $type == METADATA_REQUEST ) {
                    $self->_emit( metadata_request => $dict->{piece} );
                }
                elsif ( $type == METADATA_DATA ) {
                    $self->_emit_log( 'debug', "Received metadata data for piece $dict->{piece} (len " . length($remaining) . ')' ) if $self->debug;
                    $self->_emit( metadata_data => $dict->{piece}, $dict->{total_size}, $remaining );
                }
                elsif ( $type == METADATA_REJECT ) {
                    $self->_emit( metadata_reject => $dict->{piece} );
                }
                else {
                    $self->_emit_log( 'debug', "Unknown ut_metadata msg_type: $type" ) if $self->debug;
                }
            }
        );
    }

    method send_metadata_request ($piece) {
        return unless exists $self->remote_extensions->{ut_metadata};
        $self->_emit_log( 'debug', "Sending metadata request for piece $piece" ) if $self->debug;
        my $payload = bencode( { msg_type => METADATA_REQUEST, piece => $piece, } );
        $self->send_ext_message( 'ut_metadata', $payload );
    }

    method send_metadata_data ( $piece, $total_size, $data ) {
        return unless exists $self->remote_extensions->{ut_metadata};
        my $header = bencode( { msg_type => METADATA_DATA, piece => $piece, total_size => $total_size, } );
        $self->send_ext_message( 'ut_metadata', $header . $data );
    }

    method send_metadata_reject ($piece) {
        return unless exists $self->remote_extensions->{ut_metadata};
        my $payload = bencode( { msg_type => METADATA_REJECT, piece => $piece, } );
        $self->send_ext_message( 'ut_metadata', $payload );
    }
} 1;
