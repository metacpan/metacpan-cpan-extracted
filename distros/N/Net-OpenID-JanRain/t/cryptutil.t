#!/usr/bin/perl 

use Test::More tests => 105;
use Net::OpenID::JanRain::CryptUtil qw( hmacSha1
                                sha1
                                numToBase64
                                numToBytes
                                bytesToNum
                                base64ToNum
                                randomString );

use bignum;

sub testNumConvert {
    for $i (1..50) {
        $str1 = randomString($i);
        # twos complement rep ... first byte is null only if second byte
        # high bit is set
        $str1 = "x".$str1 if (ord($str1) == 0);
        $str1 = "\x00".$str1 if (ord($str1) > 127);
        $bignuma = bytesToNum($str1);
        $str2 = numToBytes($bignuma);
        is($str1, $str2, "numToBytes(bytesToNum(s_$i)) == s_$i");
        $bignumb = bytesToNum($str2);
        is(Math::BigInt::bcmp($bignuma, $bignumb), 0, "bytesToNum(numToBytes(n_$i)) == n_$i");
    }
}

sub charToHex {
    my ($s) = @_;
    my $i;
    my $h = "";
    for($i = 0; $i< length($s); $i++) {
        my $byten = unpack('C', substr($s, $i, 1));
        $lonybble = ($byten % 16) + 48; # ascii 0 is 48
        $lonybble += 7 if $lonybble >= 58; # ascii 9 is 57. A is 65
        $hinybble = (($byten >> 4) % 16) + 48;
        $hinybble += 7 if $hinybble >= 58;
        $nybbles = pack('C', $hinybble) . pack('C', $lonybble);
        $h = $h.$nybbles;
    }
    return $h;
}

sub hexToChar {
    my ($h) = @_;
    length($h) % 2 == 0 || die 'hexToChar passed odd-length string';
    my $s = "";
    for($i = 0; $i < length($h); $i += 2) {
        my $hinybble = unpack('C', substr($h, $i, 1));
        my $lonybble = unpack('C', substr($h, $i+1, 1));
        if ($hinybble >= 48 && $hinybble <= 57) { #0-9
            $hinybble -= 48;
            }
        elsif ($hinybble >= 65 && $hinybble <= 70) { #A-F
            $hinybble -= 55;
            }
        elsif ($hinybble >= 97 && $hinybble <= 102) { #a-f
            $hinybble -= 87;
            }
        else {
            warn "Unexpected character in hex string, code $hinybble";
        }
        if ($lonybble >= 48 && $lonybble <= 57) { #0-9
            $lonybble -= 48;
            }
        elsif ($lonybble >= 65 && $lonybble <= 70) { #A-F
            $lonybble -= 55;
            }
        elsif ($lonybble >= 97 && $lonybble <= 102) { #a-f
            $lonybble -= 87;
            }
        else {
            warn "Unexpected character in hex string, code $lonybble";
        }
        $byte = ($hinybble * 16) + $lonybble;
        $s = $s.pack('C', $byte);
    }
    return $s;
}
#from rfc2202: Test Cases for HMAC-MD5 and HMAC-SHA-1
@test_cases = (
{
number =>        1,
key =>           hexToChar('0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b'),
key_len =>       20,
data =>          "Hi There",
data_len =>      8,
digest =>        hexToChar('b617318655057264e28bc0b6fb378c8ef146be00'),
},
{
number =>        2,
key =>           "Jefe",
key_len =>       4,
data =>          "what do ya want for nothing?",
data_len =>      28,
digest =>        hexToChar('effcdf6ae5eb2fa2d27416d5f184df9c259a7c79'),
},
{
number =>        3,
key =>           hexToChar('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
key_len =>       20,
data =>          hexToChar('dd' x 50),
data_len =>      50,
digest =>        hexToChar('125d7342b9ac11cd91a39af48aa17b4f63f175d3'),
},
{
number =>        4,
key =>           hexToChar('0102030405060708090a0b0c0d0e0f10111213141516171819'),
key_len =>       25,
data =>          hexToChar('cd' x 50),
data_len =>      50,
digest =>        hexToChar('4c9007f4026250c6bc8414f9bf50c86c2d7235da'),
},
{
number =>        5,
key =>           hexToChar('0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c'),
key_len =>       20,
data =>          "Test With Truncation",
data_len =>      20,
digest =>        hexToChar('4c1a03424b55e07fe7f27be1d58bb9324a9a5a04'),
}
);

sub testHmacSha1 {
    my $i = 1;
    foreach (@test_cases) {
        %t = %$_;
        is(hmacSha1($t{key}, $t{data}), $t{digest}, "HMAC-SHA1 test $i");
        $i++;
    }
}

testHmacSha1();
testNumConvert();
exit(0);
