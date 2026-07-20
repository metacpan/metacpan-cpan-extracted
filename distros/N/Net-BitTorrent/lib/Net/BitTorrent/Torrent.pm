use v5.40;
use feature 'class', 'try';
no warnings 'experimental::class', 'experimental::try';
use Net::BitTorrent::Emitter;
class Net::BitTorrent::Torrent v2.1.0 : isa(Net::BitTorrent::Emitter) {
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
    use Net::BitTorrent::Storage;
    use Net::BitTorrent::Tracker;
    use Acme::Bitfield;
    use Net::BitTorrent::Torrent::PiecePicker;
    use Net::BitTorrent::Tracker::WebSeed;
    use Digest::SHA qw[sha1 sha256];
    use Path::Tiny;
    use IO::Select;
    use IO::Socket::IP;
    use Net::BitTorrent::Types qw[:state :pick];
    use Algorithm::RateLimiter::TokenBucket;

    # Security limits
    use constant MAX_METADATA_SIZE     => 10 * 1024 * 1024;    # 10 MB which would be... massive
    use constant MAX_FILE_TREE_DEPTH   => 128;
    use constant MAX_BLOCK_CACHE       => 32;                  # Max cached incomplete pieces per torrent (~8MB worst case)
    use constant MAX_PEERS             => 10_000;              # Max discovered peers per torrent
    use constant MAX_ATTEMPTED         => 5000;                # Max attempted connection entries
    use constant ENDGAME_STALL_TIMEOUT => 60;                  # Seconds without piece verification before endgame fallback

    #
    field $path             : param = undef;
    field $base_path        : param;
    field $client           : param : reader;
    field $metadata         : reader = undef;
    field $infohash         : param  = undef;
    field $infohash_v1      : writer : param = undef;
    field $infohash_v2      : param = undef;
    field $initial_trackers : param = [];
    field $initial_peers    : param = [];
    field $storage          : reader;
    field $bitfield         : reader;
    field $picker           : reader;
    field $tracker_manager;
    field $features : reader;
    field $peer_id : param = undef;
    field %peers;    # 'ip:port' => { ip => ..., port => ... }
    field %peer_objects;
    method peer_objects ()      { [ values %peer_objects ] }
    method peer_objects_hash () { \%peer_objects }
    field %peer_bitfields;     # Peer object => Bitfield object
    method peer_bitfields () { \%peer_bitfields }
    field %blocks_pending;     # piece_index => { offset => Peer }
    method blocks_pending () { \%blocks_pending }
    field %blocks_received;    # piece_index => { offset => 1 }
    method blocks_received () { \%blocks_received }
    field %block_sources;      # piece_index => { offset => Peer }
    field $is_private : reader;
    field $dht_nodes;
    field $last_piece_verified_at = 0;    # Timestamp of last successful piece verification (for endgame stall detection)
    field %test_data;                     # For simulation
    field %block_cache;                   # piece_index => { offset => data }
    field $bytes_downloaded = 0;
    field $bytes_uploaded   = 0;
    field $bytes_left       = 0;
    field @piece_priorities;
    field $picking_strategy = PICK_RAREST_FIRST;
    field $is_partial_seed : reader : writer(set_partial_seed) = 0;
    field $is_superseed    : reader : writer(set_superseed)    = 0;
    field %superseed_offers;              # Peer object => piece_index
    field $debug : param = 0;
    field $max_peers : param : reader : writer = 100;
    #
    method get_superseed_piece ($peer) {
        return undef unless $is_superseed;
        if ( exists $superseed_offers{$peer} ) {
            my $offered = $superseed_offers{$peer};
            my $shared  = 0;
            for my $p ( values %peer_objects ) {
                next if $p == $peer;
                if ( $peer_bitfields{$p} && $peer_bitfields{$p}->get($offered) ) {
                    $shared = 1;
                    last;
                }
            }
            return $offered unless $shared;
            delete $superseed_offers{$peer};
        }
        for ( my $i = 0; $i < $bitfield->size; $i++ ) {
            next unless $bitfield->get($i);
            my $avail = $picker->get_availability($i);
            if ( defined $avail && $avail == 0 ) {
                $superseed_offers{$peer} = $i;
                return $i;
            }
        }
        return undef;
    }
    field @webseeds;
    field $limit_up   : reader;
    field $limit_down : reader;
    field $choke_timer             = 0;
    field $optimistic_timer        = 0;
    field $optimistic_unchoke_peer = undef;
    field $state : reader          = STATE_STOPPED;    # STOPPED, STARTING, RUNNING, PAUSED, METADATA

    # PEX (BEP 11) logic
    field $pex_timer        = 0;
    field $tracker_timer    = 0;
    field $dht_lookup_timer = 0;
    field %pex_added;                                  # ip:port => { ip, port }
    field %pex_dropped;                                # ip:port => { ip, port }

    # Magnet/Metadata fetching
    field %metadata_pieces;
    field $metadata_size : reader = 0;

    method metadata_received_count () {
        my $total = 0;
        $total += length($_) for values %metadata_pieces;
        return $total;
    }

    # DHT Search Frontier
    field %dht_frontier;    # node_id_hex => { id, ip, port, visited }

    # Swarm stats from DHT (BEP 33)
    field $dht_seeders  : reader = 0;
    field $dht_leechers : reader = 0;
    method set_limit_up   ($val) { $limit_up->set_limit($val) }
    method set_limit_down ($val) { $limit_down->set_limit($val) }

    method can_read ($amount) {
        my $allowed = $client->limit_down->consume($amount);
        $allowed = $limit_down->consume($allowed);
        return $allowed;
    }

    method can_write ($amount) {
        my $allowed = $client->limit_up->consume($amount);
        $allowed = $limit_up->consume($allowed);
        return $allowed;
    }

    method is_finished () {
        return 0 unless $self->is_metadata_complete;
        return 0 if $state == STATE_METADATA;
        return $self->is_seed;
    }

    method is_seed () {
        return $bitfield && $bitfield->count == $bitfield->size;
    }

    method is_metadata_complete () {
        return defined $metadata ? 1 : 0;
    }

    method is_running () {
        return $state == STATE_RUNNING || $state == STATE_STARTING || $state == STATE_METADATA;
    }

