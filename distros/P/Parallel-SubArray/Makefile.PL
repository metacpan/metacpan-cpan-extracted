#!/usr/bin/perl
use inc::Module::Install;

name           'Parallel-SubArray';
all_from       'lib/Parallel/SubArray.pm';
license        'bsd';
requires       'Storable'   => 2.18;
test_requires  'Test::More' => 0.86;
test_requires  'Test::Deep' => 0.103;

WriteAll;
