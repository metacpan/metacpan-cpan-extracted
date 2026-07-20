use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Net::BitTorrent::Emitter;
class Net::BitTorrent::Tracker::WebSeed v2.1.0 : isa(Net::BitTorrent::Emitter) {
    use HTTP::Tiny;
    use Net::BitTorrent::SSRF qw[is_safe_url];
    field $url : param : reader;                                  # Base URL
    field $disabled : reader = !is_safe_url($url);
    use constant MAX_WEEDSEED_RESPONSE    => 16 * 1024 * 1024;    # 16 MB max per piece response
    use constant MAX_WEEDSEED_SINGLE_RESP => 16 * 1024 * 1024;    # 16 MB max per single HTTP response

    method fetch_piece ($segments) {
        return undef if $disabled;
        my $http      = HTTP::Tiny->new( max_redirect => 0, max_size => MAX_WEEDSEED_SINGLE_RESP );
        my $full_data = '';
        for my $seg (@$segments) {
            my $target_url = $self->_build_url($seg);
            unless ( is_safe_url($target_url) ) {
                $self->_emit_log( 'warn', 'URL blocked by SSRF policy: ' . $target_url );
                return undef;
            }
            my $response;
            for ( 1 .. 5 ) {
                $response = $http->get( $target_url, { headers => { Range => "bytes=$seg->{offset}-" . ( $seg->{offset} + $seg->{length} - 1 ) } } );
                last unless ( $response->{status} // '' ) =~ /^3/;
                my $loc = $response->{headers}{location} // '';
                unless ( is_safe_url($loc) ) {
                    $self->_emit_log( 'warn', 'Redirect blocked by SSRF policy: ' . $loc );
                    return undef;
                }
                $target_url = $loc;
            }
            if ( $response->{success} ) {
                $full_data .= $response->{content} // '';
                if ( length($full_data) > MAX_WEEDSEED_RESPONSE ) {
                    $self->_emit_log( 'warn', 'WebSeed response exceeded max size, aborting' );
                    return undef;
                }
            }
            elsif ( $response->{status} == 410 ) {
                $disabled = 1;
                $self->_emit_log( 'warn', "Resource 410 Gone: $target_url. Disabling webseed." );
                return undef;
            }
            else {
                $self->_emit_log( 'error', "WebSeed fetch failed: $response->{status} $response->{reason} (URL: $target_url)" );
                return undef;
            }
        }
        return $full_data;
    }

    method _build_url ($seg) {
        my $target_url = $url;
        if ( $target_url =~ m{/$} ) {
            my $rel = $seg->{rel_path} // $seg->{file}->path->basename;
            $rel =~ s{\\}{/}g;    # Normalize backslashes
            $rel =~ s{/+}{/}g;    # Collapse multiple slashes
            $rel =~ s{^/}{};      # Remove leading slash
            my @parts = grep { $_ ne '' && $_ ne '.' && $_ ne '..' } split /\//, $rel;
            $rel = join( '/', @parts );
            $target_url .= $rel;
        }
        return $target_url;
    }

    # Backward compatibility for single-file v1
    method fetch_piece_legacy ( $index, $piece_length, $total_size ) {
        my $start = $index * $piece_length;
        my $end   = $start + $piece_length - 1;
        $end = $total_size - 1 if $end >= $total_size;
        return $self->fetch_piece( [ { file => undef, offset => $start, length => ( $end - $start + 1 ), rel_path => undef } ] );
    }
};
1;
