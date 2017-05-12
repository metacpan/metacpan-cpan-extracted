#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tangence::Registry;

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

my @value;
my $on_more = sub {
   my $idx = shift;
   @value[$idx .. $idx + $#_] = @_;
};

# Fowards from first
{
   my ( $cursor, undef, $last_idx ) = $proxy->watch_property_with_cursor(
      "queue", "first",
      on_set => sub { @value = @_ },
      on_push => sub { push @value, @_ },
      on_shift => sub { shift @value for 1 .. shift },
   )->get;

   $#value = $last_idx;

   is_deeply( \@value, [ undef, undef, undef ], '@value initially' );

   $on_more->( $cursor->next_forward->get );

   is_deeply( \@value, [ 1, undef, undef ], '@value after first next_forward' );

   $obj->push_prop_queue( 4, 5 );

   is_deeply( \@value, [ 1, undef, undef, 4, 5 ], '@value after push' );

   $on_more->( $cursor->next_forward->get );

   is_deeply( \@value, [ 1, 2, undef, 4, 5 ], '@value after second next_forward' );

   $obj->shift_prop_queue( 1 );

   is_deeply( \@value, [ 2, undef, 4, 5 ], '@value after shift' );

   $on_more->( $cursor->next_forward->get );

   is_deeply( \@value, [ 2, 3, 4, 5 ], '@value after third next_forward' );

   $proxy->unwatch_property( "queue" );
}

# Reset
undef @value;
$obj->set_prop_queue( [ 1, 2, 3 ] );

# Backwards from last
{
   my ( $cursor, undef, $last_idx ) = $proxy->watch_property_with_cursor(
      "queue", "last",
      on_set => sub { @value = @_ },
      on_push => sub { push @value, @_ },
      on_shift => sub { shift @value for 1 .. shift },
   )->get;

   $#value = $last_idx;

   is_deeply( \@value, [ undef, undef, undef ], '@value initially' );

   $on_more->( $cursor->next_backward->get );

   is_deeply( \@value, [ undef, undef, 3 ], '@value after first next_backward' );

   $obj->push_prop_queue( 4, 5 );

   is_deeply( \@value, [ undef, undef, 3, 4, 5 ], '@value after push' );

   $on_more->( $cursor->next_backward->get );

   is_deeply( \@value, [ undef, 2, 3, 4, 5 ], '@value after second next_backward' );

   $obj->shift_prop_queue( 1 );

   is_deeply( \@value, [ 2, 3, 4, 5 ], '@value after shift' );

   $on_more->( $cursor->next_backward->get );

   is_deeply( \@value, [ 2, 3, 4, 5 ], '@value after third next_backward' );

   $proxy->unwatch_property( "queue" );
}

done_testing;
