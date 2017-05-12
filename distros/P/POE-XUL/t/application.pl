#!/bin/perl -w

use strict;
use warnings;

use POE;
use POE::Component::XUL;

my $port = shift;
my $root = shift;
POE::Component::XUL->spawn( {
        port => $port,
        root => $root,
        timeout=> 5*60,
        apps => {
            Test => 'My::Application',
        }
    } );

warn "# http://localhost:$port\n" unless $ENV{AUTOMATED_TESTING};
$poe_kernel->run();
warn "# exit" unless $ENV{AUTOMATED_TESTING};

#############################################################################
package My::Application;

use strict;
use warnings;

use POE;
use POE::XUL::Node;
use POE::XUL::Application;
use POE::XUL::Logging;

use constant DEBUG => 1;

use base qw( POE::XUL::Application );

###############################################################
sub boot
{
    my( $self, $event ) = @_;
    Boot( 'Test application' );
    $self->createHandler( 'Click1' );
    $self->createHandler( 'Click2' );
    $self->createHandler( 'Click2_later' );
    $self->createHandler( 'xul_Click_honk_honk' );
    my $b;
    Window(
            Description( id=>'desc', "do the following" ),
            HBox (
                Button( id=>'button', label => "click me", 
                                      Click => 'Click1' ),
                Button( id=>'blow_up', label => "Asplode!", 
                                      Click => 'blow_up' ),
                $b = Button( id=>'honk', label => "Honk" ),
            )
        );
    $b->attach( 'Click' );      # creates the xul_Click_honk handler

    my $b2 = Button( id=>'HONK', label => "HONK" );
    window->appendChild( $b2 );
    $b2->attach( 'Click' );     # creates the xul_Click_HONK handler

#    die "GRRR!";
    print "$$: boot\n";
}

###############################################################
sub Click1
{
    my( $self, $event ) = @_;

    DEBUG and xwarn "$$: Click1 CM=$POE::XUL::Node::CM";
    my $D = window->getElementById( 'desc' );
    $D->textNode( 'You did it!' );

    my $B2 = window->getElementById( 'button' );
    $B2 = Button( label=>'click me too', 
                  Click => 'Click2', 
                  id => 'button2'
                );
    # DEBUG and warn "P::X::App::window=$POE::XUL::Application::window";
    # DEBUG and warn "window=".window;
    window->firstChild->appendChild( $B2 );   
}


###############################################################
sub Click2
{
    my( $self, $event ) = @_;

    DEBUG and xwarn "$$: Click2 event=$event";
    $event->defer;
    $poe_kernel->post( $event->SID, 'Click2_later', $event );
}

sub Click2_later
{
    my( $self, $event ) = @_;

    DEBUG and xwarn "$$: Click2_later event=$event";

    my $D = window->getElementById( 'desc' );
    $D->textNode( 'Thank you' );

    $event->handled;
}

###############################################################
sub blow_up
{
    my( $self, $event ) = @_;
    xwarn "kaboom";
    die "Kabooom!";
}

###############################################################
sub xul_Click_honk
{
    my( $self, $event ) = @_;
    my $D = window->getElementById( 'desc' );
    $D->textNode( 'honk' );
    $event->defer;
    $poe_kernel->yield( 'xul_Click_honk_honk', $event, $D );
}

sub xul_Click_honk_honk
{
    my( $self, $event, $D ) = @_;
    $D->textNode( $D->textNode . " honk" );

    $event->handled;
}

###############################################################
sub xul_Click_HONK
{
    my( $self, $event ) = @_;
    my $D = window->getElementById( 'desc' );
    $D->textNode( 'HONK HONK' );
}

