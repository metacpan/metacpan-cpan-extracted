#!/usr/bin/perl -w
#
# test script for "vanilla" commands and responses

use Test::More no_plan;
use strict;

# of particular note: these stateful EPP messages are never converted
# to the stateless SRS protocol; so they will not be covered by later
# transform tests and tests before then must be particularly thorough.

#    - Hello / Greeting
#    - logout

BEGIN {
	use_ok("SRS::EPP::Command");
	use_ok("SRS::EPP::Response");
}

my $command = SRS::EPP::Command->new(
	xmlstring => "not really",
);

isa_ok($command, "SRS::EPP::Command", "new 'vanilla' command");

my $response = SRS::EPP::Response->new(
	code => 1000,
);

isa_ok($response, "SRS::EPP::Response", "new 'vanilla' response");

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
