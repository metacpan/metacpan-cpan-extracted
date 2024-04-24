#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Zip;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

# List literals
is( [ qw( one two three ) M ( 1 .. 3 ) ],
   [ one => 1, two => 2, three => 3 ],
   'basic mesh' );

is( [ qw( one two ) M ( 1 .. 3 ) ],
   [ one => 1, two => 2, undef, 3 ],
   'mesh fills in blanks of LHS' );
is( [ qw( one two three ) M ( 1 .. 2 ) ],
   [ one => 1, two => 2, three => undef ],
   'mesh fills in blanks of RHS' );

# Counts in scalar context
{
   my $count = (1..3) M (4..6);
   is( $count, 6, 'mesh counts in scalar context' );

   is( scalar( ('a'..'f') M ('Z') ), 12, 'mesh counts longest list on LHS' );
   is( scalar( ('z') M ('A'..'F') ), 12, 'mesh counts longest list on RHS' );
}

# Returned values are copies, not aliases
{
   my @n = (1..3);
   $_++ for @n M ("x")x3;
   is( \@n, [1..3], 'mesh returns copies of arguments' );
}

# list-associative
{
   is( [ qw( one two three ) M qw( I II III ) M ( 1, 2, 3 ) ],
      [ one => I => 1, two => II => 2, three => III => 3 ],
      'mesh is list-associative with itself' );
}

done_testing;
