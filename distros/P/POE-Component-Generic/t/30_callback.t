#!/usr/bin/perl -w
# $Id: 30_callback.t 1044 2012-11-28 16:35:54Z fil $

use strict;

# sub POE::Kernel::TRACE_REFCNT () { 1 }

sub DEBUG () { 0 }

use FindBin;
use lib "$FindBin::Bin/..";

use Test::More tests => 16;

use POE;
use POE::Component::Generic;

my $N = 1;
my $alt_fork = 1;
if( $ENV{HARNESS_PERL_SWITCHES} ) {
    $N *= 5;
#    $alt_fork = 0;
}
#$alt_fork = 0 if $^O eq 'MSWin32';


my $generic = POE::Component::Generic->spawn( 
          alias     => 'fibble',
          package   => 't::P30',
          methods   => [ qw( new something otherthing twothing ) ],
          callbacks => [ qw( something twothing ) ],
          verbose   => 1,
          alt_fork  => $alt_fork,
          debug     => DEBUG
      );
      
my $C1 = 0;
my $C2 = 0;
my $PID = $$;

POE::Session->create(
    inline_states => {
      _start => sub {
          $poe_kernel->alias_set( 'worker' );
          diag( "$N seconds" );
          $poe_kernel->delay( 'something', $N );
      },
      
      _stop => sub {
          DEBUG and warn "_stop";
      },
  
  
      ################
      something => sub {
          $generic->something( {event=>'something_back'},
                               10, 
                               sub { $C1++; is( $$, $PID, "Callback 1" ) },
                               17,
                             );
      },
      something_back => sub {
          my( $res, $answer ) = @_[ ARG0, ARG1 ];
          ok( (not exists $res->{error}), "No errors" );
          is( $answer, 27, "Got an answer" );
          is( $C1, 1, "Callback was called once" );
          $generic->something( {event=>'something_back2'},
                               42, 
                               sub { $C2++; is( $$, $PID, "Callback 2" ) },
                               42,
                             );
      },
      something_back2 => sub {
          my( $res, $answer ) = @_[ ARG0, ARG1 ];
          ok( (not exists $res->{error}), "No errors" );
          is( $answer, 84, "Got an answer" );
          is( $C1, 1, "Callback 1 was called once" );
          is( $C2, 1, "Callback 2 was called once" );
          
          $poe_kernel->yield( 'twothing' );
      },
      
      ###############
      twothing => sub {
          $generic->twothing( {event=>'twothing_back'},
                               sub { $C1+=$_[0]; is($$, $PID, "Callback 3") },
                               sub { $C2+=$_[0]; is($$, $PID, "Callback 4") },
                             );
      },
      twothing_back => sub {
          my( $res, $answer ) = @_[ ARG0, ARG1 ];
          ok( (not exists $res->{error}), "No errors" );
          is( $C1, 4, "Callback 3 was called twice" );
          is( $C2, 4, "Callback 4 was called twice" );
          
          $generic->shutdown;
      },

   }     
);

$poe_kernel->run;
