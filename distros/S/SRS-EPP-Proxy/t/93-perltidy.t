#!/usr/bin/perl -w

use strict;
use Test::More;
use FindBin qw($Bin);
plan skip_all => 'set TEST_TIDY to enable this test'
	unless $ENV{TEST_TIDY};
my $perltidy = "$Bin/../perltidy";
plan skip_all => 'no perltidy.pl script; run this from a git clone'
	unless -x $perltidy;
plan "no_plan";

my $output = qx($perltidy -t);
my $rc     = $?;

ok( !$rc, "all files tidy" );
diag($output) if $rc;

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
