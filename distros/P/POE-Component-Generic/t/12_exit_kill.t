#!/usr/bin/perl -w
# $Id: 10_simple.t 128 2006-05-02 18:44:22Z fil $

use strict;

use FindBin;
use lib "$FindBin::Bin/..";

use Test::More tests => 3;
use POE::Component::Generic;
use POE::Session;
use POE::Kernel;

sub DEBUG () { 0 }

my $N = 3;
if( $ENV{HARNESS_PERL_SWITCHES} ) {
    $N *= 5;
}

SKIP:
{

    if( $^O eq 'MSWin32' ) {
        skip "kill not supported on MSWin32", 3;
    }

    our $SIG;
    eval '
        use POSIX qw( SIGTERM SIGKILL );
        $TERM=SIGKILL();
    ';


    my $generic = POE::Component::Generic->spawn( 
              alias => 'first',
              package => 't::P10',
              object_options => [ delay=>$N ],
              verbose => DEBUG,
              debug => DEBUG,
              on_exit => [ worker => 'on_exit', 42 ] 
          );

    my $delayed;

    POE::Session->create(
        inline_states => {
            _start => sub {
                $poe_kernel->alias_set( 'worker' );
                $poe_kernel->delay( 'autoload', 1 );
            },
            
            ############  $generic->method( {} )
            autoload => sub {
                diag( "$N seconds" );
                $generic->delay( { event=>'autoload_done', wantarray=>1 } );
                $delayed = 1;
                $poe_kernel->delay( 'autoload_during', 2 );
            },
            autoload_during => sub {
                DEBUG and warn "DURING";
                $generic->kill( $SIG );
            },
            autoload_done => sub {
                die "This should never be called";
            },

            ############    Test error handling
            on_exit => sub {
                my( $N, $resp ) = @_[ARG0..$#_];
                is( $N, 42, "Got my data" );
                is_deeply( $resp, { objects=>[ qw( first ) ]}, 
                        "Got a list of objects that just disapeared" );
                #use Data::Dumper;
                #die Dumper $resp;
                $poe_kernel->yield( 'done' );
            },

            ############    
            done => sub {
                $poe_kernel->alias_remove( 'worker' );
            }
        }
    );

    $poe_kernel->run();

    pass( "Sane exit" );
}
