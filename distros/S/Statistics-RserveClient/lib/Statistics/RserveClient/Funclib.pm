#* Rserve client for Perl
#* Supports Rserve protocol 0103 only (used by Rserve 0.5 and higher)
#* $Revision$
#* @author Djun Kim
#* Based on Clément TURBELIN's PHP client.
#* Licensed under #GPL v2 or at your option v3

#
# * Read byte from a binary packed format @see Rserve protocol
# * @param string $buf buffer
# * @param int $o offset

#use strict;

package Statistics::RserveClient::Funclib;

our $VERSION = '0.12'; #VERSION

use Exporter;

our @EXPORT = qw( _rserve_make_packet int8 );


#sub int8($buf, $o = 0) {
sub int8($$) {
    my $buf = shift;
    my $o   = shift;

    $o = defined($o) ? $o : 0;

    my @buf = @$buf;

    # print "buf = "; foreach (@buf) {print "[" . $_ . "]"}; print "\n";
    # print "o = $o\n";

    return ord( $buf[$o] );
}

#
# * Read an integer from a 24 bits binary packed format @see Rserve protocol
# * @param string $buf buffer
# * @param int $o offset

#sub int24($b, $o = 0) {
sub int24($$) {
    my $b   = shift;
    my $o   = shift;
    my @buf = @$b;
    $o = defined($o) ? $o : 0;
    return (
        ord( $buf[$o] ) | ( ord( $buf[ $o + 1 ] ) << 8 )
            | ( ord( $buf[ $o + 2 ] ) << 16 ) );
}

# * Read an integer from a 32 bits binary packed format @see Rserve protocol
# * @param string $buf buffer
# * @param int $o offset
#sub int32($buf, $o=0) {
sub int32(@) {
    my $buf    = shift;
    my $offset = shift;

    $offset = defined($offset) ? $offset : 0;

    my @buf = @$buf;

    # foreach (@buf) {print "[". $_ . "]"}; print "\n";

    # print "offset = $offset\n";

    #print "0:" . ord($buf[$offset]) . "\n";
    #print "1:" . (ord($buf[$offset+1]) << 8) . "\n";
    #print "2:" . (ord($buf[$offset+2]) << 16) . "\n";
    #print "3:" . (ord($buf[$offset+3]) << 24) . "\n";

    return (
        ord( $buf[$offset] ) | ( ord( $buf[ $offset + 1 ] ) << 8 )
            | ( ord( $buf[ $offset + 2 ] ) << 16 )
            | ( ord( $buf[ $offset + 3 ] ) << 24 ) );
}

# One Byte
# @param $i
sub mkint8($) {
    my $i = shift;
    return chr( $i & 255 );
}

# * Make a binary representation of integer using 32 bits
# * @param int $i
# * @return string
sub mkint32($) {
    my $i = shift;
    my $r = chr( $i & 255 );
    $i >>= 8;
    $r .= chr( $i & 255 );
    $i >>= 8;
    $r .= chr( $i & 255 );
    $i >>= 8;
    $r .= chr( $i & 255 );
    return $r;
}

# * Create a 24 bit integer
# * @return string binary representation of the int using 24 bits

sub mkint24($) {
    my $i = shift;
    my $r = chr( $i & 255 );
    $i >>= 8;
    $r .= chr( $i & 255 );
    $i >>= 8;
    $r .= chr( $i & 255 );
    return $r;
}

# * Create a 24 bit integer
# * @return string binary representation of the int using 24 bits

sub mkint24b($) {
    my $i = shift;
    my @r;
    $r[0] = $i & 255;
    $i >>= 8;
    $r[1] = $i & 255;
    $i >>= 8;
    $r[2] = $i & 255;
    return @r;
}

#
# * Create a binary representation of float to 64bits
# * TODO: works only for intel endianess, should be adapted for no big endian proc
# * @param double $v

sub mkfloat64($) {
    my $v = shift;
    return pack( 'd', $v );
}

# * 64bit integer to Float
# * @param $buf
# * @param $o

