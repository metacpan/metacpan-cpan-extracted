use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Net::BitTorrent::Emitter;
class Net::BitTorrent::Peer v2.1.0 : isa(Net::BitTorrent::Emitter) {
    use Net::BitTorrent::Types qw[:encryption :state];
    use Net::BitTorrent::SSRF qw[is_safe_ip];
    field $protocol : param;

    # Instance of Net::BitTorrent::Protocol::BEP03 or subclass
    field $torrent   : param : reader;                            # Parent Net::BitTorrent::Torrent object
    field $transport : param : reader;                            # Net::BitTorrent::Transport::*
    field $ip              : param : reader = undef;
    field $port            : param : reader = undef;
    field $am_choking      : reader = 1;
    field $am_interested   : reader = 0;
    field $peer_choking    : reader = 1;
    field $peer_interested : reader = 0;
    field $blocks_inflight : reader = 0;
    field $bitfield_status : reader : writer = undef;             # 'all', 'none', or raw data
    field $offered_piece = undef;
    field $bytes_down    = 0;
    field $bytes_up      = 0;
    field $rate_down  : reader = 0;
    field $rate_up    : reader = 0;
    field $reputation : reader = 100;                             # Start at 100
    field $debug      : param : reader = 0;
    field $encryption : param : reader = ENCRYPTION_PREFERRED;    # none, preferred, required
    field $mse        : param = undef;
    field @allowed_fast_set;                                      # Pieces we are allowed to request even if choked
    field @suggested_pieces;
    field $pwp_handshake_sent = 0;
    field $requested_blocks : reader = {};                        # Track pending requests "index,begin" => 1
    field $last_activity    : reader = 0;                         # Timestamp of last data received
    field $connected_at     : reader = 0;                         # Timestamp of connection
    field $_disconnected = 0;                                     # Guard: prevent repeated disconnect
    use constant REQUEST_TIMEOUT => 30;                           # Seconds without response before disconnect
    use constant IDLE_TIMEOUT    => 120;                          # Seconds without any data before disconnect
    method protocol ()     {$protocol}
    method is_encrypted () { defined $mse             && $mse->state eq 'PAYLOAD' }
    method is_seeder ()    { defined $bitfield_status && $bitfield_status eq 'all' }

