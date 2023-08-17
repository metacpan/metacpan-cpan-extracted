#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Match qw( match :experimental(dispatch) );

package AClass {}
package BClass {}

# isa match
{
   my $ok;
   match(bless [], "AClass" : isa) {
      case(AClass) { $ok++ }
      case(BClass) { fail('Not this one sorry'); }
   }
   ok( $ok, 'Literal match' );
}

done_testing;
