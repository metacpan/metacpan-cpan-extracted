use v5.40;
use feature 'class';
no warnings 'experimental::class';

class Net::BitTorrent::DHT::Peer {
    field $ip     : param : reader;
    field $port   : param : reader;
    field $family : param : reader;
    method to_string () {"$ip:$port"}
}
class Net::BitTorrent::DHT v2.0.0 {
    use Algorithm::Kademlia;
    use Net::BitTorrent::DHT::Security;
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
    use IO::Socket::IP;
    use Socket
        qw[sockaddr_family pack_sockaddr_in unpack_sockaddr_in inet_aton inet_ntoa AF_INET AF_INET6 pack_sockaddr_in6 unpack_sockaddr_in6 inet_pton inet_ntop getaddrinfo SOCK_DGRAM];
    use IO::Select;
    use Digest::SHA qw[sha1];
    #
    field $node_id_bin : param : reader;
    field $port             : param : reader = 6881;
    field $address          : param = undef;
    field $want_v4          : param = 1;
    field $want_v6          : param = 1;
    field $bep32            : param : reader = 1;
    field $bep42            : param : reader = 1;
    field $bep33            : param : reader = 1;
    field $bep44            : param : reader = 1;
    field $read_only        : param  = 0;
    field $security         : reader = Net::BitTorrent::DHT::Security->new();
    field $routing_table_v4 : reader = Algorithm::Kademlia::RoutingTable->new( local_id_bin => $node_id_bin, k => 8 );
    field $routing_table_v6 : reader = Algorithm::Kademlia::RoutingTable->new( local_id_bin => $node_id_bin, k => 8 );
    field $peer_storage     : reader = Algorithm::Kademlia::Storage->new( ttl => 7200 );
    field $data_storage     : reader = Algorithm::Kademlia::Storage->new( ttl => 7200 );
    field $socket           : param : reader //= IO::Socket::IP->new( LocalAddr => $address, LocalPort => $port, Proto => 'udp', Blocking => 0 );
    field $select //= IO::Select->new($socket);
    field $token_secret     = pack( 'N', rand( 2**32 ) ) . pack( 'N', rand( 2**32 ) );
    field $token_old_secret = $token_secret;
    field $last_rotation    = time();
    field $boot_nodes : param : reader : writer //= [ [ 'router.bittorrent.com', 6881 ], [ 'router.utorrent.com', 6881 ],
        [ 'dht.transmissionbt.com', 6881 ], [ 'dht.aelitis.com', 6881 ] ];
    field $v : param : reader //= ();
    field $_ed25519_backend = ();
    field $running          = 0;
    #
    ADJUST {
        $socket // die "Could not create UDP socket: $!";
        if ($bep44) {
            if ( eval { require Crypt::PK::Ed25519; 1 } ) {
                $_ed25519_backend = method( $sig, $msg, $key ) {
                    my $ed = Crypt::PK::Ed25519->new();
                    $ed->import_key_raw( $key, 'public' );
                    $ed->verify_message( $sig, $msg );
                }
            }
            elsif ( eval { require Crypt::Perl::Ed25519::PublicKey; 1 } ) {
                $_ed25519_backend = method( $sig, $msg, $key ) {
                    Crypt::Perl::Ed25519::PublicKey->new($key)->verify( $msg, $sig )
                }
            }
        }
    }
    method routing_table () {$routing_table_v4}    # Backward compatibility

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
        $node_id_bin = $state->{id} if defined $state->{id};
        if ( $state->{nodes} ) {
            my @to_import = map { { id => $_->{id}, data => { ip => $_->{ip}, port => $_->{port} } } } $state->{nodes}->@*;
            $routing_table_v4->import_peers( \@to_import );
        }
        if ( $state->{nodes6} ) {
            my @to_import = map { { id => $_->{id}, data => { ip => $_->{ip}, port => $_->{port} } } } $state->{nodes6}->@*;
            $routing_table_v6->import_peers( \@to_import );
        }
        if ( $state->{peers} ) {
            for my $hash ( keys $state->{peers}->%* ) {
                $peer_storage->put( $hash, $state->{peers}{$hash}{value} );
            }
        }
        if ( $state->{data} ) {
            for my $hash ( keys $state->{data}->%* ) {
                $data_storage->put( $hash, $state->{data}{$hash} );
            }
        }
    }

    method _rotate_tokens () {
        if ( time() - $last_rotation > 300 ) {
            $token_old_secret = $token_secret;
            $token_secret     = pack( 'N', rand( 2**32 ) ) . pack( 'N', rand( 2**32 ) );
            $last_rotation    = time();
        }
    }

    method _generate_token ( $ip, $secret = undef ) {
        $secret //= $token_secret;
        return sha1( $ip . $secret );
    }

    method _verify_token ( $ip, $token ) {
        return 1 if $token eq $self->_generate_token( $ip, $token_secret );
        return 1 if $token eq $self->_generate_token( $ip, $token_old_secret );
        return 0;
    }

    method bootstrap () {
        for my $r (@$boot_nodes) {
            $self->ping( $r->@* );
            $self->find_node_remote( $node_id_bin, $r->@* );
        }
    }

    method ping ( $addr, $port ) {
        $self->_send( { t => 'pn', y => 'q', q => 'ping', a => { id => $node_id_bin } }, $addr, $port );
    }

    method find_node_remote ( $target_id, $addr, $port ) {
        $self->_send( { t => 'fn', y => 'q', q => 'find_node', a => { id => $node_id_bin, target => $target_id } }, $addr, $port );
    }

    method get_peers ( $info_hash, $addr, $port ) {
        $self->_send( { t => 'gp', y => 'q', q => 'get_peers', a => { id => $node_id_bin, info_hash => $info_hash } }, $addr, $port );
    }

    method get_remote ( $target, $addr, $port ) {
        return unless $bep44;
        $self->_send( { t => 'gt', y => 'q', q => 'get', a => { id => $node_id_bin, target => $target } }, $addr, $port );
    }

    method put_remote ( $args, $addr, $port ) {
        return unless $bep44;

        # $args should contain 'v' and optionally 'k', 'sig', 'seq', 'salt', 'cas'
        $self->_send( { t => 'pt', y => 'q', q => 'put', a => { id => $node_id_bin, %$args } }, $addr, $port );
    }

    method announce_peer ( $info_hash, $token, $announce_port, $addr, $port, $is_seed //= 0 ) {
        my $msg = {
            t => 'ap',
            y => 'q',
            q => 'announce_peer',
            a => { id => $node_id_bin, info_hash => $info_hash, port => $announce_port, token => $token, ( $bep33 && $is_seed ? ( seed => 1 ) : () ) }
        };
        $self->_send( $msg, $addr, $port );
    }

    method scrape_peers_remote ( $info_hash, $addr, $port ) {
        return unless $bep33;
        $self->_send( { t => 'sp', y => 'q', q => 'scrape_peers', a => { id => $node_id_bin, info_hash => $info_hash } }, $addr, $port );
    }

    method sample_infohashes_remote ( $target, $addr, $port ) {
        $self->_send( { t => 'si', y => 'q', q => 'sample_infohashes', a => { id => $node_id_bin, target => $target } }, $addr, $port );
    }

    method tick ( $timeout //= 0 ) {
        $self->_rotate_tokens();
        return $self->handle_incoming() if $select->can_read($timeout);
        return ( [], [], undef );
    }

    method handle_incoming () {
        my $sender = $socket->recv( my $data, 4096 );
        return ( [], [], undef ) unless defined $data && length $data;
        my $msg = eval { bdecode($data) };
        return ( [], [], undef ) if $@ || ref($msg) ne 'HASH';
        my ( $port, $ip ) = $self->_unpack_address($sender);
        return ( [], [], undef ) unless $ip;
        if ( ( $msg->{y} // '' ) eq 'q' ) {
            my $node = $self->_handle_query( $msg, $sender, $ip, $port );

            # Return flat format
            return ( $node ? [$node] : [], [], undef );
        }
        elsif ( $msg->{y} eq 'r' ) {
            return $self->_handle_response( $msg, $sender, $ip, $port );
        }
        return ( [], [], undef );
    }

    method _unpack_address ($sockaddr) {
        my $family = eval { sockaddr_family($sockaddr) } // return ();
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
        my $q  = $msg->{q} // return;
        my $a  = $msg->{a} // return;
        my $id = $a->{id}  // return;

        # BEP 42: Reject nodes with invalid IDs
        return if $bep42 && !$security->validate_node_id( $id, $ip );
        my $table = ( $ip =~ /:/ ) ? $routing_table_v6 : $routing_table_v4;
        unless ( $a->{ro} ) {
            my $stale = $table->add_peer( $id, { ip => $ip, port => $port } );
            $self->ping( $stale->{data}{ip}, $stale->{data}{port} ) if $stale;
        }
        my $res = { t => $msg->{t}, y => 'r', r => { id => $node_id_bin } };
        $res->{v} = $v if defined $v;
        if    ( $q eq 'ping' ) { }
        elsif ( $q eq 'find_node' ) {
            my @closest;
            push @closest, $routing_table_v4->find_closest( $a->{target} ) if $want_v4;
            push @closest, $routing_table_v6->find_closest( $a->{target} ) if $want_v6 && $bep32;
            my ( $v4, $v6 ) = $self->_pack_nodes( \@closest );
            $res->{r}{nodes}  = $v4 if $v4 && $want_v4;
            $res->{r}{nodes6} = $v6 if $v6 && $want_v6 && $bep32;
        }
        elsif ( $q eq 'get_peers' ) {
            my $info_hash = $a->{info_hash};
            $res->{r}{token} = $self->_generate_token($ip);
            my $peers = $peer_storage->get($info_hash);
            if ( $peers && @$peers ) {
                my @filtered = grep { ( $_->{ip} =~ /:/ ) ? $want_v6 : $want_v4 } @$peers;
                $res->{r}{values} = $self->_pack_peers_raw( \@filtered );
            }
            else {
                my @closest;
                push @closest, $routing_table_v4->find_closest($info_hash) if $want_v4;
                push @closest, $routing_table_v6->find_closest($info_hash) if $want_v6 && $bep32;
                my ( $v4, $v6 ) = $self->_pack_nodes( \@closest );
                $res->{r}{nodes}  = $v4 if $v4 && $want_v4;
                $res->{r}{nodes6} = $v6 if $v6 && $want_v6 && $bep32;
            }
        }
        elsif ( $q eq 'announce_peer' ) {
            my $info_hash = $a->{info_hash};
            if ( $self->_verify_token( $ip, $a->{token} ) ) {
                my $peers    = $peer_storage->get($info_hash) // [];
                my $new_peer = {
                    ip => $ip,
                    port => ( $a->{implied_port} ? $port : $a->{port} ),
                    ( $bep33 && defined $a->{seed} ? ( seed => $a->{seed} ) : () )
                };
                @$peers = grep { $_->{ip} ne $ip } @$peers;
                push @$peers, $new_peer;
                $peer_storage->put( $info_hash, $peers );
            }
        }
        elsif ( $q eq 'scrape_peers' ) {
            if ($bep33) {
                my $info_hash = $a->{info_hash};
                my $peers     = $peer_storage->get($info_hash) // [];
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
                my $data   = $data_storage->get($target);
                if ($data) {
                    $res->{r} = { %{ $res->{r} }, %$data };
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
                my $v          = $a->{v};
                my $target     = sha1($v);
                my $is_mutable = defined $a->{k};
                if ($is_mutable) {
                    $target = sha1( $a->{k} . ( $a->{salt} // '' ) );

                    # Validate signature
                    my $to_sign = '';
                    $to_sign .= 'salt' . length( $a->{salt} ) . ':' . $a->{salt} if defined $a->{salt};
                    $to_sign .= 'seqi' . $a->{seq} . 'e';
                    $to_sign .= 'v' . length($v) . ':' . $v;
                    if ( defined $_ed25519_backend && $_ed25519_backend->( $self, $a->{sig}, $to_sign, $a->{k} ) ) {
                        my $existing = $data_storage->get($target);
                        if ( !$existing || $a->{seq} > $existing->{seq} ) {
                            if ( !defined $a->{cas} || ( $existing && $existing->{seq} == $a->{cas} ) ) {
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
                }
                else {    # Immutable
                    $data_storage->put( $target, { v => $v } );
                }
            }
        }
        elsif ( $q eq 'sample_infohashes' ) {
            my $target   = $a->{target};
            my %entries  = $peer_storage->entries;
            my @all_keys = keys %entries;
            my $num      = scalar @all_keys;

            # BEP 51: return up to 20 samples closest to target
            my @sorted  = sort { ( $a^.$target ) cmp( $b^.$target ) } @all_keys;
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
        $self->_send_raw( bencode($res), $sender );
        return { id => $id, ip => $ip, port => $port };
    }

    method _handle_response ( $msg, $sender, $ip, $port ) {
        my $r = $msg->{r};
        return ( [], [], undef ) unless $r && $r->{id};
        if ( $bep42 && !$security->validate_node_id( $r->{id}, $ip ) ) {
            return ( [], [], undef );
        }
        my $table = ( $ip =~ /:/ ) ? $routing_table_v6 : $routing_table_v4;
        my $stale = $table->add_peer( $r->{id}, { ip => $ip, port => $port } );
        $self->ping( $stale->{data}{ip}, $stale->{data}{port} ) if $stale;
        my $peers = [];
        if ( $r->{values} ) {
            $peers = $self->_unpack_peers( $r->{values} );
        }
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
        $scrape = { id => $r->{id}, ip => $ip, port => $port, sn => $r->{sn}, ln => $r->{ln} } if ( $msg->{t} // '' ) eq 'sp';
        my $data;
        if ( ( $msg->{t} // '' ) eq 'gt' && defined $r->{v} ) {
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
        if ( ( $msg->{t} // '' ) eq 'si' && defined $r->{samples} ) {
            my @samples;
            my $blob = $r->{samples};
            push @samples, substr( $blob, 0, 20, '' ) while length($blob) >= 20;
            $sample = { id => $r->{id}, ip => $ip, port => $port, samples => \@samples, num => $r->{num}, interval => $r->{interval} };
        }
        my $token_only;
        $token_only = { id => $r->{id}, ip => $ip, port => $port, token => $r->{token} } if defined $r->{token} && !$data;
        return ( \@learned, $peers, $scrape // $data // $sample // $token_only );
    }

    method _send ( $msg, $addr, $port ) {
        $msg->{v}     = $v if defined $v;
        $msg->{a}{ro} = 1  if $read_only && $msg->{y} eq 'q';
        my ( $err, @res ) = getaddrinfo( $addr, $port, { socktype => SOCK_DGRAM } );
        return if $err || !@res;
        for my $res (@res) {
            my $family = sockaddr_family( $res->{addr} );
            if ( $family == AF_INET && $want_v4 ) {
                $self->_send_raw( bencode($msg), $res->{addr} );
            }
            elsif ( $family == AF_INET6 && $want_v6 ) {
                $self->_send_raw( bencode($msg), $res->{addr} );
            }
        }
    }
    method _send_raw ( $data, $dest ) { $socket->send( $data, 0, $dest ) }

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
        while ( length($blob) >= $stride ) {
            my $chunk  = substr( $blob,  0,  $stride, '' );
            my $id     = substr( $chunk, 0,  20 );
            my $ip_bin = substr( $chunk, 20, $ip_len );
            my $port   = unpack( 'n', substr( $chunk, 20 + $ip_len, 2 ) );
            my $ip     = ( $family == AF_INET ) ? inet_ntoa($ip_bin) : inet_ntop( AF_INET6, $ip_bin );
            push @nodes, { id => $id, ip => $ip, port => $port };
        }
        return \@nodes;
    }

    method _unpack_peers ($list) {
        my @peers;
        my @blobs = ( ref($list) eq 'ARRAY' ) ? @$list : ($list);
        for my $blob (@blobs) {
            while ( length($blob) >= 6 ) {
                if ( length($blob) % 18 == 0 ) {
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

    method run () {
        $running = 1;
        $self->bootstrap();
        $self->tick(1) while $running;
    }
};
1;
