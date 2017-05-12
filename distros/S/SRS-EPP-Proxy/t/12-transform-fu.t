#!/usr/bin/perl -w
#
# test script for general transformation infrastructure and helper
# functions

use strict;
use Test::More;

# the plan for this one is to include 'generic' transformation
# functions, not related to a particular message, demonstrating them
# on the 'dummy' schema introduced in the 10-xml-schema.t test case.
# It may disappear.
#
# At the least, this test case will test a null transform using the
# relevant Perl modules which wrap this part of the system.

plan skip_all => "TODO";

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
