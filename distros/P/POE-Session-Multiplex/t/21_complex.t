#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;
use POE;

our @LIST = qw( She said yeah );

sub DEBUG () { 0 }

Three->spawn();
Two->spawn( 'Three' );

$poe_kernel->run;


##############################################################################
package One;

use strict;
use warnings;

use POE;
use POE::Session::Multiplex;
use Test::More;

sub DEBUG () {::DEBUG}
our @LIST;

############################################
sub spawn
{
    my( $package, $other ) = @_;
    POE::Session::Multiplex->create( 
                                package_states => [
                                        $package => 
                                            [ qw( _start _stop _psm_begin _psm_end
                                                sing again )]
                                    ],
                                heap => { other => $other }
                            );
}

############################################
sub _start
{
    my( $package ) = @_;
    DEBUG and warn "$package _start";
    $poe_kernel->alias_set( $package );

    foreach my $name ( @::LIST ) {
        $_[SESSION]->object( $name, $package->new( $name ) ); 
    }
    $_[SESSION]->object( YEAH => $package->new( 'YEAH' ) ); 
}

sub _psm_begin
{
    my( $self ) = @_;
    isa_ok( $self, __PACKAGE__ );
}

############################################
sub _stop
{
    my( $package ) = @_;
    DEBUG and warn "_stop";
}

# Only one of the 'Three' packages gets unregistered
sub _psm_end
{
    my( $self ) = @_;
    isa_ok( $self, 'Three' );
}


##############################################################
sub new
{
    my( $package, $word ) = @_;
    return bless { word => $word }, $package;
}

sub sing
{
    my( $self, $heap, $word ) = @_[ OBJECT, HEAP, ARG0 ];
    is( $word, $self->{word}, "Sing: $word" );
    $poe_kernel->post( $_[SENDER], 'fetch', rsvp "again" );
}

sub again
{
    my( $self, $word ) = @_[ OBJECT, ARG0 ];
    is( $word, $self->{word}, "Again: $word" );
}




##############################################################################
package Three;

use strict;
use warnings;

use POE;
use POE::Session::Multiplex qw( :all );
use Test::More;

use base qw( One );

sub _start
{
    my( $package, $session ) = @_[ OBJECT, SESSION ];
    $session->package_register( $package, 
                                [ qw( _start _stop sing again more ) ] );

    shift->SUPER::_start( @_ );
}

sub again
{
    my( $self, $word ) = @_[ OBJECT, ARG0 ];
    $poe_kernel->yield( evo( YEAH => "more" ), 
                            $word, [ evos $_[SESSION], YEAH=>'more' ] 
                      );
    shift->SUPER::again( @_ );
}

sub more
{
    my( $self, $word, $rsvp ) = @_[ OBJECT, ARG0, ARG1 ];
    is_deeply( $rsvp, [ $_[SESSION]->ID, ev"more" ], 'evos' );
    isnt( $word, $self->{word}, "More: $word" );
    if( $word eq 'yeah' ) {
        $_[SESSION]->object( $self->{word} );
    }
}

##############################################################################
package Two;

use strict;
use warnings;

use POE;
use POE::Session::Multiplex;
use Test::More;

sub DEBUG () {::DEBUG}

############################################
sub spawn
{
    my( $package, $other ) = @_;
    POE::Session->create( 
                            package_states => [
                                    $package => 
                                        [ qw( _start _stop next done fetch )]
                                ],
                            heap => { other => $other }
                        );
    return @LIST;
}

############################################
sub _start
{
    my( $package, $heap ) = @_[ OBJECT, HEAP ];
    DEBUG and warn "$package _start";
    $poe_kernel->alias_set( $package );
    $heap->{todo} = [ @::LIST ];
    $_[KERNEL]->yield( 'next' );
}

############################################
sub _stop
{
    my( $package ) = @_;
    DEBUG and warn "_stop";
}

############################################
sub next
{
    my( $package, $heap ) = @_[ OBJECT, HEAP ];
    DEBUG and warn "next";
    my $word = shift @{ $heap->{todo} };
    if( $word ) {
        $poe_kernel->post( $heap->{other} => "$word->sing", $word );
        $heap->{word} = $word;
    }
    else {
        $poe_kernel->yield( 'done' );
    }
}

############################################
sub done
{
    my( $package, $heap ) = @_[ OBJECT, HEAP ];
    $poe_kernel->alias_remove( $package );
}

############################################
sub fetch
{
    my( $package, $heap, $rsvp ) = @_[ OBJECT, HEAP, ARG0 ];
    is( ref $rsvp, 'ARRAY', "RSVP is a reference" );
    is( 0+@$rsvp, 2, "Session + state" );
    $poe_kernel->post( @$rsvp, $heap->{word} );
    $poe_kernel->yield( 'next' );
}

