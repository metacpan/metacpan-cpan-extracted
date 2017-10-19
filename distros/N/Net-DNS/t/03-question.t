# $Id: 03-question.t 1595 2017-09-12 09:10:56Z willem $	-*-perl-*-

use strict;

use Net::DNS::Question;
use Net::DNS::Parameters;
local $Net::DNS::Parameters::DNSEXTLANG;			# suppress Extlang type queries

use Test::More tests => 121 + keys(%classbyname) + keys(%typebyname);


{					## check type conversion functions
	my ($anon) = 65500;
	is( typebyval(1),	      'A',	   "typebyval(1)" );
	is( typebyval($anon),	      "TYPE$anon", "typebyval($anon)" );
	is( typebyname("TYPE$anon"),  $anon,	   "typebyname('TYPE$anon')" );
	is( typebyname("TYPE0$anon"), $anon,	   "typebyname('TYPE0$anon')" );

	my $large = 1 << 16;
	foreach my $testcase ( "BOGUS", "Bogus", "TYPE$large" ) {
		eval { typebyname($testcase); };
		my $exception = $1 if $@ =~ /^(.+)\n/;
		ok( $exception ||= '', "typebyname($testcase)\t[$exception]" );
	}

	eval { typebyval($large); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "typebyval($large)\t[$exception]" );

	foreach ( sort keys %Net::DNS::Parameters::typebyname ) {
		my $expect = /[*]/ ? 'ANY' : uc($_);
		my $name = eval { typebyval( typebyname($_) ) };
		my $exception = $@ =~ /^(.+)\n/ ? $1 : '';
		is( $name, $expect, "typebyname('$_')\t$exception" );
	}
}


{					## check class conversion functions
	my ($anon) = 65500;
	is( classbyval(1),		'IN',	      "classbyval(1)" );
	is( classbyval($anon),		"CLASS$anon", "classbyval($anon)" );
	is( classbyname("CLASS$anon"),	$anon,	      "classbyname('CLASS$anon')" );
	is( classbyname("CLASS0$anon"), $anon,	      "classbyname('CLASS0$anon')" );

	my $large = 1 << 16;
	foreach my $testcase ( "BOGUS", "Bogus", "CLASS$large" ) {
		eval { classbyname($testcase); };
		my $exception = $1 if $@ =~ /^(.+)\n/;
		ok( $exception ||= '', "classbyname($testcase)\t[$exception]" );
	}

	eval { classbyval($large); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "classbyval($large)\t[$exception]" );

	foreach ( sort keys %Net::DNS::Parameters::classbyname ) {
		my $expect = /[*]/ ? 'ANY' : uc($_);
		my $name = eval { classbyval( classbyname($_) ) };
		my $exception = $@ =~ /^(.+)\n/ ? $1 : '';
		is( $name, $expect, "classbyname('$_')\t$exception" );
	}
}


{
	my $name = 'example.com';
	my $question = new Net::DNS::Question( $name, 'A', 'IN' );
	ok( $question->isa('Net::DNS::Question'), 'object returned by new() constructor' );

	is( $question->qname,  $name,		 '$question->qname returns expected value' );
	is( $question->qtype,  'A',		 '$question->qtype returns expected value' );
	is( $question->qclass, 'IN',		 '$question->qclass returns expected value' );
	is( $question->name,   $question->qname, '$question->name returns expected value' );
	is( $question->type,   $question->qtype, '$question->type returns expected value' );
	is( $question->zname,  $question->qname, '$question->zname returns expected value' );
	is( $question->ztype,  $question->qtype, '$question->ztype returns expected value' );
	is( $question->zclass, $question->class, '$question->zclass returns expected value' );

	my $string   = $question->string;
	my $expected = "$name.\tIN\tA";
	is( $string, $expected, '$question->string returns text representation of object' );

	my $test = 'new() argument undefined or absent';
	is( new Net::DNS::Question( $name, 'A',   undef )->string, $expected, "$test\t( $name,\tA,\tundef\t)" );
	is( new Net::DNS::Question( $name, 'A',   ()	)->string, $expected, "$test\t( $name,\tA,\t\t)" );
	is( new Net::DNS::Question( $name, undef, 'IN'	)->string, $expected, "$test\t( $name,\tundef,\tIN\t)" );
	is( new Net::DNS::Question( $name, (),    'IN'	)->string, $expected, "$test\t( $name,\t\tIN\t)" );
	is( new Net::DNS::Question( $name, undef, undef )->string, $expected, "$test\t( $name,\tundef,\tundef\t)" );
	is( new Net::DNS::Question( $name, (),    ()	)->string, $expected, "$test\t( $name \t\t\t)" );
}


{
	my $test = 'new() arguments in zone file order';
	my $fqdn = 'example.com.';
	foreach my $class (qw(IN CLASS1 ANY)) {
		foreach my $type (qw(A TYPE1 ANY)) {
			my $testcase = new Net::DNS::Question( $fqdn, $class, $type )->string;
			my $expected = new Net::DNS::Question( $fqdn, $type,  $class )->string;
			is( $testcase, $expected, "$test\t( $fqdn,\t$class,\t$type\t)" );
		}
	}
}


{
	my $question = eval { new Net::DNS::Question(undef); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "argument undefined\t[$exception]" );
}


{
	foreach my $method (qw(qname qtype qclass name)) {
		my $question = eval { new Net::DNS::Question('.')->$method('name'); };
		my $exception = $1 if $@ =~ /^(.+)\n/;
		ok( $exception ||= '', "$method read-only:\t[$exception]" );
	}
}


{
	my $wiredata = pack 'H*', '000001';
	my $question = eval { decode Net::DNS::Question( \$wiredata ); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "corrupt wire-format\t[$exception]" );
}


