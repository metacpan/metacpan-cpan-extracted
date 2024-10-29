#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::PhaserExpression;

{
   my $x;
   BEGIN $x = 10;

   my $saw_x;
   BEGIN { $saw_x = $x; }

   is( $saw_x, 10, '$x was assigned at compiletime' );
}

{
   BEGIN my $x = 20;

   my $saw_x;
   BEGIN { $saw_x = $x; }

   is( $saw_x, 20, 'my $x was assigned at compiletime' );
}

{
   my $x;
   BEGIN { $x = 20; }

   my $y = BEGIN $x + 10;

   is( $y, 30, 'BEGIN expression yields a value' );
}

{
   my $saw_arg;
   sub ten { $saw_arg = $_[0]; return 10; }

   is( $saw_arg, "the-arg", 'saw arg before runtime' );
   my $twenty = BEGIN ten( "the-arg" ) + 10;
   is( $twenty, 20, 'result of BEGIN expr' );
}

done_testing;
