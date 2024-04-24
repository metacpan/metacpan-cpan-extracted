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

   is( [ zip [qw( one )], [qw( I )], [ 1 ] ],
      [ [ one => I => 1 ] ],
      'zip() 3args' );
}

# mesh
{
   is( [ mesh [qw( one two three )], [ 1 .. 3 ] ],
      [ one => 1, two => 2, three => 3 ],
      'mesh()' );

   is( [ mesh [qw( one )], [qw( I )], [ 1 ] ],
      [ one => I => 1 ],
      'mesh() 3args' );
}

{
   package another::namespace;

   use Test2::V0;

   use Syntax::Operator::Zip qw( zip );
   no Syntax::Operator::Zip qw( zip );

   like( dies { zip( [1,2], [3,4] ) },
      qr/^Undefined subroutine &another::namespace::zip called at /,
      'unimport' );
}

done_testing;
