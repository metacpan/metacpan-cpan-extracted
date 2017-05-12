#!/usr/bin/perl -w
# $Id: 15_stdout.t 1044 2012-11-28 16:35:54Z fil $

use strict;

use FindBin;
use lib "$FindBin::Bin/..";

use Test::More tests => 3;
use POE::Component::Generic;
use POE::Session;
use POE::Kernel;

sub DEBUG () { 0 }

my $N = 15;
if( $ENV{HARNESS_PERL_SWITCHES} ) {
    $N *= 3;
}

my $generic = POE::Component::Generic->spawn( 
          alias => 'first',
          package => 't::P15',
          verbose => 0,
          debug => DEBUG
      );

my $delayed;

POE::Session->create(
    inline_states => {
        _start => sub {
            $poe_kernel->alias_set( 'worker' );
            $poe_kernel->delay( 'get_it_on', 1 );
        },

        get_it_on => sub {
            $delayed = $poe_kernel->delay_set( 'timeout', $N );
            $poe_kernel->post( 'first' => 'say', {event=>'did_it'},
                                "# this mustn't mess up interaction" );
        },

        did_it => sub {
            my( $input, $resp ) = @_[ARG0, ARG1];
            $poe_kernel->alarm_remove( $delayed );
            pass( "Got a response" );
            is( $resp, "response", "Got the right response" );
            $poe_kernel->yield( 'done' );
        },

        timeout => sub {
            fail( "Timed out" );
            fail( "Response got messed up" );
        },
        
        got_error=> sub {
            my( $resp ) = $_[ARG0];
            $poe_kernel->yield( 'done' );
        },

        ############    
        done => sub {
            $poe_kernel->post( first => 'shutdown' );
            $poe_kernel->alias_remove( 'worker' );
        }
    }
);

$poe_kernel->run();

ok( 1, "Sane exit" );

