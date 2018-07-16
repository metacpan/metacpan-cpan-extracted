# $Id: 32-NSEC3-typelist.t 1690 2018-07-03 09:02:10Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;
use Net::DNS::Text;
use Net::DNS::Parameters;
local $Net::DNS::Parameters::DNSEXTLANG;			# suppress Extlang type queries

my @prerequisite = qw(
		Net::DNS::RR::NSEC3
		);

foreach my $package (@prerequisite) {
	next if eval "use $package; 1;";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 78;


my $rr = new Net::DNS::RR(
	type	 => 'NSEC3',
	hnxtname => 'irrelevant',
	);

foreach my $rrtype ( 0, 256, 512, 768, 1024 ) {
	my $type = typebyval($rrtype);
	$rr->typelist($type);
	my $rdata = $rr->rdata;
	my ( $text, $offset ) = decode Net::DNS::Text( \$rdata, 4 );
	( $text, $offset ) = decode Net::DNS::Text( \$rdata, $offset );
	my ( $w, $l, $bitmap ) = unpack "\@$offset CCa*", $rdata;
	is( $w, $rrtype >> 8, "expected window number for $type" );
}

foreach my $rrtype ( 0, 7, 8, 15, 16, 23, 24, 31, 32, 39 ) {
	my $type = typebyval($rrtype);
	$rr->typelist($type);
	my $rdata = $rr->rdata;
	my ( $text, $offset ) = decode Net::DNS::Text( \$rdata, 4 );
	( $text, $offset ) = decode Net::DNS::Text( \$rdata, $offset );
	my ( $w, $l, $bitmap ) = unpack "\@$offset CCa*", $rdata;
	is( $l, 1 + ( $rrtype >> 3 ), "expected map length for $type" );
}

foreach my $rrtype ( 1 .. 40, 42 .. 64 ) {
	my $type = typebyval($rrtype);
	$rr->typelist($type);
	is( $rr->typemap($type), 1, "expected map bit for $type" );
}


exit;

__END__

