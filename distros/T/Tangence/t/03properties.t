#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Tangence::Constants;
use Tangence::Registry;

use lib ".";
use t::TestObj;

my $registry = Tangence::Registry->new(
   tanfile => "t/TestObj.tan",
);
my $obj = $registry->construct(
   "t::TestObj",
);

# SCALAR 

is( $obj->get_prop_scalar, "123", 'scalar initially' );

my $cb_self;

my $scalar;
$obj->watch_property( scalar =>
   on_set => sub { ( $cb_self, $scalar ) = @_ },
);

my $scalar_shadow;
$obj->watch_property( scalar =>
   on_updated => sub { $scalar_shadow = $_[1] },
);

is( $scalar_shadow, "123", 'scalar shadow initially' );

$obj->set_prop_scalar( "456" );
is( $obj->get_prop_scalar, "456", 'scalar after set' );

identical( $cb_self, $obj, '$cb_self is $obj' );
is( $scalar, "456", '$scalar after set' );

is( $scalar_shadow, "456", 'scalar shadow finally' );

# HASH

is_deeply( $obj->get_prop_hash, { one => 1, two => 2, three => 3 }, 'hash initially' );

my $hash;
undef $cb_self;
my ( $h_key, $h_value );
$obj->watch_property( hash => 
   on_set => sub { ( $cb_self, $hash ) = @_ },
   on_add => sub { ( undef, $h_key, $h_value ) = @_ },
   on_del => sub { ( undef, $h_key ) = @_ },
);

my $hash_shadow;
$obj->watch_property( hash =>
   on_updated => sub { $hash_shadow = $_[1] },
);

is_deeply( $hash_shadow, { one => 1, two => 2, three => 3 }, 'hash shadow initially' );

$obj->set_prop_hash( { four => 4 } );
is_deeply( $obj->get_prop_hash, { four => 4 }, 'hash after set' );
identical( $cb_self, $obj, '$cb_self is $obj' );
is_deeply( $hash, { four => "4" }, '$hash after set' );

$obj->add_prop_hash( five => 5 );
is_deeply( $obj->get_prop_hash, { four => 4, five => 5 }, 'hash after add' );
is( $h_key,   'five', '$h_key after add' );
is( $h_value, 5,      '$h_value after add' );

$obj->add_prop_hash( five => 6 );
is_deeply( $obj->get_prop_hash, { four => 4, five => 6 }, 'hash after add as change' );
is( $h_key,   'five', '$h_key after add as change' );
is( $h_value, 6,      '$h_value after add as change' );

$obj->del_prop_hash( 'five' );
is_deeply( $obj->get_prop_hash, { four => 4 }, 'hash after del' );
is( $h_key, 'five', '$h_key after del' );

is_deeply( $hash_shadow, { four => 4 }, 'hash shadow finally' );

# QUEUE

is_deeply( $obj->get_prop_queue, [ 1, 2, 3 ], 'queue initially' );

my $queue;
undef $cb_self;
my ( $q_count, @q_values );
$obj->watch_property( queue =>
   on_set => sub { ( $cb_self, $queue ) = @_ },
   on_push => sub { shift; @q_values = @_ },
   on_shift => sub { ( undef, $q_count ) = @_ },
);

my $queue_shadow;
$obj->watch_property( queue =>
   on_updated => sub { $queue_shadow = $_[1] },
);

is_deeply( $queue_shadow, [ 1, 2, 3 ], 'queue shadow initially' );

$obj->set_prop_queue( [ 4, 5, 6 ] );
is_deeply( $obj->get_prop_queue, [ 4, 5, 6 ], 'queue after set' );
identical( $cb_self, $obj, '$cb_self is $obj' );
is_deeply( $queue, [ 4, 5, 6 ], '$queue after set' );

$obj->push_prop_queue( 7 );
is_deeply( $obj->get_prop_queue, [ 4, 5, 6, 7 ], 'queue after push' );
is_deeply( \@q_values, [ 7 ], '@q_values after push' );

$obj->shift_prop_queue;
is_deeply( $obj->get_prop_queue, [ 5, 6, 7 ], 'queue after shift' );
is( $q_count, 1, '$q_count after shift' );

$obj->shift_prop_queue( 2 );
is_deeply( $obj->get_prop_queue, [ 7 ], 'queue after shift(2)' );
is( $q_count, 2, '$q_count after shift(2)' );

is_deeply( $queue_shadow, [ 7 ], 'queue shadow finally' );

