#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';

use DummyT;
use Test::DataDriven tests => 5;

Test::DataDriven->run;

unless( Test::DataDriven->create ) {
    ok( -d 't/dummy' );
    ok( -f 't/dummy/file1' );
    ok( -f 't/dummy/file2' );
    ok( -d 't/dummy/dir' );
    ok( -f 't/dummy/dir/file' );
}

exit 0;

__DATA__

=== Run some actions
--- touch lines chomp
t/dummy/file1
t/dummy/file2
--- mkpath lines chomp
t/dummy/dir

=== No two sections with the same name...
--- touch lines chomp
t/dummy/dir/file
