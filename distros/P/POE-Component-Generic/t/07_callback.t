#!/usr/bin/perl -w
# $Id: 07_callback.t 117 2006-04-12 08:13:22Z fil $

use strict;

use Test::More tests => 2;
use POE::Component::Generic;
use Symbol ();


my $generic = POE::Component::Generic->new( package=>'P1',
                                            callbacks=>[qw(something)],
                                            packages=>{
                                                Biff=>{callbacks=>[qw(honk)]}
                                            } );

is_deeply( $generic->{callback_map}, 
           { P1=>{something=>{ method=>'something' } },
             Biff=>{honk=>{ method=>'honk' } }
           }, "Callback map generated" );

my $g2 = POE::Component::Generic->new( package=>'P1',
                                       packages=>{
                                            Biff=>{callbacks=>'honk'},
                                            P1=>{callbacks=>'something'}
                                       } );
is_deeply( $generic->{factory_map}, $g2->{factory_map},
                       "Scalar ref produces same callback map" );

# $g2 = POE::Component::Generic->new( package=>'P1',
#                                    factories=>'factory' );
#is_deeply( $generic->{factory_map}, $g2->{factory_map},
#                       "Scalar produces same factory map" );



#######################################################################
BEGIN {
package P1;
use strict;

sub new {}
}

