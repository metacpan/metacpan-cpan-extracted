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

BEGIN { plan tests => 19 }
BEGIN { require "./t/test_utils.pl"; }

system("/bin/rm -rf test_dir/view1");

chdir "test_dir" or die;
$ENV{CWD} = getcwd;
our $S4 = "${PERL} ../s4";
our $S4uu = "${PERL} ../../s4";

my $cmd;

like_cmd("${S4} co -r11 $REPO/views/trunk/view1",
	 qr/Checked out revision/);

like_cmd("${S4} co -r11 $REPO/views/trunk/view1 2>&1",
	 qr/Error.*Stubbornly/);

like_cmd("${S4} update -r11 view1",
	 qr/.*/);
use Data::Dumper; print Dumper(file_list("view1"));
is_deeply(file_list("view1"),
          ['view1',
	   'view1/Project.viewspec',
	   'view1/trunk_tdir1',
	   'view1/trunk_tdir1/tsub1',
	   'view1/trunk_tdir1/tsub2'
	   ], "check files in view1");

like_cmd("${S4} update -r11 view1",
	 qr/.*/);
use Data::Dumper; print Dumper(file_list("view1"));
is_deeply(file_list("view1"),
          ['view1',
	   'view1/Project.viewspec',
	   'view1/trunk_tdir1',
	   'view1/trunk_tdir1/tsub1',
	   'view1/trunk_tdir1/tsub2'
	   ], "check files in view1");

like_cmd("${S4} info-switches view1",
	 qr!view1/trunk_tdir1!);

like_cmd("${S4} info-switches $REPO/views/trunk/view1",
	 qr!URL: .*/trunk/tdir1!);

like_cmd("cd view1 && ${S4uu} info-switches .",
	 qr!URL: .*/trunk/tdir1!);

# Add an entry
{
    my $fh = IO::File->new(">>view1/Project.viewspec") or die;
    $fh->print("view	^/top/trunk/tdir2	trunk_tdir2\n");
}
# Update and it should appear
print "\n";
like_cmd("${S4} update -r11 view1",
	 qr/.*/);
use Data::Dumper; print Dumper(file_list("view1"));
is_deeply(file_list("view1"),
          ['view1',
	   'view1/Project.viewspec',
	   'view1/trunk_tdir1',
	   'view1/trunk_tdir1/tsub1',
	   'view1/trunk_tdir1/tsub2',
	   'view1/trunk_tdir2',
	   'view1/trunk_tdir2/tfile1',
	   'view1/trunk_tdir2/tfile2'
	   ], "check files in view1");

# Delete an entry (trunk_tdir1)
print "\n";
{
    my $fh = IO::File->new(">view1/Project.viewspec") or die;
    $fh->print("view	^/top/trunk/tdir2	trunk_tdir2\n");
}
like_cmd("${S4} update -r11 view1",
	 qr/.*/);
use Data::Dumper; print Dumper(file_list("view1"));
is_deeply(file_list("view1"),
          ['view1',
	   'view1/Project.viewspec',
	   'view1/trunk_tdir2',
	   'view1/trunk_tdir2/tfile1',
	   'view1/trunk_tdir2/tfile2',
	   ], "check files in view1");

# Scrub and back to trunk
print "\n";
like_cmd("${S4} scrub -r11 view1",
	 qr/Cleaning/);
use Data::Dumper; print Dumper(file_list("view1"));
is_deeply(file_list("view1"),
          ['view1',
	   'view1/Project.viewspec',
	   'view1/trunk_tdir1',
	   'view1/trunk_tdir1/tsub1',
	   'view1/trunk_tdir1/tsub2'
	   ], "check files in view1");

# Manually switch something, and see what update does
print "\n";

my $ign = (svn_version() >= 1.7) ? "--ignore-ancestry" : "";
like_cmd("${S4} switch $ign ^/top/trunk/tdir2 view1/trunk_tdir1",
	 qr/Updated/);
use Data::Dumper; print Dumper(file_list("view1"));
is_deeply(file_list("view1"),
          ['view1',
	   'view1/Project.viewspec',
	   'view1/trunk_tdir1',
	   'view1/trunk_tdir1/tfile1',
	   'view1/trunk_tdir1/tfile2'
	   ], "check files in view1 as trunkdir2");

# Scrub again and back to trunk
print "\n";
like_cmd("${S4} scrub -r11 view1",
	 qr/Cleaning/);
use Data::Dumper; print Dumper(file_list("view1"));
is_deeply(file_list("view1"),
          ['view1',
	   'view1/Project.viewspec',
	   'view1/trunk_tdir1',
	   'view1/trunk_tdir1/tsub1',
	   'view1/trunk_tdir1/tsub2'
	   ], "check files in view1");