#sub flt64($buf, $o = 0) {
sub flt64($$) {
    my ( $b, $o ) = @_;
    $o = defined($o) ? $o : 0;

    my @buf = @$b;

    my @ss = @buf[ $o .. ( $o + 7 ) ];

    #	if (Rserve_Connection::$machine_is_bigendian) {
    if ( Statistics::RserveClient::Connection::machine_is_bigendian() ) {
        for ( my $k = 0; $k < 7; $k++ ) {
            $ss[ 7 - $k ] = $buf[ $o + $k ];
        }
    }

    my $r = unpack( 'd', join( '', @ss ) );
    return $r + 0;
}

# * Create a packet for QAP1 message
# * @param int $cmd command identifier
# * @param string $string contents of the message

#sub _rserve_make_packet($cmd, $string) {
sub _rserve_make_packet($$) {
    my $cmd    = shift;
    my $string = shift;
    #$n = length($string) + 1;

    $string .= chr(0);
    my $n = length($string);

    # print "cmd: $cmd; string: $string, n=$n\n";

    # take next largest muliple of 4 to pad out string length
    $n = $n + ( ( $n % 4 ) ? ( 4 - $n % 4 ) : 0 );

    #print "n = $n\n";
    #print "string = $string\n";
    my @len24 = mkint24b($n);

    #foreach (@len24) {print "[". $_ . "]";}; print "\n";
    #print "len len24 = " . length(@len24) . "\n";

    # [0]  (int) command
    # [4]  (int) length of the message (bits 0-31)
    # [8]  (int) offset of the data part
    # [12] (int) length of the message (bits 32-63)
    my $pkt = pack( "V V V V C C3 A$n",
        ( $cmd, $n + 4, 0, 0, 4, $len24[0], $len24[1], $len24[2], $string ) );

    #my @p = split ('', $pkt);
    #for ($i = 0; $i < @p; $i++) {
    #  print ("[$i:" . $p[$i] . ":" . ord($p[$i]) . "] ");
    #}
    #print "\n";

    #print "packed pkt:". unpack("V V V V C C3 A$n", $pkt) . "\n";
    return $pkt;
#return (mkint32($cmd), mkint32($n + 4), mkint32(0), mkint32(0), chr(4), mkint24($n), $string);
}

# * Make a data packet
# * @param unknown_type $type
# * @param unknown_type $string NULL terminated string

#sub _rserve_make_data($type, $string) {
sub _rserve_make_data($$) {
    my ( $type, $string ) = shift;

    my $s        = '';
    my $len      = length($string);    # Length of the binary string
    my $is_large = $len > 0xfffff0;
    my $pad      = 0;                  # Number of padding needed
    while ( ( $len & 3 ) != 0 ) {
        # ensure the data packet size is divisible by 4
        ++$len;
        ++$pad;
    }
    $s .= chr( $type & 255 )
        | ( $is_large ? Statistics::RserveClient::Connection::DT_LARGE : 0 );
    $s .= chr( $len & 255 );
    $s .= chr( ( $len & 0xff00 ) >> 8 );
    $s .= chr( ( $len & 0xff0000 ) >> 16 );
    if ($is_large) {
        $s .= chr( ( $len & 0xff000000 ) >> 24 ) . chr(0) . chr(0) . chr(0);
    }
    $s .= $string;
    if ($pad) {
        $s .= str_repeat( chr(0), $pad );
    }
}

# * Parse a Rserve packet from socket connection
# * @param unknown_type $socket

sub _rserve_get_response($) {
    my $socket = shift;
    my $buf;

    my $n = socket_recv( $socket, $buf, 16, 0 );
    if ( $n != 16 ) {
        return FALSE;
    }
    my $len = int32( $buf, 4 );
    my $ltg = $len;
    my $b2;
    while ( $ltg > 0 ) {
        $n = socket_recv( $socket, $b2, $ltg, 0 );
        if ( $n > 0 ) {
	    $buf .= $b2;
            unset($b2);
            $ltg -= $n;
        }
        else {
            last;
        }
    }
    return $buf;
}

1;
