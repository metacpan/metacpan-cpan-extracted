# $Id: 42-DNSKEY-flags.t 1367 2015-06-29 08:53:56Z willem $	-*-perl-*-
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

plan tests => 16;


my $dnskey = new Net::DNS::RR <<'END';
RSASHA1.example.	IN	DNSKEY	256 3 5 (
	AwEAAZHbngk6sMoFHN8fsYY6bmGR4B9UYJIqDp+mORLEH53Xg0f6RMDtfx+H3/x7bHTUikTr26bV
	AqsxOs2KxyJ2Xx9RGG0DB9O4gpANljtTq2tLjvaQknhJpSq9vj4CqUtr6Wu152J2aQYITBoQLHDV
	i8mIIunparIKDmhy8TclVXg9 ; Key ID = 1623
	)
END

ok( $dnskey, 'set up DNSKEY record' );

$dnskey->flags(0);
foreach my $flag ( qw(sep zone revoke) ) {
	my $boolean = $dnskey->$flag(0);
	ok( !$boolean, "Boolean $flag flag has expected value" );

	my $keytag = $dnskey->keytag;
	$dnskey->$flag( !$boolean );
	ok( $dnskey->$flag, "Boolean $flag flag toggled" );
	isnt( $dnskey->keytag, $keytag, "keytag recalculated using modified $flag flag" );

	$dnskey->$flag($boolean);
	ok( !$dnskey->$flag, "Boolean $flag flag restored" );

	is( $dnskey->keytag, $keytag, "keytag recalculated using restored $flag flag" );
}

exit;

__END__


