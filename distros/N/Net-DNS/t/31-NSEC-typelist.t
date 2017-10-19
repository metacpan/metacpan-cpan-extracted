# $Id: 31-NSEC-typelist.t 1595 2017-09-12 09:10:56Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;
use Net::DNS::Parameters;
local $Net::DNS::Parameters::DNSEXTLANG;			# suppress Extlang type queries

my @prerequisite = qw(
		Net::DNS::RR::NSEC
		Net::DNS::DomainName
		);

foreach my $package (@prerequisite) {
	next if eval "use $package; 1;";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 79;


my $rr = new Net::DNS::RR(
	type	 => 'NSEC',
	nxtdname => 'irrelevant',
	);

foreach my $rrtype ( 0, 256, 512, 768, 1024 ) {
	my $type = typebyval($rrtype);
	$rr->typelist($type);
	my $rdata = $rr->rdata;
	my ( $name, $offset ) = decode Net::DNS::DomainName( \$rdata );
	my ( $w, $l, $bitmap ) = unpack "\@$offset CCa*", $rdata;
	is( $w, $rrtype >> 8, "expected window number for $type" );
}

foreach my $rrtype ( 0, 7, 8, 15, 16, 23, 24, 31, 32, 39 ) {
	my $type = typebyval($rrtype);
	$rr->typelist($type);
	my $rdata = $rr->rdata;
	my ( $name, $offset ) = decode Net::DNS::DomainName( \$rdata );
	my ( $w, $l, $bitmap ) = unpack "\@$offset CCa*", $rdata;
	is( $l, 1 + ( $rrtype >> 3 ), "expected map length for $type" );
}

foreach my $rrtype ( 0 .. 40, 42 .. 64 ) {
	my $type = typebyval($rrtype);
	$rr->typelist($type);
	my $rdata = $rr->rdata;
	my ( $name, $offset ) = decode Net::DNS::DomainName( \$rdata );
	my ( $w, $l, $bitmap ) = unpack "\@$offset CCa*", $rdata;
	my $last = unpack 'C', reverse $bitmap;
	is( $last, ( 0x80 >> ( $rrtype % 8 ) ), "expected map bit for $type" );
}


exit;

__END__


