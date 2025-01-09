#!perl

use strict;
use warnings;

use Test::More tests => 4;

my @warnings;
BEGIN {
   $SIG{ __WARN__ } = sub {
      push @warnings, $_[0];
      print( STDERR $_[0] );
   };
}

use syntax qw( loop );

{
   my $i = 0;
   my $s = '';
   loop { $s .= "a"; last if ++$i ==  5; $s .= "b"; }
   loop { $s .= "c"; last if ++$i == 10; $s .= "d"; }
   is( $s, "ababababacdcdcdcdc" );
}

{
   my $i = 0;
   my $s = '';
   loop {
      last if $i == 8;
      $s .= " " if $i;
      ++$i;
      $s .= "a";
      redo if $i % 4 == 0;
      $s .= "b";
      next if $i % 2 == 0;
      $s .= "c";
   };

   is( $s, "abc ab abc a abc ab abc a", "redo and next" );
}

{
   my $i = 0;
   my $s = '';
   OUTER: loop {
      $s .= "o";
      INNER: loop {
         $s .= "i";
         ++$i;
         last INNER if $i == 2;
         last OUTER if $i == 4;
      }
   }

   is( $s, "oiioii", "Labels" );
}

ok( !@warnings, "no warnings" );
