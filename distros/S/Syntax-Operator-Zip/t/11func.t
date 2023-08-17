#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Zip qw( zip mesh );

# zip
{
   is( [ zip [qw( one two three )], [ 1 .. 3 ] ],
      [ [ one => 1 ], [ two => 2 ], [ three => 3 ] ],
      'zip()' );
}

# mesh
{
   is( [ mesh [qw( one two three )], [ 1 .. 3 ] ],
      [ one => 1, two => 2, three => 3 ],
      'mesh()' );
}

done_testing;
