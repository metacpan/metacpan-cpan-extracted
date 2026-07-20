use v5.40;
use feature 'class', 'try';
no warnings 'experimental::class', 'experimental::try';
class Net::BitTorrent::Tracker::HTTP v2.1.0 : isa(Net::BitTorrent::Tracker::Base) {
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[bdecode];
    use Net::BitTorrent::Protocol::BEP23;
    use Net::BitTorrent::SSRF qw[is_safe_url is_safe_ip resolve_and_pin];
    use HTTP::Tiny;
    use URI;
    use URI::Escape qw[uri_escape];
    use constant MAX_TRACKER_RESPONSE_SIZE => 1024 * 1024;    # 1MB
    use constant MAX_TRACKER_PEERS         => 1000;           # Max peers from compact response

    method build_announce_url ($params) {
        my $full_url = $self->url;
        $full_url .= ( $full_url =~ /\?/ ? '&' : '?' );
        my @query;
        for my $key ( sort keys %$params ) {
            next if $key eq 'ua';
            my $val = $params->{$key} // '';
            if ( $key eq 'info_hash' || $key eq 'peer_id' ) {
                $val = join( '', map { sprintf( '%%%02x', ord($_) ) } split( '', $val ) );
            }
            else {
                $val = uri_escape($val);
            }
            push @query, "$key=$val";
        }
        return $full_url . join( '&', @query );
    }

    method build_scrape_url ($infohashes) {
        my $scrape_url = $self->url;
        if ( $scrape_url =~ /\/announce$/ ) {
            $scrape_url =~ s/\/announce$/\/scrape/;
        }
        my $full_url = $scrape_url;
        $full_url .= ( $scrape_url =~ /\?/ ? '&' : '?' );
        my @query;
        for my $ih (@$infohashes) {
            my $val = join( '', map { sprintf( '%%%02x', ord($_) ) } split( '', $ih ) );
            push @query, "info_hash=$val";
        }
        return $full_url . join( '&', @query );
    }

