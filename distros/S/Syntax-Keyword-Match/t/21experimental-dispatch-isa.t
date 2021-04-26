#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
BEGIN {
   plan skip_all => "isa operator requires perl version >= 5.32" unless $] >= 5.032;
}

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
