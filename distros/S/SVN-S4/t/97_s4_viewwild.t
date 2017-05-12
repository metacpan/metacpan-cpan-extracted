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

system("/bin/rm -rf test_dir/viewwild");

chdir "test_dir" or die;
$ENV{CWD} = getcwd;
our $S4 = "${PERL} ../s4";
my $files;

like_cmd("${S4} co $REPO/views/trunk/viewwild",
	 qr/Checked out revision/);

#use Data::Dumper; print Dumper(file_list("viewwild"));
$files = [
          'viewwild',
          'viewwild/Project.viewspec',
          'viewwild/re_dir1',
          'viewwild/re_dir1/tsub1',
          'viewwild/re_dir1/tsub1/rev12',
          'viewwild/re_dir1/tsub2',
          'viewwild/re_dir2',
          'viewwild/re_dir2/tfile1',
          'viewwild/re_dir2/tfile2',
          'viewwild/re_dirhier',
          'viewwild/re_dirhier/Project.viewspec',
          'viewwild/re_dirhier/tdirhier__file',
	  'viewwild/re_dirhier/tsub3',
	  'viewwild/re_dirhier/tsub3/tsub3__file',
	  ];
is_deeply(file_list("viewwild"), $files, "check files in viewwild");

like_cmd("${S4} update viewwild",
	 qr/At revision/);
is_deeply(file_list("viewwild"), $files, "check files in viewwild");
