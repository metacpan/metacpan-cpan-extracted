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
local *Net::Async::CassandraCQL::_connect_node = sub {
   my $self = shift;
   my ( $connect_host, $connect_service ) = @_;
   $conns{$connect_host} = my $conn = t::MockConnection->new( $connect_host );
   $self->add_child( $conn );
   return Future->new->done( $conn );
};

my $cass = Net::Async::CassandraCQL->new(
   host => "10.0.0.1",
);

my $f = $cass->connect;

ok( my $c = $conns{"10.0.0.1"}, 'have a connection to 10.0.0.1' );

# Initial nodelist query
while( my $q = $c->next_query ) {
   if( $q->[1] eq "SELECT data_center, rack FROM system.local" ) {
      pass( "Query on system.local" );
      $q->[2]->done( rows =>
         Protocol::CassandraCQL::Result->new(
            columns => [
               [ system => local => data_center => "VARCHAR" ],
               [ system => local => rack        => "VARCHAR" ],
            ],
            rows => [
               [ "DC1", "rack1" ],
            ],
         )
      );
   }
   elsif( $q->[1] eq "SELECT peer, data_center, rack FROM system.peers" ) {
      pass( "Query on system.peers" );
      $q->[2]->done( rows =>
         Protocol::CassandraCQL::Result->new(
            columns => [
               [ system => peers => peer        => "VARCHAR" ],
               [ system => peers => data_center => "VARCHAR" ],
               [ system => peers => rack        => "VARCHAR" ],
            ],
            rows => [
               [ "\x0a\0\0\2", "DC1", "rack1" ],
            ],
         ),
      );
   }
   else {
      fail( "Unexpected initial query $q->[1]" );
   }
}

ok( $f->is_ready, '->connect now done after initial queries' );
$f->get;

my $query;
{
   my $f = $cass->prepare( "INSERT INTO t (f) = (?)" );

   ok( my $p = $c->next_prepare, '->prepare pending' );

   is( $p->[0], "10.0.0.1", 'nodeid of pending prepare' );
   is( $p->[1], "INSERT INTO t (f) = (?)", 'cql of pending prepare' );

   $p->[2]->done(
      Net::Async::CassandraCQL::Query->new(
         cassandra   => $cass,
         cql         => $p->[1],
         id          => "0123456789ABCDEF",
         params_meta => Protocol::CassandraCQL::ColumnMeta->new(
            columns   => [
               [ test => t => f => "VARINT" ],
            ],
         ),
      )
   );

   $query = $f->get;

   ok( defined $query, '$query defined after ->prepare->get' );

   undef $f;
   undef $p;
   is_oneref( $query, '$query has refcount 1 initially' );
}

# Fake closure
undef $conns{"10.0.0.1"};
$cass->_closed_node( "10.0.0.1" );

ok( $c = $conns{"10.0.0.2"}, 'new primary node picked' );

# Prepared statements
{
   ok( my $p = $c->next_prepare, 'prepare pending after reconnect' );

   is( $p->[0], "10.0.0.2", 'nodeid of pending prepare after reconnect' );
   is( $p->[1], "INSERT INTO t (f) = (?)", 'cql of pending prepare after reconnect' );

   $p->[2]->done;
}

# ->query after reconnect
{
   my $f = $cass->query( "GET THING", 0 );
   ok( defined $f, 'defined ->query after reconnect' );

   ok( my $q = $c->next_query, '->query after reconnect creates query' );

   like( $q->[0], qr/^10\.0\.0\.[23]$/, '$q conn' );
   is( $q->[1], "GET THING", '$q cql' );
   $q->[2]->done( result => "here" );

   is_deeply( [ $f->get ], [ result => "here" ], '$q result' );
}

# CHEATING
# $query->DESTROY will try to register it for late expiry on the underlying
# Cassandra object. We can convince it not to do that
undef $query->{cassandra};

{
   require IO::Async::Loop;
   my $loop = IO::Async::Loop->new;
   $loop->add( $cass );

   my $f = $cass->close_when_idle;

   identical( scalar $f->get, $cass, '->close_when_idle future yields $cass' );

   $loop->remove( $cass );
}

done_testing;
