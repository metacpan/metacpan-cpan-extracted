package Net::OpenID::JanRain::CryptUtil;

# vi:ts=4:sw=4

use warnings;
use strict;

use Carp;
use POSIX qw(ceil);

use Digest::HMAC_SHA1;
use Digest::SHA1;

use Math::BigInt lib => 'GMP'; #without GMP Diffie Hellman takes a LONG time
use Net::OpenID::JanRain::Util qw( toBase64 fromBase64 );
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	hmacSha1
	sha1
    numToBytes
    numToBase64
    bytesToNum
    base64ToNum
	randomString
    DEFAULT_DH_MOD
    DEFAULT_DH_GEN
	);

use constant {
    DEFAULT_DH_MOD => "155172898181473697471232257763715539915724801966915404479707795314057629378541917580651227423698188993727816152646631438561595825688188889951272158842675419950341258706556549803580104870537681476726513255747040765857479291291572334510643245094715007229621094194349783925984760375594985848253359305585439638443",
    DEFAULT_DH_GEN => 2,
    };

# We need a Cryptographic strength source of randomness
# /dev/urandom will work nicely.
# output will be biased as 0..255 % len(chrs)
# i.e. unbiased if len(chrs) is a power of two
sub randomString {
    my ($length, $chrs) = @_;
    my $s = "";

    if (-e "/dev/urandom") {
        my ($ur, $randomness, $got);
        open $ur, "< /dev/urandom";
        $got = sysread $ur, $randomness, $length;
        die "Couldn't get enough of /dev/urandom" unless $got == $length;
        close $ur;
        if($chrs) {
            my @chrs = split(//, $chrs);
            my @rand = split(//, $randomness);
            for(my $i=0;$i<$length;$i++) {
                $s .= $chrs[ord($rand[$i]) % @chrs];
            }
        }
        else {
            $s = $randomness;
        }
        return $s;
    }
    else {
        # An attack using the predictability of rand is possible.
        # We strongly recommend using a system with a cryptographically
        # secure source of randomness to run our OpenID library.
        warn "No /dev/urandom - YOUR OPENID LIBRARY IS NOT SECURE!";
        die "Comment out this line to continue anyway";
        my ($length, $chrs) = @_;
        my $s = "";
        if($chrs) {
            my @chrs = split(//, $chrs);
            for(1..$length) {
                $s .= $chrs[int(rand(@chrs))];
            }
        }
        else {
            for(1..$length) {
                $s .= chr(int(rand(256)));
            }
        }
        return($s);
    } # end randomString
}
########################################################################

sub hmacSha1 {
	my ($key, $text) = @_;
	return(Digest::HMAC_SHA1::hmac_sha1($text, $key));
} # end hmacSha1
########################################################################
sub sha1 {
	my ($s) = @_;
    return(Digest::SHA1::sha1($s));
} # end sha1
########################################################################
sub numToBase64 {
    my ($n) = @_;
    return toBase64(numToBytes($n));
}
########################################################################
sub numToBytes {
    my ($n) = @_;
    if ($n < 0) {die "numToBytes takes only positive integers.";}
    my @bytes = ();
    # get a big-endian base 256 representation of n
    while ($n) {
        unshift( @bytes, $n % 256 );
        $n = $n >> 8;
    }
    # first byte high bit is the sign bit
    if ($bytes[0] > 127) {
        unshift( @bytes, 0);
    }
    my $string = pack('C*',@bytes);
    return $string;
}
########################################################################
sub base64ToNum {
    my ($b64str) = @_;
    return bytesToNum(fromBase64($b64str));
}
########################################################################
sub bytesToNum {
    my ($string) = @_;
    unless($string) {
        warn "empty string passed to bytesToNum";
        return 0;
    }
    my @bytes = unpack('C*',$string);
    my $n = Math::BigInt->new(0);
    # high bit set means negative in twos complement; invalid for us
    return undef if ($bytes[0] > 127);
    for (@bytes) {
        $n = $n << 8;
        $n = $n + $_;
    }
    return $n;
}
########################################################################
1;
