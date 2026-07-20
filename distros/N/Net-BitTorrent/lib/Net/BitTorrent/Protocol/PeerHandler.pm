use v5.40;
use feature 'class';
no warnings 'experimental::class';
class Net::BitTorrent::Protocol::PeerHandler v2.0.1 : isa(Net::BitTorrent::Protocol::BEP06) {
    field $peer : reader;
    field $features : param = {};

    method set_peer ($p) {
        $peer = $p;
        if ( defined $peer ) {
            builtin::weaken($peer);
            $self->set_parent_emitter($peer);
        }
    }
    ADJUST {
        # Default all features to 1 if not provided
        $features->{bep05} //= 1;    # DHT
        $features->{bep06} //= 1;    # Fast Extension
        $features->{bep09} //= 1;    # Metadata
        $features->{bep10} //= 1;    # Extension Protocol
        $features->{bep11} //= 1;    # PEX

        # Populate local extensions for BEP 10
        my $ext = $self->local_extensions;
        $ext->{ut_metadata}  = 1 if $features->{bep09};
        $ext->{ut_pex}       = 2 if $features->{bep11};
        $ext->{ut_holepunch} = 3;

        # Set bits for Extension Protocol (byte 5, 0x10), DHT (byte 7, 0x01), Fast (byte 7, 0x04)
        $self->set_reserved_bit( 5, 0x10 ) if $features->{bep10};
        $self->set_reserved_bit( 7, 0x01 ) if $features->{bep05};
        $self->set_reserved_bit( 7, 0x04 ) if $features->{bep06};

        # Event Listeners
        $self->on(
            handshake => sub ( $self, $ih, $id ) {
                if ( $id eq $self->peer_id ) {
                    $self->_emit_log( 'debug', 'Closing self-connection and banning endpoint' ) if $self->debug;
                    if ( $peer && $peer->torrent ) {
                        $peer->torrent->ban_peer( $peer->ip, $peer->port );
                    }
                    $peer->disconnected() if $peer;
                    return;
                }
                if ( $features->{bep10} ) {
                    my $res = $self->reserved;
                    if ( ord( substr( $res, 5, 1 ) ) & 0x10 ) {
                        $self->_emit_log( 'debug', 'Remote supports BEP 10, sending extended handshake' ) if $self->debug;
                        $self->send_ext_handshake();
                    }
                }
                $peer->_emit('handshake_complete') if $peer;
            }
        );
        $self->on(
            ext_handshake => sub ( $self, $data ) {
                $self->_emit_log( 'debug', 'Received extended handshake from peer' ) if $self->debug;
            }
        );
        $self->on( metadata_request => sub ( $self, $piece ) { $peer->handle_metadata_request($piece) if $peer } );
        $self->on(
            metadata_data => sub ( $self, $piece, $total_size, $data ) {
                $peer->handle_metadata_data( $piece, $total_size, $data ) if $peer;
            }
        );
        $self->on( metadata_reject => sub ( $self, $piece ) { $peer->handle_metadata_reject($piece) if $peer } );
        $self->on(
            hash_request => sub ( $self, $root, $proof_layer, $base_layer, $index, $length ) {
                $peer->handle_hash_request( $root, $proof_layer, $base_layer, $index, $length ) if $peer;
            }
        );
        $self->on(
            hashes => sub ( $self, $root, $proof_layer, $base_layer, $index, $length, $hashes ) {
                $peer->handle_hashes( $root, $proof_layer, $base_layer, $index, $length, $hashes ) if $peer;
            }
        );
        $self->on(
            hash_reject => sub ( $self, $root, $proof_layer, $base_layer, $index, $length ) {
                $peer->handle_hash_reject( $root, $proof_layer, $base_layer, $index, $length ) if $peer;
            }
        );
        $self->on(
            pex => sub ( $self, $added, $dropped, $added6, $dropped6 ) { $peer->handle_pex( $added, $dropped, $added6, $dropped6 ) if $peer } );
        $self->on( hp_rendezvous => sub ( $self, $id ) { $peer->handle_hp_rendezvous($id) if $peer && $peer->can('handle_hp_rendezvous') } );
        $self->on( hp_connect => sub ( $self, $ip, $port ) { $peer->handle_hp_connect( $ip, $port ) if $peer && $peer->can('handle_hp_connect') } );
        $self->on( hp_error   => sub ( $self, $err ) { $peer->handle_hp_error($err) if $peer && $peer->can('handle_hp_error') } );
    }

    method _handle_message ( $id, $payload ) {

        # Feature check for Fast Extension (BEP 06) message IDs
        if ( !$features->{bep06} && ( $id >= 13 && $id <= 17 ) ) {

            # Skip fast extension messages if disabled
            return;
        }

        # Feature check for Extension Protocol (BEP 10)
        if ( !$features->{bep10} && $id == 20 ) {
            return;
        }
        if ($peer) {
            $peer->handle_message( $id, $payload );
        }
        $self->SUPER::_handle_message( $id, $payload );
    }
} 1;
