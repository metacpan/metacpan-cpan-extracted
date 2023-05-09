#!/usr/bin/perl
# $Id: 05-NSEC.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 9;

use Net::DNS;


my $name = 'alpha.example.com';
my $type = 'NSEC';
my $code = 47;
my @attr = qw( nxtdname typelist);
my @data = qw( host.example.com A NS NSEC RRSIG SOA );
my @hash = ( qw( host.example.com ), q(A NS NSEC RRSIG SOA) );
my @also = qw( );

my $wire = '04686f7374076578616d706c6503636f6d000006620000000003';

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
is( $typecode, $code, "$type RR type code = $code" );

my $hash = {};
@{$hash}{@attr} = @hash;


for my $rr ( Net::DNS::RR->new( name => $name, type => $type, %$hash ) ) {
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
}


for my $rr ( Net::DNS::RR->new("$name $type @data") ) {
	local $SIG{__WARN__} = sub { };				# suppress deprecation warning
	eval { $rr->covered('example.') };			# historical
	eval { $rr->typebm('') };				# historical
}


Net::DNS::RR->new("$name $type @data")->print;

exit;

