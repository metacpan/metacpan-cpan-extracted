#!/usr/bin/perl -w
# $Id: 20_alt_fork.t 161 2006-11-15 07:22:26Z fil $

use strict;

# sub POE::Kernel::TRACE_REFCNT () { 1 }

sub DEBUG () { 0 }

use FindBin;
use lib "$FindBin::Bin/..";

use Test::More tests => 3;
use POE::Component::Generic;
use POE::Session;
use POE::Kernel;

my $N = 10;
if( $ENV{HARNESS_PERL_SWITCHES} ) {
    $N *= 5;
}


SKIP:
{

    if( $^O eq 'MSWin32' ) {
        skip "alt_fork not supported on MSWin32", 3;
    }
    unless( -x "/bin/sh" ) {
        skip "This test uses the Bourne shell (/bin/sh)", 3;
    }
    eval { chmod 0755, 't/alt-fork' };
    unless( -x "t/alt-fork" ) {
        skip "Your archive tool failed to make t/alt-fork executable", 3;
    }    

    my $delayed;
    my $generic;
    my $OK = 1;

    POE::Session->create(
        inline_states => {
          _start => sub {
              $poe_kernel->alias_set( 'worker' );
              # diag( "This test can take a little while" );
              $generic = POE::Component::Generic->spawn( 
                        alias 		=> 'first-x',
                        package 	=> 't::P10',
                        error       => 'sub_error',
                        methods		=> [ qw( new set_delay get_delay delay ) ],
                        object_options 	=> [ delay=>$N ],
                        alt_fork 		=> "t/alt-fork",
                        debug 		=> DEBUG
                    );

              $poe_kernel->delay( 'autoload', $N );
          },
          
          _stop => sub {
              DEBUG and warn "_stop";
          },
          
          ############
          autoload => sub {
              die "Timeout";
          },

          ############
          sub_error => sub {
              my( $kernel, $error ) = @_[ KERNEL, ARG0 ];
              if( $error->{stderr} ) {
		  if( $error->{stderr} eq 'LAST' ) {
		      pass( "Done" );
		      $kernel->yield( 'shutdown' );
		      return;
		  }
                  unless( $error->{stderr} =~ /# .+/ ) {
                      $OK = 0;
                      diag( $error->{stderr} );
		  }
              }
              elsif( ( $error->{errnum} == 32 && $error->{operation} eq 'write' ) 
                     ||
                     ( $error->{errnum} == 104 && $error->{operation} eq 'read' ) ) {
                diag( "Exited" );
                $kernel->yield( 'shutdown' );
              }
              else {
                
                die "Error: ", join "\n", map { "$_: $error->{$_}" }
                                            keys %$error;
              }
          },

        

          ############
          shutdown => sub {
              $poe_kernel->post( 'first-x' => 'shutdown' );
              $poe_kernel->alarm_remove_all( );
          }
        }
    );


    $poe_kernel->run();

    ok( $OK, "All output as expected" );
    pass( "Sane exit" );
    
}


