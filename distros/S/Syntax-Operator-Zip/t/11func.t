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

no Syntax::Operator::Zip qw( zip );

like( dies { zip( [1,2], [3,4] ) },
   qr/^Undefined subroutine &main::zip called at /,
   'unimport' );

done_testing;
