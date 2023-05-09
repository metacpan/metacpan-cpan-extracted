#!/usr/bin/perl
# $Id: 02-domainname.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 35;
use TestToolkit;


use_ok('Net::DNS::DomainName');


for my $domain ( Net::DNS::DomainName->new('') ) {
	is( $domain->name, '.', 'DNS root represented as single dot' );

	my @label = $domain->_wire;
	is( scalar(@label), 0, "DNS root name has zero labels" );

	my $binary = unpack 'H*', $domain->encode;
	my $expect = '00';
	is( $binary, $expect, 'DNS root wire-format representation' );
}


my $ldh = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-0123456789';
for my $domain ( Net::DNS::DomainName->new($ldh) ) {
	is( $domain->name, $ldh, '63 octet LDH character label' );

	my @label = $domain->_wire;
	is( scalar(@label), 1, "name has single label" );

	my $buffer = $domain->encode;
	my $hex	   = '3f'
			. '4142434445464748494a4b4c4d4e4f505152535455565758595a'
			. '6162636465666768696a6b6c6d6e6f707172737475767778797a'
			. '2d30313233343536373839' . '00';
	is( lc unpack( 'H*', $buffer ), $hex, 'simple wire-format encoding' );

	my ( $decoded, $offset ) = Net::DNS::DomainName->decode( \$buffer );
	is( $decoded->name, $domain->name, 'simple wire-format decoding' );

	my $subdomain = Net::DNS::DomainName->new("sub.$ldh");
	is( Net::DNS::DomainName->decode( \$subdomain->encode )->name, $subdomain->name,
		'simple wire-format decoding' );

	my $data = '03737562c000c000c000';
	$buffer .= pack( 'H*', $data );

	my $cache = {};
	( $decoded, $offset ) = Net::DNS::DomainName->decode( \$buffer, $offset, $cache );
	is( $decoded->name, $subdomain->name, 'compressed wire-format decoding' );

	my @labels = $decoded->_wire;
	is( scalar(@labels), 2, "decoded name has two labels" );

	$decoded = Net::DNS::DomainName->decode( \$buffer, $offset, $cache );
	is( $decoded->name, $domain->name, 'compressed wire-format decoding' );
}


for my $domain ( Net::DNS::DomainName->new( uc 'EXAMPLE.COM' ) ) {
	my $hash      = {};
	my $data      = $domain->encode( 0,	       $hash );
	my $compress  = $domain->encode( length $data, $hash );
	my $canonical = $domain->encode( length $data );
	my $decoded   = Net::DNS::DomainName->decode( \$data );
	my $downcased = Net::DNS::DomainName->new( lc $domain->name )->encode( 0, {} );
	ok( $domain->isa('Net::DNS::DomainName'),  'object returned by new() constructor' );
	ok( $decoded->isa('Net::DNS::DomainName'), 'object returned by decode() constructor' );
	is( length $compress, length $data, 'Net::DNS::DomainName wire encoding is uncompressed' );
	isnt( $data, $downcased, 'Net::DNS::DomainName wire encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::DomainName canonical form is uncompressed' );
	isnt( $canonical, $downcased, 'Net::DNS::DomainName canonical form preserves case' );
}


for my $domain ( Net::DNS::DomainName1035->new( uc 'EXAMPLE.COM' ) ) {
	my $hash      = {};
	my $data      = $domain->encode( 0,	       $hash );
	my $compress  = $domain->encode( length $data, $hash );
	my $canonical = $domain->encode( length $data );
	my $decoded   = Net::DNS::DomainName1035->decode( \$data );
	my $downcased = Net::DNS::DomainName1035->new( lc $domain->name )->encode( 0x4000, {} );
	ok( $domain->isa('Net::DNS::DomainName1035'),  'object returned by new() constructor' );
	ok( $decoded->isa('Net::DNS::DomainName1035'), 'object returned by decode() constructor' );
	isnt( length $compress, length $data, 'Net::DNS::DomainName1035 wire encoding is compressible' );
	isnt( $data,		$downcased,   'Net::DNS::DomainName1035 wire encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::DomainName1035 canonical form is uncompressed' );
	is( $canonical,	       $downcased,   'Net::DNS::DomainName1035 canonical form is lower case' );
}


for my $domain ( Net::DNS::DomainName2535->new( uc 'EXAMPLE.COM' ) ) {
	my $hash      = {};
	my $data      = $domain->encode( 0,	       $hash );
	my $compress  = $domain->encode( length $data, $hash );
	my $canonical = $domain->encode( length $data );
	my $decoded   = Net::DNS::DomainName2535->decode( \$data );
	my $downcased = Net::DNS::DomainName2535->new( lc $domain->name )->encode( 0, {} );
	ok( $domain->isa('Net::DNS::DomainName2535'),  'object returned by new() constructor' );
	ok( $decoded->isa('Net::DNS::DomainName2535'), 'object returned by decode() constructor' );
	is( length $compress, length $data, 'Net::DNS::DomainName2535 wire encoding is uncompressed' );
	isnt( $data, $downcased, 'Net::DNS::DomainName2535 wire encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::DomainName2535 canonical form is uncompressed' );
	is( $canonical,	       $downcased,   'Net::DNS::DomainName2535 canonical form is lower case' );
}


my $truncated = pack 'H*', '0200';
exception( 'truncated wire-format', sub { Net::DNS::DomainName->decode( \$truncated ) } );

my $type1label = pack 'H*', join '', '40', '4142434445464748494a4b4c4d4e4f50' x 4, '00';
exception( 'unsupported wire-format', sub { Net::DNS::DomainName->decode( \$type1label ) } );

my $type2label = pack 'H*', join '', '80', '4142434445464748494a4b4c4d4e4f50' x 8, '00';
exception( 'unsupported wire-format', sub { Net::DNS::DomainName->decode( \$type2label ) } );

my $overreach = pack 'H*', 'c002';
exception( 'bad compression pointer', sub { Net::DNS::DomainName->decode( \$overreach ) } );

my $loop = pack 'H*', '0344454603414243c000';
exception( 'compression loop', sub { Net::DNS::DomainName->decode( \$loop, 4 ) } );


exit;

