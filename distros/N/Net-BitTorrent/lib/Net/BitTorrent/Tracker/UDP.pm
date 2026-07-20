use v5.40;
use feature 'class', 'try';
no warnings 'experimental::class', 'experimental::try';
class Net::BitTorrent::Tracker::UDP v2.1.0 : isa(Net::BitTorrent::Tracker::Base) {
    use Net::BitTorrent::Protocol::BEP23;
    use Net::BitTorrent::SSRF qw[is_safe_ip resolve_and_pin];
    use IO::Socket::IP;
    use Crypt::URandom qw[urandom];
    use Digest::SHA    qw[sha1];
    use Config;
    use constant HAS_64BIT                => $Config{ivsize} >= 8;
    use constant MAX_PENDING_TRANSACTIONS => 100;
    field $connection_id      = HAS_64BIT ? 0 : pack( 'NN', 0, 0 );
    field $connection_id_time = 0;
    field $transaction_id;
    field $host;
    field $port;
    field $resolved_ip;             # Cached resolved IP for SSRF-safe retransmissions
    field $socket;
    field %pending_transactions;    # tid => { type => ..., cb => ..., payload => ..., retries => ..., timestamp => ... }

    sub _split64 ($val) {
        $val //= 0;
        if (HAS_64BIT) { return $val }
        my $hi = int( $val / 4294967296 );
        my $lo = $val - ( $hi * 4294967296 );
        return ( $hi, $lo );
    }
    ADJUST {
        if ( $self->url =~ m{^udp://([^:/]+):(\d+)} ) {
            $host = $1;
            $port = $2;
            unless ( $self->ssrf_bypass ) {
                my ( $ip, $rp ) = resolve_and_pin( $host, $port );
                unless ( defined $ip ) {
                    $self->_emit_log( 'error', "UDP tracker blocked by SSRF policy: $host:$port" );
                    return;
                }
                $resolved_ip = $ip;
                $port        = $rp if defined $rp;
            }
            else {
                $resolved_ip = $host;
            }
            $socket = IO::Socket::IP->new( Proto => 'udp', Blocking => 0 ) or $self->_emit_log( 'error', "Could not create UDP socket: $!" );
        }
        else {
            $self->_emit_log( 'error', 'Invalid UDP tracker URL: ' . $self->url );
        }
    }

    method _new_transaction_id () {
        return $transaction_id = unpack( 'N', urandom(4) ) & 0x7FFFFFFF;
    }

    method _is_connected () {
        return defined $connection_id && ( time() - $connection_id_time < 60 );
    }

    method tick ( $delta = 0.1 ) {
        return unless $socket;

        # Check for incoming data
        while ( $socket->recv( my $buf, 4096 ) ) {
            my $sender_addr = $socket->peeraddr();
            if ( defined $sender_addr && defined $resolved_ip ) {
                my $sender_ip   = unpack( 'N', $sender_addr );
                my $expected_ip = unpack( 'N', inet_aton($resolved_ip) );
                if ( defined $expected_ip && $sender_ip ne $expected_ip ) {
                    $self->_emit_log( 'debug', 'UDP tracker response from unexpected sender, ignoring' );
                    next;
                }
            }
            $self->receive_data($buf);
        }

        # Handle retransmissions
        my $now = time();
        for my $tid ( keys %pending_transactions ) {
            my $entry   = $pending_transactions{$tid};
            my $timeout = 15 * ( 2**$entry->{retries} );
            if ( $now - $entry->{timestamp} > $timeout ) {
                if ( $entry->{retries} >= 8 ) {
                    $self->_emit_log( 'error', "UDP transaction $tid timed out after 8 retries" );
                    delete $pending_transactions{$tid};
                    next;
                }
                $entry->{retries}++;
                $entry->{timestamp} = $now;
                $self->_send_packet( $entry->{payload} );
            }
        }
    }

    method receive_data ($data) {
        return if length($data) < 8;
        my ( $action, $tid ) = unpack( 'N N', $data );
        my $entry = delete $pending_transactions{$tid};
        if ( !$entry ) {
            $self->_emit_log( 'debug', 'Received UDP packet with unknown transaction ID: ' . $tid );
            return;
        }
        try {
            if ( $action == 3 ) {    # Error
                my $msg = substr( $data, 8 );
                $msg =~ s/[^\x20-\x7E]/./g;    # Sanitize: replace non-printable with dot
                $self->_emit_log( 'error', 'UDP Tracker error: ' . $msg );
                return;
            }
            if ( $entry->{type} eq 'connect' ) {
                if (HAS_64BIT) {
                    ( undef, undef, $connection_id ) = unpack( 'N N Q>', $data );
                }
                else {
                    $connection_id = substr( $data, 8, 8 );
                }
                $connection_id_time = time();

                # Now that we are connected, trigger the original request
                if ( $entry->{on_connect} ) {
                    $entry->{on_connect}->();
                }
            }
            elsif ( $entry->{type} eq 'announce' ) {
                my $res = $self->parse_announce_response($data);
                $entry->{cb}->($res) if $entry->{cb};
            }
            elsif ( $entry->{type} eq 'scrape' ) {
                my $res = $self->parse_scrape_response( $data, $entry->{num_hashes} );
                $entry->{cb}->($res) if $entry->{cb};
            }
        }
        catch ($e) {
            $self->_emit_log( 'error', 'Error parsing UDP tracker response: ' . $e );
        }
    }

    method _send_packet ($payload) {
        return unless $socket;
        my $target_ip = $resolved_ip // $host;
        my $dest      = sockaddr_in( $port, inet_aton($target_ip) );
        my $sent      = $socket->send( $payload, 0, $dest );
        $self->_emit_log( 'warn', "UDP send failed: $!" ) unless defined $sent;
        return $sent;
    }

    method build_connect_packet () {
        my $tid = $self->_new_transaction_id();
        if (HAS_64BIT) {
            no warnings 'portable';
            return ( $tid, pack( 'Q> N N', 0x41727101980, 0, $tid ) );
        }
        return ( $tid, pack( 'NN N N', 0x417, 0x27101980, 0, $tid ) );
    }

    method perform_announce ( $params, $cb = undef ) {
        if ( scalar keys %pending_transactions >= MAX_PENDING_TRANSACTIONS ) {
            $self->_emit_log( 'warn', 'UDP tracker pending transaction limit reached' );
            return;
        }
        if ( !$self->_is_connected() ) {
            my ( $tid, $pkt ) = $self->build_connect_packet();
            $pending_transactions{$tid} = {
                type       => 'connect',
                payload    => $pkt,
                retries    => 0,
                timestamp  => time(),
                on_connect => sub { $self->perform_announce( $params, $cb ) },
            };
            $self->_send_packet($pkt);
            return;
        }
        my $pkt = $self->build_announce_packet($params);
        return unless $pkt;
        my ($tid) = unpack( 'x8 N', $pkt );    # transaction_id is at offset 12 but after action(4)

        # Wait, action(4) tid(4). So offset 12 is correct for cid(8) + action(4).
        $tid = unpack( 'N', substr( $pkt, 12, 4 ) );
        $pending_transactions{$tid} = { type => 'announce', payload => $pkt, retries => 0, timestamp => time(), cb => $cb, };
        $self->_send_packet($pkt);
    }

    method perform_scrape ( $infohashes, $cb = undef ) {
        if ( scalar keys %pending_transactions >= MAX_PENDING_TRANSACTIONS ) {
            $self->_emit_log( 'warn', 'UDP tracker pending transaction limit reached' );
            return;
        }
        if ( !$self->_is_connected() ) {
            my ( $tid, $pkt ) = $self->build_connect_packet();
            $pending_transactions{$tid} = {
                type       => 'connect',
                payload    => $pkt,
                retries    => 0,
                timestamp  => time(),
                on_connect => sub { $self->perform_scrape( $infohashes, $cb ) }
            };
            $self->_send_packet($pkt);
            return;
        }
        my $pkt = $self->build_scrape_packet($infohashes);
        my $tid = unpack( 'N', substr( $pkt, 12, 4 ) );
        $pending_transactions{$tid}
            = { type => 'scrape', payload => $pkt, retries => 0, timestamp => time(), cb => $cb, num_hashes => scalar @$infohashes, };
        $self->_send_packet($pkt);
    }

    method build_announce_packet ($params) {
        $self->_new_transaction_id();
        my %event_map = ( none => 0, completed => 1, started => 2, stopped => 3, );
        my $event     = $event_map{ $params->{event} // 'none' } // 0;
        my $ih        = $params->{info_hash};
        my $ih_len    = length($ih);

        # Mandatory key for tracker identification
        my $key = $params->{key} // ( unpack( 'N', urandom(4) ) & 0x7FFFFFFF );

        # BEP 52: Support 32-byte infohashes
        # For UDP trackers, we use the v1 infohash if available,
        # or truncate/hash the v2 one as per common practice if 32 bytes provided.
        # REAL BEP 52 UDP trackers expect a modified layout, but standard ones
        # usually get the 20-byte 'info_hash' (v1 or truncated).
        my $ih_20 = length($ih) == 32 ? sha1($ih)                            : $ih;
        my $tmpl  = HAS_64BIT         ? 'Q> N N a20 a20 Q> Q> Q> N N N l> n' : 'a8 N N a20 a20 NN NN NN N N N l> n';
        return pack(
            $tmpl, $connection_id, 1, $transaction_id, $ih_20, $params->{peer_id}, _split64( $params->{downloaded} // 0 ),
            _split64( $params->{left} // 0 ), _split64( $params->{uploaded} // 0 ), $event, 0,    # ip
            $key, $params->{num_want} // -1, $params->{port}
        );
    }

    method parse_announce_response ($data) {
        return { interval => 0, leechers => 0, seeders => 0, peers => [] } if length($data) < 20;
        my ( $action, $tid, $interval, $leechers, $seeders ) = unpack( 'N N N N N', $data );
        my $peers_raw = substr( $data, 20 );

        # Cap peer list: max 500 peers per response (UDP datagram is ~4096 bytes anyway)
        my $peers;
        if ( length($peers_raw) % 18 == 0 && length($peers_raw) % 6 != 0 ) {
            $peers_raw = substr( $peers_raw, 0, 500 * 18 );
            $peers     = Net::BitTorrent::Protocol::BEP23::unpack_peers_ipv6($peers_raw);
        }
        else {
            $peers_raw = substr( $peers_raw, 0, 500 * 6 );
            $peers     = Net::BitTorrent::Protocol::BEP23::unpack_peers_ipv4($peers_raw);
        }
        return { interval => $interval, leechers => $leechers, seeders => $seeders, peers => $peers, };
    }

    method build_scrape_packet ($infohashes) {
        $self->_new_transaction_id();
        my @capped = @$infohashes[ 0 .. ( @$infohashes > 70 ? 69 : $#$infohashes ) ];

        # Validate and truncate each hash to 20 bytes
        my $ih_data = join( '', map { length($_) == 32 ? sha1($_) : substr( $_, 0, 20 ) } @capped );
        my $tmpl    = HAS_64BIT ? 'Q> N N a*' : 'a8 N N a*';
        return pack( $tmpl, $connection_id, 2, $transaction_id, $ih_data );
    }

    method parse_scrape_response ( $data, $num_hashes ) {
        return { files => [] } if length($data) < 8;
        my ( $action, $tid ) = unpack( 'N N', $data );
        my $results    = { files => [] };
        my $max_hashes = int( ( length($data) - 8 ) / 12 );
        $num_hashes = $max_hashes if $num_hashes > $max_hashes;
        for ( my $i = 0; $i < $num_hashes; $i++ ) {
            my ( $seeders, $completed, $leechers ) = unpack( 'N N N', substr( $data, 8 + ( $i * 12 ), 12 ) );
            push @{ $results->{files} }, { seeders => $seeders, completed => $completed, leechers => $leechers };
        }
        return $results;
    }
};
1;
