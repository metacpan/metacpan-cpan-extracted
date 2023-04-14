#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();

my @files;

@files = $internal->_find_files();
is(scalar @files, 0, 'Found no files in the empty list');

@files = $internal->_find_files('IDoNotExist/');
is(scalar @files, 0 ,'Found no files in non existant directory');

@files = $internal->_find_files('IDoNotExist.pm');
is(scalar @files, 0 ,"Didn't find non existent file");

@files = $internal->_find_files('t/scripts/');
is(scalar @files, 12 ,'Found all the files in the scripts dir');

@files = $internal->_find_files('t/scripts/datafile');
is(scalar @files, 1 ,'Found the file we specified');


$internal->done_testing
