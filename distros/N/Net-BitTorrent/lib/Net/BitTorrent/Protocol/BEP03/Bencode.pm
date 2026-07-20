package Net::BitTorrent::Protocol::BEP03::Bencode v2.1.0 {
    use v5.40;
    use Exporter qw[import];
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[bencode bdecode] ], bencode => [] );
    #
    use constant MAX_BDECODE_DEPTH => 100;
    use constant MAX_STRING_SIZE   => 64 * 1024 * 1024;    # 64MB

    sub bencode ( $ref //= return ) {
        return ( ( ( length $ref ) && $ref =~ m[^([-\+][1-9])?\d*$] ) ? ( 'i' . $ref . 'e' ) : ( length($ref) . ':' . $ref ) ) if !ref $ref;
        return join( '', 'l', ( map { bencode($_) } @{$ref} ), 'e' )                                                           if ref $ref eq 'ARRAY';
        return join( '', 'd', ( map { length($_) . ':' . $_ . bencode( $ref->{$_} ) } sort { $a cmp $b } keys %{$ref} ), 'e' ) if ref $ref eq 'HASH';
        return '';
    }

    sub bdecode( $string //= return, $k //= 0, $depth = 0 ) {
        no warnings 'recursion';    # Let me deal with it.
        die 'bencode nesting depth limit exceeded (max ' . MAX_BDECODE_DEPTH . ' levels)' if $depth > MAX_BDECODE_DEPTH;
        my $return;
        if ( $string =~ s[^(0+|[1-9]\d*):][] ) {
            my $size = $1;
            die "bencode string too large ($size bytes, max " . MAX_STRING_SIZE . ')' if $size > MAX_STRING_SIZE;
            $return = ''                                                              if $size =~ m[^0+$];
            $return .= substr( $string, 0, $size, '' );
            return if length $return < $size;
            return $k ? ( $return, $string ) : $return;    # byte string
        }
        elsif ( $string =~ s[^i([-\+]?\d+)e][] ) {         # integer
            my $int = $1;
            $int = () if $int =~ m[^-0] || $int =~ m[^0\d+];
            return $k ? ( $int, $string ) : $int;
        }
        elsif ( $string =~ s[^l][]s ) {                    # list without greedy capture
            while ( $string and $string !~ s[^e][]s ) {
                ( my ($piece), $string ) = bdecode( $string, 1, $depth + 1 );
                push @$return, $piece;
            }
            return $k ? ( \@$return, $string ) : \@$return;
        }
        elsif ( $string =~ s[^d][]s ) {                    # dictionary without greedy capture
            my $pkey;
            while ( $string and $string !~ s[^e][]s ) {
                my ( $key, $value );
                ( $key, $string ) = bdecode( $string, 1, $depth + 1 );
                ( $value, $string ) = bdecode( $string, 1, $depth + 1 ) if $string;
                die 'malformed dictionary' if defined $pkey && defined $key && $pkey gt $key;    # BEP52
                $return->{$key} = $value if defined $key;
                $pkey           = $key   if defined $key;
            }
            return $k ? ( \%$return, $string ) : \%$return;
        }
        return;
    }
};
1;
