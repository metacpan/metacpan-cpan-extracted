#!perl

use 5.008001;

use strict;
use warnings FATAL => 'all';

use Test::More;
use Moo;

BEGIN
{
    use_ok('MooX::ConfigFromFile')                        || BAIL_OUT "Couldn't load MooX::ConfigFromFile";
    use_ok('MooX::ConfigFromFile::Role')                  || BAIL_OUT "Couldn't load MooX::ConfigFromFile::Role";
    use_ok('MooX::ConfigFromFile::Role::HashMergeLoaded') || BAIL_OUT "Couldn't load MooX::ConfigFromFile::Role::HashMergeLoaded";
    use_ok('MooX::ConfigFromFile::Role::SortedByFilename')
      || BAIL_OUT "Couldn't load MooX::ConfigFromFile::Role::SortedByFilename";
}

diag("Testing MooX::ConfigFromFile $MooX::ConfigFromFile::VERSION, Perl $], $^X");

done_testing();
