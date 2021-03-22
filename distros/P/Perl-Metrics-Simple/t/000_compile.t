#!/usr/bin/perl

use strict;
use warnings;

use Test::Compile;

my $test = Test::Compile->new();

$test->all_files_ok();
pl_file_ok('bin/countperl');

$test->done_testing();
