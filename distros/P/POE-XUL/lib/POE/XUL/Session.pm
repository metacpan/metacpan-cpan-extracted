package                     # Hide from the CPAN indexer
    POE::XUL::Session;
# $Id$
# Copyright Philip Gwyn 2007-2010.  All rights reserved.

use strict;
use warnings;
use Carp;

our $VERSION = '0.0601';

use POE;
use base qw(POE::Session);

use POE::XUL::Logging;

use POSIX qw( ENOSYS );
use Carp;

use constant DEBUG => 0;

################################################################
my %SELVES;
sub create
{
    my( $package, $application ) = @_;

    return $package->SUPER::create( 
                        inline_states => {
                            _start => \&_never,
                            _stop  => \&_never,
                        },
                        args => [ $application ] 
                );
}

sub _never { confess "Never invoke me" }


sub _get_self
{
    my( $session ) = @_;
    return $session unless $session->isa( 'POE::Session' );
    return $SELVES{ $session->ID };
}

################################################################
sub _invoke_state {
    my( $session, $source_session, $state, $etc, $file, $line, 
                  $source_state ) = @_;

    if( $state eq '_stop' ) {
        delete $SELVES{ $session->ID };
        DEBUG and xwarn "_stop";
        return;
    }
    elsif( $state eq '_start' ) {
        my $self = $SELVES{ $session->ID } = 
                POE::XUL::Session::Delegate->new( $session, $etc->[0] );
        return $self->_start();
    }

    my $self = $session->_get_self;

    DEBUG and xwarn "Invoking $state\n";


    if ($session->[POE::Session::SE_OPTIONS]->{+POE::Session::OPT_TRACE}) {
        xwarn( $POE::Kernel::poe_kernel->ID_session_to_id($session),
              " -> $state (from $file at $line)\n"
            );
    }

    my $handler = $session->[POE::Session::SE_STATES]->{$state};

    # The desired destination state doesn't exist in this session.
    # Attempt to redirect the state transition to _default. 
    unless ( $handler ) {
        $handler = $session->[POE::Session::SE_STATES]->{+POE::Session::EN_DEFAULT};
        unless( $handler ) {
            $! = ENOSYS;
            if ($session->[POE::Session::SE_OPTIONS]->{+POE::Session::OPT_DEFAULT}) {
                xwarn( "a '$state' state was sent from $file at $line to session ",
                    $POE::Kernel::poe_kernel->ID_session_to_id($session),
                      ", but session ",
                    $POE::Kernel::poe_kernel->ID_session_to_id($session),
                      " has neither that state nor a _default state to handle it\n"
                );
            }
            DEBUG and xwarn "No handler for $state";
            return undef;        
        }
    }

    local $POE::XUL::Application::window = $self->{main_window};
    local $POE::XUL::Application::server = $self;
    local $POE::XUL::Node::CM            = $self->{CM};
    local $self->{source_session}        = $source_session;
    local $self->{source_state}          = $source_state;
    local $self->{source_file}           = $file;
    local $self->{source_line}           = $line;
    local $self->{current_state}         = $state;

    # warn "P::X::App:window=$POE::XUL::Application::window";
    # warn "M::App::window=".My::Application::window();

    my $wa = wantarray;
    # DEBUG and xwarn "${state}'s handler is $handler, wantarray=", (defined $wa ? $wa : '' );

    my( $OK, @ret );
    if( $wa ) {
        eval {
            if( 'CODE' eq ref $handler ) {
                @ret = $handler->( @$etc );
            }
            else {
                my( $object, $method ) = @$handler;
                @ret = $object->$method( @$etc );
            }
            $OK = 1;
        };
    }
    else {
        my $ret;
        eval {
            if( 'CODE' eq ref $handler ) {
                $ret[0] = $handler->( @$etc );
            }
            else {
                my( $object, $method ) = @$handler;
                $ret[0] = $object->$method( @$etc );
            }
            $OK = 1;
        };
    }

    if( $OK ) {
        return @ret if wantarray;
        return $ret[0];
    }

    $self->event_error( "PERL ERROR: $@" );
}

#############################################################################
package POE::XUL::Session::Delegate;

use strict;
use warnings;

use POE::Kernel;
use POE::XUL::Logging;

