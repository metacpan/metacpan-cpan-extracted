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

BEGIN { plan tests => 13 }
BEGIN { require "./t/test_utils.pl"; }

$ENV{S4_CONFIG} = getcwd."/t/70_s4_commit_pedantic.dat";

system("/bin/rm -rf test_dir/view1");

chdir "test_dir" or die;
$ENV{CWD} = getcwd;
our $S4 = "${PERL} ../s4";
our $S4uu = "${PERL} ../../s4";
our $S4uuu = "${PERL} ../../../s4";

my $cmd;

like_cmd("${S4} co $REPO/views/trunk/view1",
	 qr/Checked out revision/);

####################
# Check non-top blocking
touch("view1/trunk_tdir1/new_file1", "new_file\n");
like_cmd("${S4} add view1/trunk_tdir1/new_file1 2>&1",
	 qr!^A *view1/trunk_tdir1/new_file1!);
# Blocked
like_cmd("cd view1/trunk_tdir1 && ${S4uuu} commit -m add_new_file1_FAILS 2>&1",
	 qr/.*Blocked unsafe commit/m);
# With path is ok
like_cmd("cd view1/trunk_tdir1 && ${S4uuu} commit . -m add_new_file1 2>&1",
	 qr/.*Committed revision/m);

# At top is ok
touch("view1/trunk_tdir1/new_file2", "new_file\n");
like_cmd("${S4} add view1/trunk_tdir1/new_file2 2>&1",
	 qr!^A *view1/trunk_tdir1/new_file2!);
like_cmd("cd view1 && ${S4uu} commit -m add_new_file2 2>&1",
	 qr/.*Committed revision/m);

####################
# Check modification blocking
touch("view1/trunk_tdir1/new_file3", "new_file\n");
like_cmd("${S4} add view1/trunk_tdir1/new_file3 2>&1",
	 qr!^A *view1/trunk_tdir1/new_file3!);
touch("view1/trunk_tdir1/unversioned_file4", "new_file\n");
# Blocked
like_cmd("cd view1/trunk_tdir1 && ${S4uuu} commit . -m add_new_file3_FAILS 2>&1",
	 qr/.*unversioned_file4.*Blocked unsafe commit/s);
# With path is ok
like_cmd("cd view1/trunk_tdir1 && ${S4uuu} commit . --unsafe -m add_new_file3 2>&1",
	 qr/.*Committed revision/);
unlink("view1/trunk_tdir1/unversioned_file4");

####################
# Leave the repo with clean state so can repeat
like_cmd("${S4} rm view1/trunk_tdir1/new_file1 2>&1",
	 qr!^D *view1/trunk_tdir1/new_file1!);
like_cmd("${S4} rm view1/trunk_tdir1/new_file2 2>&1",
	 qr!^D *view1/trunk_tdir1/new_file2!);
like_cmd("${S4} rm view1/trunk_tdir1/new_file3 2>&1",
	 qr!^D *view1/trunk_tdir1/new_file3!);
like_cmd("${S4} commit view1 -m rm_new_file12 2>&1",
	 qr/.*Committed revision/);
