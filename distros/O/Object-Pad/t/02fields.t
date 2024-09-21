#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0 0.000148; # is_refcount

use Object::Pad 0.800;

use constant HAVE_DATA_DUMP => defined eval { require Data::Dump; };

class Counter {
   field $count = 0;

   method inc { $count++ }

   method count { return $count; }
}

{
   my $counter = Counter->new;
   is( $counter->count, 0, 'Count initially 0' );

   $counter->inc;
   $counter->inc;
   $counter->inc;
   is( $counter->count, 3, 'Count is now 3 after ->inc x 3' );
}

{
   use Data::Dumper;

   class AllTheTypes {
      field $scalar = 123;
      field @array  = ( 45, 67 );
      field %hash   = ( 89 => 10 );

      method test {
         ::is( $scalar, 123, '$scalar field' );
         ::is( \@array, [ 45, 67 ], '@array field' );
         ::is( \%hash, { 89 => 10 }, '%hash field' );
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
   use Object::Pad ':experimental(init_expr)';

   my $class_in_fieldblock;

   class AllTheTypesByBlock {
      field $scalar { "one" }
      field @array  { "two", "three" }
      field %hash   { four => "five" }

      field $__dummy { $class_in_fieldblock = __CLASS__ }

      method test {
         ::is( $scalar, "one", '$scalar field' );
         ::is( \@array, [qw( two three )], '@array field' );
         ::is( \%hash, { four => "five" }, '%hash field' );
      }
   }

   AllTheTypesByBlock->new->test;

   is( $class_in_fieldblock, "AllTheTypesByBlock" );
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

{
   class FieldWithListExpr {
      field @array = ( 0 ) x 5;
   }
   pass( 'Code compiles with listexpr as field initialiser' );
}

ok( !eval <<'EOPERL',
   class SelfInField {
      field $x = $self + 1;
   }
EOPERL
   'field init expression cannot see $self' );
# TODO: Annoyingly, real parse error message has disappeared entirely from $@
# and all we get is "parse failed--compilation aborted at ..." so there's no
# point like()-testing $@ here

# RT154639 - fields should not be visible to :common methods
my $e = eval <<'EOPERL' ? undef : $@;
   class FieldInCommonMethod {
      field $x;
      method m :common { $x }
   }
EOPERL
like( $e, qr/^Global symbol "\$x" requires explicit package name /,
   'fields are not visible to :common methods' );

done_testing;
