#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

package Base::Class {
   sub new {
      my $class = shift;
      my ( $ok ) = @_;
      ::is( $ok, "ok", '@_ to Base::Class::new' );
      ::is( scalar @_, 1, 'scalar @_ to Base::Class::new' );

      return bless { base_field => 123 }, $class;
   }

   sub fields {
      my $self = shift;
      return "base_field=$self->{base_field}"
   }
}

my @BUILDS_INVOKED;

class Derived::Class {
   inherit Base::Class;

   field $derived_field = 456;

   BUILD {
      my @args = @_;
      ::is( \@args, [ "ok" ], '@_ to Derived::Class::BUILD' );
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
   is( \@BUILDS_INVOKED, [qw( Derived::Class )],
      'BUILD invoked correctly' );

   # We don't mind what the output here is but it should be well-behaved
   # and not crash the dumper
   use Data::Dumper;

   local $Data::Dumper::Sortkeys = 1;

   is( Dumper($obj) =~ s/\s+//gr,
      q($VAR1=bless({'Object::Pad/slots'=>[456],'base_field'=>123},'Derived::Class');),
      'Dumper($obj) of Object::Pad-extended foreign HASH class' );
}

@BUILDS_INVOKED = ();

# Ensure that double-derived classes still chain down to foreign new
{
   class DoubleDerived {
      inherit Derived::Class;

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
   is( \@BUILDS_INVOKED, [qw( Derived::Class DoubleDerived )],
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

# Test case one - no field access in example_method
{
   class RT132263::Child1 {
      inherit RT132263::Parent;

      method example_method { 1 }
   }

   my $e;
   ok( !defined( $e = dies { RT132263::Child1->new } ),
      'RT132263 case 1 constructs OK' ) or
      diag( "Exception was $e" );
}

# Test case two - read from an initialised field
{
   class RT132263::Child2 {
      inherit RT132263::Parent;

      field $value = 456;
      method example_method { $value }
   }

   my $obj;
   my $e;
   ok( !defined( $e = dies { $obj = RT132263::Child2->new } ),
      'RT132263 case 2 constructs OK' ) or
      diag( "Exception was $e" );

   # gutwrench into internals
   is( scalar @{ $obj->{'Object::Pad/slots'} }, 1,
      'slots ARRAY contains correct number of elements' );
}

# Check we are not allowed to switch the representation type back to native
{
   like( dies {
         eval( "class SwitchedToNative :isa(Base::Class) :repr(native) { }" ) or die $@;
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
   class RefcountTest {
      inherit RefcountTest::Base;

      sub BUILDARGS {
         return DestroyWatch->new( \$buildargs_result_destroyed )
      }
   }

   RefcountTest->new( DestroyWatch->new( \$newarg_destroyed ) );

   is( $newarg_destroyed, 1, 'argument to ->new destroyed' );
   is( $buildargs_result_destroyed, 1, 'result of BUILDARGS destroyed' );
}

# Ensure next::method works with subclassing (RT#150794)
{
   package RT150794::Base {
      sub new { return bless {}, shift }
      sub configure {}
   }

   class RT150794::Derived {
      inherit RT150794::Base;
      method configure { $self->next::method }
   }

   is(
      scalar( grep { $_ eq "Object::Pad::UNIVERSAL" } @RT150794::Derived::ISA ),
      1,
      'RT150794::Derived @ISA contains Object::Pad::UNIVERSAL only once' );

   RT150794::Derived->new->configure;
}

done_testing;
