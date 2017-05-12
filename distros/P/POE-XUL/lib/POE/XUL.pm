# Copyright 2007-2010 by Philip Gwyn.  All rights reserved;

our $VERSION = '0.0601';

use strict;

__END__

=head1 NAME

POE::XUL - Framework for remote XUL application in POE

=head1 SYNOPSIS

    use POE;
    use POE::Component::XUL;

    POE::Component::XUL->spawn( { apps => {   
                                        Test => 'My::App',
                                        # ....
                                } } );
    $poe_kernel->run();

    ##########
    package My::App;
    use POE;
    use POE::XUL::Node;
    use base qw( POE::XUL::Application );

    #####
    sub boot {
        my( $self, $event ) = @_;
        $self->{D} = Description( "do the following" );
        Boot( "This is a test application" );
        Window( HBox( $self->{D}, 
                      Button( label => "click me", 
                              Click => 'Click' ) ) );
        $self->createHandler( 'other_state' );
    }

    #####
    sub Click {
        my( $self, $event ) = @_;
        $event->defer;
        $poe_kernel->yield( 'other_state', $event );
    }

    sub other_state {
        my( $self, $event ) = @_;
        $self->{D}->textNode( 'You did it!' );
        $self->{W}->firstChild->appendChild( $self->{B2} );
        $event->handled;
    }

    #####
    sub shutdown {
        my( $self, $SID ) = @_;
        $kernel->alias_remove( $self->{SID} );
    }

See also the examples in F<eg/>.


=head1 DESCRIPTION

POE::XUL is a framework for creating remote XUL applications with POE.  It
includes a web server, a Javascript client library for Firefox and a widget
toolkit in Perl.

POE::XUL is pronounced similar to I<puzzle>.

At the heart of POE::XUL is the concept of mirror objects.  That is, each
XUL element exists as a DOM node in the client and a Perl object
(L<POE::XUL::Node>) in the server.  The ChangeManager on the server and the
javascript client library are responsible for keeping both objects in sync. 
However, while all attribute changes in the server are mirrored to the
client, only the most important attributes (C<value>, C<selected>, ...) are
mirrored from the client to the server.

