#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad 0.800;
use Object::Pad::FieldAttr::Checked;

package Numerical {
   sub check { return $_[1] =~ m/^\d+(?:\.\d+)?$/ }
}

class CheckerAsPackage {
   field $x :Checked('Numerical') :param :reader :writer :accessor(acc_x);
}

# Construction time
{
   my $obj = CheckerAsPackage->new( x => 0 );
   ok( defined $obj, 'CheckerAsPackage->new with numbers OK' );

   like( dies { CheckerAsPackage->new( x => "hello" ) },
      qr/^Field \$x requires a value satisfying :Checked\('Numerical'\) at / );
}

# :writer
{
   my $obj = CheckerAsPackage->new( x => 0 );

   $obj->set_x( 20 );
   ok( $obj->x, 20, '$obj->x modified after successful ->set_x' );

   like( dies { $obj->set_x( "hello" ) },
      qr/^Field \$x requires a value satisfying :Checked\('Numerical'\) at /,
      '$p->set_x rejects invalid values' );
   ok( $obj->x, 20, '$obj->x unmodified after rejected ->set_x' );
}

# :accessor
{
   my $obj = CheckerAsPackage->new( x => 0 );

   is( $obj->acc_x, 0, '$obj->acc_x can read' );

   $obj->acc_x( 20 );
   ok( $obj->acc_x, 20, '$obj->acc_x modified after successful ->acc_x' );

   like( dies { $obj->acc_x( "hello" ) },
      qr/^Field \$x requires a value satisfying :Checked\('Numerical'\) at /,
      '$p->acc_x rejects invalid values' );
   ok( $obj->acc_x, 20, '$obj->acc_x unmodified after rejected ->acc_x' );
}

package ArrayRefChecker {
   sub check { return ref($_[1]) eq "ARRAY" }
}

class CheckerAsObject {
   sub ArrayRef
   {
      return bless {}, "ArrayRefChecker";
   }

   field $points :Checked(ArrayRef) :param :reader;
}

{
   my $obj = CheckerAsObject->new( points => [ 1, 2, 3 ] );
   ok( defined $obj, 'CheckerAsObject->new with arrayref OK' );

   like( dies { CheckerAsObject->new( points => "hello" ) },
      qr/^Field \$points requires a value satisfying :Checked\(ArrayRef\) at / );
}

my $CHECKER;
BEGIN { $CHECKER = bless [], "ArrayRefChecker" }
class CheckerFromVariable {
   field $f :Checked($CHECKER) :param;
}

{
   my $obj = CheckerFromVariable->new( f => [] );
   ok( defined $obj, 'CheckerFromVariable->new with arrayref OK' );

   like( dies { CheckerFromVariable->new( f => "hello" ) },
      qr/^Field \$f requires a value satisfying :Checked\(\$CHECKER\) at / );
}

class InternalsCanViolate {
   field $f :Checked('Numerical') :param;

   method test {
      $f = "a string value";
   }
}

{
   my $o = InternalsCanViolate->new( f => 1234 );
   ok( defined $o, 'InternalsCanViolate->new with valid param' );

   ok( lives { $o->test },
      'Object internally can violate its own :Checked constraint' ) or
      diag( "$@" );
}

class CheckerAsCoderef {
   field $name :param :reader :writer :Checked(sub { length $_[0] });
}

{
   my $obj = CheckerAsCoderef->new( name => "str" );
   ok( defined $obj, 'CheckerAsCoderef->new with string OK' );

   ok( lives { $obj->set_name( "new-string" ) },
      '$obj->set_name accepts good values' );

   my $re = qr/^Field \$name requires a value satisfying :Checked\(sub \{ length \$_\[0\] \}\) /;

   like( dies { $obj->set_name( "" ) }, $re,
      '$obj->set_name rejects bad values' );

   like( dies { CheckerAsCoderef->new( name => "" ) }, $re,
      'CheckerAsCoderef->new rejects bad values' );
}

done_testing;
