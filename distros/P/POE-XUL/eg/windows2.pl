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
            VBox( 
                Description( 'Hello world' ), 
                HBox( )
            )
          );
    $self->{b2} = Button( 'Click me too!', id => 'button2' );
    $self->{b1} = Button( 'Click me!', Click => 'Popup' );

    my $box = window->lastChild->lastChild;
    $box->appendChild( $self->{b1} );
    $box->appendChild( $self->{b2} );

    $self->{b2}->attach( 'Click' ); 
    # equiv to ->attach( 'Click', 'xul_Click_button2' )
}

# Called when user clicks on the first button
sub Popup
{
    my( $self, $event ) = @_;
    $event->defer;
    $poe_kernel->delay( 'OpenPopup', 2, $event );
    $self->{b1}->disabled( 1 );
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

# Called when the user clicks the second button
sub xul_Click_button2
{
    my( $self, $event ) = @_;
    $self->{b2}->disabled( 1 );
    window->open( 'SubWindow2', { width=>640, height=>480, menubar=>1 } );
    $self->createHandler( 'xul_Connect_SubWindow2' );
    $self->createHandler( 'xul_Disconnect_SubWindow2' );
}

# Called when the browser opens the first window
sub connect
{
    my( $self, $event ) = @_;
    $event->window->appendChild( Description( "Hello hello!" ) );
}

# Called when the browser closes the first window
sub disconnect
{
    my( $self, $event ) = @_;
    $self->{b1}->disabled( 0 );
}

# Called when the browser opens the other window
sub xul_Connect_SubWindow2
{
    my( $self, $event ) = @_;
    $event->window->appendChild( Description( "Thank you" ) );
}

# Called when the browser closes the other window
sub xul_Disconnect_SubWindow2
{
    my( $self, $event ) = @_;
    $self->{b2}->disabled( 0 );
}

