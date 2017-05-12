#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::Refcount;

use t::MockConnection;
use Socket qw( pack_sockaddr_in inet_aton );

use Net::Async::CassandraCQL;
use Protocol::CassandraCQL::Result 0.06;

# Mock the ->_connect_node method
no warnings 'redefine';
my %conns;
local *Net::Async::CassandraCQL::_connect_node = sub {
   my $self = shift;
   my ( $connect_host, $connect_service ) = @_;
   $conns{$connect_host} = my $conn = t::MockConnection->new( $connect_host );
   return Future->new->done( $conn );
};

my $cass = Net::Async::CassandraCQL->new(
   host => "10.0.0.1",
);

my $f = $cass->connect;

ok( my $c = $conns{"10.0.0.1"}, 'Connected to 10.0.0.1' );

# Initial nodelist query
$c->send_nodelist(
   local => { dc => "DC1", rack => "rack1" },
   peers => {
      "10.0.0.2" => { dc => "DC1", rack => "rack1" },
   },
);

$f->get;

ok( $c->is_registered, 'Using 10.0.0.1 for events' );

# status changes
{
   my $nodeid;
   $cass->configure(
      on_node_up   => sub { ( undef, $nodeid ) = @_; },
      on_node_down => sub { ( undef, $nodeid ) = @_; },
   );

   # DOWN
   ok( !defined $cass->{nodes}{"10.0.0.2"}{down_time}, 'Node 10.0.0.2 does not yet have down_time' );

   $conns{"10.0.0.1"}->invoke_event(
      on_status_change => DOWN => pack_sockaddr_in( 0, inet_aton( "10.0.0.2" ) ),
   );

   ok( defined $cass->{nodes}{"10.0.0.2"}{down_time}, 'Node 10.0.0.2 has down_time after STATUS_CHANGE DOWN' );
   is( $nodeid, "10.0.0.2", '$nodeid to cluster on_node_down' );
   undef $nodeid;

   # UP
   $conns{"10.0.0.1"}->invoke_event(
      on_status_change => UP => pack_sockaddr_in( 0, inet_aton( "10.0.0.2" ) ),
   );

   ok( !defined $cass->{nodes}{"10.0.0.2"}{down_time}, 'Node 10.0.0.2 no longer has down_time after STATUS_CHANGE UP' );
   is( $nodeid, "10.0.0.2", '$nodeid to cluster on_node_up' );
}

# topology changes
{
   my $nodeid;
   $cass->configure(
      on_node_new    => sub { ( undef, $nodeid ) = @_; },
      on_node_removed => sub { ( undef, $nodeid ) = @_; },
   );

   # NEW
   ok( !defined $cass->{nodes}{"10.0.0.4"}, 'Node 10.0.0.4 does not yet exist' );
   $conns{"10.0.0.1"}->invoke_event(
      on_topology_change => NEW_NODE => pack_sockaddr_in( 0, inet_aton( "10.0.0.4" ) ),
   );

   ok( defined $cass->{nodes}{"10.0.0.4"}, 'Node 10.0.0.4 exists' );

   ok( my $q = $conns{"10.0.0.1"}->next_query, 'Peerlist query exists' );
   is( $q->[1], "SELECT peer, data_center, rack FROM system.peers WHERE peer = '10.0.0.4'", 'Peerlist query CQL' );
   $q->[2]->done( rows =>
      Protocol::CassandraCQL::Result->new(
         columns => [
            [ system => peers => peer        => "VARCHAR" ],
            [ system => peers => data_center => "VARCHAR" ],
            [ system => peers => rack        => "VARCHAR" ],
         ],
         rows => [
            [ "\x0a\0\0\4", "DC1", "rack1" ],
         ],
      )
   );

   is( $nodeid, "10.0.0.4", '$nodeid to cluster on_node_new' );
   ok( defined $cass->{nodes}{"10.0.0.4"}{data_center}, 'Node 10.0.0.4 has known DC' );
   undef $nodeid;

   # DELETE
   $conns{"10.0.0.1"}->invoke_event(
      on_topology_change => REMOVED_NODE => pack_sockaddr_in( 0, inet_aton( "10.0.0.4" ) ),
   );

   ok( !defined $cass->{nodes}{"10.0.0.4"}, 'Node 10.0.0.4 no longer exists' );

   is( $nodeid, "10.0.0.4", '$nodeid to cluster on_node_removed' );
}


done_testing;
