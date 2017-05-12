#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2002-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test::More;
use Cwd;

BEGIN { plan tests => 3 }
BEGIN { require "./t/test_utils.pl"; }

like_cmd("${PERL} s4 revert test_dir/trunk/tdir2/tfile1",
	 qr/.*/);

write_text("test_dir/trunk/tdir2/tfile1", 'text_to_appear_in_diff');
ok(1,'write_text');

like_cmd("${PERL} s4 snapshot test_dir/trunk/tdir2",
	 qr/text_to_appear_in_diff/);
