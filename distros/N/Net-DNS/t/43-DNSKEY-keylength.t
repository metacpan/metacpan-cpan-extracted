# $Id: 43-DNSKEY-keylength.t 1367 2015-06-29 08:53:56Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		MIME::Base64
		Net::DNS::RR::DNSKEY;
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 9;


my $rsa = new Net::DNS::RR <<'END';
RSASHA1.example.	IN	DNSKEY	256 3 5 (
	AwEAAZHbngk6sMoFHN8fsYY6bmGR4B9UYJIqDp+mORLEH53Xg0f6RMDtfx+H3/x7bHTUikTr26bV
	AqsxOs2KxyJ2Xx9RGG0DB9O4gpANljtTq2tLjvaQknhJpSq9vj4CqUtr6Wu152J2aQYITBoQLHDV
	i8mIIunparIKDmhy8TclVXg9 ; Key ID = 1623
	)
END

ok( $rsa, 'set up RSA public key' );

is( $rsa->keylength, 1024, 'RSA keylength has expected value' );

my $longformat = pack 'xn a*', unpack 'C a*', $rsa->keybin;
$rsa->keybin($longformat);
is( $rsa->keylength, 1024, 'keylength for long format RSA key' );


my $dsa = new Net::DNS::RR <<'END';
DSA.example.	IN	DNSKEY	256 3 3 (
	CMKzsCaT2Jy1w/sPdpigEE+nbeJ/x5C6cruWvStVum6/YulcR7MHeujx9c2iBDbo3kW4X8/l+qgk
	7ZEZ+yV5lphWtJMmMtOHIU+YdAhgLpt84NKhcupWL8wfuBW/97cqIv5Z+51fwn0YEAcZsoCrE0nL
	5+31VfkK9LTNuVo38hsbWa3eWZFalID5NesF6sJRgXZoAyeAH46EQVCq1UBnnaHslvSDkdb+Z1kT
	bMQ64ZVI/sBRXRbqIcDlXVZurCTDV7JL9KZwwfeyrQcnVyYh5mdHPsXbpX5NQJvoqPgvRZWBpP4h
	pjkAm9UrUbow9maPCQ1JQ3JuiU5buh9cjAI+QIyGMujKLT2OsogSZD2IFUciaZBL/rSe0gmAUv0q
	XrczmIYFUCoRGZ6+lKVqQQ6f2U7Gsr6zRbeJN+JCVD6BJ52zjLUaWUPHbakhZb/wMO7roX/tnA/w
	zoDYBIIF7yuRYWblgPXBJTK2Bp07xre8lKCRbzY4J/VXZFziZgHgcn9tkHnrfov04UG9zlWEdT6X
	E/60HjrP ; Key ID = 53244
	)
END

ok( $dsa, 'set up DSA public key' );

is( $dsa->keylength, 1024, 'DSA keylength has expected value' );


my $eccgost = new Net::DNS::RR <<'END';
ECC-GOST.example.	IN	DNSKEY	256 3 12 (
	6VwgNT1BXxXNVpTQXcJQ82PcsCYmI60oN88Plbl028ruvl6DqJby/uBGULHT5FXmZiXBJozE6kP0
	+BirN9YPBQ== ; Key ID = 46387
	)
END

ok( $eccgost, 'set up ECC-GOST public key' );

is( $eccgost->keylength, 256, 'ECC-GOST keylength has expected value' );


my $ecdsa = new Net::DNS::RR <<'END';
ECDSAP256SHA256.example.	IN	DNSKEY	256 3 13 (
	7Y4BZY1g9uzBwt3OZexWk7iWfkiOt0PZ5o7EMip0KBNxlBD+Z58uWutYZIMolsW8v/3rfgac45lO
	IikBZK4KZg== ; Key ID = 44222
	)
END

ok( $ecdsa, 'set up ECDSA public key' );

is( $ecdsa->keylength, 256, 'ECDSA keylength has expected value' );


exit;

__END__


