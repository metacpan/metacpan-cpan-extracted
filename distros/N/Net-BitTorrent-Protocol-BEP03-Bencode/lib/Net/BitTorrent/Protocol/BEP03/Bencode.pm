package Net::BitTorrent::Protocol::BEP03::Bencode v2.0.1 {
    use v5.40;
    use parent 'Exporter';
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[bencode bdecode] ], bencode => [] );

    sub bencode ( $ref //= return ) {
        return ( ( ( length $ref ) && $ref =~ m[^([-\+][1-9])?\d*$] ) ? ( 'i' . $ref . 'e' ) : ( length($ref) . ':' . $ref ) ) if !ref $ref;
        return join( '', 'l', ( map { bencode($_) } @{$ref} ),                                                           'e' ) if ref $ref eq 'ARRAY';
        return join( '', 'd', ( map { length($_) . ':' . $_ . bencode( $ref->{$_} ) } sort { $a cmp $b } keys %{$ref} ), 'e' ) if ref $ref eq 'HASH';
        return '';
    }

    sub bdecode( $string //= return, $k //= 0 ) {
        my ( $return, $leftover );
        if ( $string =~ s[^(0+|[1-9]\d*):][] ) {
            my $size = $1;
            $return = '' if $size =~ m[^0+$];
            $return .= substr( $string, 0, $size, '' );
            return if length $return < $size;
            return $k ? ( $return, $string ) : $return;    # byte string
        }
        elsif ( $string =~ s[^i([-\+]?\d+)e][] ) {         # integer
            my $int = $1;
            $int = () if $int =~ m[^-0] || $int =~ m[^0\d+];
            return $k ? ( $int, $string ) : $int;
        }
        elsif ( $string =~ s[^l(.*)][]s ) {                # list
            $leftover = $1;
            while ( $leftover and $leftover !~ s[^e][]s ) {
                ( my ($piece), $leftover ) = bdecode( $leftover, 1 );
                push @$return, $piece;
            }
            return $k ? ( \@$return, $leftover ) : \@$return;
        }
        elsif ( $string =~ s[^d(.*)][]s ) {                # dictionary
            $leftover = $1;
            my $pkey;
            while ( $leftover and $leftover !~ s[^e][]s ) {
                my ( $key, $value );
                ( $key, $leftover ) = bdecode( $leftover, 1 );
                ( $value, $leftover ) = bdecode( $leftover, 1 ) if $leftover;
                die 'malformed dictionary' if defined $pkey && defined $key && $pkey gt $key;    # BEP52
                $return->{$key} = $value if defined $key;
                $pkey           = $key   if defined $key;
            }
            return $k ? ( \%$return, $leftover ) : \%$return;
        }
        return;
    }
}
1;