    method flags () {
        my $f = 0;
        $f |= 0x01 if $self->is_encrypted;
        $f |= 0x02 if $self->is_seeder;
        return $f;
    }
    ADJUST {
        $connected_at  = time();
        $last_activity = $connected_at;
        $self->set_parent_emitter($torrent);
        builtin::weaken($torrent) if defined $torrent;
        if ( $protocol->can('set_peer') ) {
            $protocol->set_peer($self);
        }
        if ( !$mse && $encryption != ENCRYPTION_NONE ) {
            use Net::BitTorrent::Protocol::MSE;
            $mse = Net::BitTorrent::Protocol::MSE->new(
                infohash        => $torrent ? ( $torrent->infohash_v1 // $torrent->infohash_v2 ) : undef,
                is_initiator    => 1,                                                                       # Outgoing
                allow_plaintext => ( $encryption == ENCRYPTION_PREFERRED ? 1 : 0 ),
            );
            if ( $mse->supported ) {
                $transport->set_filter($mse);
            }
            else {
                $mse = undef;
            }
        }
        my $weak_self = $self;
        builtin::weaken($weak_self);
        $transport->on(
            'data',
            sub ( $emitter, $data ) {
                $weak_self->receive_data($data) if $weak_self;
            }
        );
        $transport->on(
            'disconnected',
            sub ( $emitter, @args ) {
                $weak_self->disconnected() if $weak_self;
            }
        );
        $transport->on(
            'filter_failed',
            sub ( $emitter, $leftover ) {
                return unless $weak_self;
                return                                                                     if $weak_self->encryption == ENCRYPTION_REQUIRED;
                $weak_self->_emit_log( 'debug', 'Falling back to plaintext handshake...' ) if $weak_self->debug;

                # We can't easily change $mse from here because it's a field
                # but we can call a method or just use it.
                # Actually $mse is in scope but it's a field.
                # In ADJUST, we can access fields.
                $mse = undef;
                $protocol->send_handshake();
                $pwp_handshake_sent = 1;
            }
        );
        $transport->on(
            'connected',
            sub ( $emitter, @args ) {
                return unless $weak_self;
                if ($mse) {
                    $weak_self->_emit_log( 'debug', 'Starting MSE handshake...' ) if $weak_self->debug;

                    # Handshake is driven by transport filter's write_buffer in tick()
                }
                else {
                    $protocol->send_handshake();
                    $pwp_handshake_sent = 1;
                }
            }
        );
        $self->on(
            'handshake_complete',
            sub ( $emitter, @args ) {
                return unless $weak_self;

                # Some peers need us to be unchoked/interested to talk to us
                # but we'll stay choked until we have metadata if we want to be safe.
                # However, we MUST send bitfield/have_none to be protocol compliant.
                # BEP 03: Send bitfield if we have one
                if ( $torrent && $torrent->bitfield ) {
                    $protocol->send_bitfield( $torrent->bitfield->data );
                }

                # BEP 06: Send HAVE_NONE ONLY if remote supports Fast Extension
                elsif ( ord( substr( $protocol->reserved, 7, 1 ) ) & 0x04 ) {
                    if ( $protocol->can('send_have_none') ) {
                        $protocol->send_have_none();
                    }
                }

                # If in METADATA mode, we don't send unchoke/interested yet
                return if $torrent && $torrent->state == STATE_METADATA;
                $weak_self->unchoke();
                $weak_self->_check_interest();

                # BEP 06: Send Allowed Fast set immediately after handshake
                if ( $protocol->isa('Net::BitTorrent::Protocol::BEP06') ) {
                    my $set = $torrent->get_allowed_fast_set( $weak_self->ip );
                    for my $idx (@$set) {
                        $protocol->send_allowed_fast($idx);
                    }
                }
                if ( $torrent && $torrent->client ) {
                    $torrent->client->_emit( 'peer_connected', $weak_self );
                }
            }
        );
    }

    method send_suggest ($index) {
        $protocol->send_suggest($index) if $protocol->can('send_suggest');
    }

    method send_allowed_fast ($index) {
        $protocol->send_allowed_fast($index) if $protocol->can('send_allowed_fast');
    }

    method on_data ($data) {
        $self->receive_data($data);
    }

    method set_protocol ($p) {
        $protocol = $p;
    }

    method set_torrent ($t) {
        $torrent = $t;
    }

    method receive_data ($data) {
        $last_activity = time();
        $self->_emit_log( 'debug', 'Peer received ' . length($data) . ' bytes of data' ) if $debug;
        $torrent->can_read( length $data );
        $protocol->receive_data($data);
    }

    method write_buffer () {
        my $raw = $protocol->write_buffer();
        return '' unless length $raw;

        # Rate limiting logic
        my $allowed = length $raw;
        if ($torrent) {
            $allowed = $torrent->can_write( length $raw );
        }
        if ( $allowed <= 0 ) {
            return 0;    # Rate limit: send nothing
        }
        elsif ( $allowed < length $raw ) {
            my $chunk = substr( $raw, 0, $allowed, '' );
            return $transport->send_data($chunk);
        }
        return $transport->send_data($raw);
    }

    method handle_hash_request ( $root, $proof_layer, $base_layer, $index, $length ) {
        my $file = $torrent->storage->get_file_by_root($root);
        if ( !$file || !$file->merkle ) {
            $protocol->send_hash_reject( $root, $proof_layer, $base_layer, $index, $length ) if $protocol->can('send_hash_reject');
            return;
        }
        my $hashes = $file->merkle->get_hashes( $base_layer, $index, $length );

        # Simplified: no proof nodes added yet
        $protocol->send_hashes( $root, $proof_layer, $base_layer, $index, $length, $hashes ) if $protocol->can('send_hashes');
    }

    method handle_hashes ( $root, $proof_layer, $base_layer, $index, $length, $hashes ) {
        my $file = $torrent->storage->get_file_by_root($root);
        return unless $file && $file->merkle;
        my $node_size = 32;
        if ( length($hashes) % $node_size != 0 ) {
            $self->_emit_log( 'warning', 'Invalid hashes length: ' . length($hashes) . ' not a multiple of ' . $node_size );
            $self->adjust_reputation(-5);
            return;
        }
        my $num_hashes = length($hashes) / $node_size;

        # BEP 52: index and length refer to the range of nodes at base_layer.
        # The hashes string contains these nodes concatenated.
        for ( my $i = 0; $i < $num_hashes; $i++ ) {
            my $hash = substr( $hashes, $i * $node_size, $node_size );
            $file->merkle->set_node( $base_layer, $index + $i, $hash );
        }
        $self->_emit_log( 'debug', "Received and stored $num_hashes hashes for root " . unpack( 'H*', $root ) . " at layer $base_layer" ) if $debug;
    }

    method handle_hash_reject ( $root, $proof_layer, $base_layer, $index, $length ) {
        $self->_emit_log( 'debug', 'Peer rejected hash request for root ' . unpack( 'H*', $root ) ) if $debug;
    }

    method handle_metadata_request ($piece) {
        $torrent->handle_metadata_request( $self, $piece );
    }

    method handle_metadata_data ( $piece, $total_size, $data ) {
        $torrent->handle_metadata_data( $self, $piece, $total_size, $data );
    }

    method handle_metadata_reject ($piece) {
        $torrent->handle_metadata_reject( $self, $piece );
    }

    method handle_pex ( $added, $dropped, $added6, $dropped6 ) {
        for my $list ( $added, $dropped, $added6, $dropped6 ) {
            next unless defined $list && ref $list eq 'ARRAY';

            # Limit PEX entries to prevent resource exhaustion
            splice( @$list, 100 ) if @$list > 100;
        }
        $added    //= [];
        $dropped  //= [];
        $added6   //= [];
        $dropped6 //= [];
        for my $p ( @$added, @$added6 ) {
            next unless ref $p eq 'HASH' && defined $p->{ip} && defined $p->{port};
            next if $p->{port} < 1 || $p->{port} > 65535;
            $torrent->add_peer($p);
        }
    }

    method handle_hp_rendezvous ($id) {

        # Remote wants to connect to a node with $id via us.
        # Find node in our swarm.
        my $target;
        for my $p ( values $torrent->peer_objects_hash->%* ) {
            if ( $p->protocol->can('peer_id') && $p->protocol->peer_id eq $id ) {
                $target = $p;
                last;
            }
        }
        if ( $target && exists $target->protocol->remote_extensions->{ut_holepunch} ) {

            # Relay connect instruction to target
            $target->protocol->send_hp_connect( $self->ip, $self->port );

            # Acknowledge to source (optional, BEP 55 says relay then ack?)
            # Actually, BEP says relay 'connect' to target.
        }
        else {
            $protocol->send_hp_error(0x01) if $protocol->can('send_hp_error');    # 0x01 = peer not found
        }
    }

    method handle_hp_connect ( $ip, $port ) {
        unless ( is_safe_ip($ip) ) {
            $self->_emit_log( 'warn', "HP_CONNECT blocked by SSRF policy: $ip:$port" ) if $debug;
            return;
        }
        unless ( defined $port && $port >= 1 && $port <= 65535 ) {
            $self->_emit_log( 'warn', "HP_CONNECT rejected: invalid port $port" ) if $debug;
            return;
        }
        state $hp_connect_count = 0;
        state $hp_connect_reset = time();
        my $now = time();
        if ( $now - $hp_connect_reset > 60 ) {
            $hp_connect_count = 0;
            $hp_connect_reset = $now;
        }
        $hp_connect_count++;
        if ( $hp_connect_count > 10 ) {
            $self->_emit_log( 'warn', "HP_CONNECT rate limit exceeded, ignoring" ) if $debug;
            $self->adjust_reputation(-20);
            return;
        }
        $self->_emit_log( 'info', "Instructed to connect to $ip:$port" ) if $debug;

        # Trigger uTP connection
        $torrent->client->connect_to_peer( $ip, $port, $torrent->infohash_v2 || $torrent->infohash_v1 );
    }

    method handle_hp_error ($err) {
        $self->_emit_log( 'error', 'Received holepunch error: ' . $err ) if $debug;
    }

    method handle_message ( $id, $payload ) {
        my $plen = length($payload);

        # Validate payload length per message type (BEP 03)
        if ( $id == 0 || $id == 1 || $id == 2 || $id == 3 || $id == 14 || $id == 15 )
        {    # CHOKE, UNCHOKE, INTERESTED, NOT_INTERESTED, HAVE_ALL, HAVE_NONE
            if ( $plen != 0 ) {
                $self->_emit_log( 'debug', "Peer message $id expected 0-byte payload, got $plen" ) if $debug;
                $self->adjust_reputation(-2);
                return;
            }
        }
        elsif ( $id == 4 || $id == 13 || $id == 17 ) {    # HAVE, SUGGEST_PIECE, ALLOWED_FAST
            if ( $plen != 4 ) {
                $self->_emit_log( 'debug', "Peer message $id expected 4-byte payload, got $plen" ) if $debug;
                $self->adjust_reputation(-2);
                return;
            }
        }
        elsif ( $id == 6 || $id == 16 ) {                 # REQUEST, REJECT
            if ( $plen != 12 ) {
                $self->_emit_log( 'debug', "Peer message $id expected 12-byte payload, got $plen" ) if $debug;
                $self->adjust_reputation(-2);
                return;
            }
        }
        elsif ( $id == 7 ) {                              # PIECE
            if ( $plen < 8 ) {
                $self->_emit_log( 'debug', "Peer PIECE message too short ($plen bytes)" ) if $debug;
                $self->adjust_reputation(-2);
                return;
            }
        }

        # warn '  [DEBUG] Peer ' . ($socket ? $socket->peerhost : 'sim') . " sent message ID $id (len " . length($payload) . ")\n";
        if ( $id == 0 ) {                                 # CHOKE
            $peer_choking = 1;
            $self->_emit('choked');
        }
        elsif ( $id == 1 ) {                              # UNCHOKE
            $peer_choking = 0;
            $self->_emit('unchoked');
            $self->_request_next_block();
        }
        elsif ( $id == 2 ) {                              # INTERESTED
            $peer_interested = 1;
            $self->_emit('interested');
        }
        elsif ( $id == 3 ) {                              # NOT_INTERESTED
            $peer_interested = 0;
            $self->_emit('not_interested');
        }
        elsif ( $id == 4 ) {                              # HAVE
            my $index      = unpack( 'N', $payload );
            my $num_pieces = $torrent->bitfield ? $torrent->bitfield->size : 0;
            if ( !defined $num_pieces || $num_pieces == 0 || $index >= $num_pieces ) {
                $self->_emit_log( 'debug', "Peer sent HAVE with out-of-range index $index (num_pieces=$num_pieces)" ) if $debug;
                $self->adjust_reputation(-2);
                return;
            }
            $torrent->update_peer_have( $self, $index );

            # BEP 16: If we see this peer (or others) have our offered piece,
            # we can offer a new one. (Simplified global check)
            if ( defined $offered_piece && $index == $offered_piece ) {
                $offered_piece = undef;
            }
            $self->_check_interest();
        }
        elsif ( $id == 5 ) {    # BITFIELD
            $bitfield_status = $payload;
            $torrent->set_peer_bitfield( $self, $payload );
            $self->_emit( bitfield => $torrent->peer_bitfields->{$self} );

            # BEP 16: If superseeding, we don't send our real bitfield.
            # Instead, we wait for interest and then offer pieces.
            $self->_check_interest();
        }
        elsif ( $id == 6 ) {    # REQUEST
            my ( $index, $begin, $len ) = unpack( 'N N N', $payload );
            my $num_pieces = $torrent->bitfield ? $torrent->bitfield->size : 0;
            my $piece_len  = $torrent->metadata->{info}{'piece length'} // 16384;
            if ( $num_pieces == 0 || $index >= $num_pieces ) {
                $self->_emit_log( 'debug', "Peer REQUEST with out-of-range index $index" ) if $debug;
                return;
            }
            if ( $len == 0 || $len > 131072 ) {    # 2^17 = 128 KiB max block
                $self->_emit_log( 'debug', "Peer REQUEST with invalid len $len" ) if $debug;
                return;
            }
            if ( $begin + $len > $piece_len ) {
                $self->_emit_log( 'debug', 'Peer REQUEST extends beyond piece boundary' ) if $debug;
                return;
            }
            $self->_handle_request( $index, $begin, $len );
        }
        elsif ( $id == 7 ) {    # PIECE
            my ( $index, $begin ) = unpack( 'N N', substr( $payload, 0, 8, '' ) );
            $self->_handle_piece_data( $index, $begin, $payload );
        }
        elsif ( $id == 13 ) {    # SUGGEST_PIECE
            my $index = unpack( 'N', $payload );
            push @suggested_pieces, $index if scalar @suggested_pieces < 100 && !grep { $_ == $index } @suggested_pieces;
            $self->_check_interest();
        }
        elsif ( $id == 14 ) {    # HAVE_ALL
            $bitfield_status = 'all';
            $torrent->set_peer_have_all($self);
            $self->_emit('have_all');
            $self->_check_interest();
        }
        elsif ( $id == 15 ) {    # HAVE_NONE
            $bitfield_status = 'none';
            $torrent->set_peer_have_none($self);
            $self->_emit('have_none');
        }
        elsif ( $id == 16 ) {    # REJECT
            my ( $index, $begin, $len ) = unpack( 'N N N', $payload );
            $self->_handle_reject( $index, $begin, $len );
        }
        elsif ( $id == 17 ) {    # ALLOWED_FAST
            my $index       = unpack( 'N', $payload );
            my $max_allowed = $torrent->bitfield ? ( $torrent->bitfield->size < 10 ? $torrent->bitfield->size : 10 ) : 10;
            push @allowed_fast_set, $index if scalar @allowed_fast_set < $max_allowed && !grep { $_ == $index } @allowed_fast_set;
            $self->_check_interest();
        }
    }

    method _handle_reject ( $index, $begin, $len ) {
        my $key = "$index,$begin";
        $blocks_inflight-- if delete $self->requested_blocks->{$key} && $blocks_inflight > 0;
        delete $torrent->blocks_pending->{$index}{$begin};
        $self->_request_next_block();
    }

    method _check_interest () {
        if ( $torrent->is_superseed ) {
            $self->_check_superseed();
        }
        if ( !$am_interested ) {
            my $bitfield = $torrent->bitfield;
            my $p_bfs    = $torrent->peer_bitfields;
            my $p_bf     = $p_bfs->{$self};
            my $has_new  = 0;
            if ($p_bf) {
                for ( my $i = 0; $i < $bitfield->size; $i++ ) {
                    if ( !$bitfield->get($i) && $p_bf->get($i) ) {
                        $has_new = 1;
                        last;
                    }
                }
            }
            if ($has_new) {
                $am_interested = 1;
                $protocol->send_message(2);    # INTERESTED
            }
        }
    }

    method _check_superseed () {
        return if defined $offered_piece;

        # Pick a piece to offer
        my $bitfield = $torrent->bitfield;
        my $p_bfs    = $torrent->peer_bitfields;
        my $p_bf     = $p_bfs->{$self};
        return unless $p_bf;
        for ( my $i = 0; $i < $bitfield->size; $i++ ) {
            if ( $bitfield->get($i) && !$p_bf->get($i) ) {
                $offered_piece = $i;
                $protocol->send_message( 4, pack( 'N', $i ) );    # HAVE
                last;
            }
        }
    }

    method _request_next_block () {
        while ( $blocks_inflight < 5 ) {
            my $req = $torrent->get_next_request($self);
            if ($req) {

                # BEP 06: Can request if not choked OR if piece is in allowed_fast_set
                if ( !$peer_choking || $self->is_allowed_fast( $req->{index} ) ) {
                    $protocol->send_message( 6, pack( 'N N N', $req->{index}, $req->{begin}, $req->{length} ) );
                    $blocks_inflight++;
                    $self->requested_blocks->{"$req->{index},$req->{begin}"} = 1;
                }
                else {
                    # We picked a piece but we are choked and it's not fast-allowed.
                    # We must un-pending it so others can pick it.
                    delete $torrent->blocks_pending->{ $req->{index} }{ $req->{begin} };
                    last;
                }
            }
            else {
                last;
            }
        }
    }

    method is_allowed_fast ($index) {
        return grep { $_ == $index } @allowed_fast_set;
    }

    method _handle_request ( $index, $begin, $len ) {
        return if $am_choking;

        # Reputation checks
        # Do we even have this piece?
        if ( !$torrent->bitfield->get($index) ) {
            $self->adjust_reputation(-5);
            return;
        }

        # Does the peer already have this piece?
        my $p_bf = $torrent->peer_bitfields->{$self};
        if ( $p_bf && $p_bf->get($index) ) {
            $self->adjust_reputation(-5);
            return;
        }
        my $piece_len  = $torrent->metadata->{info}{'piece length'} // 16384;
        my $abs_offset = ( $index * $piece_len ) + $begin;
        my $data       = $torrent->storage->read_global( $abs_offset, $len );
        if ($data) {
            $bytes_up += length($data);
            $protocol->send_message( 7, pack( 'N N', $index, $begin ) . $data );
        }
    }

    method _handle_piece_data ( $index, $begin, $data ) {
        $self->_emit_log( 'debug', 'Received ' . length($data) . " bytes for piece $index at $begin" ) if $debug;
        if ( length($data) == 0 || length($data) > 131072 ) {
            $self->_emit_log( 'debug', "Invalid PIECE data length: " . length($data) ) if $debug;
            $self->adjust_reputation(-5);
            return;
        }
        $bytes_down += length($data);
        my $key = "$index,$begin";
        if ( delete $self->requested_blocks->{$key} ) {
            $blocks_inflight-- if $blocks_inflight > 0;
        }
        else {
            $self->_emit_log( 'warning', "Received unsolicited PIECE for $key" ) if $debug;
            $self->adjust_reputation(-10);
        }
        my $status = $torrent->receive_block( $self, $index, $begin, $data );
        if ( $status == 1 ) {

            # Verified and saved
        }
        elsif ( $status == -1 ) {

            # Failed verification
        }
        $self->_request_next_block();
    }

    method disconnected () {
        return if $_disconnected;
        $_disconnected = 1;
        $torrent->peer_disconnected($self) if $torrent;
        $transport->close()                if $transport && $transport->can('close');
        $self->_emit('disconnected');
    }

    method unchoke () {
        $am_choking = 0;
        $protocol->send_message(1);    # UNCHOKE
    }

    method choke () {
        $am_choking = 1;
        $protocol->send_message(0);    # CHOKE
    }

    method interested () {
        $am_interested = 1;
        $protocol->send_message(2);    # INTERESTED
    }

    method not_interested () {
        $am_interested = 0;
        $protocol->send_message(3);    # NOT_INTERESTED
    }

    method request ( $index, $begin, $len ) {
        $blocks_inflight++;
        $self->requested_blocks->{"$index,$begin"} = 1;
        $protocol->send_message( 6, pack( 'N N N', $index, $begin, $len ) );
    }

    method cancel_request ( $index, $begin ) {
        my $key = "$index,$begin";
        if ( delete $self->requested_blocks->{$key} ) {
            $blocks_inflight-- if $blocks_inflight > 0;
        }
    }

    method tick () {
        return if $_disconnected;

        # Zombie peer detection: disconnect if no activity for too long
        my $idle = time() - $last_activity;
        if ( $blocks_inflight > 0 && $idle > REQUEST_TIMEOUT ) {
            $self->_emit_log( 'warn', "Request timeout: $ip:$port silent for ${idle}s with $blocks_inflight inflight" ) if $debug;
            $self->disconnected();
            return;
        }
        if ( $idle > IDLE_TIMEOUT && $protocol->state eq 'OPEN' ) {
            $self->_emit_log( 'debug', "Idle timeout: $ip:$port silent for ${idle}s" ) if $debug;
            $self->disconnected();
            return;
        }

        # Simple moving average / decay
        $rate_down  = ( $rate_down * 0.8 ) + ( $bytes_down * 0.2 );
        $rate_up    = ( $rate_up * 0.8 ) + ( $bytes_up * 0.2 );
        $bytes_down = 0;
        $bytes_up   = 0;
        $transport->tick() if $transport->can('tick');

        # MSE Transition Check
        if ( $mse && $mse->state eq 'PAYLOAD' && !$pwp_handshake_sent ) {
            $self->_emit_log( 'debug', 'MSE handshake complete, sending protocol handshake...' ) if $debug;
            $protocol->send_handshake();
            $pwp_handshake_sent = 1;
        }

        # Fatal Protocol Error Check
        if ( $protocol->state eq 'CLOSED' ) {
            $self->_emit_log( 'error', "Fatal protocol error from $ip:$port. Disconnecting." ) if $debug;
            $self->disconnected();
            return;
        }
        $self->write_buffer();
    }

    method adjust_reputation ($delta) {
        return if $_disconnected;
        $reputation += $delta;
        $reputation = 0   if $reputation < 0;
        $reputation = 100 if $reputation > 100;
        if ( $reputation <= 20 ) {
            $self->_emit_log( 'error', "Blacklisting peer $ip:$port due to low reputation ($reputation)" ) if $debug;
            $self->disconnected();
        }
    }
};
1;