POE::XUL currently uses a syncronous, event-based model for updates.  This
will be changed to an asyncronous, bidirectional model (aka
L<comet|http://cometd.com/>) at some point.

XUL is only supported by browsers from the mozilla project (Firefox and
xulrunner).  While this limits POE::XUL's use for general web application,
POE::XUL would make for some very powerful intranet apps.

B<NOTE>: POE::XUL should be considered beta quality.  While I have
applications based on POE::XUL in production, the documentation is probably
incomplete and this API will probably change.

POE::XUL is a fork of Ran Eilam's XUL::Node.  POE::XUL permits multiple
windows, multimode content and the async use of POE events during event
handling.  It also removes the use of the excesively slow Aspect and the
heavy XML wire protocol.  L<POE::XUL::Node>'s API is closer to that of a DOM
element.  XUL::Node's (IMHO) dangerous autoloading of XUL::Node::Application
packages has been removed.

=head2 Application server

L<POE::Component::XUL> is an HTTP server that maps all requests to the
relevant application instance.  It will timeout inactive applications.

An application instance stays in-memory for the entire duration of the
application.  There is no saving and loading of the application data for
each HTTP request.  Because of this, you will probably want to set up a HTTP
proxy front-end with process affinity.  Or be very sure that no POE state
blocks.

=head2 POE::XUL::Application

POE::XUL applications are a sub-class of L<POE::XUL::Application>, which
takes care of most of the interaction with the server and provides many
convienient features to the application.  

It is also possible to write a POE::XUL application in pure-POE.  See
L<POE::XUL::POE>.

=head2 XUL elements

If you are not familiar with XUL, you should read
L<http://www.xulplanet.com/tutorials/xultu/intro.html>.  You should also
keep L<http://developer.mozilla.org/en/docs/XUL> handy.

XUL nodes are created and manipulated with L<POE::XUL::Node>. Each
application must create a C<Window> node and all its children.

=head2 The change manager

The change manager is an object that keeps the XUL elements in the browser
and in the application server in sync.  See L<POE::XUL::ChangeManager>.
Each application instance has a single change manager, which exists
for the duration of the instance.

The change manager isn't directly available to user applications.  They
interact with the change manager via L<POE::XUL::Node>.  
Keeping the change manager visible to L<POE::XUL::Node> is the job
of L<POE::XUL::Session> or L<POE::XUL::Event/wrap>.


=head2 XBL

You are encouraged to create your own XUL nodes with XBL.  To do so, you
will need a custom C<start.xul> that loads the CSS that defines your XBL. 
To create the nodes with C<POE::XUL::Node>:

    my $node = POE::XUL::Node->new( tag=>'mytag' );

You would associate XBL with the following CSS:

    mytag {
        -moz-binding: url( 'my-xbl.xml#mytag' );
    }

See L<https://developer.mozilla.org/en/XBL> for XBL specification.

=head2 Security

Remote XUL applications run as untrusted code.  This means that you will not
be able to XPCOM, the client's harddisk.  However, it should be possible
to bundle the XUL client library into a signed component.  This will be done
once POE::XUL stablizes.


=head1 POE::XUL EVENTS

The life of an application is controled by 1 package method and 2 or more
POE events.

=head2 spawn

Not actually an event!  This is a package method that will be called to
create a new application instance.   See L<POE::XUL::Application/spawn>.

=head2 boot

Once the application's session has been spawned, a C<boot> event is sent.
This event B<must> create at least C<Window> with L<POE::XUL::Node>.  It
should also create all necessary child nodes.

See L<POE::XUL::Application/boot> and L<POE::XUL::Event/boot>.

=head2 timeout

Called after the application has been inactive (no events from the client)
for longer then the C<timeout> value.  No action is required.

See L<POE::XUL::Event/timeout>.

=head2 shutdown

Posted when it is time to delete an application instance.  This is either
when the instance has timed-out, or when the server is shutting down.

See L<POE::XUL::Application/shutdown>, 
L<POE::XUL::POE/shutdown>,
L<POE::XUL::Event/shutdown>.

=head1 MULTIPLE WINDOWS

POE::XUL applications may have multiple windows open at once.  These
are main window (created by L</boot>) and multple sub-windows.

A sub-window is created with the L<POE::XUL::Window/open> method.

=head2 connect

When the browser creates the window a
L<connect|POE::XUL::Application/connect> event is sent. This is when your
application should populate the window. See also L<POE::XUL::POE/connect>
and L<POE::XUL::Event/connect>.

=head2 disconnect

When the window is closed L<disconnect|POE::XUL::Application/disconnect>
event is sent.  This is when your application should clear all resources
used by the window.  See also L<POE::XUL::POE/disconnect> and
L<POE::XUL::Event/connect>.

=head1 DOM EVENTS

After the C<boot> event, further interaction happens via callback events
that you defined on your nodes.  A callback may be a coderef or a POE event.

Note that L<POE::XUL> events to not bubble like DOM events do.

=head2 Click

The most important event.  Happens when a user clicks on a button.  The
application will react accordingly.  See L<POE::XUL::Event/Click> for more
details.

=head2 Change

A less important event, C<Change> is called when the value of a TextBox has
changed.  The application does not have to update the source node's value;
this is a side-effect handled by the ChangeManager.  See 
L<POE::XUL::Event/Change> for more
details.

=head2 Select

See L<POE::XUL::Event/Select> for more details.

=head2 Pick

Called when the users selects a colour in a Colorpicker, Datepicker or other
nodes.  See L<POE::XUL::Event/Pick> for more details.

=head1 ARCHITECTURE

There are many layers POE::XUL.  Maybe too many.

First off, the browser or xulrunner loads C<start.xul?AppName>, which loads
the Javascript client library and any necessary CSS.  The client library
sends a C<boot> event to the server using C<prototype.js>. 
L<POE::Component::XUL> handles HTTP requests in the server.  For a boot
request, it creates a L<POE::XUL::ChangeManager> for the application which
is used by the event to capture any changes to L<POE::XUL::Node>.  The
controler then spawns the application and calls its C<boot> state.  All
nodes created during the boot request will have been noticed by the change
manager.  These nodes are converted into JSON instructions by the
ChangeManager, which are sent as the HTTP response. The JS client library
decodes the JSON instructions, populating the XUL DOM tree with the new
nodes.

The user then interacts with the XUL elements, which will provoke DOM
events. These events are turned into an AJAX request by the JS client
library.  L<POE::Component::XUL> decodes these requests and hands them to the
L<POE::XUL::Controler>.  The Controler creates and populates an
L<POE::XUL::Event>.  The Event will get the change manager to handle any
event I<side-effects>, such as setting C<value> of the target node.  The
Event will then call any user-defined event listeners.  

In the case of L<POE::XUL::Application>, L<POE::XUL::Session> will handle
furthur side effects of the event, then call your application's handlers, if
any are defined.

After the event has been handled, the change manager converts any changes to
the POE::XUL::Nodes to JSON instructions, which are sent as the HTTP
response. The JS client library decodes the JSON instructions, modifying the
XUL DOM tree as necessary.

Understand?  Maybe the following diagram will help:

                                        User
                                         |
    Firefox or xulrunner              DOM Node
                                         |
                                  +------+------+
                                 /               \
    JS client library          Event           Response
                                \/                /\
    HTTP/AJAX                 Request            JSON
                                \/                /\
    POE::Component::XUL       decode              ||
    POE::XUL::Controler       create Event        ||
    POE::XUL::Event           side effects      handled
    POE::XUL::Session         _invoke_state       ||
    POE::XUL::Application     event handlers      ||
    POE::XUL::ChangeManger    record changes -> convert



=head1 TODO

POE::XUL is still a work in progress.  Things that aren't done:

=over 4

=item Keepalive

If a keepalive request was sent every X seconds, the application timeout
could be much shorter, as we would know sooner a browser window was closed.  
This would allow us to recover the memory sooner.

=item Comet

Move from a synchronous event-based model to a full, bi-directional,
asynchronous model using Comet (L<http://cometd.com/>).  Comet would also
act as a keepalive.

=item Better XUL coverage

There are no tests for E<lt>colorpickerE<gt>, E<lt>datepickerE<gt>, 
E<lt>toolbar<gt>, E<lt>listbox<gt>, E<lt>tab<gt> and more.

=back


=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

Based on XUL::Node by Ran Eilam, POE::Component::XUL by David Davis, and of
course, POE, by the illustrious Rocco Caputo.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Philip Gwyn.  All rights reserved;

Copyright 2005 by David Davis and Teknikill Software;

Copyright 2003-2004 Ran Eilam. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), L<POE::XUL::Node>, L<POE::XUL::Event>, L<POE::XUL::Controler>, 
L<POE::XUL::Application>,
L<http://www.prototypejs.org/>.

=cut