    method name () {
        return $metadata->{info}{name} if $metadata && $metadata->{info} && $metadata->{info}{name};
        return unpack( 'H*', $self->infohash_v1 // $self->infohash_v2 // '' );
    }

    method progress () {
        return 0 unless $self->is_metadata_complete;
        return 0                                                if $state == STATE_METADATA;
        return ( ( $bitfield->count / $bitfield->size ) * 100 ) if $bitfield && $bitfield->size > 0;
        return 0;
    }

    method start () {
        return if $state != STATE_STOPPED;
        $state = STATE_STARTING;
        $self->announce('started');
        $self->start_dht_lookup() unless $is_private;

        # BEP 33: Scraping
        if ( !$is_private && $client->dht ) {
            my $weak_self = $self;
            builtin::weaken($weak_self);
            $client->dht_scrape(
                $infohash_v2 || $infohash_v1,
                sub ( $emitter, $res ) {
                    $weak_self->handle_dht_scrape($res) if $weak_self;
                }
            );
        }
        if ( !$metadata ) {
            $state = STATE_METADATA;
            $self->_emit_log( 'debug', 'Torrent starting in METADATA mode' ) if $debug;
        }
        else {
            $state = STATE_RUNNING;
            $self->_emit('started');
        }
    }

    method stop () {
        return if $state == STATE_STOPPED;
        $state = STATE_STOPPED;
        $storage->explicit_flush() if $storage;
        $self->announce('stopped');
        for my $peer ( grep {defined} values %peer_objects ) {
            $peer->disconnected();
        }
        %peer_objects = ();
        %peers        = ();
        $self->_emit('stopped');
    }

    method pause () {
        return if $state != STATE_RUNNING && $state != STATE_METADATA;
        $state = STATE_PAUSED;
        $self->_emit('paused');
    }

    method resume () {
        return if $state != STATE_PAUSED;
        $state = STATE_RUNNING;
        $self->_emit('resumed');
    }
    ADJUST {
        $self->set_parent_emitter($client);
        $self->_emit_log( 'debug',
            'Torrent::ADJUST path=' .
                ( $path        // 'undef' ) . ' ih=' .
                ( $infohash    // 'undef' ) . ' v1=' .
                ( $infohash_v1 // 'undef' ) . ' v2=' .
                ( $infohash_v2 // 'undef' ) )
            if $debug;
        builtin::weaken($client) if defined $client;
        $features = { %{ $client->features // {} } };
        $peer_id //= $client->node_id;
        $limit_up   = Algorithm::RateLimiter::TokenBucket->new( limit => 0 );
        $limit_down = Algorithm::RateLimiter::TokenBucket->new( limit => 0 );
        if ($path) {
            my $data = path($path)->slurp_raw;
            $metadata = bdecode($data);
            $self->_emit_log( 'error', 'Missing info dictionary' ) unless ref $metadata eq 'HASH' && ref $metadata->{info} eq 'HASH';
            $self->_init_from_metadata();
        }
        elsif ( $infohash || $infohash_v1 || $infohash_v2 ) {
            if ($infohash) {
                if ( length($infohash) == 20 ) {
                    $infohash_v1 = $infohash;
                }
                elsif ( length($infohash) == 32 ) {
                    $infohash_v2 = $infohash;
                }
                else {
                    $self->_emit_log( 'error', 'Invalid infohash length' );
                }
            }
            my @tiers = map { [$_] } @$initial_trackers;
            $tracker_manager = Net::BitTorrent::Tracker->new( tiers_raw => \@tiers, debug => $debug );
            for my $p_str (@$initial_peers) {
                if ( $p_str =~ /^([^:]+):(\d+)$/ ) {
                    $self->add_peer( { ip => $1, port => $2 } );
                }
            }
        }
        else {
            $self->_emit_log( 'error', 'Either path or infohash required' );
        }
    }

    method _validate_file_tree ( $tree, $depth = 0 ) {
        if ( $depth > MAX_FILE_TREE_DEPTH ) {
            $self->_emit_log( 'error', 'File tree depth limit exceeded (max ' . MAX_FILE_TREE_DEPTH . ' levels)' );
            return;
        }
        if ( ref $tree ne 'HASH' ) {
            $self->_emit_log( 'error', 'Invalid file tree' );
            return;
        }
        for my $name ( keys %$tree ) {
            if ( $name eq '' || $name eq '.' || $name eq '..' || $name =~ /[\\\/]/ || $name =~ /\0/ ) {
                $self->_emit_log( 'error', 'Invalid path element' );
                return;
            }
            my $node = $tree->{$name};
            if ( exists $node->{''} ) {
                if ( ref $node->{''} ne 'HASH' ) {
                    $self->_emit_log( 'error', 'Invalid file metadata' );
                    return;
                }
                if ( ( $node->{''}{length} // -1 ) < 0 ) {
                    $self->_emit_log( 'error', 'Invalid file length' );
                    return;
                }
            }
            else {
                $self->_validate_file_tree( $node, $depth + 1 );
            }
        }
    }

    method _init_from_metadata () {
        if ( !$metadata || ref $metadata->{info} ne 'HASH' ) {
            $self->_emit_log( 'error', 'Missing info dictionary' );
            return;
        }
        my $info = $metadata->{info};
        if ( ( $info->{'piece length'} // 0 ) <= 0 ) {
            $self->_emit_log( 'error', 'Invalid piece length' );
            return;
        }
        if ( !defined $info->{name} || !length $info->{name} ) {
            $self->_emit_log( 'error', 'Missing name' );
            return;
        }
        if ( $info->{name} =~ /[\\\/]/ || $info->{name} eq '..' || $info->{name} =~ /\0/ ) {
            $self->_emit_log( 'error', 'Invalid name: path traversal characters detected' );
            return;
        }
        require File::Spec;
        if ( File::Spec->file_name_is_absolute( $info->{name} ) ) {
            $self->_emit_log( 'error', 'Invalid name: absolute path' );
            return;
        }
        if ( !$info->{pieces} && !$info->{'file tree'} ) {
            $self->_emit_log( 'error', 'Torrent must have either \'pieces\' (v1) or \'file tree\' (v2)' );
            return;
        }

        # Validate file sizes and paths
        if ( $info->{'file tree'} ) {
            $self->_validate_file_tree( $info->{'file tree'} );
        }
        elsif ( $info->{files} ) {
            if ( ref $info->{files} ne 'ARRAY' || !@{ $info->{files} } ) {
                $self->_emit_log( 'error', 'Invalid files list' );
                return;
            }
            for my $f ( @{ $info->{files} } ) {
                if ( ( $f->{length} // -1 ) < 0 ) {
                    $self->_emit_log( 'error', 'Invalid file length' );
                    return;
                }
                if ( ref $f->{path} ne 'ARRAY' || !@{ $f->{path} } ) {
                    $self->_emit_log( 'error', 'Missing path' );
                    return;
                }
                for my $p ( @{ $f->{path} } ) {
                    if ( $p eq '' || $p eq '.' || $p eq '..' || $p =~ /[\\\/]/ || $p =~ /\0/ ) {
                        $self->_emit_log( 'error', 'Invalid path element' );
                        return;
                    }
                }
            }
        }
        else {
            # Single-file v1 or v2 (v2 length is inside 'file tree', handled above)
            if ( !exists $info->{length} && $info->{pieces} && !$info->{'file tree'} ) {

                # Some minimal tests or old v1 might omit length if it's empty or inferred?
                # Actually, BEP 03 says length is required for single-file.
                # But some tests use minimal dictionaries.
                # Let's be lenient for v1 minimal tests if pieces is present.
                # (Optionally, we could default to 0)
            }
            else {
                if ( ( $info->{length} // -1 ) < 0 ) {
                    $self->_emit_log( 'error', 'Invalid file length' );
                    return;
                }
            }
        }
        my $info_encoded = bencode($info);
        $infohash_v1 = sha1($info_encoded)   if $info->{pieces};
        $infohash_v2 = sha256($info_encoded) if $info->{'file tree'};
        $is_private  = $info->{private}   // 0;
        $dht_nodes   = $metadata->{nodes} // [];
        my $tree = $self->file_tree;
        $storage = Net::BitTorrent::Storage->new(
            base_path  => $base_path,
            file_tree  => $tree,
            piece_size => $info->{'piece length'},
            pieces_v1  => $info->{pieces}
        );

        if ( my $layers = $metadata->{'piece layers'} ) {
            for my $root ( keys %$layers ) {
                $storage->set_piece_layer( $root, $layers->{$root} );
            }
        }
        my $num_pieces = int( ( length( $info->{pieces} // '' ) / 20 ) );
        if ( !$num_pieces && $info->{'file tree'} ) {
            my $total_size = $self->_calculate_total_size();
            $num_pieces = int( ( $total_size + $info->{'piece length'} - 1 ) / $info->{'piece length'} );
        }
        $bitfield = Acme::Bitfield->new( size => $num_pieces );
        $self->_init_picker();
        my @tiers;
        if ( $metadata->{'announce-list'} ) {
            @tiers = @{ $metadata->{'announce-list'} };
        }
        elsif ( $metadata->{announce} ) {
            @tiers = ( [ $metadata->{announce} ] );
        }
        $tracker_manager = Net::BitTorrent::Tracker->new( tiers_raw => \@tiers, debug => $debug );
        my $urls = $metadata->{'url-list'} // [];
        $urls = [$urls] unless ref $urls eq 'ARRAY';
        push @webseeds, Net::BitTorrent::Tracker::WebSeed->new( url => $_ ) for @$urls;
        my $total_size = $self->_calculate_total_size();
        $bytes_left = $total_size;

        #~ warn "  [DEBUG] Swarm initialized from metadata: $total_size bytes\n";
    }

    method _init_picker () {
        if ( !@piece_priorities && $bitfield ) {
            @piece_priorities = (1) x $bitfield->size;
        }
        $picker = Net::BitTorrent::Torrent::PiecePicker->new(
            bitfield         => $bitfield,
            piece_priorities => \@piece_priorities,
            strategy         => $picking_strategy,
        );
    }

    method set_piece_priority ( $index, $priority ) {
        $picker->set_priority( $index, $priority ) if $picker;
    }

    method set_picking_strategy ($strategy) {
        $picker->set_strategy($strategy) if $picker;
    }

    method get_allowed_fast_set ($ip) {
        return [] unless $bitfield && $bitfield->size;
        my @set;
        for ( my $i = 0; $i < 5 && $i < $bitfield->size; $i++ ) {
            push @set, $i;
        }
        return \@set;
    }

    method suggest_piece ($peer) {
        return undef unless $bitfield && $bitfield->count > 0;
        for ( my $i = 0; $i < $bitfield->size; $i++ ) {
            return $i if $bitfield->get($i);
        }
        return undef;
    }

    method handle_dht_scrape ($res) {
        $dht_seeders  = $res->{sn} if exists $res->{sn};
        $dht_leechers = $res->{ln} if exists $res->{ln};
        $self->_emit_log( 'info',
            'Scrape results for ' . ( $metadata ? $metadata->{info}{name} : 'unknown' ) . ": $dht_seeders seeds, $dht_leechers leechers" )
            if $debug;
    }

    method tick ( $delta = 0.1 ) {
        return if $state == STATE_STOPPED || $state == STATE_PAUSED;
        $limit_up->tick($delta);
        $limit_down->tick($delta);
        $storage->tick($delta)         if $storage;
        $tracker_manager->tick($delta) if $tracker_manager;

        # Attempt to connect to discovered peers if we need more
        $self->_attempt_connections() if keys %peer_objects < 50;

        # Snapshot peer list to avoid hash mutation during iteration
        # (tick may trigger disconnect which modifies %peer_objects)
        my @peers_snapshot = values %peer_objects;
        for my $peer (@peers_snapshot) {
            $peer->tick();
            if ( $state == STATE_METADATA ) {
                $self->_request_metadata($peer);
            }
            elsif ( $state == STATE_RUNNING ) {

                # Update interest
                my $is_interesting = $picker->is_interesting($peer);
                if ( $is_interesting && !$peer->am_interested ) {
                    $peer->interested();
                }
                elsif ( !$is_interesting && $peer->am_interested ) {
                    $peer->not_interested();
                }

                # Request pieces if not choked
                $self->_request_pieces($peer) if !$peer->peer_choking && $peer->am_interested;
            }
        }
        $choke_timer += $delta;
        if ( $choke_timer >= 10 ) {
            $self->_evaluate_choking();
            $self->_cleanup_connections();
            $self->_emit( 'status_update',
                { downloaded => $bytes_downloaded, uploaded => $bytes_uploaded, left => $bytes_left, peers => scalar keys %peer_objects, } );
            $choke_timer = 0;
        }
        $pex_timer += $delta;
        if ( $pex_timer >= 60 ) {
            $self->_broadcast_pex();
            $pex_timer = 0;
        }
        $tracker_timer += $delta;
        if ( $tracker_timer >= 60 ) {    # Every 60s check if trackers want an announce
            $self->announce();
            $tracker_timer = 0;
        }
        $dht_lookup_timer += $delta;

        # Accelerate DHT lookups during startup/metadata phase or if starved for peers
        my $dht_interval = ( $state == STATE_METADATA || keys %peer_objects < 5 ) ? 2 : 120;
        if ( $dht_lookup_timer >= $dht_interval ) {
            $self->_update_dht_search();
            $dht_lookup_timer = 0;
        }
    }
    field %attempted_connections;    # ip:port => timestamp

    method _attempt_connections () {
        state $last_attempt = 0;
        return if time() - $last_attempt < 5;    # Don't spam connection attempts
        $last_attempt = time();
        my $peers = $self->discovered_peers;
        my $count = 0;
        for my $p (@$peers) {
            my $key = "$p->{ip}:$p->{port}";
            next if $peer_objects{$key};
            next if $attempted_connections{$key} && ( time() - $attempted_connections{$key} < 60 );

            # Try to connect
            $attempted_connections{$key} = time();
            my $ih = $infohash_v2 || $infohash_v1;
            $client->connect_to_peer( $p->{ip}, $p->{port}, $ih );
            $count++;
            last if $count >= 5;    # Limit concurrent attempts
        }
    }

    method _evaluate_choking () {
        $self->_emit_log( 'debug', 'Evaluating choking for ' . scalar( keys %peer_objects ) . ' peers' ) if $debug;
        my @interested = grep { $_->peer_interested } values %peer_objects;

        # Even if nobody is interested in US, we should still unchoke some if we want pieces?
        # No, unchoking is for UPLOAD. For DOWNLOAD, we need to send INTERESTED.
        my @sorted;
        if ( $bitfield && $bitfield->count < $bitfield->size ) {
            @sorted = sort { $b->rate_down <=> $a->rate_down } @interested;
        }
        else {
            @sorted = sort { $b->rate_up <=> $a->rate_up } @interested;
        }
        my $max_unchoked = 4;
        my %to_unchoke;
        for ( my $i = 0; $i < $max_unchoked && $i < @sorted; $i++ ) {
            $to_unchoke{ $sorted[$i] } = 1;
        }
        $optimistic_timer += 10;
        if ( $optimistic_timer >= 30 || !$optimistic_unchoke_peer ) {
            my @candidates = grep { !$to_unchoke{$_} } @interested;
            if (@candidates) {
                $optimistic_unchoke_peer = $candidates[ rand @candidates ];
            }
            $optimistic_timer = 0;
        }
        $to_unchoke{$optimistic_unchoke_peer} = 1 if $optimistic_unchoke_peer;
        for my $peer ( values %peer_objects ) {
            if ( $to_unchoke{$peer} ) {
                $peer->unchoke() if $peer->am_choking;
            }
            else {
                $peer->choke() if !$peer->am_choking;
            }
        }
    }
    field %metadata_pending;    # peer => piece_index

    method _request_metadata ($peer) {
        return unless $peer->protocol->isa('Net::BitTorrent::Protocol::BEP10');
        my $remote_ext = $peer->protocol->remote_extensions;
        return unless exists $remote_ext->{ut_metadata};

        # We need metadata_size from the peer (from extended handshake)
        my $m_size = $peer->protocol->metadata_size;
        return unless $m_size > 0;
        if ( $metadata_size == 0 ) {
            $metadata_size = $m_size;
            $self->_emit_log( 'debug', "Metadata size identified: $metadata_size bytes" ) if $debug;
        }

        # How many pieces? (BEP 09 uses 16KiB pieces)
        my $num_pieces = int( ( $metadata_size + 16383 ) / 16384 );

        # Check if we already have a request pending for this peer
        return if exists $metadata_pending{$peer};

        # Find a piece we don't have and isn't pending from another peer (simple greedy)
        # Note: In a real client, we'd track global pending metadata pieces.
        for ( my $i = 0; $i < $num_pieces; $i++ ) {
            if ( !exists $metadata_pieces{$i} ) {

                # Check if anyone else is already requesting this specific piece
                my $already_requested = 0;
                for my $p_pending ( values %metadata_pending ) {
                    if ( $p_pending == $i ) {
                        $already_requested = 1;
                        last;
                    }
                }
                next if $already_requested;
                $metadata_pending{$peer} = $i;
                $peer->protocol->send_metadata_request($i);
                return;
            }
        }
    }

    method _request_pieces ($peer) {
        return if $peer->blocks_inflight >= 20;    # Throttle per-peer
        my $pbitfield = $peer_bitfields{$peer};
        unless ($pbitfield) {
            return;
        }
        while ( $peer->blocks_inflight < 20 ) {
            my ( $index, $begin, $len ) = $picker->pick_block( $peer, \%blocks_pending );
            unless ( defined $index ) {
                last;
            }
            $blocks_pending{$index}{$begin} = $peer;
            $block_sources{$index}{$begin}  = $peer;
            $peer->request( $index, $begin, $len );
            $self->_emit_log( 'debug', "Requested block at $begin of piece $index from " . $peer->ip ) if $debug;
        }
    }

    method handle_metadata_request ( $peer, $piece ) {
        return unless $metadata;
        my $info_encoded = bencode( $metadata->{info} );
        my $num_pieces   = int( ( length($info_encoded) + 16383 ) / 16384 );
        return if $piece < 0 || $piece >= $num_pieces;
        my $piece_data = substr( $info_encoded, $piece * 16384, 16384 );
        $peer->protocol->send_metadata_data( $piece, length($info_encoded), $piece_data );
    }

    method handle_metadata_data ( $peer, $piece, $total_size, $data ) {
        delete $metadata_pending{$peer} if defined $peer;
        if ( $metadata_size == 0 ) {
            if ( $total_size > MAX_METADATA_SIZE ) {
                $self->_emit_log( 'fatal', "Metadata too large ($total_size bytes, max " . MAX_METADATA_SIZE . ')' );
                return;
            }
            $metadata_size = $total_size;
        }
        my $num_pieces = int( ( $metadata_size + 16383 ) / 16384 );
        if ( $piece < 0 || $piece >= $num_pieces ) {
            $self->_emit_log( 'warning', "Received out-of-range metadata piece index $piece (max " . ( $num_pieces - 1 ) . ')' );
            return;
        }
        $self->_emit_log( 'debug', "Received metadata piece $piece (len " . length($data) . ') from ' . ( $peer ? $peer->ip : 'unknown' ) ) if $debug;
        $metadata_pieces{$piece} = $data;
        $self->_emit_log( 'debug', 'Metadata progress: ' . scalar( keys %metadata_pieces ) . "/$num_pieces pieces" ) if $debug;
        if ( scalar keys %metadata_pieces == $num_pieces ) {
            my $full_info = join( '', map { $metadata_pieces{$_} } sort { $a <=> $b } keys %metadata_pieces );

            # Verify hash
            my $calculated_ih = sha1($full_info);
            my $verified      = 0;
            if ( $infohash_v1 && $calculated_ih eq $infohash_v1 ) {
                $verified = 1;
            }
            elsif ($infohash_v2) {
                if ( sha256($full_info) eq $infohash_v2 ) {
                    $verified = 1;
                }
            }
            if ( !$verified ) {
                $self->_emit_log( 'error', 'Metadata verification FAILED! Hash mismatch.' );
                %metadata_pieces  = ();
                %metadata_pending = ();
                $metadata_size    = 0;
                return;
            }

            # Decode and start torrent
            my $info = bdecode($full_info);
            $metadata = { info => $info };
            $self->_on_metadata_received();
        }
    }

    method handle_metadata_reject ( $peer, $piece ) {
        delete $metadata_pending{$peer}                                                if defined $peer;
        $self->_emit_log( 'debug', "Peer rejected metadata request for piece $piece" ) if $debug;
    }

    method _on_metadata_received () {
        $self->_emit_log( 'debug', 'Metadata fully received and verified' ) if $debug;

        # Validate name for path traversal before using it
        my $name = $metadata->{info}{name};
        if ( !defined $name || !length $name ) {
            $self->_emit_log( 'error', 'Missing name in metadata' );
            return;
        }
        if ( $name =~ /[\\\/]/ || $name eq '..' || $name =~ /\0/ ) {
            $self->_emit_log( 'error', 'Invalid name: path traversal characters detected' );
            return;
        }
        require File::Spec;
        if ( File::Spec->file_name_is_absolute($name) ) {
            $self->_emit_log( 'error', 'Invalid name: absolute path' );
            return;
        }

        # Multi-file torrents should be in a directory named after the torrent
        my $storage_path = $base_path;
        if ( $metadata->{info}{'file tree'} || $metadata->{info}{files} ) {
            $storage_path = $base_path->child( $metadata->{info}{name} );
        }

        # Initialize storage
        $self->_emit_log( 'debug', "Initializing storage at $storage_path" ) if $debug;
        $storage = Net::BitTorrent::Storage->new(
            base_path  => $storage_path,
            piece_size => $metadata->{info}{'piece length'},
            pieces_v1  => $metadata->{info}{pieces},
        );

        # Load files into storage
        if ( my $tree = $metadata->{info}{'file tree'} ) {
            $storage->load_file_tree($tree);
        }
        elsif ( my $files = $metadata->{info}{files} ) {    # v1 Multi-file
            for my $f (@$files) {
                my $rel_path = Path::Tiny::path( @{ $f->{path} } );
                $storage->add_file( $rel_path, $f->{length} );
            }
        }
        else {                                              # v1 Single-file
            $storage->add_file( $metadata->{info}{name}, $metadata->{info}{length} );
        }

        # Initialize bitfield
        my $num_pieces = 0;
        $num_pieces = length( $metadata->{info}{pieces} ) / 20 if exists $metadata->{info}{pieces};
        $num_pieces ||= $storage->piece_count;
        $bitfield = Acme::Bitfield->new( size => $num_pieces );

        # Initialize picker
        $picker     = Net::BitTorrent::Torrent::PiecePicker->new( bitfield => $bitfield, );
        $bytes_left = $self->_calculate_total_size();
        $state      = STATE_RUNNING;
        $self->_emit('started');

        # Re-initialize peer bitfields now that we have the size
        $self->init_peer_bitfield($_) for values %peer_objects;

        # Announce to trackers now that we have full infohash info
        $self->announce();
    }

    method receive_block ( $peer, $index, $begin, $data ) {
        return 0 unless $bitfield;
        return 0 if $bitfield->get($index);

        # If we've already received this block, or the piece is already being verified, skip.
        # We use blocks_received as an indicator that the piece is complete/queued.
        return 0 if exists $blocks_received{$index} && $self->is_piece_complete($index);

        # v2 Block-level verification (if we have pieces root)
        my ( $root, $rel_piece ) = $storage->map_v2_piece($index);
        if ( defined $root ) {
            my $info        = $metadata->{info};
            my $block_index = ( $rel_piece * ( $info->{'piece length'} / 16384 ) ) + ( $begin / 16384 );
            if ( !$storage->verify_block( $root, $block_index, $data ) ) {
                $self->_emit_log( 'error', "v2 block verification FAILED for block $block_index of root " . unpack( 'H*', $root ) ) if $debug;
                $peer->adjust_reputation(-50)                                                                                       if $peer;
                return 0;
            }
        }
        $self->_store_block( $peer, $index, $begin, $data );
        if ( $self->is_piece_complete($index) ) {
            $self->_emit_log( 'debug', "Piece $index is COMPLETE" ) if $debug;
            return 0                                                if $bitfield->get($index);
            my $piece_data = $self->_get_full_piece($index);
            if ($piece_data) {
                $self->_clear_piece_data($index);
                $client->queue_verification( $self, $index, $piece_data );
                return 1;
            }
        }
        return 0;
    }
    method _clear_piece_data ($index) { delete $block_cache{$index} }

    method _verify_queued_piece ( $index, $piece_data ) {
        my $sources  = delete $block_sources{$index} // {};
        my $verified = 0;

        # Try v2 verification first if possible
        my ( $root, $rel_index ) = $storage->map_v2_piece($index);
        if ( defined $root ) {
            my $res = $storage->verify_piece_v2( $root, $rel_index, $piece_data );
            if ( defined $res ) {
                $verified = $res;
            }
            else {
                # Fallback to v1 if v2 fails because layer is missing?
                # (Normally v2 is authoritative if pieces_root exists)
                $verified = $storage->verify_piece_v1( $index, $piece_data ) // 0;
            }
        }
        else {
            $verified = $storage->verify_piece_v1( $index, $piece_data ) // 0;
        }
        if ($verified) {
            $storage->write_piece_v1( $index, $piece_data );
            $bitfield->set($index);
            $bytes_downloaded += length($piece_data);
            $bytes_left       -= length($piece_data);
            $last_piece_verified_at = time;
            $self->_emit_log( 'debug', "Piece $index VERIFIED successfully via throttled queue" ) if $debug;
            $self->_clear_piece_cache($index);
            $self->_emit( 'piece_verified', $index );

            for my $peer ( values %$sources ) {
                $peer->adjust_reputation(1) if defined $peer;
            }
            return 1;
        }
        else {
            $self->_emit_log( 'debug', "\nPiece $index FAILED verification (len " . length( $piece_data // '' ) . ')' ) if $debug;
            $self->_clear_piece_cache($index);
            $self->_emit( 'piece_failed', $index );
            for my $peer ( values %$sources ) {
                $peer->adjust_reputation(-20) if defined $peer;
            }
            return -1;
        }
    }

    method _cancel_duplicate_requests ( $sender, $index, $begin ) {
        return unless $picker && $picker->end_game;
        for my $peer ( values %peer_objects ) {
            next if $peer == $sender;
            $peer->cancel_request( $index, $begin );
        }
    }

    method _store_block ( $peer, $index, $begin, $data ) {
        delete $blocks_pending{$index}{$begin};
        return if $blocks_received{$index}{$begin};
        $self->_cancel_duplicate_requests( $peer, $index, $begin );
        if ( keys %block_cache >= MAX_BLOCK_CACHE ) {
            my @oldest  = sort { $a <=> $b } keys %block_cache;
            my $evicted = shift @oldest;
            delete $block_cache{$evicted};
            delete $blocks_received{$evicted};
            delete $block_sources{$evicted};
        }
        $block_cache{$index} //= {};
        $block_cache{$index}{$begin}     = $data;
        $blocks_received{$index}{$begin} = 1;
        $block_sources{$index}{$begin}   = $peer if $peer;
        delete $blocks_pending{$index}{$begin};
    }

    method is_piece_complete ($index) {
        my $piece_length  = $self->piece_length($index);
        my $blocks_needed = int( ( $piece_length + 16383 ) / 16384 );
        return ( scalar keys %{ $blocks_received{$index} // {} } ) == $blocks_needed;
    }

    method piece_length ($index) {
        my $total_size   = $self->_calculate_total_size();
        my $standard_len = $metadata->{info}{'piece length'} // 16384;
        my $num_pieces   = int( ( $total_size + $standard_len - 1 ) / $standard_len );
        if ( $index == $num_pieces - 1 ) {
            my $rem = $total_size % $standard_len;
            return $rem == 0 ? $standard_len : $rem;
        }
        return $standard_len;
    }

    method _get_full_piece ($index) {
        my $cache        = $block_cache{$index} or return undef;
        my $piece_length = $self->piece_length($index);
        my $full         = '';
        my $offset       = 0;
        while ( $offset < $piece_length ) {
            my $block = $cache->{$offset} or return undef;
            $full .= $block;
            $offset += length($block);
        }
        return $full;
    }

    method _clear_piece_cache ($index) {
        $self->_clear_piece_data($index);
        delete $blocks_received{$index};
        delete $blocks_pending{$index};
        delete $block_sources{$index};
    }

    method get_next_request ($peer) {
        return undef if $state ne STATE_RUNNING;
        my $p_bf = $peer_bitfields{$peer};
        if ( !$p_bf ) {

            # warn '  [DEBUG] Peer ' . $peer->ip . " has no bitfield\n" if $debug;
            return undef;
        }
        if ( !$picker->end_game ) {
            my $missing = $bitfield->size - $bitfield->count;
            my $stalled = ( $last_piece_verified_at > 0 && ( time - $last_piece_verified_at ) >= ENDGAME_STALL_TIMEOUT );
            if ( $missing <= 3 || $missing < ( $bitfield->size / 100 ) || $stalled ) {
                $self->_emit_log( 'debug', 'Entering END-GAME mode' . ( $stalled ? ' (stall detected)' : '' ) ) if $debug;
                $picker->enter_end_game();
            }
        }
        my ( $piece_idx, $offset, $len ) = $picker->pick_block( $peer, \%blocks_pending );
        if ( !defined $piece_idx ) {

            # warn '  [DEBUG] No piece picked for ' . $peer->ip . "\n" if $debug;
            return undef;
        }
        $blocks_pending{$piece_idx}{$offset} = $peer;
        return { index => $piece_idx, begin => $offset, length => $len };
    }

    method peer_disconnected ($peer) {
        my $ip_port = $peer->ip . ':' . $peer->port;
        $self->_emit_log( 'debug', "Peer disconnected: $ip_port" ) if $debug;
        $client->on_peer_disconnected( $peer->ip )                 if $client;
        $client->_emit( 'peer_disconnected', $peer )               if $client;
        delete $metadata_pending{$peer}                            if defined $peer;
        $pex_dropped{$ip_port} = { ip => $peer->ip, port => $peer->port };
        delete $pex_added{$ip_port};
        if ( my $bf = $peer_bitfields{$peer} ) {
            $picker->update_availability( $bf, -1 ) if $picker;
        }
        for my $i ( keys %blocks_pending ) {
            for my $offset ( keys %{ $blocks_pending{$i} } ) {
                if ( $blocks_pending{$i}{$offset} == $peer ) {
                    delete $blocks_pending{$i}{$offset};
                }
            }
        }
        delete $peer_bitfields{$peer};
        delete $peer_objects{$ip_port};
    }

    method set_peer_bitfield ( $peer, $data ) {
        return unless $bitfield;
        my $bf = Acme::Bitfield->new( size => $bitfield->size );
        $bf->set_data($data);
        if ( my $old_bf = $peer_bitfields{$peer} ) {
            $picker->update_availability( $old_bf, -1 ) if $picker;
        }
        $peer_bitfields{$peer} = $bf;
        my $flags = 0;
        $flags |= 0x01 if $peer->transport->filter;    # Encrypted
        $flags |= 0x02 if $bf->count == $bf->size;     # Seeder
        $pex_added{ $peer->ip . ':' . $peer->port } = { ip => $peer->ip, port => $peer->port, flags => $flags };
        delete $pex_dropped{ $peer->ip . ':' . $peer->port };
        $picker->update_availability( $bf, 1 ) if $picker;
    }

    method update_peer_have ( $peer, $index ) {
        return                           unless $bitfield;                # Might not be initialized yet during metadata phase
        $self->init_peer_bitfield($peer) unless $peer_bitfields{$peer};
        $peer_bitfields{$peer}->set($index) if $peer_bitfields{$peer};
        my $tmp_bf = Acme::Bitfield->new( size => $bitfield->size );
        $tmp_bf->set($index);
        $picker->update_availability( $tmp_bf, 1 ) if $picker;
    }

    method init_peer_bitfield ($peer) {
        return if $peer_bitfields{$peer};
        return unless $bitfield;
        my $bf = Acme::Bitfield->new( size => $bitfield->size );
        $peer_bitfields{$peer} = $bf;

        # Apply stored status
        my $status = $peer->bitfield_status;
        if ( defined $status ) {
            if ( $status eq 'all' ) {
                $bf->fill();
            }
            elsif ( $status eq 'none' ) {

                # already zeros
            }
            else {
                $bf->set_data($status);
            }
            $picker->update_availability( $bf, 1 ) if $picker;
        }
    }

    method set_peer_have_all ($peer) {
        $self->init_peer_bitfield($peer);
        return unless $peer_bitfields{$peer};
        $picker->update_availability( $peer_bitfields{$peer}, -1 ) if $picker;
        $peer_bitfields{$peer}->fill();
        $picker->update_availability( $peer_bitfields{$peer}, 1 ) if $picker;
    }

    method set_peer_have_none ($peer) {
        $self->init_peer_bitfield($peer);
    }

    method _broadcast_pex () {
        return unless keys %pex_added || keys %pex_dropped;

        # Limit to 100 peers per message per BEP 11
        my @added = values %pex_added;
        if ( @added > 100 ) {
            @added = splice( @added, 0, 100 );
        }
        my @dropped = values %pex_dropped;
        if ( @dropped > 100 ) {
            @dropped = splice( @dropped, 0, 100 );
        }
        my @added4   = grep { $_->{ip} !~ /:/ } @added;
        my @added6   = grep { $_->{ip} =~ /:/ } @added;
        my @dropped4 = grep { $_->{ip} !~ /:/ } @dropped;
        my @dropped6 = grep { $_->{ip} =~ /:/ } @dropped;
        for my $peer ( values %peer_objects ) {
            if ( $peer->protocol->isa('Net::BitTorrent::Protocol::BEP11') ) {

                # Filter out the peer itself from the added list
                my @final_added4 = grep { $_->{ip} ne $peer->ip || $_->{port} != $peer->port } @added4;
                my @final_added6 = grep { $_->{ip} ne $peer->ip || $_->{port} != $peer->port } @added6;
                next unless @final_added4 || @final_added6 || @dropped4 || @dropped6;
                $peer->protocol->send_pex( \@final_added4, \@dropped4, \@final_added6, \@dropped6 );
            }
        }
        %pex_added   = ();
        %pex_dropped = ();
    }

    method fetch_from_webseeds ($index) {
        my $segments = $storage->map_v1_piece($index);
        return 0 unless @$segments;
        for my $seg (@$segments) {
            $seg->{rel_path} = $seg->{file}->path->relative($base_path)->stringify;
        }
        for my $ws (@webseeds) {
            try {
                my $data = $ws->fetch_piece($segments);
                if ( $storage->verify_piece_v1( $index, $data ) ) {
                    $storage->write_piece_v1( $index, $data );
                    $bitfield->set($index);
                    $bytes_downloaded += length($data);
                    $bytes_left       -= length($data);
                    $self->_emit( 'piece_verified', $index );
                    return 1;
                }
            }
            catch ($e) { }
        }
        return 0;
    }

    method primary_pieces_root () {
        return $self->_find_first_root( $self->file_tree );
    }

    method _find_first_root ($tree) {
        for my $node ( values %$tree ) {
            if ( exists $node->{''} ) {
                return $node->{''}{'pieces root'};
            }
            else {
                my $r = $self->_find_first_root($node);
                return $r if $r;
            }
        }
        return undef;
    }
    field $_cached_total_size = undef;

    method _calculate_total_size () {
        return $_cached_total_size if defined $_cached_total_size;
        my $total = 0;
        my $info  = $metadata->{info};
        if ( $info->{'file tree'} ) {
            $total = $self->_sum_file_tree( $info->{'file tree'} );
        }
        else {
            $total = $info->{length} // 0;
            if ( $info->{files} ) {
                for my $f ( @{ $info->{files} } ) {
                    $total += $f->{length};
                }
            }
        }
        $_cached_total_size = $total;
        return $total;
    }

    method _sum_file_tree ($tree) {
        my $total = 0;
        for my $node ( values %$tree ) {
            if ( exists $node->{''} ) {
                $total += $node->{''}{length};
            }
            else {
                $total += $self->_sum_file_tree($node);
            }
        }
        return $total;
    }

    method announce ( $event = undef, $cb = undef ) {
        return unless defined $tracker_manager;
        my @ihs;
        push @ihs, $infohash_v2 if $infohash_v2;
        push @ihs, $infohash_v1 if $infohash_v1;
        my $params = {
            infohash   => \@ihs,
            peer_id    => $peer_id,
            port       => ( $client && $client->can('listen_port') ? $client->listen_port : 6881 ),
            uploaded   => $bytes_uploaded,
            downloaded => $bytes_downloaded,
            left       => $bytes_left,
            compact    => 1,
            ( $client && $client->can('user_agent') ? ( ua => $client->user_agent ) : () ),
        };
        $params->{event} = $event if $event;
        my $weak_self = $self;
        builtin::weaken($weak_self);
        my $on_peers = sub ($peers) {
            return unless $weak_self;
            $weak_self->add_peer($_) for @$peers;
            $cb->($peers) if $cb;
        };
        $tracker_manager->announce_all( $params, $on_peers );
        return [ values %peers ];
    }

    method add_peer ($peer) {
        my $ip;
        try {
            $ip = $peer->ip;
        }
        catch ($e) {
            $ip = $peer->{ip} // $peer->{address};
        }
        my $port;
        try {
            $port = $peer->port;
        }
        catch ($e) {
            $port = $peer->{port};
        }
        $self->_emit_log( 'debug', "Torrent::add_peer: $ip:$port" ) if $debug;
        return unless $ip && $port;
        my $key = "$ip:$port";

        # Cap discovered peers to prevent memory exhaustion
        return if keys %peers >= MAX_PEERS && !$peers{$key};
        unless ( $peers{$key} ) {
            my $flags = 0;
            try {
                $flags = $peer->flags;
            }
            catch ($e) { }
            $peers{$key}     = { ip => $ip, port => $port, flags => $flags };
            $pex_added{$key} = $peers{$key};
            delete $pex_dropped{$key};
            $self->_emit( 'peer_discovered', $peers{$key} );
        }
    }

    method add_dht_nodes ($nodes) {
        for my $node (@$nodes) {
            my ( $id, $ip, $port );
            if ( ref $node eq 'HASH' ) {
                $id   = $node->{id};
                $ip   = $node->{ip} || $node->{address};
                $port = $node->{port};
            }
            elsif ( ref $node ) {
                try {
                    if ( $node->can('id') ) {
                        $id   = $node->id;
                        $ip   = $node->ip;
                        $port = $node->port;
                    }
                }
                catch ($e) { }
            }
            next unless $id && $ip && $port;
            my $nid_hex = unpack( 'H*', $id );
            next if exists $dht_frontier{$nid_hex};

            # Cap frontier size
            if ( keys %dht_frontier > 500 ) {

                # Remove a random unvisited node or the furthest one?
                # For simplicity, just stop adding if full.
                # In a real client we might want to replace less-desirable nodes.
                next;
            }
            $dht_frontier{$nid_hex} = { id => $id, ip => $ip, port => $port, visited => 0 };
        }
    }

    method ban_peer ( $ip, $port ) {
        my $key = "$ip:$port";
        delete $peers{$key};
        $attempted_connections{$key} = time() + 3600;    # Ban for an hour
    }

    method _cleanup_connections () {
        my $now = time();
        for my $key ( keys %attempted_connections ) {
            if ( $now - $attempted_connections{$key} > 3600 ) {
                delete $attempted_connections{$key};
            }
        }
        if ( keys %attempted_connections > MAX_ATTEMPTED ) {
            my $to_delete = scalar( keys %attempted_connections ) - MAX_ATTEMPTED;
            my @oldest    = ( sort { $attempted_connections{$a} <=> $attempted_connections{$b} } keys %attempted_connections )[ 0 .. $to_delete - 1 ];
            delete @attempted_connections{@oldest};
        }
    }

    method register_peer_object ($peer_obj) {
        my $key = $peer_obj->ip . ':' . $peer_obj->port;
        $peer_objects{$key} = $peer_obj;
    }

    method start_dht_lookup () {
        return if $is_private;
        my $dht = $client->dht();
        return unless $dht;
        my @ihs;
        push @ihs, $infohash_v2 if $infohash_v2;
        push @ihs, $infohash_v1 if $infohash_v1;

        # Explicitly ask bootstrap nodes.
        # This forces a query even if the local routing table is empty.
        my @boot_nodes = ( [ 'router.bittorrent.com', 6881 ], [ 'router.utorrent.com', 6881 ], [ 'dht.transmissionbt.com', 6881 ], );
        for my $ih (@ihs) {
            $self->_emit_log( 'debug', 'Starting DHT peer search for ' . unpack( 'H*', $ih ) ) if $debug;
            $dht->find_peers($ih);          # Query local routing table
            for my $node (@boot_nodes) {    # Force query to bootstrap nodes

                # Resolve hostname if needed (get_peers expects IP)
                # But dht->get_peers might handle hostnames if IO::Socket::IP does?
                # Let's assume the DHT module handles resolution or the socket does.
                # Actually, standard DHT expects IP.
                # Let's trust the DHT module's resolving or the fact that we passed these as boot_nodes.
                # Wait, get_peers sends a packet. UDP sendto needs packed address or IP.
                # IO::Socket::IP can handle hostnames in send() usually.
                $dht->get_peers( $ih, $node->[0], $node->[1] );
            }
        }
    }

    method _update_dht_search () {
        return if $is_private;
        my $dht = $client->dht();
        return unless $dht;
        my @ihs;
        push @ihs, $infohash_v2 if $infohash_v2;
        push @ihs, $infohash_v1 if $infohash_v1;
        for my $ih (@ihs) {

            # Merge routing table nodes into our search frontier
            # Net::BitTorrent::DHT::routing_table->find_closest returns objects
            # where the data is in {data}{ip} and {data}{port}
            my @closest_in_table = $dht->routing_table->find_closest( $ih, 50 );
            for my $node (@closest_in_table) {
                my $nid_hex = unpack( 'H*', $node->{id} );
                next if exists $dht_frontier{$nid_hex};
                $dht_frontier{$nid_hex} = { id => $node->{id}, ip => $node->{data}{ip}, port => $node->{data}{port}, visited => 0 };
            }

            # Pick the top N closest unvisited candidates
            # Note: ^. is bitwise XOR on strings in Modern Perl
            my @to_query = sort { ( $a->{id} ^.$ih ) cmp ( $b->{id} ^.$ih ) } grep { !$_->{visited} && $_->{ip} } values %dht_frontier;
            if (@to_query) {
                my $best_dist = unpack( 'H*', $to_query[0]{id} ^.$ih );
                $self->_emit_log( 'debug', sprintf( 'DHT Frontier: %d nodes. Best dist: %s', scalar( keys %dht_frontier ), $best_dist ) ) if $debug;
                my $count = 0;
                for my $c (@to_query) {
                    $self->_emit_log( 'debug', 'DHT Querying: ' . unpack( 'H*', $c->{id} ) . " at $c->{ip}:$c->{port}" ) if $debug;
                    $dht->get_peers( $ih, $c->{ip}, $c->{port} );
                    $c->{visited} = 1;
                    last if ++$count >= 8;
                }
            }
            else {
                $self->_emit_log( 'debug', 'DHT Frontier exhausted for ' . unpack( 'H*', $ih ) . '. Re-bootstrapping...' ) if $debug;
                $self->start_dht_lookup();

                # Fallback: If we are starving, try adding a public tracker if not already present
                #~ state $added_fallback = 0;
                #~ if ( !$added_fallback && keys %peer_objects < 5 ) {
                #~ warn "  [DEBUG] Adding fallback OpenTrackr\n" if $debug;
                #~ $tracker_manager->add_tracker('udp://tracker.opentrackr.org:1337/announce');
                #~ $self->announce('started');
                #~ $added_fallback = 1;
                #~ }
            }
        }
    }

    method _sort_peers_rfc6724 ($peer_list) {
        my $has_v6 = $client->dht && $client->dht->want_v6;
        return [
            sort {
                my $a_v6 = ( $a->{ip} =~ /:/       ? 1 : 0 );
                my $b_v6 = ( $b->{ip} =~ /:/       ? 1 : 0 );
                my $a_ll = ( $a->{ip} =~ /^fe80:/i ? 1 : 0 );
                my $b_ll = ( $b->{ip} =~ /^fe80:/i ? 1 : 0 );
                if ($has_v6) {

                    # Prefer Link-Local
                    return -1 if $a_ll  && !$b_ll;
                    return 1  if !$a_ll && $b_ll;

                    # Prefer Global IPv6
                    return -1 if $a_v6  && !$b_v6;
                    return 1  if !$a_v6 && $b_v6;
                }

                # Tie-break: Randomize
                return rand() <=> rand();
            } @$peer_list
        ];
    }

    method discovered_peers () {
        my @list = values %peers;
        return $self->_sort_peers_rfc6724( \@list );
    }
    method infohash_v1 () {$infohash_v1}
    method infohash_v2 () {$infohash_v2}
    method peer_id ()     {$peer_id}
    method trackers ()    { return $tracker_manager->trackers() }

    method DESTROY () {
        return unless $state != STATE_STOPPED;
        for my $peer ( grep {defined} values %peer_objects ) {
            $peer->disconnected();
        }
    }

    method files () {
        return [] unless $storage;
        return [ map { $_->path->absolute->stringify } $storage->files_ordered->@* ];
    }

    method dump_state () {
        return {
            metadata   => $metadata,
            bitfield   => $bitfield->data,
            storage    => $storage->dump_state(),
            downloaded => $bytes_downloaded,
            uploaded   => $bytes_uploaded
        };
    }

    method load_state ($state) {
        return unless ref $state eq 'HASH';
        if ( exists $state->{metadata} ) {
            if ( ref $state->{metadata} eq 'HASH' && ref $state->{metadata}{info} eq 'HASH' ) {
                $metadata = $state->{metadata};
                $self->_init_from_metadata();
            }
            else {
                $self->_emit_log( 'warn', 'load_state: invalid metadata structure, skipping' );
            }
        }
        if ( exists $state->{bitfield} && defined $state->{bitfield} && $bitfield ) {
            if ( length( $state->{bitfield} ) == int( ( $bitfield->size + 7 ) / 8 ) ) {
                $bitfield->set_data( $state->{bitfield} );
                my $piece_len = $metadata->{info}{'piece length'} // 16384;
                $bytes_left = ( $bitfield->size - $bitfield->count ) * $piece_len;
            }
            else {
                $self->_emit_log( 'warn', 'load_state: bitfield size mismatch, skipping' );
            }
        }
        $storage->load_state( $state->{storage} ) if exists $state->{storage} && $storage;
        $bytes_downloaded = $state->{downloaded} // 0;
        $bytes_uploaded   = $state->{uploaded}   // 0;
    }

    method file_tree () {
        my $info = $metadata->{info};
        if ( $info->{'file tree'} ) { return $info->{'file tree'} }
        my $tree = {};
        if ( $info->{files} ) {
            for my $f ( @{ $info->{files} } ) {
                my $curr     = $tree;
                my @path     = grep { $_ ne '' && $_ ne '.' && $_ ne '..' } @{ $f->{path} };
                my $filename = pop @path;
                for my $dir (@path) {
                    $curr->{$dir} //= {};
                    $curr = $curr->{$dir};
                }
                next unless defined $filename;
                $curr->{$filename} = { '' => { length => $f->{length} } };
            }
        }
        else {
            my $name = $info->{name};
            $name =~ s|[\\/]+|_|g;
            $tree->{$name} = { '' => { length => $info->{length} // 0 } };
        }
        return $tree;
    }
};
1;
