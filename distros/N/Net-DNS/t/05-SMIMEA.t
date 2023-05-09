#!/usr/bin/perl
# $Id: 05-SMIMEA.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 16;
use TestToolkit;

use Net::DNS;


my $name = 'c93f1e400f26708f98cb19d936620da35eec8f72e57f9eec01c1afd6._smimecert.example.com';
my $type = 'SMIMEA';
my $code = 53;
my @attr = qw( usage selector matchingtype certificate );
my @data = qw( 1 1 1 d2abde240d7cd3ee6b4b28c54df034b97983a1d16e8a410e4561cb106618e971 );
my @also = qw( certbin babble );

my $wire = qw( 010101d2abde240d7cd3ee6b4b28c54df034b97983a1d16e8a410e4561cb106618e971 );

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

	exception( 'corrupt hexadecimal', sub { $rr->certificate('123456789XBCDEF') } );
}


Net::DNS::RR->new("$name $type @data")->print;

exit;

