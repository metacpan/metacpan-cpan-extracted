#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Memory::Cycle;

use Tangence::Constants;
use Tangence::Registry;

use Struct::Dumb 0.09;  # _forbid_arrayification

use lib ".";
use t::TestObj;
use t::TestServerClient;

my $registry = Tangence::Registry->new(
   tanfile => "t/TestObj.tan",
);
my $obj = $registry->construct(
   "t::TestObj",
);

my ( $server, $client ) = make_serverclient( $registry );

my $proxy = $client->rootobj;

# SCALAR
{
   my $scalar;
   $proxy->watch_property_with_initial( "scalar",
      on_set => sub { $scalar = shift },
   )->get;

   is( $scalar, "123", 'Initial value from watch_property "scalar"' );

   undef $scalar;
   $obj->set_prop_scalar( "1234" );

   is( $scalar, "1234", 'set scalar value' );

   my $also_scalar;
   $proxy->watch_property_with_initial( "scalar",
      on_updated => sub { $also_scalar = shift },
   )->get;

   is( $also_scalar, "1234", 'Can watch_property a second time' );
}

# HASH
{
   my $hash;
   my ( $a_key, $a_value );
   my ( $d_key );
   $proxy->watch_property_with_initial( "hash",
      on_set => sub { $hash = shift },
      on_add => sub { ( $a_key, $a_value ) = @_ },
      on_del => sub { ( $d_key ) = @_ },
   )->get;

   is_deeply( $hash,
              { one => 1, two => 2, three => 3 },
              'Initial value from watch_property "hash"' );

   $obj->add_prop_hash( four => 4 );

   is( $a_key,   'four', 'add hash key' );
   is( $a_value, 4,      'add hash value' );

   $obj->del_prop_hash( 'one' );

   is( $d_key, 'one', 'del hash key' );
}

# QUEUE
{
   my $queue;
   my ( @p_values );
   my ( $sh_count );
   my ( $s_index, $s_count, @s_values );
   $proxy->watch_property_with_initial( "queue",
      on_set => sub { $queue = shift },
      on_push => sub { @p_values = @_ },
      on_shift => sub { ( $sh_count ) = @_ },
   )->get;

   $obj->push_prop_queue( 6 );

   is_deeply( \@p_values, [ 6 ], 'push queue values' );

   $obj->shift_prop_queue( 1 );

   is( $sh_count, 1, 'shift queue count' );
}

# ARRAY
{
   my $array;
   my ( @p_values );
   my ( $sh_count );
   my ( $s_index, $s_count, @s_values );
   my ( $m_index, $m_delta );
   $proxy->watch_property_with_initial( "array",
      on_set => sub { $array = shift },
      on_push => sub { @p_values = @_ },
      on_shift => sub { ( $sh_count ) = @_ },
      on_splice => sub { ( $s_index, $s_count, @s_values ) = @_ },
      on_move => sub { ( $m_index, $m_delta ) = @_ },
   )->get;

   $obj->push_prop_array( 6 );

   is_deeply( \@p_values, [ 6 ], 'push array values' );

   $obj->shift_prop_array( 1 );

   is( $sh_count, 1, 'shift array count' );

   $obj->splice_prop_array( 1, 2, ( 7 ) );

   is( $s_index, 1, 'splice array index' );
   is( $s_count, 2, 'splice array count' );
   is_deeply( \@s_values, [ 7 ], 'splice array values' );

   $obj->set_prop_array( [ 0 .. 4 ] );
   $obj->move_prop_array( 1, 3 );

   is( $m_index, 1, 'move array index' );
   is( $m_delta, 3, 'move array delta' );
}

# OBJSET
{
   my $objset;
   my $added;
   my $deleted_id;
   $proxy->watch_property_with_initial( "objset",
      on_set => sub { $objset = shift },
      on_add => sub { $added = shift },
      on_del => sub { $deleted_id = shift },
   )->get;

   # Shall have to construct some other TestObj objects to use here, as we can't
   # put regular ints in
   my $new = $registry->construct( "t::TestObj" );

   is_deeply( $objset, {}, 'Initial value from watch_property "objset"' );

   undef $objset;
   $obj->set_prop_objset( { $new->id => $new } );

   is( ref $objset, "HASH", 'set objset value type' );
   is_deeply( [ keys %$objset ], [ $new->id ], 'set objset value keys' );

   $obj->del_prop_objset( $new );

   is( $deleted_id, $new->id, 'del objset deleted_id' );

   $obj->add_prop_objset( $new );

   is( ref $added, "Tangence::ObjectProxy", 'add objset added' );
}

{
   no warnings 'redefine';
   local *Tangence::Property::Instance::_forbid_arrayification = sub {};

   memory_cycle_ok( $registry, '$registry has no memory cycles' );
   memory_cycle_ok( $obj, '$obj has no memory cycles' );
   memory_cycle_ok( $proxy, '$proxy has no memory cycles' );
}

done_testing;
