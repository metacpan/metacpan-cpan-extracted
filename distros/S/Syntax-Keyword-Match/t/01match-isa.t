#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
BEGIN {
   plan skip_all => "isa operator requires perl version >= 5.32" unless $] >= 5.032;
}

use Syntax::Keyword::Match;

package AClass {}
package BClass {}

# literals
{
   my $ok;
   match(bless [], "AClass" : isa) {
      case(AClass) { $ok++ }
      case(BClass) { fail('Not this one sorry'); }
   }
   ok( $ok, 'Literal match' );
}

# default
{
   my $ok;
   match(bless [], "CClass" : isa) {
      case(AClass) { fail("Not AClass") }
      case(BClass) { fail("Not BClass") }
      default      { $ok++ }
   }
   ok( $ok, 'Default block executed' );
}

# overloaded ->isa method
{
   my $equal;
   package Greedy {
      sub isa { $equal };
   }

   sub greedy_is_ten
   {
      match(bless [], "Greedy" : isa) {
         case(Ten) { return "YES" }
         default   { return "NO" }
      }
   }

   $equal = 1;
   is( greedy_is_ten, "YES", 'Greedy is 10 when set' );

   $equal = 0;
   is( greedy_is_ten, "NO", 'Greedy is not 10 when unset' );
}

done_testing;