use constant DEBUG => 0;
use Carp;
use Devel::Peek;
use Data::Dumper;

################################################################
sub new
{
    my( $package, $session, $application ) = @_;
    return bless {
                session     => $session->ID, 
                application => $application
            }, $package;
}

################################################################
sub _start
{
    my( $self ) = @_;
    DEBUG and xwarn "$$: _start ", $self->SID;
    $poe_kernel->alias_set( $self->SID );
    $poe_kernel->alias_set( $self );
    $poe_kernel->state( boot => $self );
    $poe_kernel->state( timeout => $self );
    $poe_kernel->state( shutdown => $self );
    $poe_kernel->state( connect => $self );
    $poe_kernel->state( disconnect => $self );
    return;
}

################################################################
sub ID
{
    my( $self ) = @_;
    return $self->{session};
}

sub SID
{
    my( $self ) = @_;
    return $self->{application}->SID;
}

sub session
{
    my( $self ) = @_;
    return unless $self->{session};
    return $poe_kernel->ID_id_to_session( $self->{session} );
}

sub sender_file { $_[0]->{source_file} }
sub sender_line { $_[0]->{source_line} }
sub sender_state { $_[0]->{source_state} }
sub sender_session { $_[0]->{source_session} }
sub current_state { $_[0]->{current_state} }

################################################################
# Initial boot request
sub boot
{
    my( $self, $event ) = @_;
    $self->{name} = $event->app;
    $self->{CM} = $event->CM;
    use Data::Dumper;
    $self->{name} or die Dumper $event;

    # we didn't have a CM until now, so _invoke_state didn't set it
    local $POE::XUL::Node::CM = $self->{CM};

    xlog "Boot $self->{name}";

    $self->{application}->boot( $event );

    unless( $self->{booted} ) {
        xlog "Application didn't Boot(), using $self->{name}";
        POE::XUL::Node::Boot( $self->{name} );
    }

    croak "You must create a Window during $self->{SID}/boot"
            unless $self->{main_window};
    $event->handled;
    return;
}

################################################################
# POE::XUL::Node::Boot telling us the boot message
sub Boot
{
    my( $self, $msg ) = @_;
    $self->{booted} = 1;
}



################################################################
## window->open creates a temporary window (TWindow)
## It, in turn, tells us so
sub attach_subwindow
{
    my( $self, $twindow ) = @_;

    # save the twindow until we get the 'connect' event
    $self->{subwindows}{ $twindow->id } = $twindow;
    return;
}


################################################################
## New sub-window connect request
sub connect
{
    my( $self, $event ) = @_;
    my $winID = $event->window;
    xlog "Connect $winID";

    my $twindow = delete $self->{subwindows}{ $winID };
    die "Connect $winID, but we don't have that TWindow." unless $twindow;

    $twindow->create_window();
    $twindow->dispose();

    $self->window_call( $event, 'Connect' );

    $event->handled;
    return;
}

################################################################
## Sub-window disconnect request
sub disconnect
{
    my( $self, $event ) = @_;
    my $winID = $event->window->id;
    xlog "Disconnect $winID";

    $self->window_call( $event, 'Disconnect' );

    # delete the window, and all sub-elements
    $event->window->dispose;
    $event->set( window => undef );

    $event->handled;
    return;
}

################################################################
## Call a handler for a sub-window
sub window_call
{
    my( $self, $event, $name ) = @_;
    my $listener = $event->window->event( $name );
    if( $listener ) {
        # it's up to the handler to do ->defer if it needs it
        $event->done( 1 );
        if( ref $listener ) {
            $listener->( $event );
        }
        else {
            DEBUG and xwarn "$name -> $listener";
            # we don't use ->yield because we want the event to go
            # through before we return
            $poe_kernel->call( $self->SID, $listener, $event );
        }
        return;
    }

    $name = lc $name;
    if( $self->{application}->can( $name ) ) {
        DEBUG and xwarn "->$name";
        $self->{application}->$name( $event );
    }

    return;
}


################################################################
## Application shutdown (close or timeout)
sub shutdown
{
    my( $self ) = @_;
    DEBUG and xwarn "Application $self->{name} shutdown";
    if( $self->{application}->can( 'shutdown' ) ) {
        $self->{application}->shutdown();
    }
    $poe_kernel->alias_remove( $self );
    $poe_kernel->alias_remove( $self->SID );
}

