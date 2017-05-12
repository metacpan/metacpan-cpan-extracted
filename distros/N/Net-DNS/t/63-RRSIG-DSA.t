# $Id: 63-RRSIG-DSA.t 1360 2015-06-15 09:58:53Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my @prerequisite = qw(
		MIME::Base64
		Time::Local
		Net::DNS::RR::RRSIG
		Net::DNS::SEC
		Net::DNS::SEC::DSA
		Crypt::OpenSSL::DSA
		Digest::SHA
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 7;

use_ok('Net::DNS::SEC');


my $ksk = new Net::DNS::RR <<'END';
DSA.example.	IN	DNSKEY	257 3 3 (
	CKrKbLrir4slVXYFrA4Y8Rik/UxzkCo1Rp0Spz907VrJL8u3I/YKTTvoMh/GL2n3/NL/KgzNRWb8
	pLB3FIWHjXXhn3r3sbld180DI4tv98CZKr86UDP0UUHVE/DkkEZw5PAy2nyhhKTJRvbR4ZT0OSZY
	+GZA2hIzmMYk4gR2mwa3jCmAGqw2i0OtAYzSOe06uoELZLl96kRsFk69OcQxzrDKz5BEZZpNBpfZ
	UBk/CRPDxBE2xjJkq3VpehAUCMOFpPQlEuW2D6CNuIbJY5pNpOF3RF17vkvxQx6678ZLIN3PdeG/
	nGwoJJArbt7Y/q+b/NxnIu6RwApE40p/7pOq6qKcqPVU2oHR/N7oNiyHnh68gSonUFfy5lETiyw8
	vDaJS/JhC2WQKzxxBo4oa/KFXFAd6NR6bE5h5XRWWqZvm2sBgcy+sKTbKcR4PDvaAoMguBjDeigm
	/NV6phNbARV926NyQZOi5uUeBYA16v1KnUll7A3I9wt3ykVIbx0WqB4Ozzk2PF/3vH3wudO5bL72
	zK1Yox60 ; Key ID = 53264
	)
END

ok( $ksk, 'set up DSA public ksk' );


my $keyfile = $ksk->privatekeyname;

END { unlink($keyfile) if defined $keyfile; }

open( KSK, ">$keyfile" ) or die "$keyfile $!";
print KSK <<'END';
Private-key-format: v1.2
Algorithm: 3 (DSA)
Prime(p): kCo1Rp0Spz907VrJL8u3I/YKTTvoMh/GL2n3/NL/KgzNRWb8pLB3FIWHjXXhn3r3sbld180DI4tv98CZKr86UDP0UUHVE/DkkEZw5PAy2nyhhKTJRvbR4ZT0OSZY+GZA2hIzmMYk4gR2mwa3jCmAGqw2i0OtAYzSOe06uoELZLk=
Subprime(q): qspsuuKviyVVdgWsDhjxGKT9THM=
Base(g): fepEbBZOvTnEMc6wys+QRGWaTQaX2VAZPwkTw8QRNsYyZKt1aXoQFAjDhaT0JRLltg+gjbiGyWOaTaThd0Rde75L8UMeuu/GSyDdz3Xhv5xsKCSQK27e2P6vm/zcZyLukcAKRONKf+6TquqinKj1VNqB0fze6DYsh54evIEqJ1A=
Private_value(x): drOKJBTwCM0O9U6tpIgymGyBrao=
Public_value(y): V/LmUROLLDy8NolL8mELZZArPHEGjihr8oVcUB3o1HpsTmHldFZapm+bawGBzL6wpNspxHg8O9oCgyC4GMN6KCb81XqmE1sBFX3bo3JBk6Lm5R4FgDXq/UqdSWXsDcj3C3fKRUhvHRaoHg7POTY8X/e8ffC507lsvvbMrVijHrQ=
END
close(KSK);


my $key = new Net::DNS::RR <<'END';
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

ok( $key, 'set up DSA public key' );


my @rrset = ( $key, $ksk );
my $rrsig = create Net::DNS::RR::RRSIG( \@rrset, $keyfile );
ok( $rrsig, 'create RRSIG over rrset using private ksk' );

my $verify = $rrsig->verify( \@rrset, $ksk );
ok( $verify, 'verify RRSIG over rrset using public ksk' ) || diag $rrsig->vrfyerrstr;

ok( !$rrsig->verify( \@rrset, $key ), 'verify fails using wrong key' );

my @badrrset = ($key);
ok( !$rrsig->verify( \@badrrset, $ksk ), 'verify fails using wrong rrset' );


exit;

__END__

