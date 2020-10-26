#!/usr/bin/perl
# $Id: 05-ZONEMD.t 1815 2020-10-14 21:55:18Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 20;
use Net::DNS;


my $name = 'ZONEMD.example';
my $type = 'ZONEMD';
my $code = 63;
my @attr = qw( serial scheme algorithm digest);
my @data = ( 12345, 1, 1, '2bb183af5f22588179a53b0a98631fad1a292118' );
my @also = qw( digestbin );

my $wire = join '', qw( 00003039 01 01 2BB183AF5F22588179A53B0A98631FAD1A292118 );


{
	my $typecode = unpack 'xn', Net::DNS::RR->new(". $type")->encode;
	is( $typecode, $code, "$type RR type code = $code" );

	my $hash = {};
	@{$hash}{@attr} = @data;

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
		is( $rr->$_, $hash->{$_}, "expected result from rr->$_()" );
	}

	foreach (@also) {
		is( $rr2->$_, $rr->$_, "additional attribute rr->$_()" );
	}


	my $empty   = Net::DNS::RR->new("$name $type");
	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my $hex1    = uc unpack 'H*', $decoded->encode;
	my $hex2    = uc unpack 'H*', $encoded;
	my $hex3    = uc unpack 'H*', substr( $encoded, length $empty->encode );
	is( $hex1, $hex2, 'encode/decode transparent' );
	is( $hex3, $wire, 'encoded RDATA matches example' );
}


{
	my $rr = Net::DNS::RR->new(". $type");
	foreach ( @attr, @also, 'rdstring' ) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


{
	my $rr = Net::DNS::RR->new( type => $type, scheme => 1 );
	ok( $rr->string, 'string method with default values' );
	is( $rr->string, Net::DNS::RR->new( $rr->string )->string, 'parse $rr->string' );
	$rr->digestbin('');
	ok( $rr->string, 'string method with null digest' );
}


{
	my $rr = Net::DNS::RR->new( type => $type );
	eval { $rr->digest('123456789XBCDEF'); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "corrupt hexadecimal\t[$exception]" );
}

exit;

