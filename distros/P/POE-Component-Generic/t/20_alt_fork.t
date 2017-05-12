#!/usr/bin/perl -w
# $Id: 20_alt_fork.t 1044 2012-11-28 16:35:54Z fil $

use strict;

# sub POE::Kernel::TRACE_REFCNT () { 1 }

sub DEBUG () { 0 }

use FindBin;
use lib "$FindBin::Bin/..";

use Test::More tests => 18;
use POE::Component::Generic;
use POE::Session;
use POE::Kernel;

my $N = 3;
if( $ENV{HARNESS_PERL_SWITCHES} ) {
    $N *= 5;
}


SKIP:
{

#    if( $^O eq 'MSWin32' ) {
#        skip "alt_fork not supported on MSWin32", 18;
#    }
    
    my $generic = POE::Component::Generic->spawn( 
              alias 		=> 'first',
              package 		=> 't::P10',
              methods		=> [ qw( new set_delay get_delay delay ) ],
              object_options 	=> [ delay=>$N ],
              alt_fork 		=> 1,
              debug 		=> DEBUG
          );

    my $delayed;

    POE::Session->create(
        inline_states => {
          _start => sub {
              $poe_kernel->alias_set( 'worker' );
              diag( "$N seconds" );
              $poe_kernel->delay( 'autoload', $N );
          },
          
          _stop => sub {
              DEBUG and warn "_stop";
          },
          
          ############
          autoload => sub {
              diag( "$N seconds" );
              $generic->delay( { event=>'autoload_done', wantarray=>1 } );
              $delayed = 1;
              $poe_kernel->delay( 'autoload_during', ($N/2) );
          },
          autoload_during => sub {
              is( $delayed, 1, "Got a POE delay while object was blocking" );
          },
          autoload_done => sub {
              my( $input ) = @_[ ARG0, ARG1 ];
              my( $before, $after ) = @{ $input->{result} };
              $delayed = 0;
              my $delay = $after - $before;
              
              is( $input->{method}, 'delay', "Callback for delay");
              is( $input->{wantarray}, 1, "Wantarray preserved");
              my $delta = abs( $delay - $N );
            my $allow = 1;
            $allow = 5 if $ENV{AUTOMATED_TESTING};
            ok( ($delta <= $allow), "Waited $N seconds")
                or warn "before=$before after=$after delay=$delay allow=$allow";
              
              $poe_kernel->yield( 'call' );
          },

          ############
          call => sub {
              $generic->set_delay( {}, 2*$N );
              diag( (2*$N) ." seconds" );
              $generic->call( delay => { event=>'call_done', wantarray=>1 } );
          },
          call_done => sub {
              my( $input, $before, $after ) = @_[ ARG0, ARG1..$#_ ];

              my $delay = $after - $before;

              is( $input->{method}, 'delay', "Callback for delay");
              is( $input->{wantarray}, 1, "Wantarray preserved");

              is_deeply( $input->{result}, [ $before, $after ], 
                      "{result} same as ARG1, ARG2" );
              my $delta = abs( $delay - 2*$N );
              ok( ($delta <= 1), "Waited ".(2*$N)." seconds" )
                  or warn "before=$before after=$after delay=$delay";

              $poe_kernel->yield( 'yield' );
          },
          
          ############
          yield => sub {
              $generic->yield( get_delay => { event=>'yield_back',
                                              wantarray=>0 } );
          },
          yield_back => sub {
              my( $input, $delay ) = @_[ARG0, ARG1];

              is( $input->{method}, 'get_delay', "Callback for get_delay");
              is( $input->{wantarray}, 0, "Wantarray preserved");
              is_deeply( $input->{result}, [2*$N], "Got current delay" );
              is( $delay, (2*$N), "Delay is ".(2*$N) );
              
              $poe_kernel->yield( 'post' );
          },

          ############
          post => sub {
              $poe_kernel->post( 'first', 
                                  set_delay => { event=>'post_set' }, 1 );
          },
          post_set => sub {
              $poe_kernel->post( 'first', get_delay => { event=>'post_get' } );
          },
          post_get => sub {
              my( $input, $delay ) = @_[ARG0, ARG1];
              is( $input->{method}, 'get_delay', "Callback for get_delay");
              is( $input->{wantarray}, 0, "Wantarray set");
              is_deeply( $input->{result}, [1], "Got current delay" );
              is( $delay, 1, "Delay is 1" );
              
              $poe_kernel->post( 'first', 
                                  delay => { event=>'post_done', wantarray=>1 } );
          },
          post_done => sub {
              my( $input ) = $_[ARG0];
              my( $before, $after ) = @{ $input->{result} };
              my $delay = $after - $before;
              ok( ($delay == 1 or $delay==2), "Waited 1 seconds")
                  or warn "before=$before after=$after delay=$delay";
              
              $poe_kernel->yield( 'shutdown' );
          },

          ############
          shutdown => sub {
              $poe_kernel->post( first => 'shutdown' );
              $poe_kernel->alias_remove( 'worker' );
          }
        }
    );


    $poe_kernel->run();

    pass( "Sane exit" );
}


