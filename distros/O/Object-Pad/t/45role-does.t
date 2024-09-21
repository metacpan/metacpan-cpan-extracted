#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

role ARole {
}

class AClass {
   apply ARole;
}

{
   my $obj = AClass->new;
   ok( $obj->DOES( "ARole" ), 'AClass::DOES ARole' );
   ok( $obj->DOES( "AClass" ), 'AClass::DOES AClass' );
   ok( AClass->DOES( "ARole" ), 'DOES works as a class method' );
}

role BRole {
}

class BClass {
   apply ARole;
   apply BRole;
}

{
   my $obj = BClass->new;
   ok( $obj->DOES( "ARole" ), 'BClass::DOES ARole' );
   ok( $obj->DOES( "BRole" ), 'BClass::DOES BRole' );
}

role CRole {
}

class CClass {
   apply CRole;
}

{
  my $obj = CClass->new;
  ok(  $obj->DOES( "CRole" ), 'CClass::DOES CRole' );
  ok( !$obj->DOES( "ARole" ), 'CClass::DOES NOT ARole' );
  ok( !$obj->DOES( "BRole" ), 'CClass::DOES NOT BRole' );
}

class ABase {
   apply ARole;
}

class ADerived {
   inherit ABase;
}

{
   ok( ABase->DOES( "ARole" ),    'Sanity?' );
   ok( ADerived->DOES( "ARole" ), 'Derived class DOES base class roles' );
   ok( ABase->DOES( "ABase" ),    'Classes are also roles' );
   ok( ADerived->DOES( "ABase" ), 'DOES implies isa' );
}

package FBaseOne {
   sub new { return bless {}, shift; }
}

class FClassOne {
   inherit FBaseOne;
   apply CRole;
}

{
   ok( FClassOne->DOES( "CRole" ), 'Our role on a class with foreign base' );
   ok( FClassOne->DOES( "FBaseOne" ), 'Foreign base class itself' );
}

package FBaseTwo {
   sub new { return bless {}, shift; }
   sub DOES {
      my $self = shift;
      my $role = shift;
      if( $role =~ m/^FakeRole\d+/ ) { return 1; }
      return $self->SUPER::DOES( $role );
   }
}

class FClassTwo {
   inherit FBaseTwo;
   apply ARole;
}

{
   ok( FClassTwo->DOES( "ARole" ),  'Our role on a class with foreign base' );
   ok( FClassTwo->DOES( "FakeRole42" ), 'Foreign base class DOES method' );
}

role DRole {
   apply ARole;
}

class DClass {
   apply DRole;
}

{
   ok( DClass->DOES( "DRole" ), 'Sanity?' );
   ok( DClass->DOES( "ARole" ), 'Class does role inherited by role' );
}

done_testing;
