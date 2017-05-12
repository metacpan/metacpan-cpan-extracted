package POE::XUL::Application;
# $Id$
# Copyright Philip Gwyn 2007-2010.  All rights reserved.

use strict;
use warnings;
use Carp;

our $VERSION = '0.0601';

use POE;
use POE::Component::XUL;
use POE::XUL::Logging;
use POE::XUL::Session;
use constant DEBUG => 1;

use vars qw( $window $server );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( window server );

################################################################
sub window () {  return $window;  }
sub server () {  return $server;  }

################################################################
sub create_server
{
    my( $package, $name ) = @_;
    POE::Component::XUL->spawn( {
            apps => {
                $name => $package
            }
        } );
    $poe_kernel->run;    
}

################################################################
sub spawn
{
    my( $self, $event ) = @_;
    $self = $self->new unless ref $self;
    $self->SID( $event->SID );

    POE::XUL::Session->create( $self );
}

################################################################
sub new
{
    my( $package ) = @_;
    return bless {}, $package;
}

################################################################
sub connect
{
    my( $self, $event ) = @_;
    die "You must overload ", ref( $self ), "->connect";
}

################################################################
sub __mk_accessor
{
    my( $name ) = @_;
    return sub {
            my $self = shift;
            my $rv = $self->{$name};
            $self->{$name} = $_[0] if @_;
            return $rv;
        };
}

*SID = __mk_accessor( 'SID' );
*name = __mk_accessor( 'name' );

################################################################
sub createHandler
{
    my( $self, $name, $what ) = @_;

    croak "Unable to createHandler outside of a POE::XUL::Application"
            unless $server;

    # TODO: Make sure current_session is our session!
    if( $what and ref $what ) {
        $poe_kernel->state( $name, $what );
    }
    else {
        $poe_kernel->state( $name, $self, $what );
    }
}

################################################################
sub removeHandler
{
    my( $self, $name ) = @_;
    # TODO: Make sure current_session is our session!
    $poe_kernel->state( $name );
}


1;

__END__

=head1 NAME

POE::XUL::Application - Base class for POE::XUL application objects

=head1 SYNOPSIS

    package My::Application;
    use strict;
    use warnings;

    use POE::XUL::Node;
    use base qw( POE::XUL::Application );

    sub boot {
        Boot( "Worlds smallest POE::XUL app" );
        Window( Description( "Hello world" ) );
    }

=head1 DESCRIPTION

POE::XUL::Application deals with most of the little details a L<POE::XUL>
application would have to deal with.  It enforces the API contract, as it were. 

It also provides 
POE::XUL::Application works hand in hand with L<POE::XUL::Session> 
to provide some advanced features.

=head1 FUNCTIONS

POE::XUL::Application exports 2 very unfull functions.


=head2 window

Returns the main window node.  This is similar to how JS DOM code always has
a window object available.  Obviously, C<window()> returns undef() before
you create the node in L</boot>.

    my $node = window->getElementById( $id );
    window->appendChild( $new_node );

=head2 server

Returns the L<POE::XUL::Session> delegate object.  This is analogous
to JS DOM's global C<browser> object. 

    $SID = server->SID;
    $poe_kernel->post( server->session, 'some_event' );


=head1 METHODS

=head2 create

This convienient package method will create a L<POE::Component::XUL>
instance.  It is provided so that mutter short code mutter.

    POE::XUL::Application->create( 'MyName' );

=head2 createHandler

Create a new POE event handler.  These handlers may be used by other POE
components, L<POE::Wheel> or as node event listeners.  

    $self->createHandler( 'some_method' );
    $node->attach( 'some_method' );

    $self->createHandler( 'Event' => 'event_handler' );
    $node->attach( 'Click' );       # auto-creates the necessary handler

Because POE::XUL::Application uses L<POE::XUL::Session>, the event handler
calling semantics are the same as regular perl method invocation:

    sub some_method {
        my( $self, $arg1, $arg2 ) = @_;
        # and not @_[ OBJECT, ARG0, ARG1 ];
    }