################################################################
## Application timeout
sub timeout
{
    my( $self ) = @_;
    DEBUG and xwarn "Application $self->{name} timeout";
    if( $self->{application}->can( 'timeout' ) ) {
        $self->{application}->timeout();
    }
}

################################################################
## Error from _invoke_state
sub event_error
{
    my( $self, $msg ) = @_;
    $self->{CM}->wrapped_error( $msg );
}

################################################################
## Reflection
sub has_handler
{
    my( $self, $state ) = @_;
    $! = 0;
    my $handler = $self->session->[POE::Session::SE_STATES]->{$state};
    return 1 if $handler;

    # The desired destination state doesn't exist in this session.
    # Attempt to redirect the state transition to _default. 
    $handler = $self->session->[POE::Session::SE_STATES]->{+POE::Session::EN_DEFAULT};
    return 1 if $handler;

    # No dice
    $! = POSIX::ENOSYS();
    return;
}

################################################################
## POE::XUL::ChangeManager telling us about a new window
sub register_window
{
    my( $self, $node ) = @_;
    unless( $self->{main_window} ) {
        $self->{main_window} = $node;
        $POE::XUL::Application::window = $node;
    }
    elsif( $self->{CM} and $self->{CM}{current_event} ) {
        $self->{CM}{current_event}->window( $node );
        $self->{CM}{current_event}{window_id} = $node->id;
    }
}

################################################################
## Create a handler if needs be
sub attach_handler
{
    my( $self, $node, $name, $listener ) = @_;

    my $app = $self->{application};

    if( ref $listener ) {
        # CODEREF -> create an event for that coderef
        my $state = join '-', "poe-xul", $name, $node->id;
        $app->createHandler( $state, $listener );
        return $state;
    }
        
    # other -> create an event for that event
    my @check = ( $listener );
    if( $node->id ) {
        my $id = $node->id;
        $id =~ s/\W/_/g;
        push @check, join '_', 'xul', $name, $id;
    }
    push @check, $name;
    DEBUG and xwarn $node->id, ".$name one of ", join ', ', @check;
    foreach my $state ( @check ) {
        next unless defined $state;
        return $state if $self->has_handler( $state );   # already have one?

        next unless $app->can( $state );    # couldn't object handle it?
        
        DEBUG and xwarn "Creating handler for ", $node->id, ".$name event ($state)";
        $app->createHandler( $state );
        return $state;
    }
    if( $listener ) {
        xcarp "Can't handle $name event $listener via package ", ref $app;
    }
    else {
        xcarp "Can't handle event $name via package ", ref $app;
    }
    return;
}


1;

__DATA__

=head1 NAME

POE::XUL::Session - POE::XUL session object

=head1 SYNOPSIS

Normaly a POE::XUL::Session isn't created directly, but is created during
L<POE::XUL::Application>'s spawn.

=head1 DESCRIPTION

POE::XUL::Session provides half of the margic for L<POE::XUL::Application>.
It implements perl-like event invocation.  It makes sure the change manager
and other bits of global data are always available to event handlers.  It
deals with most of the house keeping that POE::XUL applications have to do.

Access an application's session is done through the
L<POE::XUL::Application/server>.

=head1 METHODS

=head2 SID

Returns the unique identifier of the current application.

    $node->label( server->SID );

=head2 ID

Returns the POE::Session identifier.  See L<POE::Session/ID>

=head2 session

Returns the L<POE::Session> object.

=head2 current_state

Returns the name of the current POE event handler.  Equivalent to
C<$_[STATE]> is regular POE code.

=head2 sender_session

Equivalent to C<$_[SENDER]> in regular POE code.

=head2 sender_file

Equivalent to C<$_[CALLER_FILE]> in regular POE code.

=head2 sender_line

Equivalent to C<$_[CALLER_LINE]> in regular POE code.

=head2 sender_state

Equivalent to C<$_[CALLER_STATE]> in regular POE code.


=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Philip Gwyn.  All rights reserved;

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), L<POE::XUL>, L<POE::XUL::Event>, L<POE::XUL::Node>, 
L<POE::XUL::Application>.

L<http://www.prototypejs.org/>.

=cut

