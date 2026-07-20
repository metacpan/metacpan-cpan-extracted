use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
my @CRC32C_TABLE;

sub _init_table {
    return if @CRC32C_TABLE;
    for my $i ( 0 .. 255 ) {
        my $res = $i;
        $res = ( $res & 1 ) ? ( $res >> 1 ) ^ 0x82F63B78 : ( $res >> 1 ) for 1 .. 8;
        $CRC32C_TABLE[$i] = $res & 0xFFFFFFFF;
    }
}
#
_init_table();
#
class Net::BitTorrent::DHT::Security v2.1.0 {
    use Socket qw[inet_aton inet_pton AF_INET AF_INET6];
    use Crypt::URandom qw[urandom];

    method _crc32c ($data) {
        my $crc = 0xFFFFFFFF;
        $crc = ( $crc >> 8 ) ^ $CRC32C_TABLE[ ( $crc ^ $_ ) & 0xFF ] for unpack 'C*', $data;
        return ( $crc ^ 0xFFFFFFFF ) & 0xFFFFFFFF;
    }

    method generate_node_id ( $ip, $seed //= undef ) {
        $seed //= unpack( 'C', urandom(1) );
        my $ip_bin;
        my @v4_mask   = ( 0x03, 0x0f, 0x3f, 0xff );
        my @v6_mask   = ( 0x01, 0x03, 0x07, 0x0f, 0x1f, 0x3f, 0x7f, 0xff );
        my $ip_masked = '';
        if ( $ip !~ /:/ ) {
            $ip_bin = inet_aton($ip);
            return undef unless defined $ip_bin && length($ip_bin) == 4;
            my @bytes = unpack( 'C*', $ip_bin );
            $bytes[$_] &= $v4_mask[$_] for 0 .. 3;
            $ip_masked = pack( 'C*', @bytes );
        }
        else {
            $ip_bin = inet_pton( AF_INET6, $ip );
            return undef unless defined $ip_bin && length($ip_bin) == 16;
            my @bytes = unpack( 'C*', $ip_bin );
            $bytes[$_] &= $v6_mask[$_] for 0 .. 7;
            $ip_masked = pack 'C*', @bytes[ 0 .. 7 ];
        }
        my $input = $ip_masked . chr( $seed & 0x07 );
        my $crc   = $self->_crc32c($input);
        my @id;
        $id[0]  = ( $crc >> 24 ) & 0xFF;
        $id[1]  = ( $crc >> 16 ) & 0xFF;
        $id[2]  = ( ( $crc >> 8 ) & 0xF8 ) | ( unpack( 'C', urandom(1) ) & 0x07 );
        $id[$_] = unpack( 'C', urandom(1) ) for 3 .. 18;
        $id[19] = $seed & 0xFF;
        pack 'C*', @id;
    }

    method validate_node_id ( $id_bin, $ip ) {
        return 1 if !$ip;    # Can't validate without IP
        my $seed        = unpack 'C', substr $id_bin, 19, 1;
        my $expected_id = $self->generate_node_id( $ip, $seed );

        # Compare first 21 bits
        my @id  = unpack( 'C*', $id_bin );
        my @exp = unpack( 'C*', $expected_id );
        return 0 if $id[0] != $exp[0];
        return 0 if $id[1] != $exp[1];
        return 0 if ( $id[2] & 0xF8 ) != ( $exp[2] & 0xF8 );
        return 1;
    }
};
#
1;
