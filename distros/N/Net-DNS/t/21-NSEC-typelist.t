#!/usr/bin/perl
# $Id: 21-NSEC-typelist.t 1865 2022-05-21 09:57:49Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;

use Net::DNS;
use Net::DNS::DomainName;
use Net::DNS::Parameters qw(:type);

my @prerequisite = qw(
		Net::DNS::RR::NSEC
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";	## no critic
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 79;


my $rr = Net::DNS::RR->new(
	type	 => 'NSEC',
	nxtdname => 'irrelevant',
	);

is( $rr->typemap(0), undef, 'typemap($type) undefined for empty map' );
$rr->typelist(1);
is( $rr->typemap(256), undef, 'typemap($type) undefined for empty map block' );

foreach my $rrtype ( 0, 256, 512, 768, 1024 ) {
	my $type = "TYPE$rrtype";
	$rr->typelist($type);
	my $rdata = $rr->rdata;
	my ( $name, $offset ) = Net::DNS::DomainName->decode( \$rdata );
	my ( $w, $l, $bitmap ) = unpack "\@$offset CCa*", $rdata;
	is( $w, $rrtype >> 8, "expected window number for $type" );
}

foreach my $rrtype ( 0, 7, 8, 15, 16, 23, 24, 31, 32, 39 ) {
	my $type = typebyval($rrtype);
	$rr->typelist($type);
	my $rdata = $rr->rdata;
	my ( $name, $offset ) = Net::DNS::DomainName->decode( \$rdata );
	my ( $w, $l, $bitmap ) = unpack "\@$offset CCa*", $rdata;
	is( $l, 1 + ( $rrtype >> 3 ), "expected map length for $type" );
}

foreach my $rrtype ( 1 .. 40, 42 .. 53, 55 .. 64 ) {
	my $type = typebyval($rrtype);
	$rr->typelist($type);
	is( $rr->typemap($type), 1, "expected map bit for $type" );
}


exit;

__END__

