#!/usr/bin/perl
# $Id: 05-NSEC3.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 23;
use TestToolkit;

use Net::DNS;


my $name = '0p9mhaveqvm6t7vbl5lop2u3t2rp3tom.example';
my $type = 'NSEC3';
my $code = 50;
my @attr = qw( algorithm flags iterations salt hnxtname typelist );
my @data = qw( 1 1 12 aabbccdd 2t7b4g4vsa5smi47k61mv5bv1a22bojr NS SOA MX RRSIG DNSKEY NSEC3PARAM );
my @hash = ( qw( 1 1 12 aabbccdd 2t7b4g4vsa5smi47k61mv5bv1a22bojr ), q(NS SOA MX RRSIG DNSKEY NSEC3PARAM) );
my @also = qw( hashalgo optout );

my $wire = '0101000c04aabbccdd14174eb2409fe28bcb4887a1836f957f0a8425e27b000722010000000290';

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
is( $typecode, $code, "$type RR type code = $code" );

my $hash = {};
@{$hash}{@attr} = @hash;


for my $rr ( Net::DNS::RR->new( name => $name, type => $type, %$hash ) ) {
	my $string = $rr->string;
	my $rr2	   = Net::DNS::RR->new($string);
	is( $rr2->string, $string,     'new/string transparent' );
	is( $rr2->encode, $rr->encode, 'new($string) and new(%hash) equivalent' );

	foreach (@attr) {
		my $a = join ' ', sort split /\s+/, $rr->$_;	# typelist order unspecified
		my $b = join ' ', sort split /\s+/, $hash->{$_};
		is( $a, $b, "expected result from rr->$_()" );
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


for my $rr ( Net::DNS::RR->new(". $type 1 1 12 - 2t7b4g4vsa5smi47k61mv5bv1a22bojr A") ) {
	is( $rr->salt, '', 'parse RR with salt field placeholder' );
	like( $rr->rdstring, '/^1 1 12 - /', 'placeholder denotes empty salt field' );
	exception( 'corrupt hexadecimal', sub { $rr->salt('123456789XBCDEF') } );
}


for my $rr ( Net::DNS::RR->new(". $type @data") ) {
	my $class = ref($rr);

	$rr->algorithm('SHA-1');
	is( $rr->algorithm(),		1,	 'algorithm mnemonic accepted' );
	is( $rr->algorithm('MNEMONIC'), 'SHA-1', "rr->algorithm('MNEMONIC')" );
	is( $class->algorithm('SHA-1'), 1,	 "class method algorithm('SHA-1')" );
	is( $class->algorithm(1),	'SHA-1', "class method algorithm(1)" );
	is( $class->algorithm(255),	255,	 "class method algorithm(255)" );

	exception( 'unknown mnemonic',	sub { $rr->algorithm('X') } );
	exception( 'invalid algorithm', sub { Net::DNS::RR::NSEC3::name2hash( 0, 1, '' ) } );
}


Net::DNS::RR->new("$name $type @data")->print;

exit;