=head2 removeHandler

Removes the POE event handler.  

Because createHandler and removeHandler are small wrappers around 
L<POE::Kernel/state>, it is possible for you to remove event handlers
that are necessary for the normal functioning of the application:

    $self->removeHandler( 'shutdown' );     # pain!

SO DON'T DO THAT.

=head1 POE::XUL EVENTS

POE::XUL::Application handles most events for you.  You will need to define
a handler for L</boot>, but that is it.  All the L<POE::XUL>
events are still available if you need them as object methods.

=head2 boot

You will want to set a L<boot message|POE::XUL::Node/Boot> and create
POE event handlers in C<boot()>.

    sub boot {
        my( $self, $event ) = @_;
        Boot( $boot_message );
        Window( ... );
    }

Note that the event is automatically L<handled()|POE::XUL::Node/handled>
after the boot method returns.

Furthur events handlers may be defined 

=head2 timeout

    sub timeout {
        my( $self ) = @_;
        # Time, gentlemen, please.
    }

Called after the application has been inactive (no events from the client)
for longer then the C<timeout> value.  No action is required.

=head2 shutdown

    sub timeout {
        my( $self ) = @_;
        # Remove any user-created POE references
    }

Posted when it is time to delete an application instance.  This is either
when the instance has timed-out, or when the server is shutting down.

The session is expected to remove all references (aliases, files, extrefs,
...) so that the POE kernel may GC it.

=head2 DOM EVENTS

Attaching a listener to a node will auto-create the event handler if
nessary.  The event is mapped to one of the method names, in order:

=over

=item 1

The method name you provide to C<$node->attach>.


=item 2

A method name based on the event name and the node's ID.  Non-world (ie
C<\W>) characters in the ID are converted to _

=item 3

The event's name.

=back

So, the following code:

    my $node = Button( id=>'my-button' );
    $node->attach( Click => 'method' );

Attempt be mapped to one of the following 3 methods:

    $self->method()
    $self->xul_Click_my_button()
    $self->Click()

You may also attach to an event without naming a method:

    my $node = Button( id=>'B1' );
    $node->attach( 'Click' );
    # Maps to : $self->xul_Click_B1 or $self->Click;

Of course, your event handler may be a coderef:

    $node->attach( Click => sub { some code here } );
    



=head1 MULTIPLE WINDOWS

POE::XUL::Applications may use the temporary window returned by
L<POE::XUL::Window/open> to set event handlers to something other then the
default object methods.

    $Twin = window->open( 'subwin1' );
    $Twin->attach( 'Connect' );     # maps to xul_Connect_subwin1, see above
    $Twin->attach( 'Disconnect' => 'some_method' );

Window related events are:

=head2 Connect

Posted when a new sub-window has been created.  

The sub-window's node has already been created and is available in
C<$event->window>.

Note that the event is automatically L<handled()|POE::XUL::Node/handled>
after the Connect handler returns.  If you need to run code that would defer
the response, you must created an element who's XBL would then post a
furthur, edeferable event.  TODO how ackward!

See also L<POE::XUL::Event/connect>.


=head2 Disconnect

Posted from the main window when a sub-window is closed.  

When this handler returns, the sub-window node and all its child nodes will
be deleted.

See also L<POE::XUL::Event/disconnect>.

Note that the event is automatically L<handled()|POE::XUL::Node/handled>
after the Disconnect handler returns.




=head1 TODO

POE::XUL is still a work in progress.  Things that aren't done:

=over 4

=item connect/disconnect

Allow defereable connect and disconnect events.

=back


=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Philip Gwyn.  All rights reserved;

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), L<POE::XUL>, L<POE::XUL::Event>, L<POE::XUL::Node>, 
L<POE::XUL::Session>.

L<http://www.prototypejs.org/>.

=cut

