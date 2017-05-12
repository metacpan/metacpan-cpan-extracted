# $Id: 36-NSEC3-covered.t 1561 2017-04-19 13:08:13Z willem $	-*-perl-*-
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

plan tests => 18;


## Tests based on example zone from RFC5155, Appendix A
## as amended by erratum 4993

my %H = (
	'example'       => '0p9mhaveqvm6t7vbl5lop2u3t2rp3tom',
	'a.example'     => '35mthgpgcu1qg68fab165klnsnk3dpvl',
	'ai.example'    => 'gjeqe526plbf1g8mklp59enfd789njgi',
	'ns1.example'   => '2t7b4g4vsa5smi47k61mv5bv1a22bojr',
	'ns2.example'   => 'q04jkcevqvmu85r014c7dkba38o0ji5r',
	'w.example'     => 'k8udemvp1j2f7eg6jebps17vp3n8i58h',
	'*.w.example'   => 'r53bq7cc2uvmubfu5ocmm6pers9tk9en',
	'x.w.example'   => 'b4um86eghhds6nea196smvmlo4ors995',
	'y.w.example'   => 'ji6neoaepv8b5o6k4ev33abha8ht9fgc',
	'x.y.w.example' => '2vptu5timamqttgl4luu9kg21e0aor3s',
	'xx.example'    => 't644ebqk9bibcna874givr6joj62mlhv',
);

my %name = reverse %H;
foreach ( sort keys %name ) { print "$_\t$name{$_}\n" }


## Exercise examples from RFC5155, Appendix B

ok( Net::DNS::RR->new("$H{'example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'ns1.example'} MX DNSKEY NS SOA NSEC3PARAM RRSIG )")->covered('c.x.w.example'),
	'B.1: NSEC3 covers "next closer" name (c.x.w.example.)' );

ok( Net::DNS::RR->new("$H{'x.w.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'ai.example'} MX RRSIG )")->match('x.w.example'),
	'B.1: NSEC3 matches closest encloser (x.w.example.)' );

ok( Net::DNS::RR->new("$H{'a.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'x.w.example'} NS DS RRSIG )")->covered('*.x.w.example'),
	'B.1: NSEC3 covers wildcard at closest encloser (*.x.w.example.)' );


ok( Net::DNS::RR->new("$H{'ns1.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'x.y.w.example'} A RRSIG )")->match('ns1.example'),
	'B.2: NSEC3 matches QNAME (example.) proving MX and CNAME absent' );

ok( Net::DNS::RR->new("$H{'y.w.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'w.example'} )")->match('y.w.example'),
	'B.2.1: NSEC3 matches empty non-terminal (y.w.example.)' );


ok( Net::DNS::RR->new("$H{'a.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'x.w.example'} NS DS RRSIG )")->covered('c.example'),
	'B.3: NSEC3 covers "next closer" name (c.example.)' );

ok( Net::DNS::RR->new("$H{'example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'ns1.example'} MX DNSKEY NS SOA NSEC3PARAM RRSIG )")->match('example'),
	'B.3: NSEC3 matches closest provable encloser (example.)' );


ok( Net::DNS::RR->new("$H{'ns2.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'*.w.example'} A RRSIG )")->covered('z.w.example'),
	'B.4: NSEC3 covers "next closer" name (z.w.example.)' );


ok( Net::DNS::RR->new("$H{'w.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'ns2.example'} )")->match('w.example'),
	'B.5: NSEC3 matches closest encloser (w.example.)' );

ok( Net::DNS::RR->new("$H{'ns2.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'*.w.example'} A RRSIG )")->covered('z.w.example'),
	'B.5: NSEC3 covers "next closer name" (z.w.example.)' );

ok( Net::DNS::RR->new("$H{'*.w.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'xx.example'} MX RRSIG )")->match('*.w.example'),
	'B.5: NSEC3 matches wildcard at closest encloser (*.w.example.)' );


ok( Net::DNS::RR->new("$H{'example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'ns1.example'} MX DNSKEY NS SOA NSEC3PARAM RRSIG )")->match('example'),
	'B.6: NSEC3 matches QNAME (example.) and shows DS type bit not set' );


## covered() returns false for hashed name not strictly between ownerhash and nexthash

ok( !Net::DNS::RR->new("$H{'example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'ns1.example'} A RRSIG )")->covered('.'),
	'ancestor name not covered (.)' );			# too few matching labels

ok( !Net::DNS::RR->new("$H{'ns2.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'*.w.example'} A RRSIG )")->covered('unrelated.name'),
	'name out of zone not covered (unrelated.name.)' );	# non-matching label


ok( !Net::DNS::RR->new("$H{'a.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'w.example'} )")->covered('a.example'),
	'owner name not covered (a.example.)' );

ok( !Net::DNS::RR->new("$H{'a.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'w.example'} )")->covered('w.example'),
	'next hashed name not covered (w.example.)' );

ok( !Net::DNS::RR->new("$H{'a.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'w.example'} )")->covered('xx.example'),
	'name beyond next hashed name not covered (xx.example.)' );

ok( !Net::DNS::RR->new("$H{'a.example'}.example. NSEC3 1 1 12 aabbccdd (
	$H{'example'} )")->covered('xx.example'),
	'name beyond last hashed name not covered (xx.example.)' );


exit;

__END__


