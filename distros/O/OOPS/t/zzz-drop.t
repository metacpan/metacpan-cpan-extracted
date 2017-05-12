#!/usr/bin/perl -I../lib

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestCommon;

print "1..1\n";

db_drop();

print "# $@\n" if $@;
print "ok 1\n";

