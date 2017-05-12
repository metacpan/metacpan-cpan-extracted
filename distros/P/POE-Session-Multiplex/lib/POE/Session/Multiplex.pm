package POE::Session::Multiplex;

use strict;
use warnings;

use Carp;
use POE;
use POE::Session;

use Scalar::Util qw( blessed );

require Exporter;

our @ISA = qw(Exporter POE::Session);
our %EXPORT_TAGS = ( 'all' => [ qw( ev evs rsvp evo evos ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( ev evo evs rsvp );

our $VERSION = '0.0600';
our $CURRENTOBJ;

our $START;

#######################################
our $LAST_OFF;
BEGIN {
    *SE_NAMESPACE = \&POE::Session::SE_NAMESPACE;
    *SE_OPTIONS   = \&POE::Session::SE_OPTIONS;
    *SE_STATES    = \&POE::Session::SE_STATES;

    ## +1 and +2 used by PlainCall
    if( POE::Session->can( 'SE_ID' ) ) {
        # POE 1.300 + 
        *SE_ID       = \&POE::Session::SE_ID;
        eval '
        *SE_OBJECTS  = sub () { POE::Session::SE_ID+3 };
        *SE_STATERE  = sub () { POE::Session::SE_ID+4 };
        *SE_ISAPLAIN = sub () { POE::Session::SE_ID+5 };
        ';
    }
    else {
        # POE 1.299- 
        *SE_OBJECTS  = sub () { POE::Session::SE_STATES+3 };
        *SE_STATERE  = sub () { POE::Session::SE_STATES+4 };
        *SE_ISAPLAIN = sub () { POE::Session::SE_STATES+5 };
    }

    *EN_SIGNAL    = \&POE::Session::EN_SIGNAL;
    *EN_DEFAULT   = \&POE::Session::EN_DEFAULT;

    *OPT_TRACE    = \&POE::Session::OPT_TRACE;
    *OPT_DEBUG    = \&POE::Session::OPT_DEBUG;
    *OPT_DEFAULT  = \&POE::Session::OPT_DEFAULT;
}

sub OH_OBJECT () { 0 }
sub OH_NAME   () { 1 }
sub OH_OURS   () { 2 }

############################################################################
sub _loggable
{
    my( $self ) = @_;
    $POE::Kernel::poe_kernel->_data_alias_loggable( $_[0] );
}

sub create
{
    my $package = shift;

    if( $package->isa( 'POE::Session::PlainCall' ) ) {
        return $package->POE::Session::PlainCall::create( @_ );
    }
    else {
        return $package->SUPER::create( @_ );
    }
}

sub instantiate
{
    my $package = shift;
    my $self = $package->SUPER::instantiate( @_ );
    $self->__init;
    return $self;
}

sub __init
{
    my( $self ) = @_;
    if( $self->[SE_OBJECTS] ) {
        die "Definition of POE::Session changed!  $self needs to be modified.\n";
    }
    $self->[SE_OBJECTS] = {};
    $self->[SE_ISAPLAIN] = $self->isa( 'POE::Session::PlainCall' );
    if( $self->[SE_ISAPLAIN] ) {
        $self->POE::Session::PlainCall::__init;
    }
}

#######################################
sub _invoke_state
{
    my( $self, $source_session, $state, $etc, $file, $line, $fromstate ) = @_;

    $self->set_objectre unless $self->[SE_STATERE];

    if ($self->[SE_OPTIONS]->{+OPT_TRACE}) {
        POE::Kernel::_warn( $self->_loggable,
                            " -> $state (from $file at $line)\n"
                          );
    }
    
    if( $state =~ /^$self->[SE_STATERE]$/ ) {
        my $obj_name = $1;
        my $obj_state = $2;

        my( $object, $method ) = $self->handler_for( $obj_name, $obj_state, $state );
        if( $method ) {
            if ($self->[SE_OPTIONS]->{+OPT_TRACE}) {
                POE::Kernel::_warn( $self->_loggable,
                                    " OBJECT=$obj_name METHOD=$method\n"
                                  );
            }

            local $CURRENTOBJ = $obj_name;
            if( $self->[SE_ISAPLAIN] ) {
                local $POE::Session::PlainCall::POE_HOLDER  = bless [
                  ( $object,                        # object
                    $self,                          # session
                    $POE::Kernel::poe_kernel,       # kernel
                    $self->[SE_NAMESPACE],          # heap
                    $obj_state,                     # state
                    $source_session,                # sender
                    undef,                          # unused #6
                    $file,                          # caller file name
                    $line,                          # caller file line
                    $fromstate,                     # caller state
                    $method,                        # method
                    $etc,                           # args
                  ) ], 'POE::Session::PlainCall::Holder';
                return $object->$method( @$etc );
            }
            return $object->$method(
                    $self,                          # SESSION
                    $POE::Kernel::poe_kernel,       # KERNEL
                    $self->[SE_NAMESPACE],          # HEAP
                    $obj_state,                     # STATE
                    $source_session,                # SENDER
                    undef,                          # unused #6
                    $file,                          # CALLER_FILE
                    $line,                          # CALLER_LINE
                    $fromstate,                     # CALLER_STATE
                    @$etc,                          # ARG0, ARG1, ARG2
              );
        }
    }

    if ($self->[SE_OPTIONS]->{+OPT_TRACE}) {
                POE::Kernel::_warn( $self->_loggable,
                                " -> $state (not an multiplex state)\n"
                          );
    }

    ## Skip out if it's not our state
    if( $self->[SE_ISAPLAIN] ) {
        return shift->POE::Session::PlainCall::_invoke_state( @_ );
    }
    else {
        return shift->SUPER::_invoke_state( @_ );
    }
}


#######################################
sub evo ($$)
{
    my( $obj_name, $event ) = @_;
    return "$obj_name->$event";    
}

#######################################
sub ev ($)
{
    my( $event ) = @_;
    croak "Can't call ev outside of a multiplexed object" unless $CURRENTOBJ;
    return evo $CURRENTOBJ, $event;
}

#######################################
sub evs ($)
{
    my( $event ) = @_;
    croak "Can't call evs outside of a multiplexed object" unless $CURRENTOBJ;
    my $self = $poe_kernel->get_active_session;
    croak "Can't call evs outside of a multiplexed session" unless $self;
    return $self->ID, ev$event;
}

#######################################
sub rsvp ($)
{
    return [ evs $_[0] ];
}

#######################################
sub evos ($$$)
{
    my( $session, $obj_name, $event ) = @_;
    $session = $session->ID if blessed $session;
    return $session, evo $obj_name, $event;
}


#######################################
sub set_objectre
{
    my( $self ) = @_;
    my $re = '(' . join( '|', map quotemeta, keys %{$self->[SE_OBJECTS]} ).
              ')->(.+)';
    $self->[SE_STATERE] = $re;
}

#######################################
# $obj_name  => name of object
# $obj_state => clean state name
# $state     => raw state name ($obj_name->$obj_state)
sub handler_for
{
    my( $self, $obj_name, $obj_state, $state ) = @_;

    my @ret = $self->_handler_for( $obj_name, $state );
    return @ret if @ret;

    return $self->_handler_for( $obj_name, $obj_state );
}

sub _handler_for
{
    my( $self, $obj_name, $state ) = @_;
    my $handler = $self->[SE_STATES]->{$state};
    return unless $handler;
    return if 'CODE' eq ref $handler;

    my $def = $self->[SE_OBJECTS]->{$obj_name};
    return unless $def;

    # Same object?
    if( blessed $handler->[0] and $handler->[0] eq $def->[OH_OBJECT] ) {
        return $def->[OH_OBJECT], $handler->[1];
    }
    # Object of the right package?
    elsif( $def->[OH_OBJECT]->isa( $handler->[0] ) ) {
        return $def->[OH_OBJECT], $handler->[1];
    }
    return;
}

#######################################
sub object
{
    my( $self, $obj_name, @def ) = @_;
    if( @def ) {
        if( blessed $obj_name ) {            
            @def = ( $obj_name, @def );
            $obj_name = $self->_obj_name( $def[0] );
        }
        $self->object_register( name => $obj_name, 
                                object => $def[0], 
                                states => $def[1]
                              );
    }
    else {
        $self->object_unregister( $obj_name );
    }
}

sub _obj_name
{
    my( $package, $obj ) = @_;
    return "$obj" unless $obj->can( '__name' );
    my $name = $obj->__name;
    die ref( $obj ), "->__name must return the object's name" unless $name;
    return $name;
}


#######################################
sub object_get
{
    my( $self, $obj_name ) = @_;
    return unless exists $self->[SE_OBJECTS]->{ $obj_name };
    return $self->[SE_OBJECTS]->{ $obj_name }[OH_OBJECT];
}

#######################################
sub object_register
{
    my( $self, @def ) = @_;

    if( 1==@def ) {
        @def = ( object => $def[0] );
    }
    my %def = ( @def );

    my $object   = $def{object};
    croak "You must supply an object" unless $object;  

    my $obj_name = $def{name} || $self->_obj_name( $object );
    croak "You may not include -> in an object name" if $obj_name =~ /->/;
    my $states   = $def{states} || $def{events};

    if( $self->[SE_OBJECTS]->{ $obj_name } ) {
        $self->object_unregister( $obj_name );
    }
    $self->[SE_STATERE] = '';

    my $hold = $self->[SE_OBJECTS]->{ $obj_name } = [];
    if( $states ) {
        # Tediously define states for this object
        my $ours = $hold->[OH_OURS] = [];
        local $CURRENTOBJ = $obj_name;
        $states = [ $states ] unless ref $states;
        if( 'HASH' eq ref $states ) {
            while( my( $event, $method ) = each %$states ) {
                push @$ours, ev$event;
                $self->_register_state( $ours->[-1], $object, $method );
            }
        }
        else {
            foreach my $event ( @$states ) {
                push @$ours, ev$event;
                $self->_register_state( $ours->[-1], $object, $event );
            }
        }
    }
    else {
        # Make sure there are some states defined for this object's class
        my $ok = 0;
        my $package = ref $object;
        foreach my $handler ( values %{ $self->[SE_STATES] } ) {
            next unless 'ARRAY' eq ref $handler;
            next if blessed $handler->[0] and $handler->[0] ne $object;
            next unless $package eq $handler->[0] or 
                        $object->isa( $handler->[0] );
            $ok = 1;
            last;
        }
        croak "No package_states defined for package $package" unless $ok;
    }
    $hold->[OH_NAME]   = $obj_name;
    $hold->[OH_OBJECT] = $object;
    
    # greet the object
    if( $self->_handler_for( $obj_name, "_psm_begin" ) ) {
        $poe_kernel->call( $self, evo( $obj_name, "_psm_begin" ) );
    }

    return 1;
}

#######################################
sub object_unregister
{
    my( $self, $obj_name ) = @_;

    if( blessed $obj_name ) {
        $obj_name = $self->_obj_name( $obj_name );
    }
    # say good bye the object
    if( $self->_handler_for( $obj_name, "_psm_end" ) ) {
        $poe_kernel->call( $self, evo( $obj_name, "_psm_end" ) );
    }
    my $def = delete $self->[SE_OBJECTS]->{ $obj_name };
    unless( $def ) {
        carp "Attempt to unregister unknown object $obj_name";
        return;
    }

    $self->[SE_STATERE] = '';
    return unless $def and $def->[OH_OURS];

    foreach my $event ( @{ $def->[OH_OURS] } ) {
        $self->_register_state( $event );
    }        
    return 1;
}

#######################################
sub object_list
{
    my( $self ) = @_;
    return keys %{ $self->[SE_OBJECTS] };
}


#######################################
sub package_register
{
    my( $self, $package, $states ) = @_;

    $states = [ $states ] unless ref $states;
    if( 'HASH' eq ref $states ) {
        while( my( $event, $method ) = each %$states ) {
            $self->_register_state( $event, $package, $method );
        }
    }
    else {
        foreach my $event ( @$states ) {
            $self->_register_state( $event, $package, $event );
        }
    }
    return 1;
}

1;


__END__

=head1 NAME

POE::Session::Multiplex - POE session with object multiplexing

=head1 SYNOPSIS

    use POE;
    use POE::Session::Multiplex;

    My::Component->spawn( @args );
    $poe_kernel->run;

    package My::Component;

    sub spawn {
        my( $package, @args ) = @_;
        POE::Session::Multiplex->create(
                        package_states => [
                                $package => [ qw( _start ) ]
                                'My::Component::Object' => 
                                        [qw( fetch decode back )] 
                            ]
                        args => [ @args ]
                    );
    }

    ##### To add an object to the session:
    my $obj = My::Component::Object->new();
    $_[SESSION]->object( $name, $obj );
        # or
    $_[SESSION]->object_register( name => $name, object => $obj );

    ##### To remove an object
    $_[SESSION]->object_unregister( $name );


    ##### Address an event to the current object:
    my $state = ev"state";

    ##### To build a session/event tuple addressed to the current object
    my $rsvp = rsvp "state";
    
    # this tuple would be useful for getting a response from another session
    $poe_kernel->post( $session=>'fetch', $params, rsvp"fetch_back" );
    
    # and in the 'fetch' handler, you could reply with:
    my $rsvp = $_[ARG1];
    $poe_kernel->post( @$rsvp, $reply );

    ##### Posting to a specific object from inside the session
    $poe_kernel->yield( evo( $name, $state ), @args );

    ##### Posting to a specific object from outside the session
    $poe_kernel->post( evos( $session, $name, $state ), @args );
    $poe_kernel->post( $session, evo( $name, $state ), @args );



=head1 DESCRIPTION

POE::Session::Multiplex allows you to have multiple objects handling
events from a single L<POE::Session>.

A standard POE design is to have one POE::Session per object and to
address each object using session IDs or aliases. 
POE::Session::Multiplex takes the oposite approach; there is only one
session and each object is addressed by manipulating the event name. 

The advantage is that you save the overhead of multiple sessions.
While session creation is very fast, the POE kernel garbage
collection must continually verify that each session should still be
alive.  For a system with many sessions this could represent a
non-trivial task.


=head2 Overview

Each object has a name associated with it.  Events are addressed to the
object by including the object's name in the event name.  When invoked
POE::Session::Multiplex then seperates the object name from the event name
and calls an event handler on the object.

Objects are made available for multiplexing with L</object_register>.  They
are removed with L</object_unregister>.

POE::Session::Multiplex provides handy routines to do the event name
manipulation. See L</HELPER FUNCTIONS>.

Event handlers for a class (aka package) must be defined before hand. This
is done with either L</package_register> or L<POE::Session>'s
package_states.

POE::Session::Multiplex keeps a reference to all objects.  This means that
L<DESTROY> will not be called until you unregister the object.  It also
means that you don't have to keep track of your objects.  See L</object_get>
if you want to retrieve an object.

Objects passed to the session via C<object_states> are currently not
multiplexed, though their events are available to objects of the same class. 
I<This could change in the future>.



=head2 Event methods

POE::Session::Multiplex makes sure that a given event handler method
has been set up for a given object.  That is, if you define an event
for a certain class, that event is not available for objects of other
classes, unless they are descendents of the first class.

For example, a session is created with the following.

    POE::Session::Multiplex->create(
                    # ...
                    package_states => [
                            Class1 => [ qw( load save ) ],
                            Class2 => [ qw( marshall demarshall ) ],
                        ],
                    # ...
                );

Objects of C<Class1> are only accessible via the C<load> and C<save> events
and objects of C<Class2> are only accessible via C<marshall> and
C<demarshall>.  Unless C<Class2> is a sub-class of C<Class1> in which case
all 4 events are available.

POE::Session::Multiplex does the same thing with C<object_states>. 
L<UNIVERSAL::isa|UNIVERSAL/isa> is used to verify that 2 objects are
of the same class.



=head2 _start and _stop vs _psm_begin and _psm_end

The C<_start> event is invoked directly by POE.  This means that no object
will be associated with the event and that the helper functions will not
work.  However, when an object is registered, its L</_psm_begin> handler is
called and when it is unregistered, its L</_psm_end> handler is called.  The
_start handler then becomes a place to register an alias, create and
register one or more objects.  Furthur initialisation can happen in
L</_psm_begin>.

    sub _start {
        my( $package, $session, @args ) = @_[OBJECT,SESSION,ARG0..$#_];
        $poe_kernel->alias_set( 'multiplex' );
        $session->object( main => $package->new( @args ) );
    }

    sub _psm_begin {
        my( $self, @args ) = @_[OBJECT,ARG0..$#_];
        $poe_kernel->sig( CHLD => ev"sig_CHLD" );
        $poe_kernel->sig( INT  => ev"sig_INT" );
        # ....
    }



=head2 Examples

When creating a socket factory, we use L</ev> to create an event name
addressed to the current object:

    package Example;
    use strict;
    use warnings;
    use POE;
    use POE::Session::Multiplex;
    use POE::Wheel::SocketFactory;
    
    sub spawn {
        my( $package, $params ) = @_;
        POE::Session::Multiplex->create(
                args => [ $params ],
                package_states => [
                    $package => [ qw( _start _psm_begin connected error ) ]
                ] );
    }

    sub _start {
        my( $package, $session, $params ) = @_[OBJECT,SESSION,ARG0];
        # We can't call call open_connection(), because ev() won't
        # have a current object.
        # So we create an object
        my $obj = $package->new( $params );
        # And register it.
        $session->object( listener => $obj );
        # This will cause _psm_begin to be invoked
    }

    sub new {
        my( $package, $params ) = @_;
        return bless { params=>$params }, $package;
    }

    # we now have a 'current' object, so open_connection() may call ev() without
    # worries
    sub _psm_begin {
        my( $self ) = @_;
        $self->open_connection( $self->{params} );
    }

    sub open_connection {
        my( $self, $params ) = @_[OBJECT, ARG0];
        $self->{wheel} = POE::Wheel::SocketFactory->new(
                            %$params,
                            SuccessEvent => ev "connected",
                            FailureEvent => ev "error"
                        );
    }

When sending a request to another session, we use L</rsvp> to create
an event that is addressed tot he current object and session:

    $poe_kernel->post( $session, 'sum', 
                        [ 1, 2, 3, 4 ], rsvp "reply" 
                     );

C<$session>'s sum event handler would then be:

    sub sum_handler {
        my( $array, $reply ) = @_[ ARG0, ARG1 ];
        my $tot = 0;
        foreach ( @$array ) { $tot += $_ }
        $_[KERNEL]->post( @$reply, $tot );
    }

This could also have been implemented as:

    $poe_kernel->post( $session, 'sum', 
                        [ 1, 2, 3, 4 ], ev "reply" 
                     );

    sub sum_handler {
        my( $array, $reply ) = @_[ ARG0, ARG1 ];
        # ...
        $_[KERNEL]->post( $_[SENDER], $reply, $tot );
    }



=head2 Limits

It is impossible to multiplex events that are sent from the POE kernel.
Specifically, C<_start>, C<_stop>, C<_child> and C<_parent> can not be
multiplexed.  Use L</_being> and L</_psm_end> or C<_start> and C<_stop>.  For
C<_child> and C<_parent>, use a call to the right object:

    sub _child {
        my( $self, $session, @args ) = @_[OBJECT,SESSION,ARG0..$#_];
        my $call = evo $self->{name}, "poe_child";
        $poe_kernel->call( $session, $call, @args );
    }

    sub poe_child {
        my( $self, $reason, $child, $retval ) = @_[OBJECT,ARG0,ARG1,ARG2];
        # Do the work ...
    }

=head2 Object Names

POE::Session::Multiplex requires each object to have a name.  If you
do not supply one when registering an object, the method
C<__name> is called to fetch the name.  This is a crude form of
meta-object protocol.  If your object does not implement the
C<__name> method, a name is generated from the stringised object
reference.

=head2 Note

I<This documentation tries to consistently use the proper term
'event' to refer to POE's confusingly named 'state'.>

=head2 Event Names

Currently POE::Session::Multiplex uses event names of the form
C<< NAME->EVENT >> to address I<C<EVENT>> to the object named 
I<C<NAME>>.  B<BUT YOU MUST NOT DEPEND ON THIS BEHAVIOUR>.  It could
very well change to C<< EVENT@NAME >> or anything else in the future. 
Please use the event helper functions provided.


=head1 EVENTS

POE::Session::Multiplex provides 2 object management events: C<_psm_begin>
and C<_psm_end>.  They are invoked synchronously whenever an object is
registered or unregistered.

=head2 _psm_begin

C<_psm_begin> is invoked when an object is registered.  This is roughly
equivalent to POE's C<_start>.  Helper functions like L</ev> will have a
default object to work with.

=head2 _psm_end

C<_psm_end> is invoked when an object is registered.  This is roughly
equivalent to POE's C<_stop>.  However, there is no guarantee that
C<_psm_end> will be called; if a session is destroyed before an object is
unregistering C<_psm_end> won't be called.  If C<_psm_end> is necessary, 
you must explicitly unregister the object:

    sub _stop {
        my $session = $_[SESSION];
        foreach my $name ( $session->object_list ) {
            $session->object_unregister( $name );
        }
    }

=head1 METHODS

=head2 create

    POE::Session::Multiplex->create( @lots_of_stuff );

Creates a new multiplexed L<POE::Session>.  No new parameters are defined by
POE::Session::Multiplex.  Parameters of interest to this module are
C<package_states> and C<object_states>; they define event -> object method
mappings that are also used by L<POE::Session::Multiplex>.  Objects
referenced in C<ojbect_states> are currently not multiplexed.

=head2 object_register

    $_[SESSION]->object_register( $object );
    $_[SESSION]->object_register( name => $name,
                                  object => $object,
                                  events => $events
                                );

Register a new C<$object> named C<$name> with the session. 
Optionally creating POE states in C<$events>.  

=over 4

=item object

The object to be registered with the session.  Required.

=item name

The name of the object being registered.  If omitted,
L</object_register> will attempt to get an object name via a
C<__name> method call.  If this method isn't available, a stringised
object reference is used.

If an object with the same name has already registered, that object is
unregistered.

=item events

Optional hashref or arrayref of POE events to create.  If it is a
hashref, keys are POE event names, values are the names of event
handler methods.

    events => { load => 'load_handler', save => 'save_handler }

If you create POE events with an object, they are available to other
objects of the same class.  However, they will be removed when this
object is unregistered.  If you do not want this, use
L</package_register>.

=back

If defined, the L</_psm_begin> event handler is invoked when an object is
registered.


=head2 object_get

    my $obj = $_[SESSION]->object_get( $name );

Returns the object named C<$name>.

=head2 object_list

    my @list = $_[SESSION]->object_list;

Returns a list of names of all the currently registered objects.


=head2 object_unregister

    $_[SESSION]->object_unregister( $name );
    $_[SESSION]->object_unregister( $self );

Unregisters an object.  This makes the object unavailable for events. 
Any POE events created when the object was registered are removed.

If defined, the L</_psm_end> event handler is invoked.

=head2 object

    # Register an object
    $_[SESSION]->object( $name => $self[, $events] );
    $_[SESSION]->object( $self, $events );

    # Unregister an object
    $_[SESSION]->object( $name );
    $_[SESSION]->object( $self );

Syntactic sugar for L</object_register> or L</object_unregister>.



=head2 package_register

    $_[SESSION]->package_register( $package, $events );

Creates the POE events defined in C<$events> as package methods of
C<$package>.  This also makes the events available to all objects of
class C<$package>.

It is not currently possible to unregister a package.





=head1 HELPER FUNCTIONS

POE::Session::Multiplex exports a few helper functions for
manipulating the event names.

=head2 ev

    $event = ev "handler";
    $poe_kernel->yield( ev"handler" );

Returns an event name that is addressed to a I<handler> of the
current object.  Obviously may only be called from within a
multiplexed event.

=head2 evo

    $state = evo( $name, "handler" );
    $poe_kernel->yield( ev"handler" );

Returns an event name addressed to a I<handler> of the I<$name>ed
object.  Used when you want to address a specific object.

=head2 evs

    $poe_kernel->post( evs "handler", @args );

Returns session/event tuple addressed to I<handler> of the current
object.  Obviously may only be called from within a multiplexed
event.

=head2 evos

    $poe_kernel->post( evos( $session, $name, "handler" ), @args );

Returns session/event tuple addressed to a I<handler> of the
I<$name>ed object in I<$session>.  Currently syntatic sugar for:

    $poe_kernel->post( $session, evo( $name, "handler" ), @args );

=head2 rsvp

    my $rsvp = rsvp "handler";

Returns an opaque object that may be used to post an event addressed
to a I<handler> of the current object. Obviously may only be called
from within a multiplexed event.

C<rsvp> is used by objects to create postbacks.  You may pass the rsvp
to other objects or sessions.  They reply with:

    $poe_kernel->post( @$rsvp, @answer );

FYI, I<rsvp> is from the French I<Repondez, s'il vous plais>.  That is,
I<Answer, please> in English.





=head1 POE::Session::PlainCall

It is unfortunately impossible to have clean multiple inheritance of
L<POE::Session>.  However, POE::Session::Multiplex is compatible with
L<POE::Session::PlainCall>.  It does this by checking its inheritance
and implementing a few of L<POE::Session::PlainCall>'s methods.

If you wish to use both, create a session class as follows:

    package My::Session;
    use base qw( POE::Session::Multiplex POE::Session::PlainCall );

Then use that class to create your sessions:

    My::Session->create( 
                package_states => [],
                args           => \@args
            );


=head1 SEE ALSO

L<POE> and L<POE::Session> for details of POE.

L<Reflex> for the final solution.




=head1 AUTHOR

Philip Gwyn, E<lt>gwyn-at-cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009,2010,2011 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
