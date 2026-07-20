use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Net::BitTorrent::Emitter;
#
class Net::BitTorrent::DHT::Peer v2.0.6 {
    field $ip     : param : reader;
    field $port   : param : reader;
    field $family : param : reader;
    method to_string () {"$ip:$port"}
};
#
class Net::BitTorrent::DHT v2.1.0 : isa(Net::BitTorrent::Emitter) {
    use Algorithm::Kademlia;
    use Net::BitTorrent::DHT::Security;
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
    use IO::Socket::IP;
    use Socket
        qw[sockaddr_family pack_sockaddr_in unpack_sockaddr_in inet_aton inet_ntoa AF_INET AF_INET6 pack_sockaddr_in6 unpack_sockaddr_in6 inet_pton inet_ntop getaddrinfo getnameinfo NI_NUMERICHOST SOCK_DGRAM];
    use IO::Select;
    use Digest::SHA           qw[sha1];
    use Crypt::URandom        qw[urandom];
    use Net::BitTorrent::SSRF qw[is_safe_ip is_safe_host];
    #
    use constant MAX_STORAGE_ENTRIES      => 10000;             # Max total entries in peer+data storage
    use constant MAX_IMMUTABLE_VALUE_SIZE => 1024 * 1024;       # 1 MB max for BEP44 immutable data values
    use constant MAX_UNPACK_NODES         => 200;               # Max nodes unpacked from a single response
    use constant MAX_IMPORT_NODES         => 2000;
    use constant MAX_IMPORT_ENTRIES       => 5000;
    field $node_id_bin : param : reader //= urandom(20);
    field $port             : param : reader = 6881;
    field $address          : param //= undef;
    field $want_v4          : param : reader //= 1;
    field $want_v6          : param : reader //= 1;
    field $bep32            : param : reader //= 1;
    field $bep42            : param : reader //= 1;
    field $bep33            : param : reader //= 1;
    field $bep44            : param : reader //= 1;
    field $bep51            : param : reader //= 1;
    field $read_only        : param  = 0;
    field $ssrf_bypass      : param  = 0;
    field $security         : reader = Net::BitTorrent::DHT::Security->new();
    field $routing_table_v4 : reader = Algorithm::Kademlia::RoutingTable->new( local_id_bin => $node_id_bin, k => 8 );
    field $routing_table_v6 : reader = Algorithm::Kademlia::RoutingTable->new( local_id_bin => $node_id_bin, k => 8 );
    field $peer_storage     : reader = Algorithm::Kademlia::Storage->new( ttl => 7200 );
    field $data_storage     : reader = Algorithm::Kademlia::Storage->new( ttl => 7200 );
    field $socket           : param : reader //= IO::Socket::IP->new( LocalAddr => $address, LocalPort => $port, Proto => 'udp', Blocking => 0 );
    field $select //= IO::Select->new($socket);
    field $token_secret                      = urandom(32);
    field $token_old_secret                  = $token_secret;
    field $last_rotation                     = time;
    field $node_id_rotation_interval : param = 7200;            # 2 hours
    field $last_node_id_rotation             = time;
    field $last_external_ip_change           = 0;
    field $boot_nodes : param : reader : writer //= [ [ 'router.bittorrent.com', 6881 ], [ 'router.utorrent.com', 6881 ],
        [ 'dht.transmissionbt.com', 6881 ] ];
    field @_resolved_boot_nodes;
    field $v : param : reader //= ();
    field $debug : param = 0;
    field $_ed25519_backend = ();
    field $running          = 0;
    field %_blacklist;
    field %_query_rate;                                         # ip => [ timestamps ] for per-IP rate limiting
    field %ip_votes;                                            # external_ip => count
    field $external_ip : reader = undef;
    field %_pending_queries;
    field $_tid_counter = 0;

    method set_node_id ($new_id) {
        return unless defined $new_id && length($new_id) == 20;
        $node_id_bin = $new_id;
        $routing_table_v4->set_local_id_bin($new_id);
        $routing_table_v6->set_local_id_bin($new_id);
    }
    ADJUST {
        $socket // $self->_emit_log( 'fatal', 'Could not create UDP socket: ' . $! );

        # Pre-resolve bootstrap nodes
        for my $r (@$boot_nodes) {
            my ( $err, @res ) = getaddrinfo( $r->[0], $r->[1], { socktype => SOCK_DGRAM } );
            if ($err) {
                $self->_emit_log( 'warn', "Could not resolve bootstrap node $r->[0]:$r->[1]: $err" );
                next;
            }
            push @_resolved_boot_nodes, $res[0]{addr};
        }
        $self->on(
            external_ip_detected => sub ( $emitter, $ip ) {
                $external_ip = $ip;
                return unless $bep42;
                my $new_id = $security->generate_node_id($ip);
                $self->set_node_id($new_id);
            }
        );
        if ($bep44) {
            try {
                require Crypt::PK::Ed25519;
                $_ed25519_backend = method( $sig, $msg, $key ) {
                    my $ed = Crypt::PK::Ed25519->new();
                    try { $ed->import_key_raw( $key, 'public' )->verify_message( $sig, $msg ); }
                    catch ($e) { return 0; }
                }
            }
            catch ($e) {
                try {
                    require Crypt::Perl::Ed25519::PublicKey;
                    $_ed25519_backend = method( $sig, $msg, $key ) {
                        try {
                            # Crypt::Perl might throw if key or sig length is invalid
                            return 0 unless length($key) == 32;
                            return 0 unless length($sig) == 64;
                            my $pk = Crypt::Perl::Ed25519::PublicKey->new($key);
                            return $pk->verify( $msg, $sig );
                        }
                        catch ($e2) {
                            return 0;
                        }
                    }
                }
                catch ($e2) { }
            }
        }
    }
    method routing_table () {$routing_table_v4}    # Backward compatibility

    method routing_table_stats () {
        my $stats = { v4 => [], v6 => [] };
        my $idx   = 0;
        push $stats->{v4}->@*, { index => $idx++, count => scalar @$_ } for $routing_table_v4->buckets;
        $idx = 0;
        push $stats->{v6}->@*, { index => $idx++, count => scalar @$_ } for $routing_table_v6->buckets;
        return $stats;
    }

    method export_state () {
        my @nodes_v4;
        for my $bucket ( $routing_table_v4->buckets ) {
            push @nodes_v4, map { { id => $_->{id}, ip => $_->{data}{ip}, port => $_->{data}{port} } } @$bucket;
        }
        my @nodes_v6;
        for my $bucket ( $routing_table_v6->buckets ) {
            push @nodes_v6, map { { id => $_->{id}, ip => $_->{data}{ip}, port => $_->{data}{port} } } @$bucket;
        }
        my %peers = $peer_storage->entries;
        my %data  = $data_storage->entries;
        return { id => $node_id_bin, nodes => \@nodes_v4, nodes6 => \@nodes_v6, peers => \%peers, data => \%data, };
    }

    method import_state ($state) {
        return unless ref $state eq 'HASH';
        try {
            $node_id_bin = $state->{id} if defined $state->{id} && length( $state->{id} ) == 20;
            if ( $state->{nodes} && ref $state->{nodes} eq 'ARRAY' ) {
                my @to_import;
                for my $n ( $state->{nodes}->@* ) {
                    next unless ref $n eq 'HASH' && defined $n->{id};
                    last if scalar @to_import >= MAX_IMPORT_NODES;
                    push @to_import, { id => $n->{id}, data => { ip => $n->{ip} // '', port => $n->{port} // 0 } };
                }
                $routing_table_v4->import_peers( \@to_import ) if @to_import;
            }
            if ( $state->{nodes6} && ref $state->{nodes6} eq 'ARRAY' ) {
                my @to_import;
                for my $n ( $state->{nodes6}->@* ) {
                    next unless ref $n eq 'HASH' && defined $n->{id};
                    last if scalar @to_import >= MAX_IMPORT_NODES;
                    push @to_import, { id => $n->{id}, data => { ip => $n->{ip} // '', port => $n->{port} // 0 } };
                }
                $routing_table_v6->import_peers( \@to_import ) if @to_import;
            }
            my $count = 0;
            if ( $state->{peers} && ref $state->{peers} eq 'HASH' ) {
                for my $hash ( keys $state->{peers}->%* ) {
                    last if ++$count > MAX_IMPORT_ENTRIES;
                    my $entry = $state->{peers}{$hash};
                    $peer_storage->put( $hash, $entry->{value} ) if ref $entry eq 'HASH' && defined $entry->{value};
                }
            }
            if ( $state->{data} && ref $state->{data} eq 'HASH' ) {
                for my $hash ( keys $state->{data}->%* ) {
                    last                                               if ++$count > MAX_IMPORT_ENTRIES;
                    $data_storage->put( $hash, $state->{data}{$hash} ) if defined $state->{data}{$hash};
                }
            }
        }
        catch ($e) {
            $self->_emit_log( 'warn', "Failed to import state: $e" );
        }
    }

    method _rotate_tokens () {
        if ( time - $last_rotation > 300 ) {
            $token_old_secret = $token_secret;
            $token_secret     = urandom(32);
            $last_rotation    = time;
        }
    }

    method _rotate_node_id () {
        if ( $external_ip && $bep42 ) {
            my $new_id = $security->generate_node_id($external_ip);
            if ( $new_id ne $node_id_bin ) {
                $self->_emit_log( 'debug', 'Rotating Node ID for ' . $external_ip );
                $self->set_node_id($new_id);
            }
        }
        $last_node_id_rotation = time;
    }

    method _generate_token ( $ip, $secret //= undef ) {
        $secret //= $token_secret;
        return sha1( $ip . $secret );
    }

    method _verify_token ( $ip, $token ) {

        # Use constant-time comparison to prevent timing attacks on tokens
        return 0 unless defined $token && length($token) == 20;
        my $t1  = $self->_generate_token( $ip, $token_secret );
        my $t2  = $self->_generate_token( $ip, $token_old_secret );
        my $ok1 = 0;
        my $ok2 = 0;
        for my $i ( 0 .. 19 ) {
            $ok1 |= ord( substr( $t1, $i, 1 ) ) ^ ord( substr( $token, $i, 1 ) );
            $ok2 |= ord( substr( $t2, $i, 1 ) ) ^ ord( substr( $token, $i, 1 ) );
        }
        return $ok1 == 0 || $ok2 == 0;
    }

    method bootstrap () {
        for my $addr (@_resolved_boot_nodes) {
            $self->_send( { t => 'pn', y => 'q', q => 'ping',      a => { id => $node_id_bin } },                         $addr );
            $self->_send( { t => 'fn', y => 'q', q => 'find_node', a => { id => $node_id_bin, target => $node_id_bin } }, $addr );
        }
    }

    method ping ( $addr, $port = undef ) {
        my $tid = $self->_next_tid();
        $_pending_queries{$tid} = { q => 'ping', time => time };
        $self->_send( { t => $tid, y => 'q', q => 'ping', a => { id => $node_id_bin } }, $addr, $port );
    }

    method _next_tid () {
        $_tid_counter = ( $_tid_counter + 1 ) % 0xFFFF;
        pack 'n', $_tid_counter;
    }

    method find_node_remote ( $target_id, $addr, $port = undef ) {
        my $tid = $self->_next_tid();
        $_pending_queries{$tid} = { q => 'find_node', target => $target_id, time => time };
        $self->_send( { t => $tid, y => 'q', q => 'find_node', a => { id => $node_id_bin, target => $target_id } }, $addr, $port );
    }

    method get_peers ( $info_hash, $addr, $port = undef ) {
        my $tid = $self->_next_tid();
        $_pending_queries{$tid} = { q => 'get_peers', target => $info_hash, time => time };
        $self->_send( { t => $tid, y => 'q', q => 'get_peers', a => { id => $node_id_bin, info_hash => $info_hash } }, $addr, $port );
    }

    method get_remote ( $target, $addr, $port = undef ) {
        return unless $bep44;
        my $tid = $self->_next_tid();
        $_pending_queries{$tid} = { q => 'get', target => $target, time => time };
        $self->_send( { t => $tid, y => 'q', q => 'get', a => { id => $node_id_bin, target => $target } }, $addr, $port );
    }

    method put_remote ( $args, $addr, $port = undef ) {
        return unless $bep44;
        my $tid = $self->_next_tid();
        $_pending_queries{$tid} = { q => 'put', time => time };

        # $args should contain 'v' and optionally 'k', 'sig', 'seq', 'salt', 'cas'
        $self->_send( { t => $tid, y => 'q', q => 'put', a => { id => $node_id_bin, %$args } }, $addr, $port );
    }

    method announce_peer ( $info_hash, $token, $announce_port, $addr, $port = undef, $is_seed //= 0 ) {
        my $tid = $self->_next_tid();
        $_pending_queries{$tid} = { q => 'announce_peer', target => $info_hash, time => time };
        my $msg = {
            t => $tid,
            y => 'q',
            q => 'announce_peer',
            a => { id => $node_id_bin, info_hash => $info_hash, port => $announce_port, token => $token, ( $bep33 && $is_seed ? ( seed => 1 ) : () ) }
        };
        $self->_send( $msg, $addr, $port );
    }

    method announce_infohash ( $ih, $port ) {
        my @learned;    # High level: find closest nodes and announce
        push @learned, $routing_table_v4->find_closest($ih) if $want_v4;
        push @learned, $routing_table_v6->find_closest($ih) if $want_v6 && $bep32;

        # get_peers first to get tokens
        $self->get_peers( $ih, $_->{data}{ip}, $_->{data}{port} ) for @learned;
    }

    method scrape_peers_remote ( $info_hash, $addr, $port = undef ) {
        return unless $bep33;
        my $tid = $self->_next_tid();
        $_pending_queries{$tid} = { q => 'scrape_peers', target => $info_hash, time => time };
        $self->_send( { t => $tid, y => 'q', q => 'scrape_peers', a => { id => $node_id_bin, info_hash => $info_hash } }, $addr, $port );
    }

    method find_peers ($info_hash) {
        my @learned;
        push @learned, $routing_table_v4->find_closest($info_hash) if $want_v4;
        push @learned, $routing_table_v6->find_closest($info_hash) if $want_v6 && $bep32;
        $self->get_peers( $info_hash, $_->{data}{ip}, $_->{data}{port} ) for @learned;
    }

    method scrape ($info_hash) {
        return unless $bep33;
        my @learned;
        push @learned, $routing_table_v4->find_closest($info_hash) if $want_v4;
        push @learned, $routing_table_v6->find_closest($info_hash) if $want_v6 && $bep32;
        $self->scrape_peers_remote( $info_hash, $_->{data}{ip}, $_->{data}{port} ) for @learned;
    }

    method sample ($target) {
        return unless $bep51;
        my @learned;
        push @learned, $routing_table_v4->find_closest($target) if $want_v4;
        push @learned, $routing_table_v6->find_closest($target) if $want_v6 && $bep32;
        $self->sample_infohashes_remote( $target, $_->{data}{ip}, $_->{data}{port} ) for @learned;
    }

    method sample_infohashes_remote ( $target, $addr, $port = undef ) {
        return unless $bep51;
        my $tid = $self->_next_tid();
        $_pending_queries{$tid} = { q => 'sample_infohashes', target => $target, time => time };
        $self->_send( { t => $tid, y => 'q', q => 'sample_infohashes', a => { id => $node_id_bin, target => $target } }, $addr, $port );
    }

    method tick ( $timeout //= 0 ) {
        $self->_rotate_tokens();
        $self->_rotate_node_id()        if time - $last_node_id_rotation >= $node_id_rotation_interval;
        return $self->handle_incoming() if $select->can_read($timeout);
        return ( [], [], undef );
    }

    method handle_incoming ( $data //= undef, $sender //= undef ) {
        $sender = $socket->recv( $data, 4096 ) unless defined $data;
        return ( [], [], undef )               unless defined $data && length $data;
        my $msg;
        try { $msg = bdecode($data) }
        catch ($e) { return ( [], [], undef ) }
        return ( [], [], undef ) if ref($msg) ne 'HASH';
        my ( $port, $ip ) = $self->_unpack_address($sender);
        return ( [], [], undef ) unless $ip;

        if ($debug) {
            my $qname = $msg->{q} // '';
            $qname =~ s/[^\x20-\x7E]/./g;
            my $type = ( $msg->{y} // '' ) eq 'q' ? "QUERY ($qname)" : 'RESPONSE';
            $self->_emit_log( 'debug', "RECV $type from $ip:$port" );
        }
        if ( ( $msg->{y} // '' ) eq 'q' ) {
            my $node;
            try { $node = $self->_handle_query( $msg, $sender, $ip, $port ); }
            catch ($e) { $self->_emit_log( 'warning', "Query handler error from $ip:$port: $e" ); }
            return ( $node ? [$node] : [], [], undef );    # Return flat format
        }
        if ( ( $msg->{y} // '' ) eq 'e' ) {
            if ($debug) {
                my $code = $msg->{e}->[0] // 'unknown';
                my $text = $msg->{e}->[1] // 'no message';
                $text = substr( "$text", 0, 200 );    # Truncate
                $text =~ s/[^\x20-\x7E]/./g;          # Sanitize non-printable
                $self->_emit_log( 'debug', "RECV ERROR $code: $text from $ip:$port" );
            }
            return ( [], [], undef );
        }
        if ( ( $msg->{y} // '' ) eq 'r' ) {
            my @result;
            try { @result = $self->_handle_response( $msg, $sender, $ip, $port ); }
            catch ($e) { $self->_emit_log( 'warning', "Response handler error from $ip:$port: $e" ); return ( [], [], undef ) }
            return @result;
        }
        return ( [], [], undef );
    }

    method _unpack_address ($sockaddr) {
        return () unless defined $sockaddr;
        my $family;
        try { $family = sockaddr_family($sockaddr) }
        catch ($e) { return () }
        if ( $family == AF_INET ) {
            my ( $port, $ip_bin ) = unpack_sockaddr_in($sockaddr);
            return ( $port, inet_ntoa($ip_bin) );
        }
        elsif ( $family == AF_INET6 ) {
            my ( $port, $ip_bin, $scope, $flow ) = unpack_sockaddr_in6($sockaddr);
            return ( $port, inet_ntop( AF_INET6, $ip_bin ) );
        }
        return ();
    }

    method _handle_query ( $msg, $sender, $ip, $port ) {
        return if $_blacklist{$ip};

        # Cap blacklist size to prevent memory exhaustion from spoofed IPs
        if ( keys %_blacklist > 10000 ) {
            my @oldest = ( sort { ( $_blacklist{$a} // 0 ) <=> ( $_blacklist{$b} // 0 ) } keys %_blacklist )[ 0 .. 999 ];
            delete @_blacklist{@oldest};
        }

        # Max 20 queries per IP in a given 10s window
        my $now = time;
        $_query_rate{$ip} //= [];
        @{ $_query_rate{$ip} } = grep { $_ > $now - 10 } @{ $_query_rate{$ip} };
        if ( scalar @{ $_query_rate{$ip} } >= 20 ) {
            $_blacklist{$ip} = $now;
            $self->_emit_log( 'debug', "Rate-limited DHT query from $ip (exceeded 20/10s)" ) if $debug;
            return;
        }
        push @{ $_query_rate{$ip} }, $now;

        # Cap _query_rate to prevent memory exhaustion from spoofed IPs
        if ( keys %_query_rate > 10000 ) {
            my @stale = grep { $_query_rate{$_}[-1] < $now - 60 } keys %_query_rate;
            if (@stale) {
                my $delete = @stale > 1000 ? 1000 : scalar @stale;
                delete @_query_rate{ @stale[ 0 .. $delete - 1 ] };
            }
        }
        my $q  = $msg->{q} // return;
        my $a  = $msg->{a} // return;
        my $id = $a->{id}  // return;
        return unless defined $msg->{t} && !ref $msg->{t} && length( $msg->{t} ) > 0;

        # BEP 42: Reject nodes with invalid IDs
        return if $bep42 && !$security->validate_node_id( $id, $ip );
        my $table = ( $ip =~ /:/ ) ? $routing_table_v6 : $routing_table_v4;
        unless ( $a->{ro} ) {
            my $stale = $table->add_peer( $id, { ip => $ip, port => $port } );
            $self->ping( $stale->{data}{ip}, $stale->{data}{port} ) if $stale;
        }
        my $res = { t => $msg->{t}, y => 'r', r => { id => $node_id_bin } };
        $res->{v} = $v if defined $v;
        if ( my $ip_bin = ( $ip =~ /:/ ) ? inet_pton( AF_INET6, $ip ) : inet_aton($ip) ) {
            $res->{ip} = $ip_bin;
        }
        my $w = $a->{want} // [];
        $w = [$w] if defined $w && !ref $w;
        $w = [] unless ref $w eq 'ARRAY';
        my %want = map { $_ => 1 } @$w;
        if ( !@$w ) {    # Default: same family as query
            if   ( $ip =~ /:/ ) { $want{n6} = 1 }
            else                { $want{n4} = 1 }
        }
        if    ( $q eq 'ping' ) { }
        elsif ( $q eq 'find_node' ) {
            my @closest;
            push @closest, $routing_table_v4->find_closest( $a->{target} ) if $want_v4 && $want{n4};
            push @closest, $routing_table_v6->find_closest( $a->{target} ) if $want_v6 && $bep32 && $want{n6};
            my ( $v4, $v6 ) = $self->_pack_nodes( \@closest );
            $res->{r}{nodes}  = $v4 if $v4 && $want_v4 && $want{n4};
            $res->{r}{nodes6} = $v6 if $v6 && $want_v6 && $bep32 && $want{n6};
        }
        elsif ( $q eq 'get_peers' ) {
            my $info_hash = $a->{info_hash};

            # info_hash must be 20 or 32 bytes
            return if !defined $info_hash || ( length($info_hash) != 20 && length($info_hash) != 32 );
            $res->{r}{token} = $self->_generate_token($ip);
            my $peers_obj = $peer_storage->get($info_hash);
            if ( $peers_obj && @{ $peers_obj->value } ) {
                my @filtered = grep { ( $_->{ip} =~ /:/ ) ? $want_v6 : $want_v4 } @{ $peers_obj->value };
                $res->{r}{values} = $self->_pack_peers_raw( \@filtered );
            }
            else {
                my @closest;
                push @closest, $routing_table_v4->find_closest($info_hash) if $want_v4 && $want{n4};
                push @closest, $routing_table_v6->find_closest($info_hash) if $want_v6 && $bep32 && $want{n6};
                my ( $v4, $v6 ) = $self->_pack_nodes( \@closest );
                $res->{r}{nodes}  = $v4 if $v4 && $want_v4 && $want{n4};
                $res->{r}{nodes6} = $v6 if $v6 && $want_v6 && $bep32 && $want{n6};
            }
        }
        elsif ( $q eq 'announce_peer' ) {
            my $info_hash = $a->{info_hash};

            # Validate info_hash length
            return if !defined $info_hash || ( length($info_hash) != 20 && length($info_hash) != 32 );
            if ( $self->_verify_token( $ip, $a->{token} ) ) {
                my $peers_obj = $peer_storage->get($info_hash);
                my @peers     = $peers_obj         ? @{ $peers_obj->value } : ();
                my $peer_port = $a->{implied_port} ? $port                  : $a->{port};

                # Validate peer port is defined and within range
                return if ( !defined $peer_port || $peer_port < 1 || $peer_port > 65535 );
                my $new_peer = { ip => $ip, port => $peer_port, ( $bep33 && defined $a->{seed} ? ( seed => $a->{seed} ) : () ) };
                @peers = grep { $_->{ip} ne $ip } @peers;
                push @peers, $new_peer;
                splice( @peers, 0, @peers - 50 ) if @peers > 50;    # Cap peers per info_hash
                $peer_storage->put( $info_hash, \@peers );

                # Cap total storage entries to prevent memory exhaustion
                my %peers_entries = $peer_storage->entries;
                if ( keys %peers_entries > MAX_STORAGE_ENTRIES ) {
                    my @oldest = ( sort { $peers_entries{$a} cmp $peers_entries{$b} } keys %peers_entries )[ 0 .. 999 ];
                    $peer_storage->delete($_) for @oldest;
                }
            }
        }
        elsif ( $q eq 'scrape_peers' ) {
            if ($bep33) {
                my $info_hash = $a->{info_hash};

                # Validate info_hash length for scrape_peers
                return if !defined $info_hash || ( length($info_hash) != 20 && length($info_hash) != 32 );
                my $peers_obj = $peer_storage->get($info_hash);
                my $peers     = $peers_obj ? $peers_obj->value : [];
                my $seeders   = grep { $_->{seed} } @$peers;
                my $leechers  = @$peers - $seeders;
                $res->{r}{sn} = $seeders;
                $res->{r}{ln} = $leechers;
            }
            else {
                # If BEP 33 is disabled, we might want to return an error or just ignore.
                # Standard is to just return 'id'.
            }
        }
        elsif ( $q eq 'get' ) {
            if ($bep44) {
                my $target = $a->{target};

                # Validate target length (must be 20 or 32 bytes)
                return if !defined $target || ( length($target) != 20 && length($target) != 32 );
                my $data_obj = $data_storage->get($target);
                if ($data_obj) {
                    $res->{r} = { %{ $res->{r} }, %{ $data_obj->value } };
                }
                else {
                    my @closest;
                    push @closest, $routing_table_v4->find_closest($target) if $want_v4;
                    push @closest, $routing_table_v6->find_closest($target) if $want_v6 && $bep32;
                    my ( $v4, $v6 ) = $self->_pack_nodes( \@closest );
                    $res->{r}{nodes}  = $v4 if $v4 && $want_v4;
                    $res->{r}{nodes6} = $v6 if $v6 && $want_v6 && $bep32;
                }
                $res->{r}{token} = $self->_generate_token($ip);
            }
        }
        elsif ( $q eq 'put' ) {
            if ( $bep44 && $self->_verify_token( $ip, $a->{token} ) ) {
                my $v = $a->{v};

                # BEP44 mutable values must be <= 1000 bytes
                return unless defined $v && !ref $v;
                if ( defined $a->{k} && length($v) > 1000 ) {
                    $_blacklist{$ip} = time;
                    return;
                }
                my $target     = sha1($v);
                my $is_mutable = defined $a->{k};
                if ($is_mutable) {

                    # Validate key length and seq upper bound
                    my $seq_val = $a->{seq} // 0;
                    if (
                        !defined $a->{sig}        ||
                        !defined $a->{k}          ||
                        !defined $a->{seq}        ||
                        length( $a->{k} ) != 32   ||
                        length( $a->{sig} ) != 64 ||
                        $a->{seq} !~ /^\d+$/      ||
                        $seq_val > ( 1 << 53 )    ||    # L4: Reject seq > 2^53 (lossy float precision)
                        ( defined $a->{cas} && $a->{cas} !~ /^\d+$/ )
                    ) {
                        $_blacklist{$ip} = time;
                        return;
                    }
                    $target = sha1( $a->{k} . ( $a->{salt} // '' ) );

                    # Validate signature
                    my $to_sign = '';
                    $to_sign .= '3:cas' . bencode( $a->{cas} )   if defined $a->{cas};
                    $to_sign .= '4:salt' . bencode( $a->{salt} ) if defined $a->{salt} && length $a->{salt};
                    $to_sign .= '3:seq' . bencode( $a->{seq} );
                    $to_sign .= '1:v' . bencode($v);
                    if ( defined $_ed25519_backend && $_ed25519_backend->( $self, $a->{sig}, $to_sign, $a->{k} ) ) {
                        my $existing_obj = $data_storage->get($target);
                        if ( !defined $existing_obj || $a->{seq} > $existing_obj->value->{seq} ) {
                            if ( !defined $a->{cas} || ( $existing_obj && $existing_obj->value->{seq} == $a->{cas} ) ) {
                                $data_storage->put(
                                    $target,
                                    {   v   => $v,
                                        k   => $a->{k},
                                        sig => $a->{sig},
                                        seq => $a->{seq},
                                        ( defined $a->{salt} ? ( salt => $a->{salt} ) : () )
                                    }
                                );
                            }
                        }
                    }
                    else {
                        # BEP 44: "If the signature is invalid, the request MUST be rejected."
                        # Additionally, we blacklist the peer for attempting a malicious update.
                        $_blacklist{$ip} = time;
                        return;
                    }
                }
                else {    # Immutable

                    # Validate immutable data size to prevent memory exhaustion
                    if ( length($v) > MAX_IMMUTABLE_VALUE_SIZE ) {
                        $self->_emit_log( 'warn', "Immutable data value too large (" . length($v) . " bytes), rejecting" );
                        return;
                    }
                    $data_storage->put( $target, { v => $v } );

                    # Cap total data storage entries
                    my %data_entries = $data_storage->entries;
                    if ( keys %data_entries > MAX_STORAGE_ENTRIES ) {
                        my @oldest = ( sort { $data_entries{$a} cmp $data_entries{$b} } keys %data_entries )[ 0 .. 999 ];
                        $data_storage->delete($_) for @oldest;
                    }
                }
            }
        }
        elsif ( $q eq 'sample_infohashes' ) {
            if ($bep51) {
                my $target = $a->{target};

                # Validate target length
                return if !defined $target || ( length($target) != 20 && length($target) != 32 );
                my %entries  = $peer_storage->entries;
                my @all_keys = keys %entries;
                my $num      = scalar @all_keys;

                # BEP 51: return up to 20 samples closest to target
                my @sorted = sort {
                    my ( $a_dist, $b_dist ) = ( 0, 0 );
                    for my $i ( 0 .. 19 ) {
                        my $ab = ord( substr( $a, $i, 1 ) ) ^ ord( substr( $target, $i, 1 ) );
                        my $bb = ord( substr( $b, $i, 1 ) ) ^ ord( substr( $target, $i, 1 ) );
                        if ( $ab != $bb ) { $a_dist = $ab; $b_dist = $bb; last }
                    }
                    $a_dist <=> $b_dist;
                } @all_keys;
                my @samples = splice( @sorted, 0, 20 );
                $res->{r}{samples}  = join( '', @samples );
                $res->{r}{num}      = $num;
                $res->{r}{interval} = 21600;                  # 6 hours default
                my @closest;
                push @closest, $routing_table_v4->find_closest($target) if $want_v4;
                push @closest, $routing_table_v6->find_closest($target) if $want_v6 && $bep32;
                my ( $v4, $v6 ) = $self->_pack_nodes( \@closest );
                $res->{r}{nodes}  = $v4 if $v4 && $want_v4;
                $res->{r}{nodes6} = $v6 if $v6 && $want_v6 && $bep32;
            }
        }
        $self->_check_external_ip( $msg->{ip}, $ip ) if exists $msg->{ip};
        $self->_send_raw( bencode($res), $sender );
        return { id => $id, ip => $ip, port => $port };
    }

    method _handle_response ( $msg, $sender, $ip, $port ) {
        $self->_check_external_ip( $msg->{ip}, $ip ) if exists $msg->{ip};
        return ( [], [], undef )                     if $_blacklist{$ip};
        my $r = $msg->{r};
        return ( [], [], undef ) unless $r && $r->{id};
        my $tid     = $msg->{t} // '';
        my $pending = delete $_pending_queries{$tid};

        # Deterministic cleanup of old pending queries (older than 30s)
        {
            my $now = time;
            for my $k ( keys %_pending_queries ) {
                delete $_pending_queries{$k} if $now - $_pending_queries{$k}{time} > 30;
            }
        }
        if ( $bep42 && !$security->validate_node_id( $r->{id}, $ip ) ) {
            return ( [], [], undef );
        }
        my $table = ( $ip =~ /:/ ) ? $routing_table_v6 : $routing_table_v4;
        my $stale = $table->add_peer( $r->{id}, { ip => $ip, port => $port } );
        $self->ping( $stale->{data}{ip}, $stale->{data}{port} ) if $stale;
        my $peers = [];
        $peers = $self->_unpack_peers( $r->{values} ) if $r->{values};
        my @learned;
        push @learned, $self->_unpack_nodes( $r->{nodes},  AF_INET )->@*  if $r->{nodes};
        push @learned, $self->_unpack_nodes( $r->{nodes6}, AF_INET6 )->@* if $r->{nodes6};

        for my $node (@learned) {
            next if $bep42 && !$security->validate_node_id( $node->{id}, $node->{ip} );
            my $ntable = ( $node->{ip} =~ /:/ ) ? $routing_table_v6 : $routing_table_v4;
            $ntable->add_peer( $node->{id}, { ip => $node->{ip}, port => $node->{port} } );
        }

        # Always include the responding node itself
        push @learned, { id => $r->{id}, ip => $ip, port => $port };
        my $scrape;
        $scrape = { id => $r->{id}, ip => $ip, port => $port, sn => $r->{sn}, ln => $r->{ln} } if $pending && $pending->{q} eq 'scrape_peers';
        my $data;
        if ( defined $r->{v} ) {
            $data = {
                id    => $r->{id},
                ip    => $ip,
                port  => $port,
                v     => $r->{v},
                k     => $r->{k},
                sig   => $r->{sig},
                seq   => $r->{seq},
                salt  => $r->{salt},
                token => $r->{token}
            };
        }
        my $sample;
        if ( $pending && $pending->{q} eq 'sample_infohashes' && defined $r->{samples} ) {
            my @samples;
            my $blob = $r->{samples};
            push @samples, substr( $blob, 0, 20, '' ) while length($blob) >= 20;
            $sample = { id => $r->{id}, ip => $ip, port => $port, samples => \@samples, num => $r->{num}, interval => $r->{interval} };
        }
        my $token_only;
        $token_only = { id => $r->{id}, ip => $ip, port => $port, token => $r->{token} } if defined $r->{token} && !$data;
        my $result = $scrape // $data // $sample // $token_only;
        $result->{queried_target} = $pending->{target} if $result && $pending && $pending->{target};
        return ( \@learned, $peers, $result );
    }

    method _send ( $msg, $addr, $port //= undef ) {
        $msg->{v}     = $v if defined $v;
        $msg->{a}{ro} = 1  if $read_only && $msg->{y} eq 'q';
        if ( !defined $port && !ref $addr && length($addr) >= 16 ) {
            if ( !$ssrf_bypass ) {
                my ( $gerr, $ip ) = getnameinfo( $addr, NI_NUMERICHOST );
                if ( !$gerr && defined $ip && !is_safe_ip($ip) ) {
                    $self->_emit_log( 'warn', "DHT send blocked by SSRF policy: $ip" );
                    return;
                }
            }
            $self->_send_raw( bencode($msg), $addr );
            return;
        }
        ( $addr, $port ) = @$addr if ref $addr eq 'ARRAY';
        if ( !$ssrf_bypass && !is_safe_host($addr) ) {
            $self->_emit_log( 'debug', 'DHT send blocked by SSRF policy: ' . $addr );
            return;
        }
        my ( $err, @res ) = getaddrinfo( $addr, $port, { socktype => SOCK_DGRAM } );
        if ($err) {
            $self->_emit_log( 'debug', 'getaddrinfo failed for ' . $addr . ( defined $port ? ":$port" : '' ) . ': ' . $err );
            return;
        }
        for my $res (@res) {
            my $family = sockaddr_family( $res->{addr} );
            next unless ( $family == AF_INET && $want_v4 ) || ( $family == AF_INET6 && $want_v6 );
            if ( !$ssrf_bypass ) {
                my ( $gerr, $ip ) = getnameinfo( $res->{addr}, NI_NUMERICHOST );
                if ( !$gerr && defined $ip && !is_safe_ip($ip) ) {
                    $self->_emit_log( 'debug', 'DHT send blocked by SSRF policy: ' . $ip );
                    next;
                }
            }
            $self->_send_raw( bencode($msg), $res->{addr} );
        }
    }

    method _send_raw ( $data, $dest ) {
        if ($debug) {
            my ( $port, $ip ) = $self->_unpack_address($dest);
            $self->_emit_log( 'debug', "SEND to $ip:$port" );
        }
        my $sent = $socket->send( $data, 0, $dest );
        if ( !defined $sent ) {
            $self->_emit_log( 'warn', "DHT UDP send failed: $!" ) if $debug;
        }
        return $sent;
    }

    method _pack_nodes ($peers) {
        my $v4 = '';
        my $v6 = '';
        for my $p (@$peers) {
            my $ip   = $p->{data}{ip};
            my $port = $p->{data}{port} // 0;
            if ( $ip =~ /:/ ) {
                next unless $want_v6;
                my $ip_bin = inet_pton( AF_INET6, $ip );
                $v6 .= $p->{id} . $ip_bin . pack( 'n', $port ) if $ip_bin;
            }
            else {
                next unless $want_v4;
                my $ip_bin = inet_aton($ip);
                $v4 .= $p->{id} . $ip_bin . pack( 'n', $port ) if $ip_bin;
            }
        }
        return ( $v4, $v6 );
    }

    method _unpack_nodes ( $blob, $family //= AF_INET ) {
        my @nodes;
        my $stride = ( $family == AF_INET ) ? 26 : 38;
        my $ip_len = ( $family == AF_INET ) ? 4  : 16;
        while ( length($blob) >= $stride && @nodes < MAX_UNPACK_NODES ) {
            my $chunk  = substr( $blob,  0,  $stride, '' );
            my $id     = substr( $chunk, 0,  20 );
            my $ip_bin = substr( $chunk, 20, $ip_len );
            my $port   = unpack( 'n', substr( $chunk, 20 + $ip_len, 2 ) );
            next if $port == 0;
            my $ip = ( $family == AF_INET ) ? inet_ntoa($ip_bin) : inet_ntop( AF_INET6, $ip_bin );
            push @nodes, { id => $id, ip => $ip, port => $port };
        }
        return \@nodes;
    }

    method _unpack_peers ($list) {
        my @peers;
        my @blobs = ( ref($list) eq 'ARRAY' ) ? @$list : ($list);
        for my $blob (@blobs) {
            if ( length($blob) == 18 ) {
                my ( $ip_bin, $port ) = unpack( 'a16 n', $blob );
                push @peers, Net::BitTorrent::DHT::Peer->new( ip => inet_ntop( AF_INET6, $ip_bin ), port => $port, family => 6 ) if $want_v6;
            }
            elsif ( length($blob) == 6 ) {
                my ( $ip_bin, $port ) = unpack( 'a4 n', $blob );
                push @peers, Net::BitTorrent::DHT::Peer->new( ip => inet_ntoa($ip_bin), port => $port, family => 4 ) if $want_v4;
            }
            else {    # Fallback for non-standard implementations that pack multiple peers into one string
                while ( length($blob) >= 6 ) {
                    if ( length($blob) >= 18 && ( length($blob) % 18 == 0 ) ) {
                        my $chunk = substr( $blob, 0, 18, '' );
                        my ( $ip_bin, $port ) = unpack( 'a16 n', $chunk );
                        push @peers, Net::BitTorrent::DHT::Peer->new( ip => inet_ntop( AF_INET6, $ip_bin ), port => $port, family => 6 ) if $want_v6;
                    }
                    else {
                        my $chunk = substr( $blob, 0, 6, '' );
                        my ( $ip_bin, $port ) = unpack( 'a4 n', $chunk );
                        push @peers, Net::BitTorrent::DHT::Peer->new( ip => inet_ntoa($ip_bin), port => $port, family => 4 ) if $want_v4;
                    }
                }
            }
        }
        return \@peers;
    }

    method _pack_peers_raw ($peers) {
        return [
            map {
                ( $_->{ip} =~ /:/ ) ? ( inet_pton( AF_INET6, $_->{ip} ) . pack( 'n', $_->{port} ) ) :
                    ( inet_aton( $_->{ip} ) . pack( 'n', $_->{port} ) )
            } @$peers
        ];
    }

    method _check_external_ip ( $ip_bin, $source_ip = undef ) {
        if ( length($ip_bin) == 6 ) {
            $ip_bin = substr( $ip_bin, 0, 4 );
        }
        elsif ( length($ip_bin) == 18 ) {
            $ip_bin = substr( $ip_bin, 0, 16 );
        }
        my $ip = length($ip_bin) == 4 ? inet_ntoa($ip_bin) : length($ip_bin) == 16 ? inet_ntop( AF_INET6, $ip_bin ) : undef;
        return unless $ip;

        # Only accept public IPs as external IP
        return unless is_safe_ip($ip);
        my $consensus = 0;
        if ($source_ip) {

            # Track votes by source IP to prevent colluding-node manipulation.
            # Each source IP can only contribute one vote for one candidate IP.
            return if exists $ip_votes{$source_ip} && $ip_votes{$source_ip} eq $ip;
            $ip_votes{$source_ip} = $ip;
            my @matching = grep { $_ eq $ip } values %ip_votes;
            $consensus = 1 if scalar @matching >= 5;
        }
        else {
            # Fallback for direct/internal calls without source IP
            $ip_votes{$ip}++;
            $consensus = 1 if $ip_votes{$ip} >= 5;
        }
        if ($consensus) {
            if ( !defined $external_ip || $external_ip ne $ip ) {
                if ( time - $last_external_ip_change >= 300 ) {    # 5-min cooldown between changes
                    $external_ip             = $ip;
                    $last_external_ip_change = time;
                    $self->_emit( external_ip_detected => $ip );
                }
            }
            %ip_votes = ();                                        # Reset votes after consensus
        }

        # Cap ip_votes hash
        if ( keys %ip_votes > 500 ) {
            my @keys = keys %ip_votes;
            delete @ip_votes{ @keys[ 0 .. 49 ] };
        }
    }

    method run () {
        $running = 1;
        $self->bootstrap();
        $self->tick(1) while $running;
    }
};
1;
