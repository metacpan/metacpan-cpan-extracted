#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Fatal;

use Object::Pad;

package Base::Class {
   sub new {
      my $class = shift;
      my ( $ok ) = @_;
      Test::More::is( $ok, "ok", '@_ to Base::Class::new' );
      Test::More::is( scalar @_, 1, 'scalar @_ to Base::Class::new' );

      return bless { base_field => 123 }, $class;
   }

   sub fields {
      my $self = shift;
      return "base_field=$self->{base_field}"
   }
}

my @BUILDS_INVOKED;

class Derived::Class isa Base::Class {
   has $derived_field = 456;

   BUILD {
      my @args = @_;
      Test::More::is_deeply( \@args, [ "ok" ], '@_ to Derived::Class::BUILD' );
      push @BUILDS_INVOKED, __PACKAGE__;
   }

   method fields {
      return $self->SUPER::fields . ",derived_field=$derived_field";
   }
}

{
   my $obj = Derived::Class->new( "ok" );
   is( $obj->fields, "base_field=123,derived_field=456",
      '$obj->fields' );
   is_deeply( \@BUILDS_INVOKED, [qw( Derived::Class )],
      'BUILD invoked correctly' );

   # We don't mind what the output here is but it should be well-behaved
   # and not crash the dumper
   use Data::Dump 'pp';

   is( pp($obj),
      q(bless({ "base_field" => 123, "Object::Pad/slots" => [456] }, "Derived::Class")),
      'pp($obj) of Object::Pad-extended foreign HASH class' );
}

@BUILDS_INVOKED = ();

# Ensure that double-derived classes still chain down to foreign new
{
   class DoubleDerived isa Derived::Class {
      BUILD {
         push @BUILDS_INVOKED, __PACKAGE__;
      }
      method fields {
         return $self->SUPER::fields . ",doubled=yes";
      }
   }

   is( DoubleDerived->new( "ok" )->fields,
      "base_field=123,derived_field=456,doubled=yes",
      'Double-derived from foreign still invokes base constructor' );
   is_deeply( \@BUILDS_INVOKED, [qw( Derived::Class DoubleDerived )],
      'BUILD invoked correctly for double-derived class' );
}

# Various RT132263 test cases
{
   package RT132263::Parent;
   sub new {
      my $class = shift;
      my $self = bless {}, $class;
      $self->{result} = $self->example_method;
      return $self;
   }
}

# Test case one - no slot access in example_method
{
   class RT132263::Child1 isa RT132263::Parent {
      method example_method { 1 }
   }

   my $e;
   ok( !defined( $e = exception { RT132263::Child1->new } ),
      'RT132263 case 1 constructs OK' ) or
      diag( "Exception was $e" );
}

# Test case two - read from an initialised slot
{
   class RT132263::Child2 isa RT132263::Parent {
      has $value = 456;
      method example_method { $value }
   }

   my $obj;
   my $e;
   ok( !defined( $e = exception { $obj = RT132263::Child2->new } ),
      'RT132263 case 2 constructs OK' ) or
      diag( "Exception was $e" );

   {
      local our $TODO = "slot initialisers no longer run during foreign superconstructor";

      $obj and is( $obj->{result}, 456, '$obj->{result} has correct value' );
   }

   # gutwrench into internals
   is( scalar @{ $obj->{'Object::Pad/slots'} }, 1,
      'slots ARRAY contains correct number of elements' );
}

# Check we are not allowed to switch the representation type back to native
{
   like( exception {
         eval( "class SwitchedToNative isa Base::Class :repr(native) { }" ) or die $@;
      },
      qr/^Cannot switch a subclass of a foreign superclass type to :repr\(native\) at /,
      'Exception from switching a foreign derived class back to native representation' );
}

{
   my $newarg_destroyed;
   my $buildargs_result_destroyed;
   package DestroyWatch {
      sub new { bless [ $_[1] ], $_[0] }
      sub DESTROY { ${ $_[0][0] }++ }
   }

   package RefcountTest::Base {
      sub new { bless {}, shift }
   }
   class RefcountTest isa RefcountTest::Base {
      sub BUILDARGS {
         return DestroyWatch->new( \$buildargs_result_destroyed )
      }
   }

   RefcountTest->new( DestroyWatch->new( \$newarg_destroyed ) );

   is( $newarg_destroyed, 1, 'argument to ->new destroyed' );
   is( $buildargs_result_destroyed, 1, 'result of BUILDARGS destroyed' );
}

done_testing;
