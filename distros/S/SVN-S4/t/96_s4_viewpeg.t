#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2002-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use IO::File;
use Test::More;
use Cwd;

BEGIN { plan tests => 4 }
BEGIN { require "./t/test_utils.pl"; }

system("/bin/rm -rf test_dir/viewpeg");

chdir "test_dir" or die;
$ENV{CWD} = getcwd;
our $S4 = "${PERL} ../s4";

like_cmd("${S4} co $REPO/views/trunk/viewpeg",
	 qr/Checked out revision/);

#use Data::Dumper; print Dumper(file_list("viewpeg"));
is_deeply(file_list("viewpeg"),
          ['viewpeg',
	   'viewpeg/Project.viewspec',
	   'viewpeg/trunk_tdir1_11',
	   'viewpeg/trunk_tdir1_11/tsub1',
	   'viewpeg/trunk_tdir1_11/tsub2',
	   'viewpeg/trunk_tdir1_12',
	   'viewpeg/trunk_tdir1_12/tsub1',
	   'viewpeg/trunk_tdir1_12/tsub1/rev12',
	   'viewpeg/trunk_tdir1_12/tsub2'
	   ], "check files in viewpeg");


like_cmd("${S4} update viewpeg",
	 qr/At revision/);
is_deeply(file_list("viewpeg"),
          ['viewpeg',
	   'viewpeg/Project.viewspec',
	   'viewpeg/trunk_tdir1_11',
	   'viewpeg/trunk_tdir1_11/tsub1',
	   'viewpeg/trunk_tdir1_11/tsub2',
	   'viewpeg/trunk_tdir1_12',
	   'viewpeg/trunk_tdir1_12/tsub1',
	   'viewpeg/trunk_tdir1_12/tsub1/rev12',
	   'viewpeg/trunk_tdir1_12/tsub2'
	   ], "check files in viewpeg");
