# $Id: 24-NSEC-encloser.t 1740 2019-04-04 14:45:31Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		Net::DNS::ZoneFile
		Net::DNS::RR::NSEC
		);

foreach my $package (@prerequisite) {
	next if eval "use $package; 1;";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 9;


## Based on example from RFC7129 3.2

my @nsec = grep $_->type eq 'NSEC', parse Net::DNS::ZoneFile <<'END';

$ORIGIN example.org.
example.org.	SOA ( ns1 dns )
;		DNSKEY ( ... )
;		NS  a.example.org.
		NSEC a.example.org. NS SOA RRSIG NSEC DNSKEY
;		RRSIG(NS) ( ... )
;		RRSIG(SOA) ( ... )
;		RRSIG(NSEC) ( ... )
;		RRSIG(DNSKEY) ( ... )
a.example.org.	A 192.0.2.1
;		TXT "a record"
		NSEC d.example.org. A TXT RRSIG NSEC
;		RRSIG(A) ( ... )
;		RRSIG(TXT) ( ... )
;		RRSIG(NSEC) ( ... )
d.example.org.	A 192.0.2.1
;		TXT "d record"
		NSEC example.org. A TXT RRSIG NSEC
END


sub closest_encloser {
	my $qname = shift;
	my $encloser;
	foreach my $nsec (@nsec) {
		my $ancestor = $nsec->encloser($qname);
		$encloser = $ancestor if $ancestor;
	}

	foreach my $nsec ( reverse @nsec ) {			# check order independence
		my $ancestor = $nsec->encloser($qname);
		$encloser = $ancestor if $ancestor;
	}
	return $encloser;
}

sub next_closer_name {
	my $qname = shift;
	my $nextcloser;
	foreach my $nsec (@nsec) {
		next unless $nsec->encloser($qname);
		$nextcloser = $nsec->nextcloser;
	}
	return $nextcloser;
}

sub closer_wildcard {
	my $qname = shift;
	my $wildcard;
	foreach my $nsec (@nsec) {
		next unless $nsec->encloser($qname);
		$wildcard = $nsec->wildcard;
	}
	return $wildcard;
}

is( closest_encloser('example.org.'),	undef,	       'encloser(example.org)' );
is( closest_encloser('a.example.org.'), 'example.org', 'encloser(a.example.org)' );
is( closest_encloser('d.example.org.'), 'example.org', 'encloser(d.example.org)' );

is( closest_encloser('b.example.org.'), 'example.org',	 'encloser(b.example.org)' );
is( next_closer_name('b.example.org.'), 'b.example.org', 'nextcloser(b.example.org)' );
is( closer_wildcard('b.example.org.'),	'*.example.org', 'wildcard(b.example.org)' );

is( closest_encloser('a.b.c.example.org.'), 'example.org',   'encloser(a.b.c.example.org)' );
is( next_closer_name('a.b.c.example.org.'), 'c.example.org', 'nextcloser(a.b.c.example.org)' );
is( closer_wildcard('a.b.c.example.org.'),  '*.example.org', 'wildcard(a.b.c.example.org)' );


exit;

__END__

