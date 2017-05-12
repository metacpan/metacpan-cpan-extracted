#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';

use DummyT;
use Test::DataDriven tests => 1;
use Test::Differences;
use File::Slurp;

filters( { directory => 'chomp' } );

# experimental: use at your own risk
Test::DataDriven->create( 't/a03_create.data' );
Test::DataDriven->run;

my @lines = read_file( 't/a03_create.data' );

eq_or_diff( \@lines, [ map { "$_\n" } split /\n/, <<EOT ] );
=== Run some actions (1)
Foo moo boo
boo
--- touch lines chomp
t/dummy/file1

=== Run more actions (2)
--- directory
t/dummy
--- touch lines chomp
t/dummy/file2
--- mkpath lines chomp
t/dummy/dir
--- created lines chomp
dir/
file2
EOT

exit 0;

__DATA__

=== Run some actions (1)
Foo moo boo
boo
--- touch lines chomp
t/dummy/file1

=== Run more actions (2)
--- directory
t/dummy
--- touch lines chomp
t/dummy/file2
--- mkpath lines chomp
t/dummy/dir
--- created lines chomp
