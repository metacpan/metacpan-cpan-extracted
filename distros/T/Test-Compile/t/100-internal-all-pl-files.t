#!perl

use strict;
use warnings;

use File::Spec;
use Test::More;
use Test::Compile::Internal;
eval 'use Test::Warnings; 1;'
    or diag "Please install Test::Warnings, so I can make sure there are no warnings";

my $internal = Test::Compile::Internal->new();

my @files;

@files = sort $internal->all_pl_files();
is(scalar @files,0,'Found correct number of scripts in default location');

@files = sort $internal->all_pl_files('t/scripts');
is(scalar @files,5,'Found correct number of scripts in t/scripts');
like($files[0],qr/t.scripts.failure.pl/,'Found script: failure.pl');
like($files[1],qr/t.scripts.lib.pl/,'Found script: lib.pl');
like($files[2],qr/t.scripts.perlscript/,'Found script: perlscript');
like($files[3],qr/t.scripts.subdir.success.pl/,'Found script: success.pl');
like($files[4],qr/t.scripts.taint.pl/,'Found script: taint.pl');

# Try specifying som files rather than directories
my @search = ('t/scripts/failure.pl', 't/scripts/Module.pm');

@files = sort $internal->all_pl_files($search[0]);
is(scalar @files,1,"found the specific pl file");

@files = sort $internal->all_pl_files($search[1]);
is(scalar @files,0,"didn't find the specific pm file");

@files = sort $internal->all_pl_files(@search);
is(scalar @files,1,"only found one specific file");
like($files[0],qr/t.scripts.failure.pl/,'Found specific file: failure.pl');

$internal->done_testing();
