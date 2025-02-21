#!/usr/bin/perl
# $Id: 05-DHCID.t 2003 2025-01-21 12:06:06Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;

use Net::DNS;

my @prerequisite = qw(
		MIME::Base64
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";	## no critic
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 11;


my $name = 'DHCID.example';
my $type = 'DHCID';
my $code = 49;
my @attr = qw( identifiertype digesttype digest );
my @data = qw();
my @also = qw();

my $data = 'AAIBT2JmdXNjYXRlZElkZW50aXR5RGF0YQ==';
my $wire = '0002014f6266757363617465644964656e7469747944617461';


for my $rr ( Net::DNS::RR->new( type => $type ) ) {
	my $typecode = unpack 'xn', $rr->encode;
	is( $typecode, $code, "$type RR type code = $code" );

	like( $rr->string, '/no data/i', "empty $type record" );

	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


for my $rr ( Net::DNS::RR->new("$name $type $data") ) {
	my $string = $rr->string;
	my $rr2	   = Net::DNS::RR->new($string);
	is( $rr2->string, $string, 'new/string transparent' );

	foreach (@attr) {
		is( defined( $rr->$_ ), 1, "'$_' attribute defined" );
	}

	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my $hex1    = unpack 'H*', $encoded;
	my $hex2    = unpack 'H*', $decoded->encode;
	my $hex3    = unpack 'H*', $rr->rdata;
	is( $hex2, $hex1, 'encode/decode transparent' );
	is( $hex3, $wire, 'encoded RDATA matches example' );
}


Net::DNS::RR->new("$name $type $data")->print;

exit;

