#!/usr/bin/perl
# $Id: 05-DS.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 38;
use TestToolkit;

use Net::DNS;


my $name = 'DS.example';
my $type = 'DS';
my $code = 43;
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

	$rr->digest('');
	ok( $rr->rdstring, '$rr->rdstring with empty digest field' );
}


for my $rr ( Net::DNS::RR->new(". $type") ) {
	foreach ( @attr, 'rdstring' ) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}

	my $class = ref($rr);

	is( $class->algorithm('RSASHA256'), 8,		 'class method algorithm("RSASHA256")' );
	is( $class->algorithm(8),	    'RSASHA256', 'class method algorithm(8)' );
	is( $class->algorithm(255),	    255,	 'class method algorithm(255)' );

	$rr->algorithm(255);
	is( $rr->algorithm(), 255, 'algorithm number accepted' );
	$rr->algorithm('RSASHA1');
	is( $rr->algorithm(),		5,	   'algorithm mnemonic accepted' );
	is( $rr->algorithm('MNEMONIC'), 'RSASHA1', 'rr->algorithm("MNEMONIC") returns mnemonic' );
	is( $rr->algorithm(),		5,	   'rr->algorithm("MNEMONIC") preserves value' );

	exception( 'unknown algorithm', sub { $rr->algorithm('X') } );

	exception( 'disallowed algorithm 0', sub { $rr->algorithm(0) } );

	is( $class->digtype('SHA256'), 2,	  'class method digtype("SHA256")' );
	is( $class->digtype(2),	       'SHA-256', 'class method digtype(2)' );
	is( $class->digtype(255),      255,	  'class method digtype(255)' );

	$rr->digtype('SHA256');
	is( $rr->digtype(),	      2,	 'digest type mnemonic accepted' );
	is( $rr->digtype('MNEMONIC'), 'SHA-256', 'rr->digtype("MNEMONIC") returns mnemonic' );
	is( $rr->digtype(),	      2,	 'rr->digtype("MNEMONIC") preserves value' );

	exception( 'disallowed digtype 0', sub { $rr->digtype(0) } );

	exception( 'corrupt hexadecimal', sub { $rr->digest('123456789XBCDEF') } );


	my $keyrr = Net::DNS::RR->new( type => 'DNSKEY', keybin => '' );

	exception( 'create: wrong digtype', sub { $class->create( $keyrr, ( 'digtype' => 255 ) ) } );

	exception( 'create: revoked key', sub { $keyrr->flags(0x80); $class->create($keyrr) } );

	exception( 'create: non-zone key', sub { $keyrr->flags(0); $class->create($keyrr) } );

	exception( 'create: non-DNSSEC key', sub { $keyrr->protocol(0); $class->create($keyrr) } );
}


Net::DNS::RR->new("$name $type @data")->print;

exit;

