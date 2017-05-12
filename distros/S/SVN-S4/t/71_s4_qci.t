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

chdir "test_dir" or die;
$ENV{CWD} = getcwd;
our $S4 = "${PERL} ../s4";
our $S4uu = "${PERL} ../../s4";

my $cmd;

like_cmd("${S4} co $REPO/views/trunk/view1",
	 qr/Checked out revision/);

{
    my $fh = IO::File->new(">view1/new_file") or die;
    $fh->print("new_file\n");
}

like_cmd("${S4} add view1/new_file 2>&1",
	 qr!^A *view1/new_file!);

like_cmd("${S4} qci view1 -m add_new_file 2>&1",
	 qr/.*Committed revision/m);


# Leave the repo with clean state so can repeat
like_cmd("${S4} rm view1/new_file 2>&1",
	 qr!^D *view1/new_file!);

like_cmd("${S4} qci view1 -m rm_new_file 2>&1",
	 qr/.*Committed revision/m);
