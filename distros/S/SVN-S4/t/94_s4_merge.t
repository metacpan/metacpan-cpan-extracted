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

BEGIN { plan tests => 5 }
BEGIN { require "./t/test_utils.pl"; }

system("/bin/rm -rf test_dir/view1");
system("/bin/rm -rf test_dir/tdir1");

chdir "test_dir" or die;
$ENV{CWD} = getcwd;
our $S4 = "${PERL} ../s4";
our $S4uu = "${PERL} ../../s4";

my $cmd;

##### Trapped
like_cmd("${S4} co -r11 $REPO/views/trunk/view1 view1",
	 qr/Checked out revision/);

like_cmd("${S4} merge $REPO/top/trunk/tdir1 view1 2>&1",
	 qr/Error.*s4 merge not allowed/);

like_cmd("cd view1 && ${S4uu} merge $REPO/top/trunk/tdir1 2>&1",
	 qr/Error.*s4 merge not allowed/);

##### Pass-through
like_cmd("${S4} co -r11 $REPO/top/trunk/tdir1",
	 qr/Checked out revision/);

like_cmd("${S4} merge -q $REPO/top/trunk/tdir1 tdir1",
	 qr/^$/);
