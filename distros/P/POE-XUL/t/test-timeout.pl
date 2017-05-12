#!/usr/bin/perl -w

use strict;

sub POE::Kernel::CATCH_EXCEPTIONS () { 0 }

use POE;
use POE::Component::XUL;

my $port = shift;
my $root = shift;
POE::Component::XUL->spawn( {
        port => $port,
        root => $root,
        timeout=> 5,
        apps => {
            Test => 'My::App',
        }
    } );

warn "# http://localhost:$port" unless $ENV{AUTOMATED_TESTING};
$poe_kernel->run();

warn "# exit" unless $ENV{AUTOMATED_TESTING};

###############################################################
package My::App;

use strict;
use POE;

use POE::XUL::Node;

use constant DEBUG => 0;

###############################################################
sub spawn
{
    my( $package, $event ) = @_;
    my $SID = $event->SID;

    DEBUG and warn "# spawn";

    my $self = bless { SID=>$event->SID }, $package;
    POE::Session->create(
            object_states => [
                $self => [ qw( _start boot Click1 Click2 Click2_later 
                               shutdown _stop ) ]
            ]
        );
}

###############################################################
sub _start
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    $kernel->alias_set( $self->{SID} );
}

sub shutdown
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    $kernel->alias_remove( delete $self->{SID} );
}

sub _stop
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    warn "# _stop" unless $ENV{AUTOMATED_TESTING};
}

###############################################################
sub boot
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];
    DEBUG and warn "# boot";
    $event->wrap( sub {
            DEBUG and warn "# boot CM=$POE::XUL::Node::CM";
            $self->{D} = Description( "do the following" );
            $self->{B1} = Button( label => "click me", 
                                 Click => 'Click1' );
            $self->{W} = Window( HBox( $self->{D}, $self->{B1} ) );

            $event->finish;
        } );
}

###############################################################
sub Click1
{
    my( $self, $kernel, $session, $event ) = 
                @_[ OBJECT, KERNEL, SESSION, ARG0 ];

    DEBUG and warn "# Click1";

    DEBUG and warn "# Click1 CM=$POE::XUL::Node::CM";
    $self->{D}->textNode( 'You did it!' );

    $self->{B2} = Button( label=>'click me too', 
                            Click => $session->callback( 'Click2' )
                        );
    $self->{W}->firstChild->appendChild( $self->{B2} );   
}


###############################################################
sub Click2
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG1 ];

    $event = $event->[0];
    DEBUG and warn "# Click2 event=$event";
    $event->done( 0 );
    $kernel->post( $event->SID(), 'Click2_later', $event );
}

sub Click2_later
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];

    DEBUG and warn "# Click2_later";
    $event->wrap( sub {
            DEBUG and warn "# Click2 CM=$POE::XUL::Node::CM";
            $self->{D}->textNode( 'Thank you' );

            $event->done( 1 );
            $event->finish;
        } );
}





