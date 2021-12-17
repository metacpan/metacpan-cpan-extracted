#!/usr/bin/perl
# $Id: 03-rr.t 1856 2021-12-02 14:36:25Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 108;

use Net::DNS::RR;
local $Net::DNS::Parameters::DNSEXTLANG;			# suppress Extlang type queries


{					## check exception raised for unparsable argument
	foreach my $testcase ( undef, '', ' ', '. NULL x', '. OPT x', '. ATMA x', [], {} ) {
		my $test = defined $testcase ? "'$testcase'" : 'undef';
		eval { Net::DNS::RR->new($testcase) };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "Net::DNS::RR->new($test)\t[$exception]" );
	}
}


{					## check plausible ways to create empty record
	foreach my $testcase (
		'example.com	A',
		'example.com	IN',
		'example.com	IN A',
		'example.com	IN 123 A',
		'example.com	123 A',
		'example.com	123 IN A',
		'example.com	123 In Aaaa',
		'example.com	A \\# 0',
		) {
		my $rr = Net::DNS::RR->new("$testcase");
		is( length( $rr->rdata ), 0, "Net::DNS::RR->new( $testcase )" );
	}
}


{					## check basic functions
	my ( $name, $class, $ttl, $type, $rdata ) = qw(example.com IN 123 A 192.0.2.1);
	my $rr	  = Net::DNS::RR->new("$name $ttl $class $type $rdata");
	my $rdlen = length( $rr->rdata );
	is( $rr->owner,	   $name,  'expected value returned by $rr->owner' );
	is( $rr->type,	   $type,  'expected value returned by $rr->type' );
	is( $rr->class,	   $class, 'expected value returned by $rr->class' );
	is( $rr->ttl,	   $ttl,   'expected value returned by $rr->ttl' );
	is( $rr->rdstring, $rdata, 'expected value returned by $rr->rdstring' );
	is( $rr->rdlength, $rdlen, 'expected value returned by $rr->rdlength' );
}


