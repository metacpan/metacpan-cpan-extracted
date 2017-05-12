package POE::XUL::Event;
# $Id: Event.pm 1566 2010-11-03 03:13:32Z fil $
# Copyright Philip Gwyn 2007-2010.  All rights reserved.
# Based on code Copyright 2003-2004 Ran Eilam. All rights reserved.

use strict;
use warnings;

use Carp;
use POE::XUL::Logging; 

use constant DEBUG => 0;

our $VERSION = '0.0601';

##############################################################
sub new
{
	my( $package, $event_type, $CM, $response ) = @_;

    croak "Why didn't you give me a ChangeManager" unless $CM;
    croak "Why didn't you give me a HTTP::Response" unless $response;

    my $self = bless {
            event_type  => $event_type,
            CM          => $CM,
            response    => $response,
            canceled    => 0,
            done        => 0
        }, $package;

    $CM->request_start( $self );

    DEBUG and xwarn "$self.CM=$self->{CM}";

    return $self;
}

##############################################################
sub __init
{
    my( $self, $req ) = @_;

    $self->{app} = $req->param( 'app' );
    if( $self->{event_type} ne 'connect' and 
                $self->{event_type} ne 'disconnect' and
                $self->{event_type} ne 'boot' ) {

        my $source_id = $req->param( 'source_id' );
        my $rc = $self->__source_id( $source_id );
        die $rc if $rc;
    }
    foreach my $f ( $req->params ) {
        next if $f eq 'source_id';
        $self->set( $f => $req->param( $f ) );
        # warn "$f=", $self->get( $f );
    }

    if( $self->{event_type} ne 'connect' and 
                $self->{event_type} ne 'boot' ) {
        my $winID = $req->param( 'window' );
        my $rc = $self->__window_id( $winID );
        die $rc if $rc;
    }
}


##############################################################
sub __source_id
{
    my( $self, $id ) = @_;

    my $node = $self->{CM}->getElementById( $id );
    unless( $node ) {
        # xwarn "known = ", join ',', grep { $_ !~ /PXN/ }
        #                             keys %{ $self->{CM}{nodes} };
        return "Can't find source node $id";
    }
    $self->{source} = $node;
    $self->{source_id} = $id;
    return;
}

##############################################################
sub __window_id
{
    my( $self, $id ) = @_;

    my $node;
    if( $id ) {
        $node = $self->{CM}->getElementById( $id );
        DEBUG and xwarn "winID=$id node=$node";
        return "Can't find window node $id" unless $node;
    }
    elsif( $self->{CM} ) {
        $node = $self->{CM}->window;
    }
    $id ||= '';
    $self->{window} = $node;
    $self->{window_id} = $id;
    return;
}

##############################################################
# Accessors
sub set { $_[0]->{ $_[1] } = $_[2] }
sub get { $_[0]->{ $_[1] } }
sub name { 
    return $_[0]->{event_type} unless 2==@_;
    $_[0]->{event_type} = $_[1];
}
*event = \&name;
sub type { $_[0]->{event_type} }
sub session { 
    carp "Please use SID() instead of session()";
    shift->SID( @_ ) 
}

sub resp { $_[0]->{response} }
sub response { $_[0]->{response} }
sub req  { $_[0]->{response}->connection->request }
sub request { $_[0]->{response}->connection->request }

# general accessor/mutator
sub AUTOLOAD {
	my $self = shift;
	my $key  = our $AUTOLOAD;
	return if $key =~ /DESTROY$/;
	$key =~ s/^.*:://;
	return $self->{$key} if @_ == 0;
	$self->{$key} = shift;
}

*target = \&source;

##############################################################
sub coderef
{
    my( $self, $coderef ) = @_;
    $self->{coderef} = $coderef;
}




