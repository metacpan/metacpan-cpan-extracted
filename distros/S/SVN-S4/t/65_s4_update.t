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

BEGIN { plan tests => 13*2 }
BEGIN { require "./t/test_utils.pl"; }

chdir "test_dir" or die;
$ENV{CWD} = getcwd;
our $S4 = "${PERL} ../s4";
our $S4uu = "${PERL} ../../s4";
our $S4uuu = "${PERL} ../../../s4";

my $cmd;

# need to run whole suite for both sparse and non-sparse checkouts
foreach my $sparse ("", " --sparse") {
    # Update whole tree
    to_r3($sparse);
    like_cmd("cd upd && ${S4uu} update -r7",
             qr/.*/);
    #use Data::Dumper; print Dumper(file_list("upd"));
    is_deeply(file_list("upd"),
              ['upd',
               'upd/tdir1',
               'upd/tdir1/tsub1',
               'upd/tdir1/tsub2',
               'upd/tdir2',
              ], "check files in 'upd'");

    # Update one dir tree
    to_r3($sparse);
    like_cmd("cd upd/tdir1 && ${S4uuu} update -r7",
             qr/.*/);
    #use Data::Dumper; print Dumper(file_list("upd"));
    is_deeply(file_list("upd"),
              ['upd',
               'upd/tdir1',
               'upd/tdir1/tsub1',
               'upd/tdir1/tsub2',
              ], "check files in 'upd'");

    # Update whole tree with --top
    to_r3($sparse);
    like_cmd("cd upd/tdir1 && ${S4uuu} update --top -r7",
             qr/.*/);
    #use Data::Dumper; print Dumper(file_list("upd"));
    is_deeply(file_list("upd"),
              ['upd',
               'upd/tdir1',
               'upd/tdir1/tsub1',
               'upd/tdir1/tsub2',
               'upd/tdir2',
              ], "check files in 'upd'");

    # Status whole tree with --top
    like_cmd("cd upd/tdir1 && ${S4uuu} status --top",
             qr//);
}

sub to_r3 {
    my $sparse = shift;
    system("/bin/rm -rf test_dir/upd");
    like_cmd("${S4} co$sparse -r3 $REPO/top/trunk upd",
             qr/Checked out revision/);
    is_deeply(file_list("upd"),
              ['upd',
               'upd/tdir1',
              ], "check files in 'upd'");
}
