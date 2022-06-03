#! /usr/bin/perl

use strict;
use warnings;

use Test::Compile qw();

my $test = Test::Compile->new();
$test->all_files_ok();
$test->done_testing();
