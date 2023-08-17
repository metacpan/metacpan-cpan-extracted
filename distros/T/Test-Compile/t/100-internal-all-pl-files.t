#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;
eval 'use Test::Warnings; 1;'
    or diag "Please install Test::Warnings, so I can make sure there are no warnings";

my $internal = Test::Compile::Internal->new();

my @files;

# Given(empty input), When
@files = $internal->all_pl_files();
# Then
is(scalar @files, 0, "There weren't any files in the default location");

# Given(a directory with files in it), When
@files = $internal->all_pl_files('t/scripts');
# Then
is(scalar @files, 6, 'Found correct number of scripts in t/scripts');
like($files[0], qr/t.scripts.failure.pl/, 'Found script: failure.pl');
like($files[1], qr/t.scripts.messWithLib.pl/, 'Found script: messWithLib.pl');
like($files[2], qr/t.scripts.perlscript$/, 'Found script: perlscript');
like($files[3], qr/t.scripts.perlscript.psgi/i, 'Found script: perlscript.pSgi');
like($files[4], qr/t.scripts.subdir.success.pl/, 'Found script: success.pl');
like($files[5], qr/t.scripts.taint.pl/, 'Found script: taint.pl');

my @search = ('t/scripts/failure.pl', 't/scripts/Module.pm');

# Given(a file), When
@files = $internal->all_pl_files($search[0]);
# Then
is(scalar @files, 1, "found the specific pl file");

# Given(a file that doesn't exist), When
@files = $internal->all_pl_files($search[1]);
# Then
is(scalar @files, 0, "didn't find the nonexitant pm file");

# Given(a list of files), When
@files = $internal->all_pl_files(@search);
# Then
is(scalar @files, 1, "only found one specific file");
like($files[0], qr/t.scripts.failure.pl/, 'Found specific file: failure.pl');

$internal->done_testing();
