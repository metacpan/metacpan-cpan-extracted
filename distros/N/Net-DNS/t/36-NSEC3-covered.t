# $Id: 36-NSEC3-covered.t 1682 2018-06-04 08:55:40Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		Digest::SHA
		Net::DNS::RR::NSEC3
		);

foreach my $package (@prerequisite) {
	next if eval "use $package; 1;";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 16;


## Tests based on example zone from RFC5155, Appendix A

my %H = (
	'example'       => '0p9mhaveqvm6t7vbl5lop2u3t2rp3tom',
	'ns1.example'   => '2t7b4g4vsa5smi47k61mv5bv1a22bojr',
	'x.y.w.example' => '2vptu5timamqttgl4luu9kg21e0aor3s',
	'a.example'     => '35mthgpgcu1qg68fab165klnsnk3dpvl',
	'x.w.example'   => 'b4um86eghhds6nea196smvmlo4ors995',
	'ai.example'    => 'gjeqe526plbf1g8mklp59enfd789njgi',
	'y.w.example'   => 'ji6neoaepv8b5o6k4ev33abha8ht9fgc',
	'w.example'     => 'k8udemvp1j2f7eg6jebps17vp3n8i58h',
	'ns2.example'   => 'q04jkcevqvmu85r014c7dkba38o0ji5r',
	'*.w.example'   => 'r53bq7cc2uvmubfu5ocmm6pers9tk9en',
	'xx.example'    => 't644ebqk9bibcna874givr6joj62mlhv',
);

my %name = reverse %H;
foreach ( sort keys %name ) { print "$_\t$name{$_}\n" }


## Exercise examples from RFC5155, Appendix B

ok( Net::DNS::RR->new("0p9mhaveqvm6t7vbl5lop2u3t2rp3tom.example. NSEC3 1 1 12 aabbccdd (
	2t7b4g4vsa5smi47k61mv5bv1a22bojr MX DNSKEY NS SOA NSEC3PARAM RRSIG )")->covered('a.c.x.w.example'),
	'B.1(1):	NSEC3 covers "next closer" name (c.x.w.example.)' );		# Name Error

ok( !Net::DNS::RR->new("b4um86eghhds6nea196smvmlo4ors995.example. NSEC3 1 1 12 aabbccdd (
	gjeqe526plbf1g8mklp59enfd789njgi MX RRSIG )")->covered('a.c.x.w.example'),
	'B.1(2):	NSEC3 matches closest encloser (x.w.example.)' );

ok( Net::DNS::RR->new("35mthgpgcu1qg68fab165klnsnk3dpvl.example. NSEC3 1 1 12 aabbccdd (
	b4um86eghhds6nea196smvmlo4ors995 NS DS RRSIG )")->covered('*.x.w.example'),
	'B.1(3):	NSEC3 covers wildcard at closest encloser (*.x.w.example.)' );


ok( !Net::DNS::RR->new("2t7b4g4vsa5smi47k61mv5bv1a22bojr.example. NSEC3 1 1 12 aabbccdd (
	2vptu5timamqttgl4luu9kg21e0aor3s A RRSIG )")->covered('ns1.example'),
	'B.2:	NSEC3 matches QNAME (ns1.example.) proving MX and CNAME absent' );	# No Data Error

ok( !Net::DNS::RR->new("ji6neoaepv8b5o6k4ev33abha8ht9fgc.example. NSEC3 1 1 12 aabbccdd (
	k8udemvp1j2f7eg6jebps17vp3n8i58h )")->covered('y.w.example'),
	'B.2.1:	NSEC3 matches QNAME (y.w.example.) proving A absent' );			# No Data, Empty Non-Terminal


ok( Net::DNS::RR->new("35mthgpgcu1qg68fab165klnsnk3dpvl.example. NSEC3 1 1 12 aabbccdd (
	b4um86eghhds6nea196smvmlo4ors995 NS DS RRSIG )")->covered('mc.c.example'),
	'B.3(1):	NSEC3 covers "next closer" name (c.example.)' );		# Referral to an Opt_Out Unsigned Zone

ok( !Net::DNS::RR->new("0p9mhaveqvm6t7vbl5lop2u3t2rp3tom.example. NSEC3 1 1 12 aabbccdd (
	2t7b4g4vsa5smi47k61mv5bv1a22bojr MX DNSKEY NS SOA NSEC3PARAM RRSIG )")->covered('mc.c.example'),
	'B.3(2):	NSEC3 matches closest provable encloser (example.)' );


ok( Net::DNS::RR->new("q04jkcevqvmu85r014c7dkba38o0ji5r.example. NSEC3 1 1 12 aabbccdd (
	r53bq7cc2uvmubfu5ocmm6pers9tk9en A RRSIG )")->covered('a.z.w.example'),
	'B.4:	NSEC3 covers "next closer" name (z.w.example.)' );			# Wildcard Expansion


ok( !Net::DNS::RR->new("k8udemvp1j2f7eg6jebps17vp3n8i58h.example. NSEC3 1 1 12 aabbccdd (
	kohar7mbb8dc2ce8a9qvl8hon4k53uhi )")->covered('a.z.w.example'),
	'B.5(1):	NSEC3 matches closest encloser (w.example.)' );			# Wildcard No Data Error

ok( Net::DNS::RR->new("q04jkcevqvmu85r014c7dkba38o0ji5r.example. NSEC3 1 1 12 aabbccdd (
	r53bq7cc2uvmubfu5ocmm6pers9tk9en A RRSIG )")->covered('a.z.w.example'),
	'B.5(2):	NSEC3 covers "next closer" name (z.w.example.)' );

ok( !Net::DNS::RR->new("r53bq7cc2uvmubfu5ocmm6pers9tk9en.example. NSEC3 1 1 12 aabbccdd (
	t644ebqk9bibcna874givr6joj62mlhv MX RRSIG )")->covered('*.w.example'),
	'B.5(3):	NSEC3 matches wildcard at closest encloser (*.w.example)' );


ok( !Net::DNS::RR->new("0p9mhaveqvm6t7vbl5lop2u3t2rp3tom.example. NSEC3 1 1 12 aabbccdd (
	2t7b4g4vsa5smi47k61mv5bv1a22bojr MX DNSKEY NS SOA NSEC3PARAM RRSIG )")->covered('example'),
	'B.6:	NSEC3 matches QNAME (example.) DS type bit not set' );			# DS Child Zone No Data Error


## covered() returns false for hashed name not strictly between ownerhash and nexthash

ok( !Net::DNS::RR->new("0p9mhaveqvm6t7vbl5lop2u3t2rp3tom.example. NSEC3 1 1 12 aabbccdd (
	2t7b4g4vsa5smi47k61mv5bv1a22bojr A RRSIG )")->covered('.'),
	'ancestor name not covered (.)' );			# too few matching labels

ok( !Net::DNS::RR->new("q04jkcevqvmu85r014c7dkba38o0ji5r.example. NSEC3 1 1 12 aabbccdd (
	53bq7cc2uvmubfu5ocmm6pers9tk9en A RRSIG )")->covered('unrelated.name'),
	'name out of zone not covered (unrelated.name.)' );	# non-matching label

ok( !Net::DNS::RR->new("0p9mhaveqvm6t7vbl5lop2u3t2rp3tom.example. NSEC3 1 1 12 aabbccdd (
	2t7b4g4vsa5smi47k61mv5bv1a22bojr )")->covered('example'),
	'owner name not covered (example.)' );

ok( !Net::DNS::RR->new("0p9mhaveqvm6t7vbl5lop2u3t2rp3tom.example. NSEC3 1 1 12 aabbccdd (
	2t7b4g4vsa5smi47k61mv5bv1a22bojr )")->covered('ns1.example'),
	'next hashed name not covered (ns1.example.)' );

exit;

__END__

