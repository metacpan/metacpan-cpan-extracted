use strict;
use warnings;
package POE::Component::Supervisor::Handle::Session;

our $VERSION = '0.09';

use MooseX::POE 0.210;

with qw(
    POE::Component::Supervisor::Handle
    POE::Component::Supervisor::LogDispatch
);

use POE::API::Peek 2.13;
#use MooseX::Types::Set::Object;
use Set::Object ();
use namespace::autoclean;

has implicit_tracking => (
    isa => "Bool",
    is  => "ro",
    default => 0,
);

has start_callback => (
    isa => "CodeRef|Str",
    is  => "ro",
    required => 1,
);

has error => (
    is  => "rw",
    writer => "_error",
    predicate => "has_error",
);

has _sessions => (
    #isa => "Set::Object",
    is  => "rw",
    init_arg => undef,
    default => sub { Set::Object->new },
);

has _dead_sessions => (
    #isa => "Set::Object",
    is  => "rw",
    init_arg => undef,
    default => sub { Set::Object->new },
);

has _started => (
    isa => "Bool",
    is  => "rw",
);

sub START {
    my ( $self, $kernel ) = @_[OBJECT, KERNEL];

    # traps child death under POE 0.9999_01 and up
    $kernel->sig( DIE => "exception" );

    my $cb = $self->start_callback;

    $self->logger->debug("calling start callback $cb, implicit child session tracking is " . ( $self->implicit_tracking ? "on" : "off" ));

    my ( @ret, $e );

    {
        local $@;

        @ret = eval { $self->$cb() };
        $e = $@;
    };

    if ( $e ) {
        $self->logger->error("error in start callback: $@");

        # in case there is implicit tracking, don't leak session refs
        $self->_sessions->clear;

        die $e;
    }

    if ( $self->implicit_tracking ) {
        $self->logger->log_and_die( level => "error", message => "No sessions created in callback" ) unless $self->_sessions->size;
    } else {
        foreach my $session ( @ret ) {
            unless ( blessed($session) and $session->isa("POE::Session") ) {
                $self->logger->log_and_die( level => "error", message => "return value from start_callback is not a POE session: " . ( defined($session) ? $session : "undef" ) );
            }
        }

        $self->_sessions->insert(@ret);
    }

    $self->notify_spawn( sessions => [ $self->_sessions->members ] );
}

event exception => sub {
    my ( $self, $kernel, $error_info ) = @_[OBJECT, KERNEL, ARG1];

    # currently we don't keep the full $error_info because I'm worried about leaks (it refs sessions)

    my $error = $error_info->{error_str}; # could be a ref too
    my $session = $error_info->{dest_session};

    $self->logger->debug("tracked sessions: @{ $self->_sessions }");

    my $sessions = $self->_sessions;
    my $tracked_session = $session;

    my $peek = POE::API::Peek->new;
    until ( $sessions->includes($tracked_session) ) {
        $tracked_session = $peek->get_session_parent($tracked_session); # FIXME violates POE::Kernel's encapsulation
    }

    {
        no warnings 'uninitialized';
        $self->logger->warning( join " ",
            $session,
            ( $session == $tracked_session ? () : "(untracked)" ),
            "generated an error: $error"
        );
    }

    if ( $tracked_session ) {
        # sig_handled does not keep the child alive, but prevents the kernel from closing
        $kernel->sig_handled;
        $self->_error($error);

        $self->yield("stop_tracked_sessions");
    }
};

sub CHILD {
    my ( $self, $action, $child_session ) = @_[OBJECT, ARG0, ARG1];

    $self->logger->debug("child event $action for $child_session");

    my $method = "_child_$action";

    if ( my $coderef = $self->can($method) ) {
        goto &$coderef; # maybe OBJECT != 0, so shift->$method(@_) could break
    } else {
        return;
    }
}

sub _child_create {
    my ( $self, $session ) = @_[OBJECT, ARG1, ARG2];

    $self->logger->debug("new child session for $self: $session");

    if ( $self->implicit_tracking ) {
        $self->logger->info("implicitly tracking $session");
        $self->_sessions->insert($session);
    }
}

sub _child_lose {
    my ( $self, $session ) = @_[OBJECT, ARG1, ARG2];

    $self->_dead_sessions->insert($session);

    $self->logger->debug("child session of $self stopped: $session");

    if ( not $self->is_running ) {
        $self->logger->info("all tracked sessions of $self have stopped. Actually spawned " . $self->spawned);

        if ( $self->spawned ) { # only notify if we also notified start
            $self->notify_stop( $self->has_error ? ( error => $self->error ) : () );
        }
    }
}

sub _child_gain {
    # does this ever actually happen?
}

sub stop {
    my $self = shift;

    $self->logger->debug("stopping $self");

    $self->yield("stop_tracked_sessions");
}

event stop_tracked_sessions => sub {
    my ( $self, $kernel ) = @_[OBJECT, KERNEL];

    if ( my @roots = $self->_sessions->difference( $self->_dead_sessions )->members ) {
        $self->logger->debug("$self killing tracked sessions @roots");
        $kernel->signal( $_ => "KILL" ) for @roots;
    }
};

sub is_running {
    my $self = shift;

    # does this impl suffer from race conditions?

    return not $self->_dead_sessions->superset( $self->_sessions );

    # more cumbersome, but potentially more reliable

    #foreach my $session ( $self->_sessions->members ) {
    #    return unless defined POE::API::Peek->new->resolve_session_to_id($session);
    #}
    #return 1;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

POE::Component::Supervisor::Handle::Session - Helps
L<POE::Component::Supervisor> babysit POE sessions.

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    # used by L<POE::Component::Supervisor::Supervised::Session>

=head1 DESCRIPTION

This supervision handle will watch L<POE::Session>s

=head1 ATTRIBUTES

These attributes apply to the
L<POE::Component::Supervisor::Supervised::Session> constructor.

=over 4

=item start_callback

The body of code to run in order to (re)spawn the session(s).

If C<implicit_tracking> is off (the default) the sessions to be tracked must be
returned from this method.

=item implicit_tracking

When true, all created child sessions will be implicitly tracked.

This means that you can generally just create POE components or sessions in the
start callback.

Otherwise the sessions to be tracked must be returned from the C<start_callback>.

Defaults to false.

=back

=head1 METHODS

=over 4

=item new

Never called directly, only called by L<POE::Component::Supervisor::Supervised::Session>.

=item stop

Stop the supervised sessions.

=item is_running

=back

=cut
