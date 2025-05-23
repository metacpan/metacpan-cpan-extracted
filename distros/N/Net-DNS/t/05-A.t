#!/usr/bin/perl
# $Id: 05-A.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 9;

use Net::DNS;


my $name = 'A.example';
my $type = 'A';
my $code = 1;
my @attr = qw( address );
my @data = qw( 192.0.2.1 );
my @also = qw( );

my $wire = 'c0000201';

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


my %IPv4completion = (
	'1.2.3.4' => '1.2.3.4',
	'1.2.4'	  => '1.2.0.4',
	'1.4'	  => '1.0.0.4',
	);

foreach my $address ( sort keys %IPv4completion ) {
	my $expect = $IPv4completion{$address};
	my $rr	   = Net::DNS::RR->new( name => $name, type => $type, address => $address );
	is( $rr->address, $expect, "address completion:\t$address" );
}


exit;

