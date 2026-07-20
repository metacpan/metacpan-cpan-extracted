package Net::BitTorrent::SSRF v2.1.0 {
    use v5.40;
    use Exporter qw[import];
    use Socket   qw[inet_pton inet_ntop AF_INET AF_INET6 AF_UNSPEC SOCK_STREAM getaddrinfo getnameinfo NI_NUMERICHOST];
    our @EXPORT_OK = qw[is_safe_ip is_safe_host is_safe_url resolve_and_pin];

    # This should honestly be part of a dist all on its own...
    sub is_safe_ip ($ip) {
        my $packed = inet_pton( AF_INET, $ip );
        if ($packed) {
            my @o = unpack( 'C4', $packed );
            return 0 if $o[0] == 127;                                  # 127.0.0.0/8
            return 0 if $o[0] == 10;                                   # 10.0.0.0/8
            return 0 if $o[0] == 172 && $o[1] >= 16 && $o[1] <= 31;    # 172.16.0.0/12
            return 0 if $o[0] == 192 && $o[1] == 168;                  # 192.168.0.0/16
            return 0 if $o[0] == 169 && $o[1] == 254;                  # 169.254.0.0/16
            return 0 if ( $o[0] & 0xF0 ) == 224;                       # 224.0.0.0/4 multicast
            return 0 if $o[0] == 0;                                    # 0.0.0.0
            return 1;
        }
        $packed = inet_pton( AF_INET6, $ip );
        if ($packed) {
            my @w = unpack( 'n8', $packed );
            return 0 if $packed eq ( "\0" x 15 ) . "\1";                                            # ::1
            return 0 if $packed eq "\0" x 16;                                                       # ::
            return 0 if ( $w[0] & 0xFFC0 ) == 0xFE80;                                               # fe80::/10 link-local
            return 0 if ( $w[0] & 0xFE00 ) == 0xFC00;                                               # fc00::/7 ULA
            return 0 if ( $w[0] & 0xFF00 ) == 0xFF00;                                               # ff00::/8 multicast
            return 0 if $w[0] == 0 && $w[1] == 0 && $w[2] == 0 && $w[3] == 0 && $w[5] == 0xFFFF;    # ::ffff:0:0/96 IPv4-mapped
            return 1;
        }
        return 0;
    }

    sub is_safe_host ($host) {
        return 0 unless defined $host && length $host;
        return is_safe_ip($host) if is_safe_ip($host);
        my ( $err, @results ) = getaddrinfo( $host, undef, { family => AF_UNSPEC, socktype => SOCK_STREAM } );
        return 0 if $err || !@results;
        for my $res (@results) {
            my ( $gerr, $ip ) = getnameinfo( $res->{addr}, NI_NUMERICHOST );
            return 0 if $gerr || !defined $ip || !is_safe_ip($ip);
        }
        return 1;
    }

    sub is_safe_url ($url) {
        require URI;
        my $uri  = URI->new($url);
        my $host = $uri->host;
        return is_safe_host($host);
    }

    sub resolve_and_pin ( $host, $port = undef ) {
        return ( $host, $port ) if is_safe_ip($host);
        my ( $err, @results ) = getaddrinfo( $host, $port, { family => AF_UNSPEC, socktype => SOCK_STREAM } );
        return () if $err || !@results;
        for my $res (@results) {
            my ( $gerr, $ip ) = getnameinfo( $res->{addr}, NI_NUMERICHOST );
            next if $gerr || !defined $ip;
            next unless is_safe_ip($ip);
            my $resolved_port = $res->{port} // $port;
            return ( $ip, $resolved_port );
        }
        return ();
    }
};
1;
