#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();

my @files;

@files = sort $internal->all_pm_files();
is(@files,2,'Found correct number of modules in default location');
like($files[0],qr/lib.Test.Compile.pm/,'Found module: Compile.pm');
like($files[1],qr/lib.Test.Compile.Internal.pm/,'Found module: Internal.pm');

@files = sort $internal->all_pm_files('t/scripts');
is(@files,3,'Found correct number of modules in t/scripts');
like($files[0],qr/t.scripts.LethalImport.pm/,'Found module: Module2.pm');
like($files[1],qr/t.scripts.Module.pm/,'Found module: Module.pm');
like($files[2],qr/t.scripts.Module2.pm/,'Found module: Module2.pm');

# Try specifying some files rather than directories
my @search = ('t/scripts/failure.pl', 't/scripts/Module.pm');

@files = sort $internal->all_pm_files($search[0]);
is(scalar @files,0,"didn't find the specific pl file");

@files = sort $internal->all_pm_files($search[1]);
is(scalar @files,1,"found the specific pm file");

@files = sort $internal->all_pm_files(@search);
is(scalar @files,1,"only found one specific file");
like($files[0],qr/t.scripts.Module.pm/,'Found specific file: failure.pl');

$internal->done_testing();
