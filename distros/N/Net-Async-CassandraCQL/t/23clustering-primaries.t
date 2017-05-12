#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::Refcount;

use t::MockConnection;

use Net::Async::CassandraCQL;
use Protocol::CassandraCQL::Result 0.06;

# Mock the ->_connect_node method
no warnings 'redefine';
my %conns;
my %conn_f;
local *Net::Async::CassandraCQL::_connect_node = sub {
   my $self = shift;
   my ( $connect_host, $connect_service ) = @_;
   $conns{$connect_host} = my $conn = t::MockConnection->new( $connect_host );
   return $conn_f{$connect_host} = Future->new;
};

my $cass = Net::Async::CassandraCQL->new(
   host => "10.0.0.1",
   primaries => 3,
);

my $f = $cass->connect;

$conn_f{"10.0.0.1"}->done( my $c = $conns{"10.0.0.1"} );

# Initial nodelist query
$c->send_nodelist(
   local => { dc => "DC1", rack => "rack1" },
   peers => {
      "10.0.0.2" => { dc => "DC1", rack => "rack1" },
      "10.0.0.3" => { dc => "DC1", rack => "rack1" },
   },
);

is( scalar keys %conns, 3, 'All three server connect attempts after ->connect' );

# complete one but not the other
$conn_f{"10.0.0.2"}->done( $conns{"10.0.0.2"} );

# Queries should RR between the two currently connected
{
   my @f = map { $cass->query( "GET THING", 0 ) } 1 .. 6;

   my %q_by_nodeid;
   foreach my $c ( values %conns ) {
      while( my $q = $c->next_query ) {
         $q_by_nodeid{$q->[0]}++;
         $q->[2]->done( result => "here" );
      }
   }

   is_deeply( \%q_by_nodeid,
              { "10.0.0.1" => 3,
                "10.0.0.2" => 3 },
              'Queries distributed per ready node' );

   Future->needs_all( @f )->get;
}

# now complete the final
$conn_f{"10.0.0.3"}->done( $conns{"10.0.0.3"} );

{
   my @f = map { $cass->query( "GET THING", 0 ) } 1 .. 6;

   my %q_by_nodeid;
   foreach my $c ( values %conns ) {
      while( my $q = $c->next_query ) {
         $q_by_nodeid{$q->[0]}++;
         $q->[2]->done( result => "here" );
      }
   }

   is_deeply( \%q_by_nodeid,
              { "10.0.0.1" => 2,
                "10.0.0.2" => 2,
                "10.0.0.3" => 2 },
              'Queries distributed per node' );

   Future->needs_all( @f )->get;
}

$f->get;

done_testing;
