#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Refcount;

use Tangence::Constants;
use Tangence::Registry;

use Tangence::Server;
use Tangence::Client;

use Tangence::Types;

use lib ".";
use t::TestObj;
use t::TestServerClient;

my $registry = Tangence::Registry->new(
   tanfile => "t/TestObj.tan",
);
my $obj = $registry->construct(
   "t::TestObj",
   scalar   => 123,
   s_scalar => 456,
);

my ( $server, $client ) = make_serverclient( $registry );

my $objproxy = $client->rootobj;

# Methods
{
   my $mdef = $objproxy->can_method( "method" );

   ok( defined $mdef, 'defined $mdef' );
   is( $mdef->name, "method", '$mdef->name' );
   is_deeply( [ $mdef->argtypes ], [ TYPE_INT, TYPE_STR ], '$mdef->argtypes' );
   is( $mdef->ret, TYPE_STR, '$mdef->ret' );

   my $f = $objproxy->call_method( method => 10, "hello" );

   ok( $f->is_ready, '$f ready after MSG_RESULT' );
   is( scalar $f->get, "10/hello", 'result of call_method()' );

   ok( exception { $objproxy->call_method( no_such_method => 123 ) },
      'Calling no_such_method fails in proxy'
   );
}

# Events
{
   my $edef = $objproxy->can_event( "event" );

   ok( defined $edef, 'defined $edef' );
   is( $edef->name, "event", '$edef->event' );
   is_deeply( [ $edef->argtypes ], [ TYPE_INT, TYPE_STR ], '$edef->argtypes' );

   my $event_i;
   my $event_s;
   my $f = $objproxy->subscribe_event( "event",
      on_fire => sub {
         ( $event_i, $event_s ) = @_;
      },
   );

   ok( $f->is_ready, '$f is ready after subscribe_event' );

   $obj->fire_event( event => 20, "bye" );

   is( $event_i, 20, '$event_i after subscribed event' );

   $objproxy->unsubscribe_event( "event" );

   ok( exception { $objproxy->subscribe_event( "no_such_event",
                    on_fire => sub {},
                  ); },
      'Subscribing to no_such_event fails in proxy'
   );
}

# Properties get/set
{
   my $pdef = $objproxy->can_property( "scalar" );

   ok( defined $pdef, 'defined $pdef' );
   is( $pdef->name, "scalar", '$pdef->name' );
   is( $pdef->dimension, DIM_SCALAR, '$pdef->dimension' );
   is( $pdef->type, TYPE_INT, '$pdef->type' );

   is( $objproxy->prop( "s_scalar" ), 456, 'Smashed property initially set in proxy' );

   my $f = $objproxy->get_property( "scalar" );

   is( scalar $f->get, 123, '$f->get after get_property' );

   $f = $objproxy->get_property_element( "hash", "two" );

   is( scalar $f->get, 2, '$f->get after get_property_element hash key' );

   $f = $objproxy->get_property_element( "array", 1 );

   is( scalar $f->get, 2, '$f->get after get_property_element array index' );

   $f = $objproxy->set_property( "scalar", 135 );

   is( $obj->get_prop_scalar, 135, '$obj->get_prop_scalar after set_property' );
   ok( $f->is_ready, '$f is ready after set_property' );
}

# Properties watch
{
   my $value;
   my $f = $objproxy->watch_property( "scalar",
      on_set => sub { $value = shift },
   );

   $obj->set_prop_scalar( 147 );

   is( $value, 147, '$value after watch_property/set_prop_scalar' );

   my $valuechanged = 0;
   my $secondvalue;
   $f = $objproxy->watch_property_with_initial( "scalar",
      on_set => sub {
         $secondvalue = shift;
         $valuechanged = 1
      },
   );

   is( $secondvalue, 147, '$secondvalue after watch_property with want_initial' );

   $obj->set_prop_scalar( 159 );

   is( $value, 159, '$value after second set_prop_scalar' );
   is( $valuechanged, 1, '$valuechanged is true after second set_prop_scalar' );

   $objproxy->unwatch_property( "scalar" );

   ok( exception { $objproxy->get_property( "no_such_property" ) },
      'Getting no_such_property fails in proxy'
   );
}

# Cursors
{
   my @value;
   my $f = $objproxy->watch_property_with_cursor( "queue", "first",
      on_set => sub { @value = @_ },
      on_push => sub { push @value, @_ },
      on_shift => sub { shift @value for 1 .. shift },
   );

   ok( $f->is_ready, '$f is ready after MSG_WATCHING_ITER' );

   my ( $cursor, $first_idx, $last_idx ) = $f->get;

   is( $first_idx, 0, '$first_idx after MSG_WATCHING_ITER' );
   is( $last_idx,  2, '$last_idx after MSG_WATCHING_ITER' );

   my ( $idx, @more ) = $cursor->next_forward->get;

   is( $idx, 0, 'next_forward starts at element 0' );
   is_deeply( \@more, [ 1 ], 'next_forward yielded 1 element' );

   ( $idx, @more ) = $cursor->next_forward( 5 )->get;

   is( $idx, 1, 'next_forward starts at element 1' );
   is_deeply( \@more, [ 2, 3 ], 'next_forward yielded 2 elements' );

   ( $idx, @more ) = $cursor->next_backward->get;

   is( $idx, 2, 'next_backward starts at element 2' );
   is_deeply( \@more, [ 3 ], 'next_forward yielded 1 element' );
}

# Smashed Properties
{
   my $value;
   my $f = $objproxy->watch_property_with_initial( "s_scalar",
      on_set => sub { $value = shift },
   );

   ok( $f->is_ready, 'watch_property on smashed prop is synchronous' );

   is( $value, 456, 'watch_property on smashed prop gives initial value' );

   undef $value;
   $obj->set_prop_s_scalar( 468 );

   is( $value, 468, 'smashed prop update succeeds' );
}

# Test object destruction
{
   my $proxy_destroyed = 0;
   $objproxy->subscribe_event( "destroy",
      on_fire => sub { $proxy_destroyed = 1 },
   )->get;

   my $obj_destroyed = 0;

   $obj->destroy( on_destroyed => sub { $obj_destroyed = 1 } );

   is( $proxy_destroyed, 1, 'proxy gets destroyed' );

   is( $obj_destroyed, 1, 'object gets destroyed' );
}

is_oneref( $client, '$client has refcount 1 before shutdown' );
is_oneref( $server, '$server has refcount 1 before shutdown' );
undef $client; undef $server;

is_oneref( $obj, '$obj has refcount 1 before shutdown' );
is_oneref( $objproxy, '$objproxy has refcount 1 before shutdown' );
is_oneref( $registry, '$registry has refcount 1 before shutdown' );

done_testing;
