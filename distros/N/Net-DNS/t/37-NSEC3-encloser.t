# $Id: 37-NSEC3-encloser.t 1709 2018-09-07 08:03:09Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;
use Net::DNS::ZoneFile;

my @prerequisite = qw(
		Digest::SHA
		Net::DNS::RR::NSEC3
		);

foreach my $package (@prerequisite) {
	next if eval "use $package; 1;";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 4;


## Based on examples from RFC5155, Appendix B

my @nsec3 = parse Net::DNS::ZoneFile <<'END';
0p9mhaveqvm6t7vbl5lop2u3t2rp3tom.example.	IN	NSEC3	( 1 1 12 aabbccdd
	2t7b4g4vsa5smi47k61mv5bv1a22bojr NS SOA MX RRSIG DNSKEY NSEC3PARAM )

b4um86eghhds6nea196smvmlo4ors995.example.	IN	NSEC3	( 1 1 12 aabbccdd
	gjeqe526plbf1g8mklp59enfd789njgi MX RRSIG )

35mthgpgcu1qg68fab165klnsnk3dpvl.example.	IN	NSEC3	( 1 1 12 aabbccdd
	b4um86eghhds6nea196smvmlo4ors995 NS DS RRSIG )
END


my $encloser;
my $nextcloser;
my $wildcard;
foreach my $nsec3 (@nsec3) {
	for ( $nsec3->encloser('a.c.x.w.example') ) {
		next if $encloser && length($encloser) > length;
		$encloser   = $_;
		$nextcloser = $nsec3->nextcloser;
		$wildcard   = $nsec3->wildcard;
	}
}

is( $encloser,	 'x.w.example',	  'closest (provable) encloser' );
is( $nextcloser, 'c.x.w.example', 'next closer name' );
is( $wildcard,	 '*.x.w.example', 'wildcard at closest encloser' );

is( $nsec3[0]->encloser('a.n.other'), undef, 'reject name out of zone' );

exit;

__END__

