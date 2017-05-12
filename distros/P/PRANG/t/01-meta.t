#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;
use t::Octothorpe;

ok( Fingernails->meta->get_attribute("currency")->has_xml_name,
	"has_attr produces an XML attribute"
);

my %atts;

for my $class (
	qw(Octothorpe Ampersand Caret Asteriks Pilcrow
	Deaeresis Fingernails )
	)
{
	for my $att ( $class->meta->get_all_attributes ) {
		if ( $att->does("PRANG::Graph::Meta::Element") ) {
			$atts{$att->name} = $att;
		}
	}
}
my @attnames = map { $_->name }
	sort { $a->insertion_order <=> $b->insertion_order }
	values %atts;
my %gn;

cmp_ok(@attnames, ">", 7, "found at least 7 elements in Octothorpe.pm");

for my $attname (@attnames) {
	my $gn = eval { $atts{$attname}->graph_node };
	if ( !$gn ) {
		if ($@) {
			diag("error during build of '$attname' graph node: $@");
		}
	}
	ok( $gn, "Build graph node for '$attname' attribute ("
			.($atts{$attname}->type_constraint).")"
	);
	$gn{$attname} = $gn;
}

ok( Octothorpe->meta->meta->does_role("PRANG::Graph::Meta::Class"),
	"use PRANG::Graph applies metarole"
);

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
