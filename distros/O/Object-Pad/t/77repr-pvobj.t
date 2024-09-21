#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

BEGIN {
   $^V ge v5.38 or
      plan skip_all => "Not supported on Perl $^V";
}

use Object::Pad 0.800;

class Test1 :repr(pvobj)
{
   field $x :reader = 10;
   field $y :reader = 20;

   method where { sprintf "(%d,%d)", $x, $y }
}

{
   my $obj = Test1->new;
   is( $obj->where, "(10,20)", 'Basic instances can be created on :repr(pvobj)' );
}

class Test2
{
   inherit Test1;
   field $z :reader = 30;

   method where { sprintf "(%d,%d,%d)", $self->x, $self->y, $z }
}

{
   my $obj = Test2->new;
   is( $obj->where, "(10,20,30)", 'Subclasses work' );
}

role Test3R
{
   field $w :reader = 40;
}
class Test3 :isa(Test2) :does(Test3R) {}

{
   my $obj = Test3->new;
   is( $obj->w, 40, 'Roles can have fields' );
}

{
   use Object::Pad ':experimental(mop)';

   my $obj = Test3->new;

   my $class1meta = Object::Pad::MOP::Class->for_class( "Test1" );
   is( $class1meta->get_field( '$x' )->value( $obj ), 10,
      'Fieldmeta for base class field usable as accessor' );

   my $class2meta = Object::Pad::MOP::Class->for_class( "Test2" );
   is( $class2meta->get_field( '$z' )->value( $obj ), 30,
      'Fieldmeta for derived class field usable as accessor' );

   my $role3meta = Object::Pad::MOP::Class->for_class( "Test3R" );
   is( $role3meta->get_field( '$w' )->value( $obj ), 40,
      'Fieldmeta for role field usable as accessor' );
}

use Object::Pad::MetaFunctions qw( deconstruct_object get_field );

{
   my $obj = Test3->new;

   is( [ deconstruct_object $obj ],
      [ 'Test3',
        'Test3R.$w' => 40,
        'Test2.$z'  => 30,
        'Test1.$x'  => 10,
        'Test1.$y'  => 20, ],
      'deconstruct_object on Test3' );

   is( get_field( 'Test1.$x', $obj ), 10,
      'get_field on base class field' );
   is( get_field( 'Test2.$z', $obj ), 30,
      'get_field on derived class field' );
   is( get_field( 'Test3R.$w', $obj ), 40,
      'get_field on role field' );
}

done_testing;
