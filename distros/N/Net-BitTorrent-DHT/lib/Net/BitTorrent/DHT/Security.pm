use v5.40;
use experimental 'class';
my @CRC32C_TABLE;

sub _init_table {
    return if @CRC32C_TABLE;
    for my $i ( 0 .. 255 ) {
        my $res = $i;
        for ( 1 .. 8 ) {
            $res = ( $res & 1 ) ? ( $res >> 1 ) ^ 0x82F63B78 : ( $res >> 1 );
        }
        $CRC32C_TABLE[$i] = $res & 0xFFFFFFFF;
    }
}
_init_table();

class Net::BitTorrent::DHT::Security {
    use Socket qw(inet_aton inet_pton AF_INET AF_INET6);

    method _crc32c ($data) {
        my $crc = 0xFFFFFFFF;
        for my $byte ( unpack( 'C*', $data ) ) {
            $crc = ( $crc >> 8 ) ^ $CRC32C_TABLE[ ( $crc ^ $byte ) & 0xFF ];
        }
        return ( $crc ^ 0xFFFFFFFF ) & 0xFFFFFFFF;
    }

    method generate_node_id ( $ip, $seed = undef ) {
        $seed //= int( rand(256) );
        my $ip_bin;
        my @v4_mask   = ( 0x03, 0x0f, 0x3f, 0xff );
        my @v6_mask   = ( 0x01, 0x03, 0x07, 0x0f, 0x1f, 0x3f, 0x7f, 0xff );
        my $ip_masked = "";
        if ( $ip !~ /:/ ) {
            $ip_bin = inet_aton($ip);
            my @bytes = unpack( 'C*', $ip_bin );
            for my $i ( 0 .. 3 ) {
                $bytes[$i] &= $v4_mask[$i];
            }
            $ip_masked = pack( 'C*', @bytes );
        }
        else {
            $ip_bin = inet_pton( AF_INET6, $ip );
            my @bytes = unpack( 'C*', $ip_bin );
            for my $i ( 0 .. 7 ) {
                $bytes[$i] &= $v6_mask[$i];
            }
            $ip_masked = pack( 'C*', @bytes[ 0 .. 7 ] );
        }
        my $input = $ip_masked . chr( $seed & 0x07 );
        my $crc   = $self->_crc32c($input);
        my @id;
        $id[0] = ( $crc >> 24 ) & 0xFF;
        $id[1] = ( $crc >> 16 ) & 0xFF;
        $id[2] = ( ( $crc >> 8 ) & 0xF8 ) | ( int( rand(256) ) & 0x07 );
        for my $i ( 3 .. 18 ) {
            $id[$i] = int( rand(256) );
        }
        $id[19] = $seed & 0xFF;
        return pack( 'C*', @id );
    }

    method validate_node_id ( $id_bin, $ip ) {
        return 1 if !$ip;    # Can't validate without IP
        my $seed        = unpack( 'C', substr( $id_bin, 19, 1 ) );
        my $expected_id = $self->generate_node_id( $ip, $seed );

        # Compare first 21 bits
        my @id  = unpack( 'C*', $id_bin );
        my @exp = unpack( 'C*', $expected_id );
        return 0 if $id[0] != $exp[0];
        return 0 if $id[1] != $exp[1];
        return 0 if ( $id[2] & 0xF8 ) != ( $exp[2] & 0xF8 );
        return 1;
    }
}

=head1 NAME

Net::BitTorrent::DHT::Security - BEP 42 security extensions for BitTorrent DHT

=head1 SYNOPSIS

    use Net::BitTorrent::DHT::Security;
    my $sec = Net::BitTorrent::DHT::Security->new;

    my $id = $sec->generate_node_id("127.0.0.1");
    if ($sec->validate_node_id($id, "127.0.0.1")) {
        say "Node ID is valid for this IP";
    }

=head1 DESCRIPTION

This class implements the security extensions defined in BEP 42. It provides methods for generating and validating Node
IDs based on the node's IP address to prevent Sybil attacks and routing table poisoning.

=head2 CRC32c Implementation

This module includes a pure-Perl implementation of the CRC32c (Castagnoli) polynomial (0x82F63B78), which is required
by BEP 42 for Node ID calculation.

=head1 METHODS

=head2 generate_node_id( $ip, $seed? )

Generates a 20-byte Node ID compliant with BEP 42 for the given IP address. An optional 1-byte seed (0-255) can be
provided.

=head2 validate_node_id( $id, $ip )

Returns true if the provided Node ID is valid for the given IP address according to the BEP 42 criteria (matching the
first 21 bits of the ID).

=head1 SEE ALSO

BEP 42: L<http://www.bittorrent.org/beps/bep_0042.html>

=cut

1;