{					## check basic parsing of all acceptable forms of A record
	my $example  = Net::DNS::RR->new('example.com. 0 IN A 192.0.2.1');
	my $expected = $example->string;
	foreach my $testcase (
		join( "\t", qw( example.com 0 IN A ), q(\# 4 c0 00 02 01) ),
		join( "\t", qw( example.com 0 IN A ), q(\# 4 c0000201 ) ),
		'example.com	0	IN	A	192.0.2.1',
		'example.com	0	IN	TYPE1	192.0.2.1',
		'example.com	0	CLASS1	A	192.0.2.1',
		'example.com	0	CLASS1	TYPE1	192.0.2.1',
		'example.com	0		A	192.0.2.1',
		'example.com	0		TYPE1	192.0.2.1',
		'example.com		IN	A	192.0.2.1',
		'example.com		IN	TYPE1	192.0.2.1',
		'example.com		CLASS1	A	192.0.2.1',
		'example.com		CLASS1	TYPE1	192.0.2.1',
		'example.com			A	192.0.2.1',
		'example.com			TYPE1	192.0.2.1',
		'example.com	IN	0	A	192.0.2.1',
		'example.com	IN	0	TYPE1	192.0.2.1',
		'example.com	CLASS1	0	A	192.0.2.1',
		'example.com	CLASS1	0	TYPE1	192.0.2.1',
		) {
		my $rr = Net::DNS::RR->new("$testcase");
		$rr->ttl( $example->ttl );			# TTL only shown if defined
		is( $rr->string, $expected, "Net::DNS::RR->new( $testcase )" );
	}
}


{					## check parsing of comments, quotes and brackets
	my $example  = Net::DNS::RR->new('example.com. 0 IN TXT "txt-data"');
	my $expected = $example->string;
	foreach my $testcase (
		q(example.com 0 IN TXT txt-data ; space delimited),
		q(example.com 0	   TXT txt-data),
		q(example.com	IN TXT txt-data),
		q(example.com	   TXT txt-data),
		q(example.com IN 0 TXT txt-data),
		q(example.com	0	IN	TXT	txt-data	; tab delimited),
		q(example.com	0		TXT	txt-data),
		q(example.com		IN	TXT	txt-data),
		q(example.com			TXT	txt-data),
		q(example.com	IN	0	TXT	txt-data),
		q(example.com	0	IN	TXT	"txt-data"	; "quoted"),
		q(example.com	0		TXT	"txt-data"),
		q(example.com		IN	TXT	"txt-data"),
		q(example.com			TXT	"txt-data"),
		q(example.com	IN	0	TXT	"txt-data"),
		'example.com (	0	IN	TXT	txt-data )	; bracketed',
		) {
		my $rr = Net::DNS::RR->new("$testcase");
		$rr->ttl( $example->ttl );			# TTL only shown if defined
		is( $rr->string, $expected, "Net::DNS::RR->new( $testcase )" );
	}
}


{					## check parsing of implemented RR type with hexadecimal RDATA
	my @common   = qw( example.com. 3600 IN TXT );
	my $expected = join "\t", @common, q("two separate" "quoted strings");
	my $testcase = join "\t", @common, q(\# 28 0c74776f2073657061726174650e71756f74656420737472696e6773);
	my $rr	     = Net::DNS::RR->new("$testcase");
	is( $rr->string, $expected, "Net::DNS::RR->new( $testcase )" );
}


{					## check for exception if RFC3597 format hexadecimal data inconsistent
	foreach my $testcase ( '\# 0 c0 00 02 01', '\# 3 c0 00 02 01', '\# 5 c0 00 02 01' ) {
		eval { Net::DNS::RR->new("example.com 3600 IN A $testcase") };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "mismatched length: $testcase\t[$exception]" );
	}
}


{					## check object construction from attribute list
	foreach my $testcase ( [type => 'A', address => '192.0.2.1'], [type => 'A', address => ['192.0.2.1']], ) {
		my $rr = Net::DNS::RR->new(@$testcase);
		is( length( $rr->rdata ), 4, "Net::DNS::RR->new( @$testcase )" );
	}

	foreach my $testcase (
		[type => 'A',		rdata => ''],
		[name => 'example.com', type  => 'MX'],
		[type => 'MX',		class => 'IN', ttl => 123],
		) {
		my $rr = Net::DNS::RR->new(@$testcase);
		is( length( $rr->rdata ), 0, "Net::DNS::RR->new( @$testcase )" );
	}
}


{					## check for exception for nonexistent attribute
	my $method = 'bogus-method';
	foreach my $testcase ( [type => 'A'], [type => 'ATMA'], [type => 'ATMA', unimplemented => 'x'], ) {
		eval { Net::DNS::RR->new(@$testcase)->$method('x') };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "unknown method:\t[$exception]" );
	}
	my $rr = Net::DNS::RR->new( type => 'A' );
	is( $rr->$method, undef, 'suppress repeated unknown method exception' );
	is( $rr->DESTROY, undef, 'DESTROY() exists to placate pre-5.18 AUTOLOAD' );
}


{					## check for exception on bad class method
	eval { xxxx Net::DNS::RR( type => 'X' ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unknown class method:\t[$exception]" );
}


{					## check for exception if RR name not recognised
	eval { Net::DNS::RR->new('example.com. IN BOGUS') };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unrecognised RR type:\t[$exception]" );
}


{					## check for exception when abusing $rr->type()
	my $rr = Net::DNS::RR->new( type => 'A' );
	eval { $rr->type('X'); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "cannot change type:\t[$exception]" );
}


{					## check for exception when abusing $rr->ttl()
	my $rr = Net::DNS::RR->new( type => 'A' );
	eval { $rr->ttl('1year'); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unknown time unit:\t[$exception]" );
}


{					## check for exception when abusing $rr->rdata()
	my $rr = Net::DNS::RR->new( type => 'SOA' );
	eval { $rr->rdata( pack 'H* H*', '00c000', '00000001' x 5 ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "compressed rdata:\t[$exception]" );
}


{					## check propagation of exception in string()
					## (relies on bug that nobody cares enough to fix)
	my $rr = Net::DNS::RR->new( type => 'MINFO', emailbx => '.' );
	local $SIG{__WARN__} = sub { die @_ };
	eval { $rr->string() };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "exception in string:\t[$exception]" );
}


{					## check propagation of exception in rdstring()
					## (relies on bug that nobody cares enough to fix)
	my $rr = Net::DNS::RR->new( type => 'MINFO', emailbx => '.' );
	local $SIG{__WARN__} = sub { die @_ };
	eval { $rr->rdatastr() };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "exception in rdstring:\t[$exception]" );
}


{					## check encode/decode functions
	foreach my $testcase (
		'example.com	A',
		'example.com	IN',
		'example.com	IN A',
		'example.com	IN 123 A',
		'example.com	123 A',
		'example.com	123 IN A',
		'example.com	A 192.0.2.1',
		) {
		my $rr	    = Net::DNS::RR->new("$testcase");
		my $encoded = $rr->encode;
		my $decoded = decode Net::DNS::RR( \$encoded );
		$rr->ttl( $decoded->ttl ) unless $rr->ttl;
		is( $decoded->string, $rr->string, "encode/decode $testcase" );
	}

	my $opt	    = Net::DNS::RR->new( type => 'OPT' );
	my $encoded = $opt->encode;
	my ( $decoded, $offset ) = decode Net::DNS::RR( \$encoded );
	is( $decoded->string, $opt->string,	"encode/decode OPT RR" );
	is( $offset,	      length($encoded), "decode returns offset of next RR" );
}


{					## check canonical encode function
	foreach my $testcase ( 'example.com 123 IN A', 'EXAMPLE.com 123 A 192.0.2.1', ) {
		my $rr	      = Net::DNS::RR->new("$testcase");
		my $expected  = unpack 'H*', $rr->encode(0);
		my $canonical = unpack 'H*', $rr->canonical;
		is( $canonical, $expected, "canonical encode $testcase" );
	}
}


{
	foreach my $testcase ( '', '000001', '0000010001000000010004', ) {
		my $wiredata	= pack 'H*', $testcase;
		my $question	= eval { decode Net::DNS::RR( \$wiredata ); };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "corrupt wire-format\t[$exception]" );
	}
}


{					## check plain and generic formats
	my @testcase = (
		[owner => 'example.com.', type => 'A'],
		[owner => 'example.com.', type => 'A', rdata => ''],
		['example.com.	IN	NS	a.iana-servers.net.'],
		[	'example.com.	IN	SOA	(
				sns.dns.icann.org. noc.dns.icann.org.
				2015082417	;serial
				7200		;refresh
				3600		;retry
				1209600		;expire
				3600		;minimum
			)'
			],
		[owner => 'example.com.', type => 'ATMA'],	# unimplemented
		[owner => 'example.com.', type => 'ATMA', rdata => ''],
		[owner => 'example.com.', type => 'ATMA', rdata => 'octets'],
		);
	foreach my $testcase (@testcase) {
		my $rr	  = Net::DNS::RR->new(@$testcase);
		my $type  = $rr->type;
		my $plain = Net::DNS::RR->new( $rr->plain );
		is( $plain->string, $rr->string, "parse rr->plain format $type" );
		my $rfc3597 = Net::DNS::RR->new( $rr->generic );
		is( $rfc3597->string, $rr->string, "parse rr->generic format $type" );
	}
}


{					## check RR sorting functions
	foreach my $attr ( [], ['preference'], ['X'] ) {
		my $func = Net::DNS::RR::MX->get_rrsort_func(@$attr);
		is( ref($func), 'CODE', "MX->get_rrsort_func(@$attr)" );
	}
}


eval {					## exercise printing functions
	require Data::Dumper;
	require IO::File;
	local $Data::Dumper::Maxdepth;
	local $Data::Dumper::Sortkeys;
	my $object = Net::DNS::RR->new('example.com A 192.0.2.1');
	my $file   = "03-rr.tmp";
	my $handle = IO::File->new( $file, '>' ) || die "Could not open $file for writing";
	select( ( select($handle), $object->print )[0] );
	select( ( select($handle), $object->dump )[0] );
	$Data::Dumper::Maxdepth = 6;
	$Data::Dumper::Sortkeys = 1;
	select( ( select($handle), $object->dump )[0] );
	close($handle);
	unlink($file);

	Net::DNS::RR::_wrap( 'exercise', '', "\n", "\n", "line\n", 'wrapping' );
};


exit;

