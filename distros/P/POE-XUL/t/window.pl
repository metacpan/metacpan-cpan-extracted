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

our $ID = 1;

###############################################################
sub boot
{
    my( $self, $event ) = @_;
    Boot( 'Test application' );
    $self->createHandler( 'xul_Connect_sub_window_1' );
    Window(
            Description( id=>'desc', "Hello" ),
            HBox (
                Button( id=>'open_it', label => "Open window", 
                                       Click => 'Open' ),
                Button( id=>'blow_up', label => "Asplode!", 
                                       Click => 'blow_up' ),
                Button( id=>'open_better', label => "Better open" ),
              $self->{closeB} = 
                Button( id=>'close_it', label => "Close window", 
                                        disabled => 1 )
            )
        );
    $self->{closeB}->attach( 'Click' );
    window->getElementById( 'open_better' )->attach( 'Click' );
    # print "$$: boot\n";
}

###############################################################
sub Open
{
    my( $self, $event ) = @_;

    DEBUG and xwarn "$$: Click1 CM=$POE::XUL::Node::CM";
    my $D = window->getElementById( 'desc' );
    $D->textNode( 'Opening a window' );

    $ID ||= 1;
    $self->{closeB}->disabled( 0 ) if $ID == 1;
    window->open( 'sub-window-'.$ID, 
                    {
                        width => 640, height => 400,
                        menubar => 1
                }   );
    $ID++;
}

###############################################################
sub blow_up
{
    my( $self, $event ) = @_;
    xwarn "kaboom";
    die "Kabooom!";
}

###############################################################
sub xul_Connect_sub_window_1
{
    my( $self, $event ) = @_;
    my $win = $event->window;
    DEBUG and xwarn "Connect ", $win->id;

    my $D = window->getElementById( 'desc' );
    $D->textNode( 'Opened window '.$win->id );
    window->appendChild( Description( 'honk' ) );

    $win->appendChild( Description( "This is ".$win->id ) );
    warn "This is ", $win->id, " desc.id=", $win->lastChild->id 
                unless $ENV{AUTOMATED_TESTING};
}

sub connect
{
    my( $self, $event ) = @_;
    my $win = $event->window;
    DEBUG and xwarn "Connect ", $win->id;

    my $D = window->getElementById( 'desc' );
    $D->textNode( 'Opened window '.$win->id );

    $win->appendChild( Description( "This is ".$win->id ) );
    # warn "This is ", $win->id, " desc.id=", $win->lastChild->id;

    die "Why no number in ", $win->id unless $win->id =~ /-(\d+)/;
    my $n = $1;
    my $b = Button( id=>"close_me$n", label => 'Close' );
    $win->appendChild( $b );
    if( $n > 3 ) {
        $b->attach( 'Click' );
    }
    else {
        $b->attach( 'Click' => 'Click' );        
    }
}


###############################################################
sub xul_Click_close_it
{
    my( $self, $event ) = @_;

    my $D = window->getElementById( 'desc' );
    $D->textNode( 'Close first window' );

    DEBUG and xwarn "Click close_it";
    my $win = window->getElementById( 'sub-window-1' );
    $win->close;    

    $self->{closeB}->disabled( 1 );
}

###############################################################
sub xul_Click_close_me2
{
    my( $self, $event ) = @_;

    my $D = window->getElementById( 'desc' );
    $D->textNode( 'Closing window #2' );

    $event->window->close;
}

sub xul_Click_close_me3
{
    my( $self, $event ) = @_;

    my $D = window->getElementById( 'desc' );
    $D->textNode( 'Closing window #3' );

    $event->window->close;
}

###############################################################
sub Click
{
    my( $self, $event ) = @_;
    my $D = window->getElementById( 'desc' );
    $D->textNode( 'Closing window ' . $event->window->id );

    $event->window->close;
}


###############################################################
sub xul_Click_open_better
{
    my( $self, $event ) = @_;

    DEBUG and xwarn "$$: Better open CM=$POE::XUL::Node::CM";
    my $D = window->getElementById( 'desc' );
    $D->textNode( 'Opening a better window' );

    my $twin = window->open( '', {
                                    width => 640, height => 400,
                                    menubar => 1
                            } );

    $twin->attach( 'Connect' => 'better_connect' );
    $twin->attach( 'Disconnect' => 'better_disconnect' );
}

###############################################################
sub better_connect
{
    my( $self, $event ) = @_;
    my $win = $event->window;
    DEBUG and xwarn "$$: Better connect ", $win->id;
    $win->appendChild( Description( "This is ".$win->id ) );
}

###############################################################
sub better_disconnect
{
    my( $self, $event ) = @_;
    my $win = $event->window;
    DEBUG and xwarn "$$: Better disconnect ", $win->id;

    my $D = window->getElementById( 'desc' );
    $D->textNode( 'Closing window ' . $win->id );
}

