#!perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    eval { require Test::PerlTidy }
      or plan skip_all => "Test::PerlTidy required for this test";
}

use Test::PerlTidy;

run_tests(perltidyrc => '.perltidyrc');