##############################################################
sub run
{
    my( $self ) = @_;

    local $POE::XUL::Logging::SINGLETON->{app} = $self->{app};

    # Tell the ChangeManager to keep the Node in sync with the browser
    # elements.  This is where event "side-effects" happen
    my $method = "handle_" . $self->event; 
    my $CMm = $self->{CM}->can( $method );

    if( $CMm ) {
        DEBUG and xdebug "$method = $CMm";
        $self->wrap( sub { $CMm->( $self->{CM}, $self ) } ) ;
        return if $self->{CM}{responded};
    }

    # Call code that our builder thinks we should execute
    if( $self->{coderef} ) {
        DEBUG and 
            xdebug "coderef";
        $self->wrap( delete $self->{coderef} );
    }
    # Call code that the application thinks we should execute
    else {
        DEBUG and 
            xdebug "do_event";
        $self->do_event();
    }
}

sub do_event
{
    my( $self ) = @_;
    local $POE::XUL::Logging::SINGLETON->{app} = $self->{app};

    my $bt = delete $self->{bubble_to};
    foreach my $N ( $self->{source}, $bt ) {
        next unless $N;

        my $listener = $N->event( $self->{event_type} );
        DEBUG and 
            xdebug "========== $N listener=$listener";
        next unless $listener;

        $self->{source} = $N;

        $self->wrap( sub {
                if( ref $listener ) {
                    $listener->( $self );
                }
                else {
                    DEBUG and xdebug "Posting to $self->{SID}/$listener";
                    $POE::Kernel::poe_kernel->call( $self->{SID}, 
                                                    $listener, 
                                                    $self 
                                                  );
                }
            } );
        last;
    }
}


##############################################################
sub wrap
{
    my( $self, $coderef ) = @_;
    local $POE::XUL::Logging::SINGLETON->{app} = $self->{app};

    eval {
        local $SIG{__DIE__} = 'DEFAULT';
        DEBUG and 
            xcarp "Wrapping user code CM=$self->{CM}";
        local $POE::XUL::Node::CM = $self->{CM};
        $coderef->( $self );
    };

    if( $@ ) {
        my $err = "APPLICATION ERROR: $@";
        $self->wrapped_error( $err );
        return;
    }
}

##############################################################
## Make sure it is still possible to respond to this event
sub __respondable
{
    my( $self, $action ) = @_;
    if( $self->{canceled} ) {
        xcarp2 "Attempt to $action a canceled event";
        return;
    }
    if( $self->has_response ) {
        xcarp2 "Attempt to $action to a responded event";
        return;
    }
    return 1;
}


##############################################################
sub cancel
{
    my( $self ) = @_;
    $self->{canceled} = 1;
    unless( $self->has_response ) {
        xlog "Event canceled before CM responded";
        $self->{done} = 1;
    }
    else {
        xlog "Event canceled";
    }
}

##############################################################
sub canceled
{
    my( $self ) = @_;
    return $self->{canceled};
}

##############################################################
sub handled
{
    my( $self ) = @_;
    local $POE::XUL::Logging::SINGLETON->{app} = $self->{app};

    $self->done( 1 );
    DEBUG and xcarp "Event finished";

    $self->flush();
}
*finish = \&handled;

##############################################################
sub has_response
{
    my( $self ) = @_;
    return 1 unless $self->{CM};
    return 1 if $self->{CM}->responded;
    return;
}

##############################################################
sub defer
{
    my( $self ) = @_;
    return unless $self->__respondable( 'defer' );
    $self->done( 0 );
}

##############################################################
sub flushed
{
    my( $self ) = @_;
    return $self->{is_flushed};
}

##############################################################
# Flush is called from Controler->xul_request or from Event->finish/flush
sub flush
{
    my( $self ) = @_;
    local $POE::XUL::Logging::SINGLETON->{app} = $self->{app};

    if( $self->{is_flushed} or not $self->{CM} ) {
        Carp::confess "This event was already flushed!";
#        $self->dispose if $self->{CM}; # TODO is this a good idea?
        return;
    }

    return unless $self->__respondable( 'flush' );
    $self->{is_flushed} = 1;

    DEBUG and xdebug "$self->flush";

    # TODO don't do this in case of error
    $self->{CM}->response( $self->{response} ); 
}

