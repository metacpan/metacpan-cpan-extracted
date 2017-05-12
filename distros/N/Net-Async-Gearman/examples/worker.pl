#!/usr/bin/perl

use strict;
use warnings;

use Future::Utils qw( repeat );
use IO::Async::Loop;
use Net::Async::Gearman::Worker;

my $loop = IO::Async::Loop->new;

my $worker = Net::Async::Gearman::Worker->new;
$loop->add( $worker );

my %FUNCS = (
   strrev => sub { $_[0]->complete( scalar reverse $_[0]->arg ) },
   strtoupper => sub { $_[0]->complete( uc $_[0]->arg ) },
   strtolower => sub { $_[0]->complete( lc $_[0]->arg ) },
   sleep => sub {
      my ( $job ) = @_;
      my $count = $job->arg;
      ( repeat {
         my $i = shift;
         $loop->delay_future( after => 1 )->on_done( sub {
            $job->status( $i, $count );
         });
      } foreach => [ 1 .. $count ] )->then( sub {
         Future->done( "Done" );
      });
   },
);

$worker->add_function( $_ => $FUNCS{$_} ) for keys %FUNCS;

$worker->connect(
   host => "127.0.0.1",
)->get;

$loop->run;
