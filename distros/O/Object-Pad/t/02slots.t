#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Refcount;

use Object::Pad;

class Counter {
   has $count = 0;

   method inc { $count++ };

   method describe { "Count is now $count" }
}

{
   my $counter = Counter->new;
   $counter->inc;
   $counter->inc;
   $counter->inc;

   is( $counter->describe, "Count is now 3",
      '$counter->describe after $counter->inc x 3' );

   # BEGIN-time initialised slots get private storage
   my $counter2 = Counter->new;
   is( $counter2->describe, "Count is now 0",
      '$counter2 has its own $count' );
}

{
   use Data::Dump 'pp';

   class AllTheTypes {
      has $scalar = 123;
      has @array  = ( 45, 67 );
      has %hash   = ( 89 => 10 );

      method test {
         Test::More::is( $scalar, 123, '$scalar slot' );
         Test::More::is_deeply( \@array, [ 45, 67 ], '@array slot' );
         Test::More::is_deeply( \%hash, { 89 => 10 }, '%hash slot' );
      }
   }

   my $instance = AllTheTypes->new;

   $instance->test;

   # The exact output of this test is fragile as it depends on the internal
   # representation of the instance, which we do not document and is not part
   # of the API guarantee. We're not really checking that it has exactly this
   # output, just that Data::Dump itself doesn't crash. If a later version
   # changes the representation so that the output here differs, just change
   # the test as long as it is something sensible.
   is( pp($instance),
      q(bless([123, [45, 67], { 89 => 10 }], "AllTheTypes")),
      'pp($instance) sees slot data' );
}

{
   class AllTheTypesByBlock {
      has $scalar { "one" };
      has @array  { "two", "three" };
      has %hash   { four => "five" };

      method test {
         Test::More::is( $scalar, "one", '$scalar slot' );
         Test::More::is_deeply( \@array, [qw( two three )], '@array slot' );
         Test::More::is_deeply( \%hash, { four => "five" }, '%hash slot' );
      }
   }

   AllTheTypesByBlock->new->test;
}

# Variant of RT132228 about individual slot lexicals
class Holder {
   has $slot;
   method slot :lvalue { $slot }
}

{
   my $datum = [];
   is_oneref( $datum, '$datum initially' );

   my $holder = Holder->new;
   $holder->slot = $datum;
   is_refcount( $datum, 2, '$datum while held by Holder' );

   undef $holder;
   is_oneref( $datum, '$datum finally' );
}

# Sequencing order of expressions
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
      has $at_construct { ::seq("construct") };

      method test {
         ::is( $at_BEGIN, "BEGIN", '$at_BEGIN set correctly' );
         ::is( $at_class, "class", '$at_class set correctly' );
         ::is( $at_construct, "construct", '$at_construct set correctly' );
      }
   }

   seq("new");
   Sequencing->new->test;

   is_deeply( \@order, [qw( start class new construct )],
      'seq() calls happened in the correct order' );
}

Sequencing->new->test;

# Slots are visible to string-eval()
{
   class Evil {
      has $slot;

      method test {
         $slot = "the value";
         ::is( eval '$slot', "the value", 'slots are visible to string eval()' );
      }
   }

   Evil->new->test;
}

done_testing;
