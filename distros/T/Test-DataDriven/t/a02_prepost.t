#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';

use DummyT;
use Test::DataDriven tests => 1;

Test::DataDriven->run;

exit 0;

__DATA__

=== Run some actions (1)
Foo moo boo
boo
--- touch lines chomp
t/dummy/file1

=== Run more actions (2)
--- directory chomp
t/dummy
--- touch lines chomp
t/dummy/file2
--- mkpath lines chomp
t/dummy/dir
--- created lines chomp
dir/
file2
