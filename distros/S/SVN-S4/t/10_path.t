#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2002-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test::More;
use Cwd qw(getcwd);
use File::Spec::Functions;

BEGIN { plan tests => 5 }
BEGIN { require "./t/test_utils.pl"; }

my $uppwd = getcwd();
mkdir 'test_dir', 0777;
chdir 'test_dir';

use SVN::S4::Path;
ok(1, 'use');

#$SVN::S4::Path::Debug = 1;

is (SVN::S4::Path::fileNoLinks('.'),
    getcwd(),
    "Path");
is (SVN::S4::Path::fileNoLinks(catfile(catdir('bebop','.','uptoo','..','..'),'down1')),
    catfile(getcwd(),"down1"),
    "catfile");

SVN::S4::Path::prefetchDirTree('..');
# Make sure errors are silent
SVN::S4::Path::prefetchDirTree('../directory_that_doesnt_exist_I_presume');
ok(1);

SKIP: {
    skip(1,1) # symlink not supported on windows
	if ($^O =~ /win/i);

    eval { symlink ('..', 'to_dot_dot') ; };
    is (SVN::S4::Path::fileNoLinks(catfile('to_dot_dot','down1')),
	catfile($uppwd,"down1"),
	"fileNoLinks");
}
