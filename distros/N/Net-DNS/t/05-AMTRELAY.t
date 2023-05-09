#!/usr/bin/perl
# $Id: 05-AMTRELAY.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 26;
use TestToolkit;

use Net::DNS;


my $name = '12.100.51.198.in-addr.arpa';
my $type = 'AMTRELAY';
my $code = 260;
my @attr = qw( precedence D relaytype relay );
my @data = qw( 10 1 3 amtrelays.example.com );
my @also = qw( );

my $wire = '0a8309616d7472656c617973076578616d706c6503636f6d00';

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


for my $rr ( Net::DNS::RR->new("$name $type @data") ) {
	foreach ( undef, qw(192.0.2.38 2001:db8:0:8002:0:0:2000:1 relay.example.com) ) {
		my $relay = $_ || '.';
		$rr->D( !$rr->D );				# toggle D-bit
		$rr->relay($relay);
		is( scalar( $rr->relay ), $_, "rr->relay( '$relay' )" );
		my $rr2 = Net::DNS::RR->new( $rr->string );
		is( $rr2->rdstring, $rr->rdstring, 'new/string transparent' );
		my $encoded = $rr->encode;
		my $decoded = Net::DNS::RR->decode( \$encoded );
		is( $decoded->rdstring, $rr->rdstring, 'encode/decode transparent' );
	}
}


for my $rr ( Net::DNS::RR->new(". $type") ) {
	foreach (@attr) {
		ok( !$rr->$_(), "$_ attribute of empty RR undefined" );
	}

	exception( 'unrecognised relay ttype', sub { $rr->relay('X') } );
}


Net::DNS::RR->new("$name $type @data")->print;

exit;

