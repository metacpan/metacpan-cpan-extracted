#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;
use XML::LibXML;

{

	package Sins;

	use Moose;
	use PRANG::Graph;

	has_attr "envy" =>
		is => "ro",
		isa => "Str",
		xml_name => "Envy",
		;

	has_attr "greed" =>
		is => "ro",
		isa => "Int",
		;

	has_attr "lust" =>
		is => "ro",
		isa => "Int",
		required => 1,
		;

	has_attr "gluttony" =>
		is => "ro",
		;
}

my $parser = XML::LibXML->new;
my $doc = $parser->parse_string(<<XML);
<tests>
  <ok>
    <Sins lust="0" />
    <Sins Envy="Elli" greed="123406" lust="1" gluttony="AEgir" />
  </ok>
  <fail>
    <Sins />
    <Sins lust="0 but wrong" />
    <Sins lust="1" greed=" -1" />
  </fail>
</tests>
XML

my @ok_init_args = (
	{ lust => 0 },
	{qw(envy Elli greed 123406 lust 1 gluttony AEgir)},
);

my $context = PRANG::Graph::Context->new(
	xpath => "/dummy",
	xsi => { "" => "" },
);
my $test_num = 1;
for my $oktest ( $doc->findnodes("//ok/Sins") ) {
	next unless $oktest->isa("XML::LibXML::Element");
	my @attrs = $oktest->attributes;
	my %rv =
		eval { Sins->meta->accept_attributes( \@attrs, $context ) };
	is($@, "", "ok test $test_num - no exception");
	is_deeply(
		\%rv, $ok_init_args[$test_num-1],
		"ok test $test_num - correct init args returned"
	);
	my $sin = eval{ Sins->new(%rv) };
	ok($sin, "created new sin OK") or diag("exception: $@");

	my $node = $doc->createElement("Blah");
	eval { Sins->meta->add_xml_attr($sin, $node, $context) };
	is($@, "", "ok test $test_num - output attributes no exception");
	my @wrote_attrs = $node->attributes;
	is( @wrote_attrs, @attrs,
		"ok test $test_num - correct number of output attributes"
	);
	$test_num++;
}

$test_num = 1;
for my $failtest ( $doc->findnodes("//fail/Sins") ) {
	next unless $failtest->isa("XML::LibXML::Element");
	my @attrs = $failtest->attributes;
	my %rv = eval {
		Sins->new(
			Sins->meta->accept_attributes( \@attrs, $context )
		);
	};
	isnt($@, "", "fail test $test_num - exception raised");
	$test_num++;
}

# Copyright (C) 2009, 2010  NZ Registry Services
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
