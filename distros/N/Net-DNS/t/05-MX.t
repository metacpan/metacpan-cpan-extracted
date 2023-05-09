#!/usr/bin/perl
# $Id: 05-MX.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 12;

use Net::DNS;


my $name = 'MX.example';
my $type = 'MX';
my $code = 15;
my @attr = qw( preference exchange );
my @data = qw( 10 mx.example.com );
my @also = qw( );

my $wire = '000a026d78076578616d706c6503636f6d00';

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


for my $empty ( Net::DNS::RR->new( type => $type ) ) {
	is( $empty->preference, 0,     'unspecified integer returns 0 (not default value)' );
	is( $empty->exchange,	undef, 'unspecified domain name returns undefined' );
}

for my $rr ( Net::DNS::RR->new( type => $type, exchange => 'mx.example' ) ) {
	is( $rr->preference, 10, 'unspecified integer returns default value' );
	ok( $rr->exchange, 'domain name defined as expected' );
	is( $rr->preference(0), 0, 'zero integer replaces default value' );
}


exit;

