#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();

my @files;

@files = sort $internal->_find_files();
is(scalar @files, 0, 'Found no files in the empty list');

@files = sort $internal->_find_files('IDoNotExist/');
is(scalar @files, 0 ,'Found no files in non existant directory');

@files = sort $internal->_find_files('IDoNotExist.pm');
is(scalar @files, 0 ,"Didn't find non existent file");

@files = sort $internal->_find_files('t/scripts/');
is(scalar @files, 11 ,'Found all the files in the scripts dir');

@files = sort $internal->_find_files('t/scripts/datafile');
is(scalar @files, 1 ,'Found the file we specified');

## Hrmm, it would nice if _find_files could ignore this CVS dir
#@files = sort $internal->_find_files('t/scripts/CVS/');
#is(scalar @files, 0 ,'Ignored the files in the CVS dir');

$internal->done_testing
