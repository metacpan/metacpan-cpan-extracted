#!/usr/bin/perl
# $Id: 05-CAA.t 2003 2025-01-21 12:06:06Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 15;

use Net::DNS;


my $name = 'nocerts.example,com';
my $type = 'CAA';
my $code = 257;
my @attr = qw( flags tag value );
my @data = ( 0, 'issue', ";" );
my @also = qw( critical );

my $wire = '000569737375653b';

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
		next if /certificate/;
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

	ok( $rr->critical(1),  'set $rr->critical' );
	ok( $rr->flags,	       '$rr->flags changed' );
	ok( !$rr->critical(0), 'clear $rr->critical' );
}


Net::DNS::RR->new( name => $name, type => $type, %$hash )->print;

exit;

