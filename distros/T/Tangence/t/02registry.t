#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::Memory::Cycle;
use Test::Refcount;

use Tangence::Constants;

use Tangence::Registry;

use Struct::Dumb 0.09;  # _forbid_arrayification

use lib ".";
use t::TestObj;

$Tangence::Message::SORT_HASH_KEYS = 1;

my $registry = Tangence::Registry->new(
   tanfile => "t/TestObj.tan",
);

ok( defined $registry, 'defined $registry' );
isa_ok( $registry, "Tangence::Registry", '$registry isa Tangence::Registry' );
isa_ok( $registry, "Tangence::Object"  , '$registry isa Tangence::Object' );

is( $registry->id, "0", '$registry->id' );
is( $registry->describe, "Tangence::Registry", '$registry->describe' );

is_deeply( $registry->get_prop_objects, 
           { 0 => 'Tangence::Registry' },
           '$registry objects initially has only registry' );

my $cb_self;
my $added_object_id;
$registry->subscribe_event(
   object_constructed => sub { ( $cb_self, $added_object_id ) = @_ }
);

my $obj = $registry->construct(
   "t::TestObj",
   scalar   => 12,
   s_scalar => 34,
);

ok( defined $obj, 'defined $obj' );
isa_ok( $obj, "t::TestObj", '$obj isa t::TestObj' );

is_oneref( $obj, '$obj has refcount 1 initially' );

is( $obj->id, 1, '$obj->id' );

is( $obj->registry, $registry, '$obj->registry' );

is_deeply( $registry->get_prop_objects, 
           { 0 => 'Tangence::Registry',
             1 => 't::TestObj[scalar=12]' },
           '$registry objects now has obj too' );

identical( $cb_self, $registry, '$cb_self is $registry' );
is( $added_object_id, "1", '$added_object_id is 1' );

undef $cb_self;

ok( $registry->get_by_id( "1" ) == $obj, '$registry->get_by_id "1"' );

ok( !defined $registry->get_by_id( "2" ), '$registry->get_by_id "2"' );

is( $obj->describe, 't::TestObj[scalar=12]', '$obj->describe' );

# Methods
{
   my $mdef = $obj->can_method( "method" );

   isa_ok( $mdef, "Tangence::Meta::Method", '$obj->can_method "method"' );
   is( $mdef->name, "method", 'can_method "method" name' );
   is_deeply( [ map $_->sig, $mdef->argtypes ], [qw( int str )], 'can_method "method" argtypes' );
   is( $mdef->ret->sig, "str", 'can_method "method" ret' );

   ok( !$obj->can_method( "fly" ), '$obj->can_method "fly" is undef' );

   my $methods = $obj->class->methods;
   is_deeply( [ sort keys %$methods ],
              [qw( method noreturn )],
              '$obj->class->methods yields all' );
}

# Events
{
   my $edef = $obj->can_event( "event" );

   isa_ok( $edef, "Tangence::Meta::Event", '$obj->can_event "event"' );
   is( $edef->name, "event", 'can_event "event" name' );
   is_deeply( [ map $_->sig, $edef->argtypes ], [qw( int str )], 'can_event "event" argtypes' );

   ok( $obj->can_event( "destroy" ), '$obj->can_event "destroy"' );

   ok( !$obj->can_event( "flew" ), '$obj->can_event "flew" is undef' );

   my $events = $obj->class->events;
   is_deeply( [ sort keys %$events ],
              [qw( destroy event )],
              '$obj->class->events yields all' );
}

# Properties
{
   my $pdef = $obj->can_property( "scalar" );
   isa_ok( $pdef, "Tangence::Meta::Property", '$obj->can_property "scalar"' );
   is( $pdef->name, "scalar", 'can_property "scalar" name' );
   is( $pdef->dimension, DIM_SCALAR, 'can_property "scalar" dimension' );
   is( $pdef->type->sig, "int", 'can_property "scalar" type' );

   ok( !$obj->can_property( "style" ), '$obj->can_property "style" is undef' );

   my $properties = $obj->class->properties;
   is_deeply( [ sort keys %$properties ],
              [qw( array hash items objset queue s_array s_scalar scalar )],
              '$obj->class->properties yields all' );

   is_deeply( $obj->smashkeys,
              [qw( s_array s_scalar )],
              '$obj->smashkeys' );
}

is_oneref( $obj, '$obj has refcount 1 just before unref' );

{
   no warnings 'redefine';
   local *Tangence::Property::Instance::_forbid_arrayification = sub {};

   memory_cycle_ok( $obj, '$obj has no memory cycles' );

   memory_cycle_ok( $registry, '$registry has no memory cycles' );
}

done_testing;
