#!/usr/bin/perl -w

use strict;

# sub POE::Kernel::TRACE_REFCNT () { 1 }

sub DEBUG () { 0 }

use Test::More tests => 19;

use FindBin;
use lib "$FindBin::Bin/..";

use POE;
use POE::Component::Generic;

my $alt_fork = 1;
my $N = 1;
if( $ENV{HARNESS_PERL_SWITCHES} ) {
    $N *= 5;
}
#$alt_fork = 0 if $^O eq 'MSWin32';

my $daemon=0;
#eval "use POE::Component::Daemon; \$daemon++";

my $generic = POE::Component::Generic->spawn( 
          package   => 't::P50',
          methods   => [ qw( new buildthing ) ],
          factories => [ qw( buildthing ) ],
          alt_fork  => $alt_fork,
          verbose   => 1,
          debug     => DEBUG
      );
      
my $C1 = 0;
my $C2 = 0;
my $PID = $$;

my $subobj1;
my $number1;
my $subobj2;

POE::Session->create(
    inline_states => {
        _start => sub {
            $poe_kernel->alias_set( 'worker' );
            diag( "$N seconds" );
            $poe_kernel->delay( 'buildthing', $N );
            if( $daemon ) {
                $poe_kernel->sig( USR1=>'USR1' );
            }
        },
        USR1 => sub { Daemon->__peek( 1 ); },

        _stop => sub {
            DEBUG and warn "_stop";
        },

        #############
        buildthing => sub {
            $generic->buildthing( { event=>'builtthing' }, 
                                    ( number=>17 ) );
        },
        builtthing => sub {
            my( $res, $obj ) = @_[ ARG0, ARG1 ];

            ok( (not $res->{error}), "No errors" )
                        or die "Error = $res->{error}";
            ok( $obj, "Got first object" ); 
            ok( $obj->object_id, "Has an ID" );
            ok( ($obj->object_id =~ /poeAgenericOBJ000000/), 
                    "ID looks like we expect" ) or warn "ID=", $obj->object_id;

            $subobj1 = $obj;



            is( $obj->{package}, 'Duffus', "Nice package" );
            is_deeply( $obj->{package_map}, {new=>'Duffus', number=>'Duffus'},
                        "Nice package_map" );

            $generic->yield( buildthing => { event=>'builtthing2' }, 
                                    ( number=>42 ) );
        },
        builtthing2 => sub {
            my( $res, $obj ) = @_[ ARG0, ARG1 ];

            ok( (not $res->{error}), "No errors" )
                        or die "Error = $res->{error}";
            ok( $obj, "Got second object" ); 
            
            isnt( $obj, $subobj1, "Not the same objects" );
            isnt( $obj->object_id, $subobj1->object_id, "Not the same IDs" );
            
            $subobj2 = $obj;
            $subobj1->number( {event=>'number1'} );     ## psuedo-method
        },
        number1 => sub {
            my( $res, $number ) = @_[ ARG0, ARG1 ];
            ok( (not $res->{error}), "No errors" )
                        or die "Error = $res->{error}";

            is( $number, 17, "Got number 17" ); 
            $number1 = $number;
            $subobj2->yield( 'number', {event=>'number2'} );    ## yield
        },
        number2 => sub {
            my( $res, $number ) = @_[ ARG0, ARG1 ];
            ok( (not $res->{error}), "No errors" )
                        or die "Error = ", join "\n", @{$res->{errors}};

            isnt( $number, $number1, "Not the same number" );

            $subobj1->call( 'number', {event=>'number3'} );     ## call
        },
        number3 => sub {
            my( $res, $number ) = @_[ ARG0, ARG1 ];
            ok( (not $res->{error}), "No errors" )
                        or die "Error = ", join "\n", @{$res->{errors}};

            is( $number, $number1, "Got the same number" );

            my $id = $subobj1->object_id;

            undef( $subobj1 );
            $poe_kernel->yield( 'not_object', $id );
        },

        #############           # call a method on an unknown object
        not_object => sub {
            my $id = $_[ARG0];
            $generic->buildthing( {event=>'not_not', data=>$id,
                                  obj=>$id } );
        },

        not_not => sub {
            my( $resp, $something ) = @_[ARG0..$#_];
            my $id = $resp->{data};
            ok( $resp->{error}, "Expecting error" );
            ok( ($resp->{error} =~ /$id/), "Right-oh" ) 
                or warn "Error: $resp->{error}";

            eval {
                $subobj2->HONK();                
            };
            ok( ($@ =~ /HONK/), "AUTOLOAD error OK" );


            $poe_kernel->yield( 'done' );
        },
        
        done => sub {        

            $generic->shutdown;
        },



    },
);

$poe_kernel->run;

