#!/usr/bin/perl
# $Id: 05-CDS.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 30;

use Net::DNS;


my $name = 'CDS.example';
my $type = 'CDS';
my $code = 59;
my @attr = qw( keytag algorithm digtype digest );
my @data = ( 60485, 5, 1, '2bb183af5f22588179a53b0a98631fad1a292118' );
my @also = qw( digestbin babble );

my $wire = join '', qw( EC45 05 01 2BB183AF5F22588179A53B0A98631FAD1A292118 );

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
	foreach ( @attr, 'rdstring' ) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}

	$rr->algorithm(255);
	is( $rr->algorithm(), 255, 'algorithm number accepted' );
	$rr->algorithm('RSASHA1');
	is( $rr->algorithm(),		5,	   'algorithm mnemonic accepted' );
	is( $rr->algorithm('MNEMONIC'), 'RSASHA1', 'rr->algorithm("MNEMONIC") returns mnemonic' );
	is( $rr->algorithm(),		5,	   'rr->algorithm("MNEMONIC") preserves value' );

	$rr->digtype('SHA-256');
	is( $rr->digtype(),	      2,	 'digest type mnemonic accepted' );
	is( $rr->digtype('MNEMONIC'), 'SHA-256', 'rr->digtype("MNEMONIC") returns mnemonic' );
	is( $rr->digtype(),	      2,	 'rr->digtype("MNEMONIC") preserves value' );
}


for my $rr ( Net::DNS::RR->new("$name. $type 0 0 0 00") ) {	# per RFC8078(4), erratum 5049
	ok( ref($rr), "DS delete: $name. $type 0 0 0 00" );
	is( $rr->keytag(),    0, 'DS delete: keytag 0' );
	is( $rr->algorithm(), 0, 'DS delete: algorithm 0' );
	is( $rr->digtype(),   0, 'DS delete: digtype 0' );

	my $rdata = unpack 'H*', $rr->rdata();
	is( $rdata, '0000000000', 'DS delete: rdata wire-format' );

	is( $rr->rdstring(), '0 0 0 00', 'DS delete: presentation format' );
}


for my $rr ( Net::DNS::RR->new("$name. $type 0 0 0 0") ) {	# per RFC8078(4) as published
	is( $rr->rdstring(), '0 0 0 00', 'DS delete: accept old format' );
}


Net::DNS::RR->new("$name $type @data")->print;


exit;

