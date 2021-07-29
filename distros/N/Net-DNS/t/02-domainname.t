#!/usr/bin/perl
# $Id: 02-domainname.t 1841 2021-06-23 20:34:28Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 35;


use_ok('Net::DNS::DomainName');


{
	my $domain = Net::DNS::DomainName->new('');
	is( $domain->name, '.', 'DNS root represented as single dot' );

	my @label = $domain->_wire;
	is( scalar(@label), 0, "DNS root name has zero labels" );

	my $binary = unpack 'H*', $domain->encode;
	my $expect = '00';
	is( $binary, $expect, 'DNS root wire-format representation' );
}


{
	my $ldh	      = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-0123456789';
	my $domain    = Net::DNS::DomainName->new($ldh);
	my $subdomain = Net::DNS::DomainName->new("sub.$ldh");
	is( $domain->name, $ldh, '63 octet LDH character label' );

	my @label = $domain->_wire;
	is( scalar(@label), 1, "name has single label" );

	my $buffer = $domain->encode;
	my $hex	   = '3f'
			. '4142434445464748494a4b4c4d4e4f505152535455565758595a'
			. '6162636465666768696a6b6c6d6e6f707172737475767778797a'
			. '2d30313233343536373839' . '00';
	is( lc unpack( 'H*', $buffer ), $hex, 'simple wire-format encoding' );

	my ( $decoded, $offset ) = decode Net::DNS::DomainName( \$buffer );
	is( $decoded->name, $domain->name, 'simple wire-format decoding' );

	is( decode Net::DNS::DomainName( \$subdomain->encode )->name, $subdomain->name, 'simple wire-format decoding' );

	my $data = '03737562c000c000c000';
	$buffer .= pack( 'H*', $data );

	my $cache = {};
	( $decoded, $offset ) = decode Net::DNS::DomainName( \$buffer, $offset, $cache );
	is( $decoded->name, $subdomain->name, 'compressed wire-format decoding' );

	my @labels = $decoded->_wire;
	is( scalar(@labels), 2, "decoded name has two labels" );

	$decoded = decode Net::DNS::DomainName( \$buffer, $offset, $cache );
	is( $decoded->name, $domain->name, 'compressed wire-format decoding' );
}


{
	my $buffer = pack 'H*', '0200';
	eval { my $domain = decode Net::DNS::DomainName( \$buffer ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "corrupt wire-format\t[$exception]" );
}


{
	my $buffer = pack 'H*', 'c002';
	eval { my $domain = decode Net::DNS::DomainName( \$buffer ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "bad compression pointer\t[$exception]" );
}


{
	my $buffer = pack 'H*', 'c000';
	eval { my $domain = decode Net::DNS::DomainName( \$buffer ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "name compression loop\t[$exception]" );
}


{
	my $hex = '40'
			. '4142434445464748494a4b4c4d4e4f505152535455565758595a'
			. '6162636465666768696a6b6c6d6e6f707172737475767778797a'
			. '2d30313233343536373839ff' . '00';
	my $buffer = pack 'H*', $hex;
	eval { my $domain = decode Net::DNS::DomainName( \$buffer ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unsupported wire-format\t[$exception]" );
}


{
	my $hex = '80'
			. '4142434445464748494a4b4c4d4e4f505152535455565758595a'
			. '6162636465666768696a6b6c6d6e6f707172737475767778797a'
			. '2d30313233343536373839ff'
			. '4142434445464748494a4b4c4d4e4f505152535455565758595a'
			. '6162636465666768696a6b6c6d6e6f707172737475767778797a'
			. '2d30313233343536373839ff' . '00';
	my $buffer = pack 'H*', $hex;
	eval { my $domain = decode Net::DNS::DomainName( \$buffer ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unsupported wire-format\t[$exception]" );
}


{
	my $domain    = Net::DNS::DomainName->new( uc 'EXAMPLE.COM' );
	my $hash      = {};
	my $data      = $domain->encode( 0,	       $hash );
	my $compress  = $domain->encode( length $data, $hash );
	my $canonical = $domain->encode( length $data );
	my $decoded   = decode Net::DNS::DomainName( \$data );
	my $downcased = Net::DNS::DomainName->new( lc $domain->name )->encode( 0, {} );
	ok( $domain->isa('Net::DNS::DomainName'),  'object returned by new() constructor' );
	ok( $decoded->isa('Net::DNS::DomainName'), 'object returned by decode() constructor' );
	is( length $compress, length $data, 'Net::DNS::DomainName wire encoding is uncompressed' );
	isnt( $data, $downcased, 'Net::DNS::DomainName wire encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::DomainName canonical form is uncompressed' );
	isnt( $canonical, $downcased, 'Net::DNS::DomainName canonical form preserves case' );
}


{
	my $domain    = Net::DNS::DomainName1035->new( uc 'EXAMPLE.COM' );
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


{
	my $domain    = Net::DNS::DomainName2535->new( uc 'EXAMPLE.COM' );
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


exit;