# ARRAY

is_deeply( $obj->get_prop_array, [ 1, 2, 3 ], 'array initially' );

my $array;
undef $cb_self;
my ( $a_index, $a_count, @a_values, $a_delta );
$obj->watch_property( array =>
   on_set => sub { ( $cb_self, $array ) = @_ },
   on_push => sub { shift; @a_values = @_ },
   on_shift => sub { ( undef, $a_count ) = @_ },
   on_splice => sub { ( undef, $a_index, $a_count, @a_values ) = @_ },
   on_move => sub { ( undef, $a_index, $a_delta ) = @_ },
);

my $array_shadow;
$obj->watch_property( array =>
   on_updated => sub { $array_shadow = $_[1] },
);

is_deeply( $array_shadow, [ 1, 2, 3 ], 'array shadow initially' );

$obj->set_prop_array( [ 4, 5, 6 ] );
is_deeply( $obj->get_prop_array, [ 4, 5, 6 ], 'array after set' );
identical( $cb_self, $obj, '$cb_self is $obj' );
is_deeply( $array, [ 4, 5, 6 ], '$array after set' );

$obj->push_prop_array( 7 );
is_deeply( $obj->get_prop_array, [ 4, 5, 6, 7 ], 'array after push' );
is_deeply( \@a_values, [ 7 ], '@a_values after push' );

$obj->shift_prop_array;
is_deeply( $obj->get_prop_array, [ 5, 6, 7 ], 'array after shift' );
is( $a_count, 1, '$a_count after shift' );

$obj->shift_prop_array( 2 );
is_deeply( $obj->get_prop_array, [ 7 ], 'array after shift(2)' );
is( $a_count, 2, '$a_count after shift(2)' );

$obj->splice_prop_array( 0, 0, ( 5, 6 ) );
is_deeply( $obj->get_prop_array, [ 5, 6, 7 ], 'array after splice(0,0)' );
is( $a_index, 0, '$a_index after splice(0,0)' );
is( $a_count, 0, '$a_count after splice(0,0)' );
is_deeply( \@a_values, [ 5, 6 ], '@a_values after splice(0,0)' );

$obj->splice_prop_array( 2, 1, () );
is_deeply( $obj->get_prop_array, [ 5, 6 ], 'array after splice(2,1)' );
is( $a_index, 2, '$a_index after splice(2,1)' );
is( $a_count, 1, '$a_count after splice(2,1)' );
is_deeply( \@a_values, [ ], '@a_values after splice(2,1)' );

$obj->move_prop_array( 0, 1 );
is_deeply( $obj->get_prop_array, [ 6, 5 ], 'array after move(+1)' );
is( $a_index, 0, '$a_index after move' );
is( $a_delta, 1, '$a_delta after move' );

$obj->set_prop_array( [ 0 .. 9 ] );
$obj->move_prop_array( 3, 2 );
is_deeply( $obj->get_prop_array, [ 0, 1, 2, 4, 5, 3, 6, 7, 8, 9 ], 'array after move(+2)' );

$obj->move_prop_array( 5, -2 );
is_deeply( $obj->get_prop_array, [ 0 .. 9 ], 'array after move(-2)' );

is_deeply( $array_shadow, [ 0 .. 9 ], 'array shadow finally' );

# OBJSET
# Shall have to construct some other TestObj objects to use here, as we can't
# put regular ints in

is_deeply( $obj->get_prop_objset, [], 'objset initially' );

my $objset;
undef $cb_self;
my ( $added, $deleted_id );
$obj->watch_property( objset =>
   on_set => sub { ( $cb_self, $objset ) = @_ },
   on_add => sub { ( undef, $added ) = @_ },
   on_del => sub { ( undef, $deleted_id ) = @_ },
);

my $new = $registry->construct( "t::TestObj" );

$obj->set_prop_objset( { $new->id => $new } );
is_deeply( $obj->get_prop_objset, [ $new ], 'objset after set' );
identical( $cb_self, $obj, '$cb_self is $obj' );
is_deeply( $objset, [ $new ], '$objset after set' );

$obj->del_prop_objset( $new );
is_deeply( $obj->get_prop_objset, [], 'objset after del' );
is( $deleted_id, $new->id, '$deleted_id after del' );

$obj->add_prop_objset( $new );
is_deeply( $obj->get_prop_objset, [ $new ], 'objset after add' );
identical( $added, $new, '$added after add' );

done_testing;
