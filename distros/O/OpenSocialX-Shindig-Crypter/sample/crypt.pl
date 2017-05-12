#!/usr/bin/perl

use strict;
use warnings;
use MIME::Base64;
use Crypt::CBC;
use Digest::SHA;

my $str    = 'o=1&v=3&p=5';
my $cipher = Crypt::CBC->new(
    {
        'key'         => 'length16length16',
        'cipher'      => 'Rijndael',
        'iv'          => '1234567890abcdef',
        'literal_key' => 1,
        'padding'     => 'null',
        'header'      => 'none',
        keysize       => 128 / 8
    }
);
my $encrypted = $cipher->encrypt($str);
print "encrypted: " . encode_base64($encrypted) . "\n";
print "decrypted: " . $cipher->decrypt($encrypted) . "\n";

my $hmac = Digest::SHA::hmac_sha1( $encrypted, 'hmackey' );
print "hmac: " . encode_base64($hmac) . "\n";
print "total: " . encode_base64( $encrypted . $hmac ) . "\n";

1;
