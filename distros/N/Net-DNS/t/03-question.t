#!/usr/bin/perl
# $Id: 03-question.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 105;
use TestToolkit;

use Net::DNS::Question;
use Net::DNS::Parameters;


for my $question ( Net::DNS::Question->new( my $name = 'example.com', 'A', 'IN' ) ) {
	ok( $question->isa('Net::DNS::Question'), 'object returned by new() constructor' );

	is( $question->qname,  $name,		 '$question->qname returns expected value' );
	is( $question->qtype,  'A',		 '$question->qtype returns expected value' );
	is( $question->qclass, 'IN',		 '$question->qclass returns expected value' );
	is( $question->name,   $name,		 '$question->name returns expected value' );
	is( $question->type,   $question->qtype, '$question->type returns expected value' );
	is( $question->zname,  $name,		 '$question->zname returns expected value' );
	is( $question->ztype,  $question->qtype, '$question->ztype returns expected value' );
	is( $question->zclass, $question->class, '$question->zclass returns expected value' );

	my $string   = $question->string;
	my $expected = "$name.\tIN\tA";
	is( $string, $expected, '$question->string returns text representation of object' );

	my $test = 'new() argument undefined or absent';
	is( Net::DNS::Question->new( $name, 'A', undef )->string,   $expected, "$test\t( $name,\tA,\tundef\t)" );
	is( Net::DNS::Question->new( $name, 'A', () )->string,	    $expected, "$test\t( $name,\tA,\t\t)" );
	is( Net::DNS::Question->new( $name, undef, 'IN' )->string,  $expected, "$test\t( $name,\tundef,\tIN\t)" );
	is( Net::DNS::Question->new( $name, (), 'IN' )->string,	    $expected, "$test\t( $name,\t\tIN\t)" );
	is( Net::DNS::Question->new( $name, undef, undef )->string, $expected, "$test\t( $name,\tundef,\tundef\t)" );
	is( Net::DNS::Question->new( $name, (), () )->string,	    $expected, "$test\t( $name \t\t\t)" );
}


foreach my $class (qw(IN CLASS1 ANY)) {
	my $test = 'new() arguments in zone file order';
	my $fqdn = 'example.com.';
	foreach my $type (qw(A TYPE1 ANY)) {
		my $testcase = Net::DNS::Question->new( $fqdn, $class, $type )->string;
		my $expected = Net::DNS::Question->new( $fqdn, $type,  $class )->string;
		is( $testcase, $expected, "$test\t( $fqdn,\t$class,\t$type\t)" );
	}
}


foreach my $class (qw(IN HS ANY)) {
	my $test = 'decoded object matches encoded data';
	foreach my $type (qw(A AAAA MX NS SOA ANY)) {
		my $question = Net::DNS::Question->new( 'example.com', $type, $class );
		my $encoded  = $question->encode;
		my $expected = $question->string;
		my $decoded  = Net::DNS::Question->decode( \$encoded );
		is( $decoded->string, $expected, "$test\t$expected" );
	}
}


for my $question ( Net::DNS::Question->new('example.com') ) {
	my $encoded = $question->encode;
	my ( $decoded, $offset ) = Net::DNS::Question->decode( \$encoded );
	is( $offset, length($encoded), 'returned offset has expected value' );
}


my @IPv4part = ( 1 .. 4 );
while (@IPv4part) {
	my $test   = 'interpret IPv4 prefix as PTR query';
	my $prefix = join '.', @IPv4part;
	my $domain = Net::DNS::Question->new($prefix);
	my $actual = $domain->qname;
	my $invert = join '.', reverse 'in-addr.arpa', @IPv4part;
	my $inaddr = Net::DNS::Question->new($invert);
	my $expect = $inaddr->qname;
	is( $actual, $expect, "$test\t$prefix" );
	pop @IPv4part;
}


foreach my $type (qw(NS SOA ANY)) {
	my $test     = "query $type in in-addr.arpa namespace";
	my $question = Net::DNS::Question->new( '1.2.3.4', $type );
	my $qtype    = $question->qtype;
	my $string   = $question->string;
	is( $qtype, $type, "$test\t$string" );
}


