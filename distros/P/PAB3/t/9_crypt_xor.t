#!/usr/bin/perl

print "1..$tests\n";

$_pos = 1;

require PAB3::Crypt::XOR;
_check( 1 );

import PAB3::Crypt::XOR qw(:default);
_check( 1 );

$key = 'bla';
$plain = 'THIS IS A REAL PLAIN TEXT';

$cipher = &xor_encrypt( $key, $plain );
_check( $cipher );

$plain2 = &xor_decrypt( $key, $cipher );
_check( $plain eq $plain2 );

$cipher = &xor_encrypt_hex( $key, $plain );
_check( $cipher );

$plain2 = &xor_decrypt_hex( $key, $cipher );
_check( $plain eq $plain2 );

BEGIN {
	$tests = 6;
}

sub _check {
	my( $val ) = @_;
	print "" . ( $val ? "ok" : "fail" ) . " $_pos\n";
	$_pos ++;
}
