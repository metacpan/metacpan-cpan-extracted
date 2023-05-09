#!/usr/bin/perl
# $Id: 05-URI.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 11;

use Net::DNS;


my $name = '_ftp._tcp.example.net';
my $type = 'URI';
my $code = 256;
my @attr = qw( priority weight target );
my @data = qw( 10 1 ftp://ftp1.example.com/public );
my @also = qw( );

my $wire = '000A00016674703A2F2F667470312E6578616D706C652E636F6D2F7075626C6963';

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
	my $hex1    = uc unpack 'H*', $decoded->encode;
	my $hex2    = uc unpack 'H*', $encoded;
	my $hex3    = uc unpack 'H*', $rr->rdata;
	is( $hex1, $hex2, 'encode/decode transparent' );
	is( $hex3, $wire, 'encoded RDATA matches example' );
}


for my $rr ( Net::DNS::RR->new(". $type") ) {
	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


exit;

