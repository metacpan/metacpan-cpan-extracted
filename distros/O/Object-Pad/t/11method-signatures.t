#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use Object::Pad;

class List {
   field @values;

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
   field $_who;

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
      'subroutine signature default exprs can see instance fields'
   );
}

{
   my @keys;

   class WithAdjustParams {
      ADJUSTPARAMS ( $params ) { @keys = sort keys %$params; %$params = () }
   }

   WithAdjustParams->new( x => 1, y => 2, z => 3 );
   is_deeply( \@keys, [qw( x y z )], 'Keys captured from $params' );
}

{
   my $warnings;
   my $LINE;

   BEGIN { $SIG{__WARN__} = sub { $warnings .= $_[0] }; }
   class WithAdjustSignature {
      $LINE = __LINE__+1;
      ADJUST ( $params ) { }
   }
   BEGIN { undef $SIG{__WARN__}; }

   like( $warnings, qr/^Use of ADJUST \(signature\) \{BLOCK\} is now deprecated at \S+ line $LINE\./,
      'ADJUST (signature) { BLOCK } raises a warning' );
}

done_testing;
