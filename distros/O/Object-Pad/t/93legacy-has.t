#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

my @warnings;
BEGIN { $SIG{__WARN__} = sub { push @warnings, $_[0] }; }

class Counter {
   has $count = 0;

   method inc { $count++ }

   method describe { "Count is now $count" }
}

like( $warnings[0], qr/^'has' is deprecated; use 'field' instead at /,
   'legacy has keyword emits deprecation warning' );

# can't (yet) do 
#   no warnings 'deprecated';
# because 'class' will turn them all back on again

{
   my $counter = Counter->new;
   $counter->inc;
   $counter->inc;
   $counter->inc;

   is( $counter->describe, "Count is now 3",
      '$counter->describe after $counter->inc x 3' );

   # BEGIN-time initialised fields get private storage
   my $counter2 = Counter->new;
   is( $counter2->describe, "Count is now 0",
      '$counter2 has its own $count' );
}

{
   class AllTheTypes {
      has $scalar = 123;
      has @array  = ( 45, 67 );
      has %hash   = ( 89 => 10 );

      method test {
         ::is( $scalar, 123, '$scalar field' );
         ::is( \@array, [ 45, 67 ], '@array field' );
         ::is( \%hash, { 89 => 10 }, '%hash field' );
      }
   }

   my $instance = AllTheTypes->new;

   $instance->test;
}

# Sequencing order of `has` expressions
{
   my @order;
   sub seq
   {
      push @order, $_[0];
      return $_[0];
   }

   seq("start");

   class Sequencing {
      has $at_BEGIN = "BEGIN";
      has $at_class = ::seq("class");
      has $at_construct { ::seq("construct") }

      method test {
         ::is( $at_BEGIN, "BEGIN", '$at_BEGIN set correctly' );
         ::is( $at_class, "class", '$at_class set correctly' );
         ::is( $at_construct, "construct", '$at_construct set correctly' );
      }
   }

   seq("new");
   Sequencing->new->test;

   is( \@order, [qw( start class new construct )],
      'seq() calls happened in the correct order' );
}

Sequencing->new->test;

done_testing;
