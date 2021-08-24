#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Match qw( match :experimental(dispatch) );

# code stolen from benchmark.pl
sub match_case
{
   my ( $x ) = @_;
   match( $x : eq ) {
      case( "one"   ) { return 1; }
      case( "two"   ) { return 2; }
      case( "three" ) { return 3; }
      case( "four"  ) { return 4; }
      case( "five"  ) { return 5; }
      case( "six"   ) { return 6; }
      case( "seven" ) { return 7; }
      case( "eight" ) { return 8; }
      case( "nine"  ) { return 9; }
      default         { return 0; }
   }
}

# large stringy match
{
   my $i = 0;
   my %expect = map { $_ => $i++ } qw( zero one two three four five six seven eight nine );

   is( match_case( $_ ), $expect{$_}, "match_case($_)" )
      for sort keys %expect;
}

# overloaded 'eq' operator
{
   my $equal;
   package Greedy {
      use overload 'eq' => sub { $equal };
   }

   sub greedy_is_ten
   {
      match(bless [], "Greedy" : eq) {
         case("ten")    { return "YES" }
         case("twenty") { return "NO" }
         default        { return "NO" }
      }
   }

   $equal = 1;
   is( greedy_is_ten, "YES", 'Greedy is 10 when set' );

   $equal = 0;
   is( greedy_is_ten, "NO", 'Greedy is not 10 when unset' );
}

# mixed dispsatch + var
{
   my $four = 4;

   match( 2 : == ) {
      case(1)     { fail("No"); }
      case(2)     { pass("Mixed dispatch"); }
      case(3)     { fail("No"); }
      case($four) { fail("No"); }
      case(5)     { fail("No"); }
   }
}

# Various cornercases of our copy-pasted do_neq() function
{
   match(1 : ==) {
      case(1) { pass("IV == IV"); }
      default { fail("IV == IV"); }
   }

   match(2.2 : ==) {
      case(2.0) { fail("NV == NV first"); }
      case(2.2) { pass("NV == NV"); }
      default   { fail("NV == NV second"); }
   }

   match(~3 : ==) {
      case(3)  { fail("UV == UV a"); }
      case(~4) { fail("UV == UV b"); }
      case(~3) { pass("UV == UV"); }
      default  { fail("UV == UV c"); }
   }
}

done_testing;
