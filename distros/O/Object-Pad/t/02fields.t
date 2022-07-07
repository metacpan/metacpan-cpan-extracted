#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Refcount;

use Object::Pad ':experimental(init_expr)';

use constant HAVE_DATA_DUMP => defined eval { require Data::Dump; };

class Counter {
   has $count = 0;

   method inc { $count++ }

   method describe { "Count is now $count" }
}

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
   use Data::Dumper;

   class AllTheTypes {
      has $scalar = 123;
      has @array  = ( 45, 67 );
      has %hash   = ( 89 => 10 );

      method test {
         Test::More::is( $scalar, 123, '$scalar field' );
         Test::More::is_deeply( \@array, [ 45, 67 ], '@array field' );
         Test::More::is_deeply( \%hash, { 89 => 10 }, '%hash field' );
      }
   }

   my $instance = AllTheTypes->new;

   $instance->test;

   # The exact output of this test is fragile as it depends on the internal
   # representation of the instance, which we do not document and is not part
   # of the API guarantee. We're not really checking that it has exactly this
   # output, just that Data::Dumper itself doesn't crash. If a later version
   # changes the representation so that the output here differs, just change
   # the test as long as it is something sensible.
   is( Dumper($instance) =~ s/\s+//gr,
      q($VAR1=bless([123,[45,67],{'89'=>10}],'AllTheTypes');),
      'Dumper($instance) sees field data' );
   HAVE_DATA_DUMP and is( Data::Dump::pp($instance),
      q(bless([123, [45, 67], { 89 => 10 }], "AllTheTypes")),
      'pp($instance) sees field data' );
}

{
   class AllTheTypesByBlock {
      field $scalar { "one" }
      field @array  { "two", "three" }
      field %hash   { four => "five" }

      method test {
         Test::More::is( $scalar, "one", '$scalar field' );
         Test::More::is_deeply( \@array, [qw( two three )], '@array field' );
         Test::More::is_deeply( \%hash, { four => "five" }, '%hash field' );
      }
   }

   AllTheTypesByBlock->new->test;
}

# Variant of RT132228 about individual field lexicals
class Holder {
   field $field;
   method field :lvalue { $field }
}

{
   my $datum = [];
   is_oneref( $datum, '$datum initially' );

   my $holder = Holder->new;
   $holder->field = $datum;
   is_refcount( $datum, 2, '$datum while held by Holder' );

   undef $holder;
   is_oneref( $datum, '$datum finally' );
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

   is_deeply( \@order, [qw( start class new construct )],
      'seq() calls happened in the correct order' );
}

Sequencing->new->test;

# Fields are visible to string-eval()
{
   class Evil {
      field $field;

      method test {
         $field = "the value";
         ::is( eval '$field', "the value", 'fields are visible to string eval()' );
      }
   }

   Evil->new->test;
}

done_testing;
