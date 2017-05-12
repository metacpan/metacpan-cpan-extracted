#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2002-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test::More;
use Cwd;

BEGIN { plan tests => 1 }
BEGIN { require "./t/test_utils.pl"; }

SKIP: {
    skip("Not in a subversion area",1)
	if (!-e "test_dir/trunk/.svn");

    run_system("${PERL} s4 info test_dir/trunk");
    ok(1,'s4 info');
}
