#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;
use Object::Pad::SlotAttr::LazyInit;

my $init_called;

class Example
{
   has $value :param :reader :writer :LazyInit(_make_value) = undef;

   method _make_value { $init_called++; return 1234 };

   method m_get_value { return $value; }
   method m_set_value { $value = shift; }
}

# invoke lazyinit directly
{
   undef $init_called;

   my $obj = Example->new;
   ok( !$init_called, 'lazyinit not yet called after constructor' );

   is( $obj->m_get_value, 1234, 'direct slot read yields lazyinit result' );
   is( $init_called, 1, 'lazyinit called once' );

   is( $obj->m_get_value, 1234, 'direct slot read yields result a second time' );
   is( $init_called, 1, 'lazyinit not called a second time' );
}

# invoke lazyinit via :reader
{
   undef $init_called;

   my $obj = Example->new;
   ok( !$init_called, 'lazyinit not yet called after constructor' );

   is( $obj->value, 1234, '->value yields lazyinit result' );
   is( $init_called, 1, 'lazyinit called once' );

   is( $obj->value, 1234, '->value yields result a second time' );
   is( $init_called, 1, 'lazyinit not called a second time' );
}

# setting slot value cancels lazyinit
{
   undef $init_called;

   my $obj = Example->new;
   ok( !$init_called, 'lazyinit not yet called after constructor' );

   $obj->m_set_value( 5678 );
   is( $obj->value, 5678, '->value sees set value' );
   ok( !$init_called, 'lazyinit not called' );
}

# providing slot value via param cancels lazyinit
{
   undef $init_called;

   my $obj = Example->new( value => 9876 );
   ok( !$init_called, 'lazyinit not called after constructor' );

   is( $obj->value, 9876, '->value sees the initialised value' );
   ok( !$init_called, 'lazyinit still not called' );
}

done_testing;
