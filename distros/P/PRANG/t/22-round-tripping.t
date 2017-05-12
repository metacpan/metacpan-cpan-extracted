#!/usr/bin/perl
#
#  This module re-uses the data from the previous two tests, and
#  checks that they both round-trip to XML and back or from XML and
#  back without significant different, according to XML::Compare
#  and/or Test::More::is_deeply.

use Test::More;
use strict;

use FindBin qw($Bin);
use lib $Bin;

use Scriptalicious;
use Octothorpe;
use XMLTests;
use XML::Compare;
use YAML;

getopt;

our @xml_tests = XMLTests::find_tests "xml/valid";

our @yaml_tests = XMLTests::find_tests "yaml";

plan tests => @xml_tests * 3 + @yaml_tests * 3;

for my $test ( sort @xml_tests ) {
	my $xml = XMLTests::read_xml($test);
	my @ignores = $xml =~ m{<!-- ignore: (.*) -->}g;

	my $ignore_xmlns;
	if (@ignores) {
		$ignore_xmlns = {};
		my $dom = XML::LibXML->load_xml(string => $xml);
		my @nodes = $dom->findnodes('@xmlns:*');
		for my $ns (@nodes) {
			next unless $ns->can("declaredURI");
			$ignore_xmlns->{$ns->declaredPrefix}
				= $ns->declaredURI;
		}
	}
	my $comparator = XML::Compare->new(
		(   @ignores
			? ( ignore => \@ignores,
				ignore_xmlns => $ignore_xmlns
				)
			: ()
		),
	);

	my $object = XMLTests::parse_test( "Octothorpe", $xml, $test );
SKIP:{
		skip "parse failed", 2 if !$object;

		my $xml_2 = XMLTests::emit_test($object, $test);
		skip "re-emit failed", 1 if !$xml_2;

		ok( eval { $comparator->same($xml, $xml_2) },
			"$test - round-tripped from XML to data and back OK"
			)
			or do {
			diag("Error: $@");
			diag("XML was: ".$xml_2);
			};
	}
}

for my $test ( sort @yaml_tests ) {
	my ($object, $yaml) = XMLTests::read_yaml($test);
SKIP:{
		my $xml = XMLTests::emit_test($object, $test);
		skip "emit failed", 2 if !$xml;

		my $object_2 = XMLTests::parse_test(
			"Octothorpe", $xml, $test,
			)
			or do {
			diag("tried to parse:\n".$xml);
			skip "re-parse failed", 1;
			};

		skip "round-trip test skipped for this case", 1
			if $yaml =~ /NO_ROUNDTRIP/;

		is_deeply(
			$object_2, $object,
			"$test - round-tripped from YAML to XML and back OK"
			)
			or do {
			diag("parsed to: ".Dump($object_2));
			};
	}
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