foreach my $n ( 32, 24, 16, 8 ) {
	my $ip4	   = '1.2.3.4';
	my $test   = "accept CIDR address/$n prefix syntax";
	my $m	   = ( ( $n + 7 ) >> 3 ) << 3;
	my $actual = Net::DNS::Question->new("$ip4/$n");
	my $expect = Net::DNS::Question->new("$ip4/$m");
	my $string = $expect->qname;
	is( $actual->qname, $expect->qname, "$test\t$string" );
}


is(	Net::DNS::Question->new('1:2:3:4:5:6:7:8')->string,
	"8.0.0.0.7.0.0.0.6.0.0.0.5.0.0.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.ip6.arpa.\tIN\tPTR",
	'interpret IPv6 address as PTR query in ip6.arpa namespace'
	);
is(	Net::DNS::Question->new('::ffff:192.0.2.1')->string,
	"1.2.0.192.in-addr.arpa.\tIN\tPTR",
	'interpret IPv6 form of IPv4 address as query in in-addr.arpa'
	);
is(	Net::DNS::Question->new('1:2:3:4:5:6:192.0.2.1')->string,
	"1.0.2.0.0.0.0.c.6.0.0.0.5.0.0.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.ip6.arpa.\tIN\tPTR",
	'interpret IPv6 + embedded IPv4 address as query in ip6.arpa'
	);
is( Net::DNS::Question->new(':x:')->string,
	":x:.\tIN\tA", 'non-address character precludes interpretation as PTR query' );
is( Net::DNS::Question->new(':.:')->string,
	":.:.\tIN\tA", 'non-numeric character precludes interpretation as PTR query' );


my @IPv6part = ( 1 .. 8 );
while (@IPv6part) {
	my $n	   = 16 * scalar(@IPv6part);
	my $test   = 'interpret IPv6 prefix as PTR query';
	my $prefix = join ':', @IPv6part;
	my $actual = Net::DNS::Question->new($prefix)->qname;
	my $expect = Net::DNS::Question->new("$prefix/$n")->qname;
	is( $actual, $expect, "$test\t$prefix" ) if $prefix =~ /:/;
	pop @IPv6part;
}


foreach my $n ( 16, 12, 8, 4 ) {
	my $ip6	   = '1234:5678:9012:3456:7890:1234:5678:9012';
	my $test   = "accept IPv6 address/$n prefix syntax";
	my $m	   = ( ( $n + 3 ) >> 2 ) << 2;
	my $actual = Net::DNS::Question->new("$ip6/$n");
	my $expect = Net::DNS::Question->new("$ip6/$m");
	my $string = $expect->qname;
	is( $actual->qname, $expect->qname, "$test\t$string" );
}


foreach my $i ( reverse 0 .. 6 ) {
	my $expected = length Net::DNS::Question->new('1:2:3:4:5:6:7:8')->qname;
	foreach my $j ( $i + 3 .. 9 ) {
		my $ip6	 = join( ':', 1 .. $i ) . '::' . join( ':', $j .. 8 );
		my $name = Net::DNS::Question->new("$ip6")->qname;
		is( length $name, $expected, "check length of expanded IPv6 address\t$ip6" );
	}
}


eval {					## no critic		# exercise but do not test print
	require IO::File;
	my $object = Net::DNS::Question->new('example.com');
	my $file   = '03-question.txt';
	my $handle = IO::File->new( $file, '>' ) || die "Could not open $file for writing";
	select( ( select($handle), $object->print )[0] );
	close($handle);
	unlink($file);
};


exception( 'argument undefined',  sub { Net::DNS::Question->new(undef) } );
exception( 'corrupt wire-format', sub { my $wire = pack 'H*', '000001'; Net::DNS::Question->decode( \$wire ) } );

foreach my $method (qw(qname qtype qclass name)) {
	exception( "$method is read-only", sub { Net::DNS::Question->new('.')->$method('any') } );
}

exit;

