#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2006-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test::More;
use Cwd;

BEGIN { plan tests => 4 }
BEGIN { require "./t/test_utils.pl"; }

# Blow old stuff away, if there was anything there
system("/bin/rm -rf test_dir/*");  # Ignore errors

print "If below svnadmin create hangs, you're out of random numbers.\n";
print "See http://www.linuxcertified.com/hw_random.html\n";

run_system("svnadmin create --fs-type fsfs $REPOFN");
ok(1, "create");

run_system("svnadmin load $REPOFN < t/50_makerepo.dump");
ok(1, "load");

run_system("svn co $REPO test_dir/all");
ok(1, "co");

run_system("svn co $REPO/top/trunk test_dir/trunk");
ok(1, "co");

print "If you need to change the initial repository, after this step\n";
print "make your changes to test_dir/all, then:\n";
# svn co file:`pwd`/test_dir/repo repo_co
print "   svnadmin dump test_dir/repo > t/50_makerepo.dump\n";