    method parse_response ($data) {
        my $dict;
        try { $dict = bdecode($data) }
        catch ($e) {
            $self->_emit_log( 'error', 'Malformed tracker response: ' . $e );
            return { failure_reason => 'Malformed tracker response: ' . $e };
        }
        if ( !defined $dict || ref $dict ne 'HASH' ) {
            return { failure_reason => 'Tracker response is not a valid dictionary' };
        }
        if ( $dict->{failure_reason} ) {
            $self->_emit_log( 'error', 'Tracker failure: ' . $dict->{failure_reason} );
            return $dict;
        }
        if ( defined $dict->{peers} && !ref $dict->{peers} ) {
            try { $dict->{peers} = Net::BitTorrent::Protocol::BEP23::unpack_peers_ipv4( $dict->{peers} ) }
            catch ($e) {
                $self->_emit_log( 'error', 'Malformed compact IPv4 peer list: ' . $e );
                return { failure_reason => 'Malformed compact peer list: ' . $e };
            }
        }
        if ( defined $dict->{peers6} && !ref $dict->{peers6} ) {
            try {
                my $p6 = Net::BitTorrent::Protocol::BEP23::unpack_peers_ipv6( $dict->{peers6} );
                $dict->{peers} = [ @{ $dict->{peers} // [] }, @$p6 ];
            }
            catch ($e) {
                $self->_emit_log( 'error', 'Malformed compact IPv6 peer list: ' . $e );
                return { failure_reason => 'Malformed compact peer6 list: ' . $e };
            }
        }
        $dict->{peers} = [ @{ $dict->{peers} }[ 0 .. MAX_TRACKER_PEERS - 1 ] ]
            if ref $dict->{peers} eq 'ARRAY' && @{ $dict->{peers} } > MAX_TRACKER_PEERS;
        $dict->{peers} //= [];    # Ensure it is an array ref
        return $dict;
    }

    method perform_announce ( $params, $cb = undef ) {
        my $target = $self->build_announce_url($params);
        if ( !$self->ssrf_bypass && !is_safe_url($target) ) {
            $self->_emit_log( 'warn', 'HTTP announce blocked by SSRF policy: ' . $target );
            return undef;
        }

        # Resolve and pin the IP to prevent TOCTOU DNS rebinding.
        my $uri  = URI->new($target);
        my $host = $uri->host;
        my $port = $uri->port;
        if ( !$self->ssrf_bypass && $host && !is_safe_ip($host) ) {
            my ( $pinned_ip, $pinned_port ) = resolve_and_pin( $host, $port );
            if ( !defined $pinned_ip ) {
                $self->_emit_log( 'warn', 'HTTP announce DNS pinning failed (unsafe resolution): ' . $host );
                return undef;
            }
            unless ( is_safe_ip($pinned_ip) ) {
                $self->_emit_log( 'warn', 'HTTP announce pinned IP failed re-validation: ' . $pinned_ip );
                return undef;
            }
            $uri->host($pinned_ip);
            $uri->port($pinned_port) if defined $pinned_port;
            $target = $uri->as_string();
        }
        if ( $params->{ua} && $params->{ua}->can('get') ) {
            $params->{ua}->get(
                $target,
                sub ( $res, @ ) {
                    if ( $res->{success} ) {
                        if ( length( $res->{content} // '' ) > MAX_TRACKER_RESPONSE_SIZE ) {
                            $self->_emit_log( 'warn', 'Async tracker response exceeded max size' );
                            return;
                        }
                        try {
                            if ($cb) {
                                $cb->( $self->parse_response( $res->{content} ) );
                            }
                        }
                        catch ($e) {
                            $self->_emit_log( 'error', 'Error in HTTP announce callback: ' . $e );
                        }
                    }
                    else {
                        $self->_emit_log( 'error', "Async HTTP error during announce: $res->{status} $res->{reason}" );
                    }
                }
            );
            return;
        }
        my $http     = HTTP::Tiny->new( max_size => MAX_TRACKER_RESPONSE_SIZE );
        my $response = $http->get($target);
        if ( $response->{success} ) {
            my $parsed;
            try { $parsed = $self->parse_response( $response->{content} ) }
            catch ($e) {
                $self->_emit_log( 'error', "Error parsing tracker announce response: $e" );
                return { failure_reason => "Error parsing tracker response: $e" };
            }
            $cb->($parsed) if $cb;
            return $parsed;
        }
        else {
            $self->_emit_log( 'error', "HTTP error during announce: $response->{status} $response->{reason}" );
            return undef;
        }
    }

    method perform_scrape ( $infohashes, $cb = undef ) {
        my $target = $self->build_scrape_url($infohashes);
        if ( !$self->ssrf_bypass && !is_safe_url($target) ) {
            $self->_emit_log( 'warn', 'HTTP scrape blocked by SSRF policy: ' . $target );
            return undef;
        }

        # Resolve and pin the IP to prevent TOCTOU DNS rebinding.
        my $uri  = URI->new($target);
        my $host = $uri->host;
        my $port = $uri->port;
        if ( !$self->ssrf_bypass && $host && !is_safe_ip($host) ) {
            my ( $pinned_ip, $pinned_port ) = resolve_and_pin( $host, $port );
            if ( !defined $pinned_ip ) {
                $self->_emit_log( 'warn', 'HTTP scrape DNS pinning failed (unsafe resolution): ' . $host );
                return undef;
            }
            unless ( is_safe_ip($pinned_ip) ) {
                $self->_emit_log( 'warn', 'HTTP scrape pinned IP failed re-validation: ' . $pinned_ip );
                return undef;
            }
            $uri->host($pinned_ip);
            $uri->port($pinned_port) if defined $pinned_port;
            $target = $uri->as_string();
        }
        my $http     = HTTP::Tiny->new( max_size => MAX_TRACKER_RESPONSE_SIZE );
        my $response = $http->get($target);
        if ( $response->{success} ) {
            my $parsed;
            try { $parsed = bdecode( $response->{content} ) }
            catch ($e) {
                $self->_emit_log( 'error', 'Malformed HTTP scrape response: ' . $e );
                return undef;
            }
            if ( ref $parsed ne 'HASH' ) {
                $self->_emit_log( 'warn', 'HTTP scrape response is not a dictionary' );
                return undef;
            }
            $cb->($parsed) if $parsed;
            return $parsed;
        }
        else {
            $self->_emit_log( 'error', "HTTP scrape error: $response->{status} $response->{reason}" );
            return undef;
        }
    }
};
1;
