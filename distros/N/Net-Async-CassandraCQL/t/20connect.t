#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Net::Async::CassandraCQL;
use Protocol::CassandraCQL::Result 0.06;

# Mock the ->_connect_node method
no warnings 'redefine';
my @connect_futures;
my $connect_host;
local *Net::Async::CassandraCQL::_connect_node = sub {
   shift;
   die "No connect future pending" unless @connect_futures;
   ( $connect_host ) = @_;
   return shift @connect_futures;
};

my $cass = Net::Async::CassandraCQL->new(
   host => "my-seed",
);

push @connect_futures, my $conn_f = Future->new;

my $f = $cass->connect;

ok( defined $f, 'defined $f for ->connect' );
is( $connect_host, "my-seed", '->connect host' );
ok( !$f->is_ready, '$f not yet ready' );

my @pending_queries;
my $registered;
my $conn = TestConnection->new;
$cass->add_child( $conn );
$conn_f->done( $conn );

# Initial nodelist query

ok( !$f->is_ready, '$f not yet ready before nodelist queries are done' );

is( scalar @pending_queries, 2, '2 pending queries from connect' );
while( @pending_queries ) {
   my $q = shift @pending_queries;
   identical( $q->[0], $conn, 'connection on pending query' );

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
               [ "\x0a\0\0\3", "DC1", "rack1" ],
            ],
         ),
      );
   }
   else {
      fail( "Unexpected initial query $q->[1]" );
   }
}

ok( $f->is_ready, '$f is now ready' );
ok( $registered, '->register was invoked' );

# ->query on the primary
{
   $f = $cass->query( "DO SOMETHING now", 0 );
   $f->on_fail( sub { die @_ } );

   ok( scalar @pending_queries, '@pending_queries after ->query' );
   my $q = shift @pending_queries;

   identical( $q->[0], $conn, 'connection on pending query' );
   is( $q->[1], "DO SOMETHING now", 'cql for pending query' );

   $q->[2]->done;
   ok( $f->is_ready, '$f is now ready' );
}

# List of hosts
{
   $cass->configure(
      hosts => [qw( seed-1 seed-2 )],
   );

   push @connect_futures, my $conn1_f = Future->new, my $conn2_f = Future->new;

   my $f = $cass->connect;

   is( $connect_host, "seed-1", '->connect host for list of hosts' );
   $conn1_f->fail( "Connection failed", connect => "don't wanna not gonna" );

   is( $connect_host, "seed-2", '->connect host after first of list fails' );

   $conn2_f->done( $conn );
}

done_testing;

package TestConnection;
use base qw( Net::Async::CassandraCQL::Connection );
use Protocol::CassandraCQL qw/:opcodes/;

sub nodeid
{
   return "10.0.0.1";
}

# To handle the register
sub send_message {
    return Future->done( OPCODE_READY );
}
sub query
{
   my $self = shift;
   my ( $cql ) = @_;
   push @pending_queries, [ $self, $cql, my $f = Future->new ];
   return $f;
}

sub register
{
   $registered++;

   Future->done;
}
