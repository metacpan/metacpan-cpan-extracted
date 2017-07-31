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

BEGIN { plan tests => 14*2 }
BEGIN { require "./t/test_utils.pl"; }

chdir "test_dir" or die;
$ENV{CWD} = getcwd;
our $S4 = "${PERL} ../s4";
my $files;

# need to run whole suite for both sparse and non-sparse checkouts
foreach my $sparse ("", " --sparse") {

    system("/bin/rm -rf tdirhier");
    system("/bin/rm -rf tdirquiet");
    system("/bin/rm -rf viewhier");

    ##########
    like_cmd("${S4} co$sparse $REPO/top/trunk/tdirhier",
             qr/Checked out revision/);

    #use Data::Dumper; print Dumper(file_list("tdirhier"));
    $files = ['tdirhier',
              'tdirhier/Project.viewspec',
              'tdirhier/tdirhier__file',
              'tdirhier/trunk_tdir1',
              'tdirhier/trunk_tdir1/tsub1',
              'tdirhier/trunk_tdir1/tsub1/rev12',
              'tdirhier/trunk_tdir1/tsub2',
              'tdirhier/trunk_tdir2',
              'tdirhier/trunk_tdir2/tfile1',
              'tdirhier/trunk_tdir2/tfile2',
              'tdirhier/tsub3',
              'tdirhier/tsub3/tsub3__file',
        ];
    is_deeply(file_list("tdirhier"), $files, "check files in tdirhier");

    #--------
    # Check that --quiet is quiet
    like_cmd("${S4} co$sparse --quiet $REPO/top/trunk/tdirhier tdirquiet",
             qr/^$/o);
    like_cmd("${S4} update --quiet tdirquiet",
             qr/^$/o);

    #---------
    like_cmd("${S4} update tdirhier",
             qr/At revision/);
    is_deeply(file_list("tdirhier"), $files, "check files in tdirhier");

    ##########
    like_cmd("${S4} co$sparse $REPO/views/trunk/viewhier",
             qr/Checked out revision/);

    #use Data::Dumper; print Dumper(file_list("viewhier"));
    $files = ['viewhier',
              'viewhier/Project.viewspec',
              'viewhier/tdirhier',
              'viewhier/tdirhier/Project.viewspec',
              'viewhier/tdirhier/tdirhier__file',
              'viewhier/tdirhier/tsub3',
              'viewhier/tdirhier/tsub3/tsub3__file',
              'viewhier/trunk_tdir2',
              'viewhier/trunk_tdir2/tfile1',
              'viewhier/trunk_tdir2/tfile2',
        ];
    is_deeply(file_list("viewhier"), $files, "check files in viewhier");

    #---------
    like_cmd("${S4} update viewhier",
             qr/At revision/);
    is_deeply(file_list("viewhier"), $files, "check files in viewhier");

    #---------
    # Specifically we want to make sure that the Project.viewspec that is "down" one
    # directory doesn't cause trunk_tdir2 to reappear

    like_cmd("${S4} update viewhier/tdirhier",
             qr/At revision/);
    is_deeply(file_list("viewhier"), $files, "check files in viewhier");

    like_cmd("${S4} scrub viewhier/tdirhier",
             qr/At revision/);
    is_deeply(file_list("viewhier"), $files, "check files in viewhier");
}
