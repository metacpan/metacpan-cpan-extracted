package POE::Session::PlainCall;

use strict;
use warnings;

use Carp;
use POE;
use Scalar::Util qw( blessed );

require Exporter;

our $VERSION = '0.0301';


#######################################
our $POE_HOLDER;
$POE_HOLDER = bless [], 'POE::Session::PlainCall::Holder';

sub poe () { $POE_HOLDER }

#######################################
use base qw( Exporter POE::Session );

our %EXPORT_TAGS = ( 'all' => [ qw( $poe_kernel poe ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( $poe_kernel poe );

#######################################
BEGIN {
    *SE_NAMESPACE = \&POE::Session::SE_NAMESPACE;
    *SE_OPTIONS   = \&POE::Session::SE_OPTIONS;
    *SE_STATES    = \&POE::Session::SE_STATES;
    if( POE::Session->can( 'SE_ID' ) ) {
        # POE 1.300 + 
        *SE_ID       = \&POE::Session::SE_ID;
        eval '
        *SE_RUNNING  = sub () { POE::Session::SE_ID+1 };
        *SE_MYSTATES = sub () { POE::Session::SE_ID+2 };
        ';
    }
    else {
        # POE 1.299- 
        *SE_RUNNING  = sub () { POE::Session::SE_STATES+1 };
        *SE_MYSTATES = sub () { POE::Session::SE_STATES+2 };
    }

    *EN_SIGNAL    = \&POE::Session::EN_SIGNAL;    
    *EN_DEFAULT   = \&POE::Session::EN_DEFAULT;

    *OPT_TRACE    = \&POE::Session::OPT_TRACE;
    *OPT_DEBUG    = \&POE::Session::OPT_DEBUG;
    *OPT_DEFAULT  = \&POE::Session::OPT_DEFAULT;
}

############################################################################
sub _loggable
{
    my( $self ) = @_;
    return $self unless $self->[SE_RUNNING];
    $POE::Kernel::poe_kernel->_data_alias_loggable( $_[0] );
}

our %OURS;
sub instantiate
{
    my $self = shift->SUPER::instantiate( @_ );
    if( $self->[SE_RUNNING] or $self->[SE_MYSTATES] ) {
        die "Definition of POE::Session changed!  $self needs to be modified.\n";
    }
    $self->__init;
    return $self;
}

sub __init
{
    my( $self ) = @_;
    $self->[SE_RUNNING] = 0;
    # warn "keys = ", join ', ', keys %OURS;
    $self->[SE_MYSTATES] = {%OURS};
    $self->SUPER::__init if $self->can( 'SUPER::__init' );
}

#######################################
sub create
{
    my( $package, @params ) = @_;

    if (@params & 1) {
        croak "odd number of events/handlers (missing one or the other?)";
    }
    my %args = @params;

    my $obj = delete $args{object};
    unless( $obj ) {
        my $package = delete $args{package};
        if( $package ) {
            my $args = delete $args{ctor_args};
            $args ||= [];
            $obj = $package->new( @$args );
        }
    }

    if( $obj ) {
        my $events = delete $args{events} || 
                     delete $args{states};
        croak "Parameters 'events' or 'states' are required if you supply 'object' or 'package'"
                unless defined $events;
        $args{object_states} ||= [];
        push @{ $args{object_states} }, $obj, $events;
    }

    local %OURS;
    $package->__process_args( \%args );
    # warn "keys = ", join ', ', keys %OURS;

    my $self = $package->SUPER::create( %args );
    $self->[SE_RUNNING] = 1;
    return $self;
}

#######################################
## Find all state names and mark them as ours
sub __process_args 
{
    my( $package, $args ) = @_;
    foreach my $f ( qw( package_states object_states ) ) {
        next unless $args->{$f};
        my $L = $args->{$f};
        for(my $off = 1; $off <= $#$L ; $off+=2 ) {
            my $states = $args->{$f}[$off];
            if( 'HASH' eq ref $states ) {
                $package->__process_ours( keys %$states );
            }
            elsif( 'ARRAY' eq ref $states ) {
                $package->__process_ours( @$states );
            }
        }
    }
    return unless $args->{inline_states};
    $package->__process_ours( keys %{ $args->{inline_states} } );
}

#######################################
sub __process_ours
{
    my( $package, @list ) = @_;
    # warn "OURS=", join ', ', @list;
    @OURS{ @list } = (1) x (0+@list);
}

#######################################
sub _invoke_state
{
    my( $self, $source_session, $state, $etc, $file, $line, $fromstate ) = @_;

    unless( $self->[SE_MYSTATES]{$state} or $self->[SE_MYSTATES]{+EN_DEFAULT} ) {
        if ($self->[SE_OPTIONS]->{+OPT_TRACE}) {
            POE::Kernel::_warn( $self->_loggable, 
                                " -> $state (external event)\n"  
                          );
        }
        ## Skip out if it's not our state
        return shift->SUPER::_invoke_state( @_ );
    }

    # Most of the following was lifted AS IS from POE::Session::_invoke_state
    # and simply reformated because I'm a tad anal.
    # But then, POE::Session overloading is like that...
    
    # Trace the state invocation if tracing is enabled.

    if ($self->[SE_OPTIONS]->{+OPT_TRACE}) {
        POE::Kernel::_warn( $self->_loggable, 
                            " -> $state (from $file at $line)\n"
                          );
    }

    # The desired destination state doesn't exist in this session.
    # Attempt to redirect the state transition to _default.

    unless (exists $self->[SE_STATES]->{$state}) {

        # There's no _default either; redirection's not happening today.
        # Drop the state transition event on the floor, and optionally
        # make some noise about it.

        unless (exists $self->[SE_STATES]->{+EN_DEFAULT}) {
            $! = exists &Errno::ENOSYS ? &Errno::ENOSYS : &Errno::EIO;
            if ($self->[SE_OPTIONS]->{+OPT_DEFAULT} and $state ne EN_SIGNAL) {
                my $loggable_self = $self->_loggable;
                POE::Kernel::_warn(
                  "a '$state' event was sent from $file at $line to $loggable_self ",
                  "but $loggable_self has neither a handler for it ",
                  "nor one for _default\n"
                );
            }
            return undef;
        }

        # If we get this far, then there's a _default state to redirect
        # the transition to.  Trace the redirection.

        if ($self->[SE_OPTIONS]->{+OPT_TRACE}) {
            POE::Kernel::_warn( $self->_loggable, 
                                  " -> $state redirected to _default\n"
                              );
        }

        # Transmogrify the original state transition into a corresponding
        # _default invocation.  ARG1 is copied from $etc so it can't be
        # altered from a distance.

        $etc   = [ $state, [@$etc] ];
        $state = EN_DEFAULT;
    }

    #####
    ## The following is unique/specific to POE::Session::PlainCall

    # If we get this far, then the state can be invoked.  So invoke it
    # already!

    # Inline states are invoked this way.

    my $handler = $self->[SE_STATES]->{$state};
    if( ref $handler eq 'CODE') {
        local $POE_HOLDER = bless [
              ( undef,                          # object
                $self,                          # session
                $POE::Kernel::poe_kernel,       # kernel
                $self->[SE_NAMESPACE],          # heap
                $state,                         # state
                $source_session,                # sender
                undef,                          # unused #6
                $file,                          # caller file name
                $line,                          # caller file line
                $fromstate,                     # caller state
                undef,                          # method
                $etc                            # args
              ) ], 'POE::Session::PlainCall::Holder';
        return $handler->( @$etc );
    }

    # Package and object states are invoked this way.
    my ($object, $method) = @{$handler};
    local $POE_HOLDER  = bless [
      ( $object,                        # object
        $self,                          # session
        $POE::Kernel::poe_kernel,       # kernel
        $self->[SE_NAMESPACE],          # heap
        $state,                         # state
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

#######################################
sub _register_state
{
    my( $self, $name, @definition ) = @_;
    if( $self->[SE_MYSTATES]{$name} ) {
        return $self->state( $name, @definition );
    }
    else {
        # states created via POE::Kernel->state
        if( @definition ) {
            if ($self->[SE_OPTIONS]->{+OPT_TRACE}) {
                POE::Kernel::_warn( $self->_loggable, " -> $name is external\n" );
            }
        } 
        else {
            # just in case something strange happened
            delete $self->[SE_MYSTATES]{$name};
        }
        $self->SUPER::_register_state( $name, @definition );
    }
}

#######################################
sub state
{
    my( $self, $name, @definition ) = @_;
    if( ! $self->[SE_MYSTATES]{$name} and 
            $self->[SE_STATES]{$name} ) {
        croak "You may not redefine an event handler defined by a wheel or other external module.";
    }

    if( @definition ) {
        if ($self->[SE_OPTIONS]->{+OPT_TRACE}) {
            POE::Kernel::_warn( $self->_loggable, " -> $name is ours\n" );
        }
        $self->[SE_MYSTATES]{$name} = 1;
    } 
    else {
        delete $self->[SE_MYSTATES]{$name};
    }
    $self->SUPER::_register_state( $name, @definition );
}

############################################################################
package POE::Session::PlainCall::Holder;

use strict;
use warnings;

# use POE::Session;
use Scalar::Util qw( blessed );

sub METHOD  { POE::Session::ARG0 }
sub ETC     { POE::Session::ARG1 }

sub object  { $_[0]->[POE::Session::OBJECT] }
sub package { my $r=$_[0]->[POE::Session::OBJECT]; blessed $r ? ref $r : $r }
sub session { $_[0]->[POE::Session::SESSION] }
sub kernel  { $POE::Kernel::poe_kernel }
sub heap    { $_[0]->[POE::Session::HEAP] }
sub state   { $_[0]->[POE::Session::STATE] }
sub event   { $_[0]->[POE::Session::STATE] }
sub method  { $_[0]->[METHOD] }
sub sender  { $_[0]->[POE::Session::SENDER]->ID }
sub SENDER () { $_[0]->[POE::Session::SENDER] }
sub caller_file  { $_[0]->[POE::Session::CALLER_FILE] }
sub caller_line  { $_[0]->[POE::Session::CALLER_LINE] }
sub caller_state { $_[0]->[POE::Session::CALLER_STATE] }
sub args { 
    my $etc = $_[0]->[ETC];
    return wantarray ? @$etc : [ @$etc ]
}


# These would mess up ->caller_file and ->caller_line :-/
# sub post  { shift->[KERNEL]->post( @_ ) }
# sub call  { shift->[KERNEL]->call( @_ ) }
# sub yield  { shift->[KERNEL]->yield( @_ ) }


1;
__END__

=head1 NAME

POE::Session::PlainCall - POE sessions with plain perl calls

=head1 SYNOPSIS

    Something->spawn( @args );

    POE::Kernel->run();

    package Something;
    use POE::Session::PlainCall;

    sub new {
        # Normal object constructor
    }

    sub spawn {
        my( $package, @args ) = @_;
        POE::Session::PlainCall->create(
                        package   => $package,
                        ctor_args => \@args,
                        states    => [ qw( _start load load_done ) ]
                    );
    }

    sub _start {
        my( $self ) = @_;
        poe->kernel->alias_set( $self->{alias} );
    }

    sub load {
        my( $self, $uri, $reply ) = @_;
        $self->{todo}{$uri} = [ poe->sender, $reply ];
        # Start doing some processing on $uri
    }

    sub load_done {
        my( $self, $uri ) = @_;
        # The processing of URI is complete
        my $reply = delete $self->{todo}{$uri};
        poe->kernel->post( @$reply, $req->reply );
    }

=head1 DESCRIPTION

POE::Session::PlainCall provides standard perl object-oriented call signature
to your L<POE> event handlers.  This allows for your methods and functions
to be called either via POE events or as normal methods and functions.  It
also requires less typing then the POE argument constants.

Where a normal POE object method event handler would fetch it's arguments
with:

    my( $self, $something, $backto ) = @_[ OBJECT, ARG0, ARG1 ];

POE::Session::PlainCall event handlers do it the normal way:

    my( $self, $something, $backto ) = @_;

Method overloading becomes much less fraught:

    # POE::Session
    shift->SUPER::method( @_ ); # wait, what if shift was already called?
    # POE::Session::PlainCall
    $self->SUPER::method( @_ );

The other elements of C<@_> (C<SENDER>, C<HEAP>, C<CALLER_STATE>, etc)
are available through a small object called L</poe>.

    my $kernel = poe->kernel;       # $_[KERNEL] / $poe_kernel
    my $heap = poe->heap;           # $_[HEAP]
    my $from = poe->caller_state;   # $_[CALLER_STATE]
    # and so on

The one difference is that L</sender> is in fact the sender session's ID. 
This is to help prevent you from keeping a reference to a L<POE::Session>
object.

    my $sender = poe->sender;       # $_[SENDER]->ID
    my $sender_ses = poe->kernel->ID_id_to_session( $sender );

However, if you really have a legitimate reason to want the session object, 
you may use L</SENDER>.

    my $sender_ses = poe->SENDER;   # $_[SENDER]

But please remember to B<never> keep a reference to a L<POE::Session> object.

=head2 Package Methods

POE::Session::PlainCall also allows you to use package methods as event handlers:

    POE::Session::PlainCall->create(
                package_states => {
                        'Some::Package' => {
                                event => 'handler'
                            }
                    }
                # ...
            );

The package methods will be called as you would expect them to be:

    sub handler {
        my( $package, @args ) = @_;
        my $event = poe->state;         # $_[STATE]
        # $event would be 'event'
    }

=head2 Functions

But that's not all!  Even though this package is called POE::Session::PlainCall,
you can also use plain functions and coderefs as event handlers:

    POE::Session::PlainCall->create(
                inline_states => {
                        _start  => sub { poe->kernel->yield( 'work', @args ) },

                        work    => \&work,
                    }
                # ...
            );

The event handlers as you would expect them to be:

    sub work {
        my( @args ) = @_;
        my $event = poe->state;         # $_[STATE]
        # $event would be 'work'
    }

=head2 Wheels and other external event handlers

Wheels and other external modules can add or remove event handlers with
C<POE::Kernel/state>.  These event handlers expect to be called with C<@_>
as POE::Kernel would supply it.  POE::Session::PlainCall has to know if a given
event handler is I<internal> (our call signature) or I<external> (POE call
signature).  Internal event handlers are defined via L</create> or
L</state>.  External event handlers can be defined via L<POE::Kernel/state>,
which is what wheels and other components will already do.


=head2 Nomenclature: state vs event

For historical reasons POE refers to event handlers as I<state handlers>. 
This nomenclature, while incorrect from a computer science standpoint, is
preserved in C<POE::Session::PlainCall>'s API.  However, the present
documentation uses the more correct I<event handlers>.


=head1 METHODS

=head2 create

C<create()> starts a new session running.  
It returns a new L<POE::Session> object upon success.  All the regular
L<POE::Session/create> named parameters are available.

You may also use:

=over 4

=item object

    object => $obj

Object reference that the event handlers will be invoked on.

=item package

    package => 'Some::Package'

If you do not supply an object POE::Session::PlainCall will construct one by
calling C<new> on this package, with L</ctor_args> as arguments.

=item ctor_args

    ctor_args => ARRAYREF

Arguments that are passed to L</package>->new.  If absent, an empty
list is used.


=item states

    states => ARRAYREF
    states => HASHREF

C<states> defines a list of methods to be called on your L</object> when
a given event happens.

In other words:

    POE::Session::PlainCall->create(
                    object => $object,
                    states => [ qw( one two ) ]
                );

Is the same as:

    POE::Session::PlainCall->create(
                    object_states => [ 
                            $object => [ qw( one two ) ] 
                    ]
                );

=item events

    events => ARRAYREF
    events => HASHREF

Syntactic sugar for L</states>

=back

=head2 state

    poe->session->state( $event => $object => $method );
    poe->session->state( $event );

To allow POE::Session::PlainCall to play nicely with other modules,
specifically C<POE::Wheel>s, POE::Session::PlainCall must track which event
handlers need the new call signature and which need the POE call signature.

New event handlers defined with C<POE::Kernel/state> will be invoked with the POE
call signature.  New event handlers defined with C</state> will be invoked
with the new call signature.

    poe->session->state( 'something', $self );
    # $self->something() is invoked like a normal method
    sub something {
        my( $self, @args ) = @_;
        # ...
    }


    POE::Kernel->state( 'other', $self );
    # $self->other() is inovked like a POE event handler
    sub other {
        my( $self, @args ) = @_[ OBJECT, ARG0 .. $#_ ];
        # ...
    }

=head1 EXPORT

POE::Session::PlainCall exports one function and one variable.

=head2 $poe_kernel

Courtesy export of $POE::Kernel::poe_kernel.

=head2 poe

The C<poe> function returns an object that you use to find additional
information about an event method invocation:

=over 4

=item object

The current object,  Equivalent to $_[OBJECT].  C<undef> for C<inline_states>.

=item package

Package of the current object or simply the package for C<package_states> event
handlers.  C<undef> for C<inline_states>.

=item session

The current session.  Equivalent to $_[OBJECT].

    poe->session->state( $new_state => 'does_state' );

=item kernel

The POE kernel.  Equivalent to C<$_[KERNEL]> or C<$poe_kernel>.

=item heap

The session heap.  Equivalent to C<$_[HEAP]>.

=item state

The name of the currently running event.  Equivalent to C<$_[STATE]>.

=item event

Syntactic sugar for L</state>.

=item method

Name of the current method being invoked as an event handler.  If you
specify a hashref to L</events> you can map an event handler to a method
that doesn't carry the same name as event.  If you specify an arrayref, then
L</method> returns the same thing as L</state>.

No equivalent in POE, but this information is available through
L<perlfunc/caller>.

=item sender

The ID of the session that sent the current event.  Equivalent to
C<$_[SENDER]-E<gt>ID>.

=item SENDER

The session object that sent the current event.  Equivalent to
C<$_[SENDER]>.

=item caller_file

Name of the source code file where an event was posted from.  Equivalent to
C<$_[CALLER_FILE]>.

=item caller_line

Line within the source code file where an event was posted from.  Equivalent to
C<$_[CALLER_LINE]>.

=item caller_state

Name of the event that the current event was posted from.  Equivalent to
C<$_[CALLER_STATE]>.


=back

=head1 SEE ALSO

L<POE::Session>, 
L<POE>.

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn-at-cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2011 by Philip Gwyn

Contains code from L<POE::Session>.  
Please see L<POE> for more information about authors and contributors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
