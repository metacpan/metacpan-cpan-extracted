#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use Object::Pad;

class List {
   has @values;

   method push ( @more ) { push @values, @more }
   method nshift ( $n )  { splice @values, 0, $n }
}

{
   my $l = List->new;
   $l->push(qw( a b c d ));
   is_deeply( [ $l->nshift( 2 ) ],
      [qw( a b )],
      '$l->nshift yields values' );
}

class Greeter {
   has $_who;

   BUILD ( %args ) {
      $_who = $args{who};
   }

   method greet ( $message = "Hello, $_who" ) {
      return $message;
   }
}

{
   my $g = Greeter->new(who => "unit test");

   is( $g->greet, "Hello, unit test",
      'subroutine signature default exprs can see instance slots'
   );
}

done_testing;
