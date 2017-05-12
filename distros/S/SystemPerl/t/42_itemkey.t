#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2014 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test;

BEGIN { plan tests => 2 }
BEGIN { require "t/test_utils.pl"; }

use SystemC::Coverage::ItemKey;
ok(1);

my $filename = "src/SpCoverage.cpp";
my $ok = SystemC::Coverage::ItemKey::_edit_code($filename, 'nowrite');
ok($ok?1:0, 1, "$filename is out of date relative to ItemKey.pm");

if ($ENV{VERILATOR_AUTHOR_SITE}) {
    SystemC::Coverage::ItemKey::_edit_code($filename);
}
