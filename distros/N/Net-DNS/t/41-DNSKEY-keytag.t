# $Id: 41-DNSKEY-keytag.t 1352 2015-06-02 08:13:13Z willem $	-*-perl-*-
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

plan tests => 4;


my $key = new Net::DNS::RR <<'END';
RSASHA1.example.	IN	DNSKEY	256 3 5 (
	AwEAAZHbngk6sMoFHN8fsYY6bmGR4B9UYJIqDp+mORLEH53Xg0f6RMDtfx+H3/x7bHTUikTr26bV
	AqsxOs2KxyJ2Xx9RGG0DB9O4gpANljtTq2tLjvaQknhJpSq9vj4CqUtr6Wu152J2aQYITBoQLHDV
	i8mIIunparIKDmhy8TclVXg9 ; Key ID = 1623
	)
END

ok( $key, 'set up DNSKEY record' );


my $keytag = $key->keytag;
is( $keytag, 1623, 'numerical keytag has expected value' );


my $newkey = <<'END';
	AwEAAcNz+cEA/Zkl/8u5/kfJKPNSbmXbdMpk6jM4bMWTEhZlaEOJE+GYsbM+HvjMgEMz00eDpvDR
	XEMl1o4x60SgW8ap44deky/KAYzDC80rIZrvjDx8DPzF3yIikrGc8P7Eq+0zbWrYyiHRg5DllIT4
	5NCz6EMtji1RQloWCaXuAzCN
END

my $keybin = $key->keybin;
$key->key($newkey);
isnt( $key->keytag, $keytag, 'keytag recalculated from modified key' );


$key->keybin($keybin);
is( $key->keytag, $keytag, 'keytag recalculated from restored key' );


exit;

__END__


