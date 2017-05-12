# $Id: 02-domainname.t 1355 2015-06-05 08:23:04Z willem $	-*-perl-*-

use strict;
use Test::More tests => 51;


BEGIN {
	use_ok('Net::DNS::DomainName');
}


{
	my $domain = new Net::DNS::DomainName('');
	is( $domain->name, '.', 'DNS root represented as single dot' );

	my @label = $domain->_wire;
	is( scalar(@label), 0, "DNS root name has zero labels" );

	my $binary = unpack 'H*', $domain->encode;
	my $expect = '00';
	is( $binary, $expect, 'DNS root wire-format representation' );
}


{
	my $ldh	      = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-0123456789';
	my $domain    = new Net::DNS::DomainName($ldh);
	my $subdomain = new Net::DNS::DomainName("sub.$ldh");
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
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "corrupt wire-format\t[$exception]" );
}


{
	my $buffer = pack 'H*', 'c002';
	eval { my $domain = decode Net::DNS::DomainName( \$buffer ); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "bad compression pointer\t[$exception]" );
}


{
	my $buffer = pack 'H*', 'c000';
	eval { my $domain = decode Net::DNS::DomainName( \$buffer ); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "name compression loop\t[$exception]" );
}


{
	my $hex = '40'
			. '4142434445464748494a4b4c4d4e4f505152535455565758595a'
			. '6162636465666768696a6b6c6d6e6f707172737475767778797a'
			. '2d30313233343536373839ff' . '00';
	my $buffer = pack 'H*', $hex;
	eval { my $domain = decode Net::DNS::DomainName( \$buffer ); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "unsupported wire-format\t[$exception]" );
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
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "unsupported wire-format\t[$exception]" );
}


{
	foreach my $case (
		'\000\001\002\003\004\005\006\007\008\009\010\011\012\013\014\015',
		'\016\017\018\019\020\021\022\023\024\025\026\027\028\029\030\031'
		) {
		my $domain = new Net::DNS::DomainName($case);
		my $binary = $domain->encode;
		my $result = decode Net::DNS::DomainName( \$binary )->name;
		is( unpack( 'H*', $result ), unpack( 'H*', $case ), "C0 controls:\t$case" );
	}
}


{
	foreach my $case (
		'\032!"#$%&\'()*+,-\./',			#  32 .. 47
		'0123456789:;<=>?',				#  48 ..
		'@ABCDEFGHIJKLMNO',				#  64 ..
		'PQRSTUVWXYZ[\\\\]^_',				#  80 ..
		'`abcdefghijklmno',				#  96 ..
		'pqrstuvwxyz{|}~\127'				# 112 ..
		) {
		my $domain = new Net::DNS::DomainName($case);
		my $binary = $domain->encode;
		my $result = decode Net::DNS::DomainName( \$binary )->name;
		is( unpack( 'H*', $result ), unpack( 'H*', $case ), "G0 graphics:\t$case" );
	}
}


{
	foreach my $case (
		'\128\129\130\131\132\133\134\135\136\137\138\139\140\141\142\143',
		'\144\145\146\147\148\149\150\151\152\153\154\155\156\157\158\159',
		'\160\161\162\163\164\165\166\167\168\169\170\171\172\173\174\175',
		'\176\177\178\179\180\181\182\183\184\185\186\187\188\189\190\191',
		'\192\193\194\195\196\197\198\199\200\201\202\203\204\205\206\207',
		'\208\209\210\211\212\213\214\215\216\217\218\219\220\221\222\223',
		'\224\225\226\227\228\229\230\231\232\233\234\235\236\237\238\239',
		'\240\241\242\243\244\245\246\247\248\249\250\251\252\253\254\255'
		) {
		my $domain = new Net::DNS::DomainName($case);
		my $binary = $domain->encode;
		my $result = decode Net::DNS::DomainName( \$binary )->name;
		is( unpack( 'H*', $result ), unpack( 'H*', $case ), "8-bit codes:\t$case" );
	}
}


{
	my $domain    = new Net::DNS::DomainName( uc 'EXAMPLE.COM' );
	my $hash      = {};
	my $data      = $domain->encode( 0, $hash );
	my $compress  = $domain->encode( length $data, $hash );
	my $canonical = $domain->encode( length $data );
	my $decoded   = decode Net::DNS::DomainName( \$data );
	my $downcased = new Net::DNS::DomainName( lc $domain->name )->encode( 0, {} );
	ok( $domain->isa('Net::DNS::DomainName'),  'object returned by new() constructor' );
	ok( $decoded->isa('Net::DNS::DomainName'), 'object returned by decode() constructor' );
	is( length $compress, length $data, 'Net::DNS::DomainName wire encoding is uncompressed' );
	isnt( $data, $downcased, 'Net::DNS::DomainName wire encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::DomainName canonical form is uncompressed' );
	isnt( $canonical, $downcased, 'Net::DNS::DomainName canonical form preserves case' );
}


{
	my $domain    = new Net::DNS::DomainName1035( uc 'EXAMPLE.COM' );
	my $hash      = {};
	my $data      = $domain->encode( 0, $hash );
	my $compress  = $domain->encode( length $data, $hash );
	my $canonical = $domain->encode( length $data );
	my $decoded   = decode Net::DNS::DomainName1035( \$data );
	my $downcased = new Net::DNS::DomainName1035( lc $domain->name )->encode( 0x4000, {} );
	ok( $domain->isa('Net::DNS::DomainName1035'),  'object returned by new() constructor' );
	ok( $decoded->isa('Net::DNS::DomainName1035'), 'object returned by decode() constructor' );
	isnt( length $compress, length $data, 'Net::DNS::DomainName1035 wire encoding is compressible' );
	isnt( $data,		$downcased,   'Net::DNS::DomainName1035 wire encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::DomainName1035 canonical form is uncompressed' );
	is( $canonical,	       $downcased,   'Net::DNS::DomainName1035 canonical form is lower case' );
}


{
	my $domain    = new Net::DNS::DomainName2535( uc 'EXAMPLE.COM' );
	my $hash      = {};
	my $data      = $domain->encode( 0, $hash );
	my $compress  = $domain->encode( length $data, $hash );
	my $canonical = $domain->encode( length $data );
	my $decoded   = decode Net::DNS::DomainName2535( \$data );
	my $downcased = new Net::DNS::DomainName2535( lc $domain->name )->encode( 0, {} );
	ok( $domain->isa('Net::DNS::DomainName2535'),  'object returned by new() constructor' );
	ok( $decoded->isa('Net::DNS::DomainName2535'), 'object returned by decode() constructor' );
	is( length $compress, length $data, 'Net::DNS::DomainName2535 wire encoding is uncompressed' );
	isnt( $data, $downcased, 'Net::DNS::DomainName2535 wire encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::DomainName2535 canonical form is uncompressed' );
	is( $canonical,	       $downcased,   'Net::DNS::DomainName2535 canonical form is lower case' );
}


exit;