{
	my $test = 'decoded object matches encoded data';
	foreach my $class (qw(IN HS ANY)) {
		foreach my $type (qw(A AAAA MX NS SOA ANY)) {
			my $question = new Net::DNS::Question( 'example.com', $type, $class );
			my $encoded  = $question->encode;
			my $expected = $question->string;
			my $decoded  = decode Net::DNS::Question( \$encoded );
			is( $decoded->string, $expected, "$test\t$expected" );
		}
	}
}


{
	my $question = new Net::DNS::Question('example.com');
	my $encoded  = $question->encode;
	my ( $decoded, $offset ) = decode Net::DNS::Question( \$encoded );
	is( $offset, length($encoded), 'returned offset has expected value' );
}


{
	my @part = ( 1 .. 4 );
	while (@part) {
		my $test   = 'interpret IPv4 prefix as PTR query';
		my $prefix = join '.', @part;
		my $domain = new Net::DNS::Question($prefix);
		my $actual = $domain->qname;
		my $invert = join '.', reverse 'in-addr.arpa', @part;
		my $inaddr = new Net::DNS::Question($invert);
		my $expect = $inaddr->qname;
		is( $actual, $expect, "$test\t$prefix" );
		pop @part;
	}
}


{
	foreach my $type (qw(NS SOA ANY)) {
		my $test     = "query $type in in-addr.arpa namespace";
		my $question = new Net::DNS::Question( '1.2.3.4', $type );
		my $qtype    = $question->qtype;
		my $string   = $question->string;
		is( $qtype, $type, "$test\t$string" );
	}
}


{
	foreach my $n ( 32, 24, 16, 8 ) {
		my $ip4	   = '1.2.3.4';
		my $test   = "accept CIDR address/$n prefix syntax";
		my $m	   = ( ( $n + 7 ) >> 3 ) << 3;
		my $actual = new Net::DNS::Question("$ip4/$n");
		my $expect = new Net::DNS::Question("$ip4/$m");
		my $string = $expect->qname;
		is( $actual->qname, $expect->qname, "$test\t$string" );
	}
}


{
	is(	new Net::DNS::Question('1:2:3:4:5:6:7:8')->string,
		"8.0.0.0.7.0.0.0.6.0.0.0.5.0.0.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.ip6.arpa.\tIN\tPTR",
		'interpret IPv6 address as PTR query in ip6.arpa namespace'
		);
	is(	new Net::DNS::Question('::ffff:192.0.2.1')->string,
		"1.2.0.192.in-addr.arpa.\tIN\tPTR",
		'interpret IPv6 form of IPv4 address as query in in-addr.arpa'
		);
	is(	new Net::DNS::Question('1:2:3:4:5:6:192.0.2.1')->string,
		"1.0.2.0.0.0.0.c.6.0.0.0.5.0.0.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.ip6.arpa.\tIN\tPTR",
		'interpret IPv6 + embedded IPv4 address as query in ip6.arpa'
		);
	is(	new Net::DNS::Question(':x:')->string,
		":x:.\tIN\tA",
		'non-address character precludes interpretation as PTR query'
		);
	is(	new Net::DNS::Question(':.:')->string,
		":.:.\tIN\tA",
		'non-numeric character precludes interpretation as PTR query'
		);
}


{
	my @part = ( 1 .. 8 );
	while (@part) {
		my $n	   = 16 * scalar(@part);
		my $test   = 'interpret IPv6 prefix as PTR query';
		my $prefix = join ':', @part;
		my $actual = new Net::DNS::Question($prefix)->qname;
		my $expect = new Net::DNS::Question("$prefix/$n")->qname;
		is( $actual, $expect, "$test\t$prefix" ) if $prefix =~ /:/;
		pop @part;
	}
}


{
	foreach my $n ( 16, 12, 8, 4 ) {
		my $ip6	   = '1234:5678:9012:3456:7890:1234:5678:9012';
		my $test   = "accept IPv6 address/$n prefix syntax";
		my $m	   = ( ( $n + 3 ) >> 2 ) << 2;
		my $actual = new Net::DNS::Question("$ip6/$n");
		my $expect = new Net::DNS::Question("$ip6/$m");
		my $string = $expect->qname;
		is( $actual->qname, $expect->qname, "$test\t$string" );
	}
}


{
	my $expected = length new Net::DNS::Question('1:2:3:4:5:6:7:8')->qname;
	foreach my $i ( reverse 0 .. 6 ) {
		foreach my $j ( $i + 3 .. 9 ) {
			my $ip6 = join( ':', 1 .. $i ) . '::' . join( ':', $j .. 8 );
			my $name = new Net::DNS::Question("$ip6")->qname;
			is( length $name, $expected, "check length of expanded IPv6 address\t$ip6" );
		}
	}
}


eval {					## exercise but do not test print
	my $object   = new Net::DNS::Question('example.com');
	my $filename = '03-question.txt';
	open( TEMP, ">$filename" ) || die "Could not open $filename for writing";
	select( ( select(TEMP), $object->print )[0] );
	close(TEMP);
	unlink($filename);
};


					## exercise but do not test ad hoc RRtype registration
Net::DNS::Parameters::register( 'TOY', 65280 );			# RR type name and number
Net::DNS::Parameters::register( 'TOY', 65280 );			# ignore duplicate entry
eval { Net::DNS::Parameters::register('ANY') };			# reject CLASS identifier
eval { Net::DNS::Parameters::register('A') };			# reject conflicting type name
eval { Net::DNS::Parameters::register( 'Z', 1 ) };		# reject conflicting type number


exit;