##############################################################
sub wrapped_error
{
    my( $self, $err ) = @_;
    local $POE::XUL::Logging::SINGLETON->{app} = $self->{app};
    DEBUG and xdebug "wrapped_error via $self->{CM} ($err)";
    unless( $self->{CM} ) {
        xlog "No CM for error response: ", Dumper $err;
        return;
    }
    $self->{CM}->error_response( $self->{response}, $err );
}


##############################################################
sub data_response
{
    my( $self, $data ) = @_;
    local $POE::XUL::Logging::SINGLETON->{app} = $self->{app};
    $self->{CM}->data_response( $self->{response}, $data );
}

##############################################################
sub dispose
{
    my( $self ) = @_;
    $self->{is_flushed} = 1;
    delete $self->{CM};
    delete $self->{response};    
    DEBUG and xdebug "$self->dispose";
}

1;

__DATA__

=head1 NAME

POE::XUL::Event - A DOM event

=head1 SYNOPSIS

    # POEish
    sub xul_Handler {
        my( $self, $event ) = @_[ OBJECT, ARG0 ];
        warn "Event ", $event->name, " on ", $event->target->id;
        $event->defer;
        $poe_kernel->yield( other_event => $event );
    }

    sub other_event {
        my( $self, $event ) = @_[ OBJECT, EVENT ];
        $event->wrap( sub {
                # ... do work
                $event->handled;
            } );
    }

=head1 DESCRIPTION

User interaction with the browser's DOM may provoke a DOM event.  These
events are handled by the Javascript client library, which will send them
to the L<POE::XUL> server.  C<POE::XUL> encapsulates the event as a
POE::XUL::Event object.  This object associates an application's
L<POE::XUL::Nodes> with the application's L<POE::XUL::ChangeManager>.

First, the ChangeManager handles all side-effects of an event, such as
setting the target node's C<value> attribute.

Next, if there is a listener defined for the event, further execution is
wrappedso that any changes to a Node will be seen by the ChangeManager and
the listener is called.


Note that L<POE::XUL::Events> to not I<bubble> up the DOM tree like DOM
events do.

=head1 METHODS

=head2 name / type / event

    my $name = $event->name;

Accessor that returns the name of the event.  Normaly one of L</Click>,
L</Change>, L</Select> or L</Pick>.

=head2 SID

    my $SID = $event->SID;
    my $instance = $heap->{ $SID };

Returns the session ID of the current application instance.  This is roughly
equivalent to a PID.

=head2 target / source

    my $node = $event->target;

Returns the L<POE::XUL::Node> that was the target of the event.  For
C<Click> this is the a C<Button>, for C<Change>, a C<TextBox>, for
C<Select>, the node you attached the event (either C<RadioGroup>, C<Radio>
C<MenuList> or C<MenuItem>).

=head2 window

Returns the Window node that generated a request.  While
POE::XUL::Aplication's window() always points to the main window, 
C<$event->window()> may point to a sub-window, if the event orginated there.

=head2 defer

    $event->defer;

Defer the event until L</handled> is called.

=head2 done

    $event->done( $state );
    $state = $event->done;

Mark the current event as completed.  Or not.  Initially, an event is marked
as completed.  If you wish to defer the event to another POE state, you may
set done to 0, and then call L</finish> later.

C<$event->done(0)> is better written as C<$event->defer>.

=head2 handled

    $event->handled;

Mark the current event as completed, and flush any changes from the
ChangeManager to the browser.  You only have to call this if you 
called L</defer> previously.

=head2 wrap

    $event->wrap( $coderef );

Wrap a coderef in this event.  This has 2 effects:

First, activates the application's ChangeManager, so that any new or 
modified L<POE::XUL::Node> are seen by it.

Second, if the coderef dies, the error message is displayed in the browser.

POE::XUL::Application handlers are already wrapped.

=head2 flushed

    die "Too late!" if $event->flushed;

Returns true if the current event has already been flushed to the browser.
Because L<POE::XUL> uses a synchronous-event-based model, an event may only
be flushed once.  This, however, should change later at some point.

=head2 data_reponse

    $event->response->content_type( 'image/gif' );
    $event->data_response( $data );

