#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Operator::Zip;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

# List literals
is_deeply( [ qw( one two three ) M ( 1 .. 3 ) ],
   [ one => 1, two => 2, three => 3 ],
   'basic mesh' );

is_deeply( [ qw( one two ) M ( 1 .. 3 ) ],
   [ one => 1, two => 2, undef, 3 ],
   'mesh fills in blanks of LHS' );
is_deeply( [ qw( one two three ) M ( 1 .. 2 ) ],
   [ one => 1, two => 2, three => undef ],
   'mesh fills in blanks of RHS' );

# Counts in scalar context
{
   my $count = (1..3) M (4..6);
   is( $count, 6, 'mesh counts in scalar context' );

   is( scalar( ('a'..'f') M ('Z') ), 12, 'mesh counts longest list on LHS' );
   is( scalar( ('z') M ('A'..'F') ), 12, 'mesh counts longest list on RHS' );
}

done_testing;
