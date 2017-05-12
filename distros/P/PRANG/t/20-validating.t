#!/usr/bin/perl
#
#  This module tests parsing/validation abilities of the module using
#  the example schema

use Test::More;
use strict;

use FindBin qw($Bin);
use lib $Bin;

use Scriptalicious;
use Octothorpe;
use XMLTests;

getopt;
our @valid_tests = XMLTests::find_tests "xml/valid";

our @invalid_tests = XMLTests::find_tests "xml/invalid";

our @lax_tests = XMLTests::find_tests "xml/lax";

plan tests => @valid_tests + (@invalid_tests * 2) + @lax_tests;

for my $test ( sort @valid_tests ) {
	my $xml = XMLTests::read_xml($test) or die "erp!";

	my $object = XMLTests::parse_test( "Octothorpe", $xml, $test );
}

for my $test ( sort @invalid_tests ) {
	my $xml = XMLTests::read_xml($test);

	my $error = XMLTests::parsefail_test( "Octothorpe", $xml, $test );
	if ( $xml =~ m{<!-- error: /(.*)/ -->} ) {
		my $expected_error = $1;
		like(
			$error, qr/$expected_error/,
			"$test - exception as expected"
		);
	}
	else {
	SKIP: {
			skip "no exception comment in test case", 1;
		}
	}
}

for my $test ( sort @lax_tests ) {
	my $xml = XMLTests::read_xml($test) or die "erp!";

	my $object = XMLTests::parse_test( "Octothorpe", $xml, $test, 1 );
}


# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>
