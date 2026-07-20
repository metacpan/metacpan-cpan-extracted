use v5.40;
use feature 'class', 'try';
no warnings 'experimental::class', 'experimental::try';
class Net::BitTorrent::Protocol::BEP55 v2.0.0 : isa(Net::BitTorrent::Protocol::BEP11) {
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
    use Net::BitTorrent::Protocol::BEP23;

    # BEP 55 Message IDs (internal to ut_holepunch)
    use constant { HP_RENDEZVOUS => 0, HP_CONNECT => 1, HP_ERROR => 2, };
    ADJUST {
        $self->on(
            extended_message => sub ( $self, $name, $payload ) {
                return unless $name eq 'ut_holepunch';
                my $type = unpack( 'C', substr( $payload, 0, 1, '' ) );
                my $dict;
                try {
                    my @res = bdecode( $payload, 1 );
                    if ( @res > 2 ) {
                        pop @res;    # Discard leftover
                        $dict = {@res};
                    }
                    else {
                        $dict = $res[0];
                    }
                }
                catch ($e) {
                    $self->_emit_log( 'error', "Malformed ut_holepunch message: $e" );
                    return;
                }
                if ( ref $dict ne 'HASH' ) {
                    $self->_emit_log( 'error', 'Malformed ut_holepunch message: dict is not a hash' );
                    return;
                }
                if ( $type == HP_RENDEZVOUS ) {
                    $self->_emit( hp_rendezvous => $dict->{id} );
                }
                elsif ( $type == HP_CONNECT ) {
                    $self->_emit( hp_connect => $dict->{addr}, $dict->{port} );
                }
                elsif ( $type == HP_ERROR ) {
                    $self->_emit( hp_error => $dict->{e} );
                }
            }
        );
    }

    method send_hp_rendezvous ($target_id) {
        return unless exists $self->remote_extensions->{ut_holepunch};
        my $payload = bencode( { id => $target_id, } );
        $self->send_ext_message( 'ut_holepunch', pack( 'C a*', HP_RENDEZVOUS, $payload ) );
    }

    method send_hp_connect ( $ip, $port ) {
        return unless exists $self->remote_extensions->{ut_holepunch};
        my $payload = bencode( { addr => $ip, port => $port, } );
        $self->send_ext_message( 'ut_holepunch', pack( 'C a*', HP_CONNECT, $payload ) );
    }

    method send_hp_error ($err_code) {
        return unless exists $self->remote_extensions->{ut_holepunch};
        my $payload = bencode( { e => $err_code, } );
        $self->send_ext_message( 'ut_holepunch', pack( 'C a*', HP_ERROR, $payload ) );
    }
} 1;
