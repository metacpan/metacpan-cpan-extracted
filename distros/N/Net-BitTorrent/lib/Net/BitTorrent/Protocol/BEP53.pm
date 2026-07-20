use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Net::BitTorrent::Emitter;
#
class Net::BitTorrent::Protocol::BEP53 v2.1.0 : isa(Net::BitTorrent::Emitter) {
    use URI::Escape qw[uri_unescape uri_escape];
    #
    field $infohash_v1 : reader : param = undef;
    field $infohash_v2 : reader : param = undef;
    field $trackers    : reader : param = [];
    field $name        : reader : param = undef;
    field $nodes       : reader : param = [];      # DHT bootstrap nodes (x.pe)

    #
    sub parse ( $class, $uri ) {
        die 'Not a magnet URI' unless $uri =~ /^magnet:\?/;
        my %params;
        my $query = substr( $uri, 8 );
        for my $pair ( split( /[&;]/, $query ) ) {
            my ( $key, $val ) = split( /=/, $pair, 2 );
            next unless defined $key && defined $val;
            $val = uri_unescape($val);
            push @{ $params{$key} }, $val;
        }
        my ( $v1, $v2 );
        for my $xt ( @{ $params{xt} // [] } ) {
            if ( $xt =~ /^urn:btih:([a-fA-F0-9]{40})$/ ) {
                $v1 = pack( 'H*', $1 );
            }
            elsif ( $xt =~ /^urn:btih:([a-zA-Z2-7]{32})$/ ) {

                # Base32 encoded (v1)
                $v1 = _decode_base32($1);
            }
            elsif ( $xt =~ /^urn:btmh:1220([a-fA-F0-9]{64})$/ ) {

                # BEP 53 v2 (multihash SHA-256)
                $v2 = pack( 'H*', $1 );
            }
        }
        return $class->new(
            infohash_v1 => $v1,
            infohash_v2 => $v2,
            trackers    => ( $params{tr}     // [] ),
            name        => ( $params{dn}[0]  // undef ),
            nodes       => ( $params{'x.pe'} // [] ),
        );
    }

    sub _decode_base32 ($str) {
        $str = uc($str);
        my $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
        my %map;
        @map{ split //, $alphabet } = 0 .. 31;
        my $buffer = 0;
        my $bits   = 0;
        my $res    = '';
        for my $char ( split //, $str ) {
            next unless exists $map{$char};
            $buffer = ( $buffer << 5 ) | $map{$char};
            $bits += 5;
            if ( $bits >= 8 ) {
                $bits -= 8;
                $res .= chr( ( $buffer >> $bits ) & 0xFF );
                $buffer &= ( 1 << $bits ) - 1;
            }
        }
        return $res;
    }

    method to_string () {
        my @pairs;
        push @pairs, 'xt=urn:btih:' . unpack( 'H*', $infohash_v1 )     if $infohash_v1;
        push @pairs, 'xt=urn:btmh:1220' . unpack( 'H*', $infohash_v2 ) if $infohash_v2;
        push @pairs, 'dn=' . uri_escape($name)                         if defined $name;
        push @pairs, 'tr=' . uri_escape($_)   for @$trackers;
        push @pairs, 'x.pe=' . uri_escape($_) for @$nodes;
        'magnet:?' . join( '&', @pairs );
    }
};
#
1;
