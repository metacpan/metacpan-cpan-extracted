#!/usr/bin/perl
# $Id: 05-NAPTR.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 17;

use Net::DNS;


my $name = '2.1.2.1.5.5.5.0.7.7.1.e164.arpa.';
my $type = 'NAPTR';
my $code = 35;
my @attr = qw( order preference flags service regexp replacement );
my @data = qw( 100 10 u sip+E2U !^.*$!sip:information@foo.se!i . );
my @also = qw( );

my $wire = '0064000a0175077369702b4532551e215e2e2a24217369703a696e666f726d6174696f6e40666f6f2e7365216900';

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
is( $typecode, $code, "$type RR type code = $code" );

my $hash = {};
@{$hash}{@attr} = @data;


for my $rr ( Net::DNS::RR->new( name => $name, type => $type, %$hash ) ) {
	my $string = $rr->string;
	my $rr2	   = Net::DNS::RR->new($string);
	is( $rr2->string, $string, 'new/string transparent' );

	is( $rr2->encode, $rr->encode, 'new($string) and new(%hash) equivalent' );

	foreach (@attr) {
		is( $rr->$_, $hash->{$_}, "expected result from rr->$_()" );
	}

	foreach (@also) {
		is( $rr2->$_, $rr->$_, "additional attribute rr->$_()" );
	}

	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my $hex1    = unpack 'H*', $encoded;
	my $hex2    = unpack 'H*', $decoded->encode;
	my $hex3    = unpack 'H*', $rr->rdata;
	is( $hex2, $hex1, 'encode/decode transparent' );
	is( $hex3, $wire, 'encoded RDATA matches example' );
}


for my $rr ( Net::DNS::RR->new(". $type") ) {
	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


exit;

