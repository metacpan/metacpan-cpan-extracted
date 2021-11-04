#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

role ARole {
}

class AClass does ARole {
}

{
   my $obj = AClass->new;
   ok( $obj->DOES( "ARole" ), 'AClass::DOES ARole' );
   ok( $obj->DOES( "AClass" ), 'AClass::DOES AClass' );
   ok( AClass->DOES( "ARole" ), 'DOES works as a class method' );
}

role BRole {
}

class BClass does ARole, BRole {
}

{
   my $obj = BClass->new;
   ok( $obj->DOES( "ARole" ), 'BClass::DOES ARole' );
   ok( $obj->DOES( "BRole" ), 'BClass::DOES BRole' );
}

role CRole {
}

class CClass does CRole {
}

{
  my $obj = CClass->new;
  ok(  $obj->DOES( "CRole" ), 'CClass::DOES CRole' );
  ok( !$obj->DOES( "ARole" ), 'CClass::DOES NOT ARole' );
  ok( !$obj->DOES( "BRole" ), 'CClass::DOES NOT BRole' );
}

class ABase does ARole {
}

class ADerived isa ABase {
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

class FClassOne isa FBaseOne does CRole {
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

class FClassTwo isa FBaseTwo does ARole {
}

{
   ok( FClassTwo->DOES( "ARole" ),  'Our role on a class with foreign base' );
   ok( FClassTwo->DOES( "FakeRole42" ), 'Foreign base class DOES method' );
}

role DRole does ARole {
}

class DClass does DRole {
}

{
   ok( DClass->DOES( "DRole" ), 'Sanity?' );
   ok( DClass->DOES( "ARole" ), 'Class does role inherited by role' );
}

done_testing;
