#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();


## Given

## When
my @files;
my @snvfiles;
@files = $internal->_find_files('t/scripts/');
@snvfiles = grep(/Ignore.pm/, @files);

## Then
ok(scalar @files > 0, 'Found some files ...');
ok(scalar @snvfiles == 0, "Didn't fild the file in the SVN dir");

$internal->done_testing
