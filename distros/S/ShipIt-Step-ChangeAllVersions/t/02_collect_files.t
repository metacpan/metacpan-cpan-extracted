#!perl -w

use strict;
use Test::More;

use ShipIt::Step::ChangeAllVersions;

use File::Spec;

my @files = ShipIt::Step::ChangeAllVersions->collect_files;
is_deeply \@files, [File::Spec->catfile(qw(lib ShipIt Step ChangeAllVersions.pm))];

done_testing;
