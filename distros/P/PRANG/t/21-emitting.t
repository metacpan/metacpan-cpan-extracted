#!/usr/bin/perl
#
#  This module tests output abilities of the module using the example
#  schema and some objects

use Test::More;
use strict;

use FindBin qw($Bin);
use lib $Bin;

use Octothorpe;
use XMLTests;
use Scriptalicious;
getopt;

# only valid tests.  While in general it may be possible to construct
# object structures which cannot emit valid objects, this is more of a
# problem with the Moose constraints.  If a general class of errors is
# discovered which need to be tested for, this may change.

our @valid_tests = XMLTests::find_tests "yaml";

plan tests => scalar @valid_tests;

for my $test ( sort @valid_tests ) {
	my $object = XMLTests::read_yaml($test);

	XMLTests::emit_test( $object, $test );
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

