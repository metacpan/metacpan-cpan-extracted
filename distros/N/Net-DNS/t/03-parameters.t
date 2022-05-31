#!/usr/bin/perl
# $Id: 03-parameters.t 1865 2022-05-21 09:57:49Z willem $	-*-perl-*-
#

use strict;
use warnings;

use Net::DNS::Parameters qw(:class :type :opcode :rcode :ednsoption :dsotype);

use Test::More tests => ( 5 + scalar keys %Net::DNS::Parameters::classbyval ) +
		( 3 + scalar keys %Net::DNS::Parameters::typebyval ) +
		( 3 + scalar keys %Net::DNS::Parameters::opcodebyval ) +
		( 3 + scalar keys %Net::DNS::Parameters::rcodebyval ) +
		( 2 + scalar keys %Net::DNS::Parameters::ednsoptionbyval ) +
		( 2 + scalar keys %Net::DNS::Parameters::dsotypebyval );


{					## check class conversion functions
	my $anon = 65500;
	foreach ( sort { $a <=> $b } $anon, keys %Net::DNS::Parameters::classbyval ) {
		my $name	= classbyval($_);
		my $code	= eval { classbyname($name) };
		my ($exception) = split /\n/, "$@\n";
		is( $code, $_, "classbyname($name)\t$exception" );
	}

	my $large = 65536;
	foreach my $testcase ( "BOGUS", "Bogus", "CLASS$large" ) {
		eval { classbyname($testcase); };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "classbyname($testcase)\t[$exception]" );
	}

	eval { classbyval($large); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "classbyval($large)\t[$exception]" );
}


{					## check type conversion functions
	foreach ( sort { $a <=> $b } keys %Net::DNS::Parameters::typebyval ) {
		my $name	= typebyval($_);
		my $code	= eval { typebyname($name) };
		my ($exception) = split /\n/, "$@\n";
		is( $code, $_, "typebyname($name)\t$exception" );
	}
	is( typebyname('*'), typebyname('ANY'), "typebyname(*)" );

	my $large = 65536;
	foreach my $testcase ("TYPE$large") {
		eval { typebyname($testcase); };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "typebyname($testcase)\t[$exception]" );
	}

	eval { typebyval($large); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "typebyval($large)\t[$exception]" );
}


{					## check OPCODE type conversion functions
	my $anon = 255;
	foreach ( sort { $a <=> $b } $anon, keys %Net::DNS::Parameters::opcodebyval ) {
		my $name	= opcodebyval($_);
		my $code	= eval { opcodebyname($name) };
		my ($exception) = split /\n/, "$@\n";
		is( $code, $_, "opcodebyname($name)\t$exception" );
	}
	is( opcodebyname('NS_NOTIFY_OP'), opcodebyname('NOTIFY'), "opcodebyname(NS_NOTIFY_OP)" );

	foreach my $testcase ('BOGUS') {
		eval { opcodebyname($testcase); };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "opcodebyname($testcase)\t[$exception]" );
	}
}


{					## check RCODE conversion functions
	my $anon = 4095;
	foreach ( sort { $a <=> $b } $anon, keys %Net::DNS::Parameters::rcodebyval ) {
		my $name	= rcodebyval($_);
		my $code	= eval { rcodebyname($name) };
		my ($exception) = split /\n/, "$@\n";
		is( $code, $_, "rcodebyname($name)\t$exception" );
	}
	is( rcodebyname('BADVERS'), rcodebyname('BADSIG'), "rcodebyname(BADVERS)" );

	foreach my $testcase ('BOGUS') {
		eval { rcodebyname($testcase); };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "rcodebyname($testcase)\t[$exception]" );
	}
}


{					## check EDNS option conversion functions
	my $anon = 65535;
	foreach ( sort { $a <=> $b } $anon, keys %Net::DNS::Parameters::ednsoptionbyval ) {
		my $name	= ednsoptionbyval($_);
		my $code	= eval { ednsoptionbyname($name) };
		my ($exception) = split /\n/, "$@\n";
		is( $code, $_, "ednsoptionbyname($name)\t$exception" );
	}

	foreach my $testcase ('BOGUS') {
		eval { ednsoptionbyname($testcase); };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "ednsoptionbyname($testcase)\t[$exception]" );
	}
}


{					## check DSO type conversion functions
	my $anon = 65535;
	foreach ( sort { $a <=> $b } $anon, keys %Net::DNS::Parameters::dsotypebyval ) {
		my $name	= dsotypebyval($_);
		my $code	= eval { dsotypebyname($name) };
		my ($exception) = split /\n/, "$@\n";
		is( $code, $_, "dsotypebyname($name)\t$exception" );
	}

	foreach my $testcase ('BOGUS') {
		eval { dsotypebyname($testcase); };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "dsotypebyname($testcase)\t[$exception]" );
	}
}


exit;