Allows you to send any data as a response to an event.  Especially useful
for <image> with C<src> attribute set to a callback.  C<data_response> will
set the C<Content-Length> header.

=head1 DOM EVENTS

The following events are generated in response to user interaction. 
The application will attach event listeners to nodes.  See
L<POE::XUL::Node/attach>.

=head2 Click

    sub Click {
        my( $self, $event ) = @_[ OBJECT, ARG0 ];
        my $button = $event->source;
    }

The most important event; most action in the application will be in reaction to
the user clicking a button or other control.

=head2 Change

    sub Change {
        my( $self, $event ) = @_[ OBJECT, ARG0 ];
        my $node = $event->source;
        my $value = $event->value;
    }

A less important event, C<Change> is called when the value of a TextBox has
changed.  The application does not have to update the source node's value;
this is a side-effect handled by the ChangeManager.

=head2 Select

    sub Select {
        my( $self, $event ) = @_[ OBJECT, ARG0 ];
        my $list =  $event->source;
        my $selected = $list->getItemAtIndex( $list->selectIndex );
        my $value = $selected->value;
    }

This event happens when a user selects an item in a menulist, radiogroup,
list or other.  The event may also be attached to the menulist or radiogroup
itself.

The target node will be the menulist or radiogroup.  These node's
C<selected> is set as a side-effect by the ChangeManager.

=head2 Pick

    sub Pick {
        my( $self, $event ) = @_[ OBJECT, ARG0 ];
    }

Called when the users selects a colour in a Colorpicker, Datepicker or other
nodes.  TODO better doco.


=head1 APPLICATION EVENTS

The following events are generated during the life time of the application and
do not have an equivalent in the DOM.

Non-POE::XUL::Application events are not automatically handled;
event listeners must call C<$event->handled> when completed.

=head2 boot

    sub boot {
        my( $self, $event ) = @_[ OBJECT, ARG0 ];
        Window( ... );
        $event->handled;
    }

Called when an application instance is first started.  There is no node
to attach a listener to, however, so this event is posted directly to the
application's session.

A boot event does not have a L</target> node nor a source C</window>.

The application's boot handler is expected to create a Window node.

=head2 close

Called when an application closes, that is when the main window closes.

NOT CURRENTLY IMPLEMENTED.  See L<POE::XUL/timeout> and shutdown.

=head2 connect

Called when the browser opens a sub-window.  Sub-windows are created
with L<"window->open()"|POE::XUL::Window/open>.

POE::XUL::Application's will have a window opened and available via
C<$event->window>.  

    sub connect {
        my( $self, $event ) = @_;

        # add elements to the sub-window
        $event->window->appendChild( Description( "Hello world!" ) );

        # updated the main window also
        window->getElementById( 'message' )->textNode( 'Sub-window opened' );
    }

Other applications  will need to create the
L<POE::XUL::Window> themselves.  C<$event->window> will be the window ID
as passed to C<"window->open()">.

    sub connect {
        my( $self, $event ) = @_[ OBJECT, ARG0 ];
        my $winID = $event->window;
        # create and popuplate the sub-window
        my $win = POE::XUL::Window( id=>$win, 
                                    Description( "Hello world!" ) 
                                  );
        $event->handled;
    }

=head2 disconnect

Called when the users closes a sub-window.

C<$event->window> is the sub-window node.

POE::XUL::Application's will have the sub-window node closed when disconnect
returns.

    sub disconnect {
        my( $self, $event ) = @_;
        my $winID = $event->window->id;
        window->getElementById( 'message' )
                    ->textNode( "Closed window $winID" );
    }

Other applications must get rid of the sub-window explicitly.

    sub disconnect {
        my( $self, $event ) = @_[ OBJECT, ARG0 ];
        $event->window->destroy;
        $event->window( undef() );
        $event->handled;
    }


=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

Based on XUL::Node::Event by Ran Eilam.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Philip Gwyn.  All rights reserved;

Copyright 2003-2004 Ran Eilam. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), L<POE::XUL>, L<POE::XUL::ChangeManager>.

=cut

