#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2002-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test::More;
use Cwd;

BEGIN { plan tests => 6 }
BEGIN { require "./t/test_utils.pl"; }

our $S4 = "${PERL} ../../s4";

chdir "test_dir/trunk";

like_cmd("${S4} workpropset testprop value",
	 qr/^$/);

like_cmd("${S4} workpropget testprop",
	 qr/value/);

like_cmd("${S4} workproplist -v",
	 qr/testprop\n\s+value/);

like_cmd("${S4} workproplist --xml -v",
	 qr/name=/);

like_cmd("${S4} workpropdel testprop",
	 qr/^$/);

like_cmd("${S4} workpropget testprop",
	 qr/^$/);

