#!/usr/bin/perl
# $Id: 05-CSYNC.t 1815 2020-10-14 21:55:18Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 20;

use Net::DNS;


my $name = 'alpha.example.com';
my $type = 'CSYNC';
my $code = 62;
my @attr = qw( SOAserial flags typelist);
my @data = qw( 66 3 A NS AAAA);
my @hash = ( 66, 3, q(A NS AAAA) );
my @also = qw( immediate soaminimum );

my $wire = '000000420003000460000008';


{
	my $typecode = unpack 'xn', Net::DNS::RR->new(". $type")->encode;
	is( $typecode, $code, "$type RR type code = $code" );

	my $hash = {};
	@{$hash}{@attr} = @hash;

	my $rr = Net::DNS::RR->new(
		name => $name,
		type => $type,
		%$hash
		);

	my $string = $rr->string;
	my $rr2	   = Net::DNS::RR->new($string);
	is( $rr2->string, $string, 'new/string transparent' );

	is( $rr2->encode, $rr->encode, 'new($string) and new(%hash) equivalent' );

	foreach (@attr) {
		my $a = join ' ', sort split /\s+/, $rr->$_;	# typelist order unspecified
		my $b = join ' ', sort split /\s+/, $hash->{$_};
		is( $a, $b, "expected result from rr->$_()" );
	}

	foreach (@also) {
		is( $rr2->$_, $rr->$_, "additional attribute rr->$_()" );
	}


	my $null    = Net::DNS::RR->new("$name NULL")->encode;
	my $empty   = Net::DNS::RR->new("$name $type")->encode;
	my $rxbin   = Net::DNS::RR->decode( \$empty )->encode;
	my $txtext  = Net::DNS::RR->new("$name $type")->string;
	my $rxtext  = Net::DNS::RR->new($txtext)->encode;
	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my $hex1    = unpack 'H*', $encoded;
	my $hex2    = unpack 'H*', $decoded->encode;
	my $hex3    = unpack 'H*', substr( $encoded, length $null );
	is( $hex2,	     $hex1,	    'encode/decode transparent' );
	is( $hex3,	     $wire,	    'encoded RDATA matches example' );
	is( length($empty),  length($null), 'encoded RDATA can be empty' );
	is( length($rxbin),  length($null), 'decoded RDATA can be empty' );
	is( length($rxtext), length($null), 'string RDATA can be empty' );
}


{
	my $rr = Net::DNS::RR->new(". $type");
	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}

	ok( $rr->immediate(1),	'set $rr->immediate' );
	ok( !$rr->immediate(0), 'clear $rr->immediate' );

	ok( $rr->soaminimum(1),	 'set $rr->soaminimum' );
	ok( !$rr->soaminimum(0), 'clear $rr->soaminimum' );
}


{
	my $rr = Net::DNS::RR->new("$name $type @data");
	$rr->print;
}


exit;

