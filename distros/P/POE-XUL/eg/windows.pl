#!/usr/bin/perl -w

HelloWorld->create_server( 'Hello' );

package HelloWorld;

use strict;
use warnings;

use POE;
use POE::XUL::Node;
use POE::XUL::Application;
use base 'POE::XUL::Application';

# Called when the user starts the application
sub boot
{
    my( $self, $event ) = @_;
    $self->createHandler( 'OpenPopup' );
    POE::XUL::Window->new( tag=>'window',
            Description( 'Hello world' ),
            Button( 'Click me!', Click => 'Popup' )
          );
}

# Called when user clicks on the button
sub Popup
{
    my( $self, $event ) = @_;
    $event->defer;
    $poe_kernel->delay( 'OpenPopup', 2, $event );
    window->lastChild->disabled( 1 );
}

# Called 2 seconds after user clicks on the button
sub OpenPopup
{
    my( $self, $event ) = @_;
    window->open( 'SubWindow', { width=> 640, height=>480 } );
    $event->handled;
    # Note that in the current version, the button isn't disabled until
    # $event->handled is called, which sends the HTTP response
}

# Called when the browser opens the new window
sub connect
{
    my( $self, $event ) = @_;
    $event->window->appendChild( Description( "Hello hello!" ) );
}

# Called when the browser closes the new window
sub disconnect
{
    window->lastChild->disabled( 0 );
}
