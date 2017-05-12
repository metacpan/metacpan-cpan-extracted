use strict;
use warnings;
package POE::Component::Supervisor; # git description: 0.08-14-g6e2e02b

our $VERSION = '0.09';

use MooseX::POE 0.210;
use Moose::Util::TypeConstraints;
use POE::Component::Supervisor::Supervised;
use POE::Component::Supervisor::Handle;
use Devel::PartialDump;
use Hash::Util::FieldHash::Compat qw(idhash);
use namespace::autoclean;

with qw(
    POE::Component::Supervisor::Interface
    MooseX::POE::Aliased
    POE::Component::Supervisor::LogDispatch
);

sub run {
    my $self = shift->new(@_);
    $poe_kernel->run;
}

# by default when all the children die we exit as well
sub _build_alias { undef }

has restart_policy => (
    isa => enum(__PACKAGE__ . "::RestartPolicy" => [qw(one all rest)]),
    is  => "rw",
    default => "one",
);

has children => (
    isa => "ArrayRef",
    init_arg => undef,
    is  => "ro",
    auto_deref => 1,
    default => sub { [] },
);

has _children_tmp => (
    isa => "ArrayRef",
    is  => "rw",
    init_arg => undef,
    clearer => "_clear_children_tmp",
);

has _last_child_id => (
    isa => "Int",
    is  => "rw",
    default => 0,
);

sub _next_child_id {
    my $self = shift;
    $self->_last_child_id( $self->_last_child_id + 1 );
}

has _children_hash => (
    isa => "HashRef",
    is  => "ro",
    init_arg => undef,
    default  => sub { idhash my %h },
);

sub _child_id {
    my ( $self, $child ) = @_;

    if ( defined ( my $id = $self->_children_hash->{$child}{id} ) ) {
        return $id;
    } else {
        confess "unknown child $child";
    }
}

sub _child_handle {
    my ( $self, $child ) = @_;
    $self->_children_hash->{$child}{handle};
}

# used to track which children are currently being stopped for the purpose of
# restarting, because we first have to stop everything and then we start them again
has _stopping_for_restart => (
    isa => "HashRef",
    is  => "ro",
    init_arg => undef,
    default  => sub { idhash my %h },
);

# when children that are being restarted have stopped they are tracked here
# when the last child is stopped this collection of children will be started based on the order of 'children'
has _pending_restart => (
    isa => "HashRef",
    is  => "ro",
    init_arg => undef,
    default  => sub { idhash my %h },
);

sub START {
    my ( $self, $kernel ) = @_[OBJECT, KERNEL];

    $kernel->sig( DIE => "exception" );

    $self->logger->info("starting supervisor $self in process $$");

    if ( my $children = $self->_children_tmp ) {
        $self->_clear_children_tmp;
        $self->start(@$children);
    }
}

sub STOP {
    my $self = $_[OBJECT];

    $self->logger->info("stopping supervisor $self in process $$");
}

event exception => sub {
    my ( $self, $error_info ) = @_[OBJECT, ARG1];

    $self->logger->error("Error in supervisor child session, event $error_info->{event} of $error_info->{dest_session}: $error_info->{error_str}, sent from $error_info->{source_session} state $error_info->{from_state} at $error_info->{file} line $error_info->{line}");
};

sub _register_child {
    my ( $self, $new_child ) = @_;

    $self->logger->debug("registering child $new_child");

    $self->_children_hash->{$new_child} ||= do {
        push @{ $self->children }, $new_child;
        $self->_new_child_registration($new_child);
    }
}

sub _new_child_registration {
    my ( $self, $new_child ) = @_;
    return { id => $self->_next_child_id };
}

sub _unregister_child {
    my ( $self, $child ) = @_;

    $self->logger->debug("unregistering child $child");

    if ( delete $self->_children_hash->{$child} ) {
        @{ $self->children } = grep { $_ != $child } @{ $self->children };
    }

}

sub BUILD {
    my ( $self, $params ) = @_;

    if ( my $children = $params->{children} ) {
        $self->_children_tmp($children);
    }
}

sub start {
    my ( $self, @children ) = @_;

    foreach my $child ( @children ) {
        next if $self->_children_hash->{$child};
        $self->_register_child($child);
        $self->yield( spawn => $child );
    }
}

sub stop {
    my ( $self, @children ) = @_;

    @children = reverse $self->children unless @children;

    foreach my $child ( @children ) {
        if ( my $entry = $self->_children_hash->{$child} ) {
            if ( my $handle = $entry->{handle} ) {
                $entry->{stopping} = 1;
                $entry->{handle}->stop;

                # remove it from the children list, so that it isn't restarted due to a
                # 'rest' or 'all' policy because of some other childs' exit
                # _unregister_child will eventually try to do this too, but that's OK
                # because it *should* do it if the child has been stopped unexpectedly
                # and is temporary/transient
                @{ $self->children } = grep { $_ != $child } @{ $self->children };
            } else {
                # it's already dead, just delete it
                $self->_unregister_child($child);
            }
        }
    }
}

sub notify_spawned {
    my ( $self, @args ) = @_;
    $self->yield( spawned => @args );
}

sub notify_stopped {
    my ( $self, @args ) = @_;
    $self->yield( stopped => @args );
}

event spawned => sub {
    my ( $self, $kernel, $child, @args ) = @_[OBJECT, KERNEL, ARG0 .. $#_];

    $kernel->refcount_increment( $self->get_session_id(), "handles" );

    $self->logger->info("child " . $self->_child_id($child) . " spawned " . Devel::PartialDump::dump(@args));
};

event spawn => sub {
    my ( $self, $child ) = @_[OBJECT, ARG0 ];

    $self->logger->debug("instructing child " . $self->_child_id($child) . " to spawn");

    $self->_children_hash->{$child}{handle} = $child->spawn( supervisor => $self );
};

event respawn => sub {
    my ( $self, $child ) = @_[OBJECT, ARG0];

    $self->_pending_restart->{$child} = $child;

    if ( scalar keys %{ $self->_stopping_for_restart } ) {
        # if we're waiting on more children to exit, just mark this child as ready to restart
        $self->logger->debug("child " . $self->_child_id($child) . " respawn postponed, other children still not stopped");
    } else {
        # otherwise we can now restart all the children which are ready to be restarted
        $self->logger->debug("no more unstopped children, ready to respawn");
        my @children_to_restart = grep { defined } delete @{ $self->_pending_restart }{ $self->children };

        foreach my $child ( @children_to_restart ) {
            $self->yield( _respawn => $child );
        }
    }
};

event _respawn => sub {
    my ( $self, $child ) = @_[OBJECT, ARG0];

    $self->logger->info("respawning child " . $self->_child_id($child));
    $self->_children_hash->{$child}{handle} = $child->respawn( supervisor => $self );
};

event stopped => sub {
    my ( $self, $kernel, $child, @args ) = @_[OBJECT, KERNEL, ARG0 .. $#_];

    $kernel->refcount_decrement( $self->get_session_id(), "handles" );

    delete $self->_children_hash->{$child}{handle};

    if ( $self->_children_hash->{$child}{stopping} ) {
        $self->call( stopped_per_request => $child, @args );
    } elsif ( my $restarting = delete $self->_stopping_for_restart->{$child} ) {
        $self->call( stopped_for_restart => $child, @args );
    } else {
        $self->call( stopped_unexpectedly => $child, @args );
    }
};

event stopped_per_request => sub {
    my ( $self, $kernel, $child, @args ) = @_[OBJECT, KERNEL, ARG0 .. $#_];

    $self->logger->info("child " . $self->_child_id($child) . " exited as requested");

    $self->_unregister_child($child);
    $kernel->refcount_decrement( $self->get_session_id(), "children" );
};

event stopped_unexpectedly => sub {
    my ( $self, $kernel, $child, @args ) = @_[OBJECT, KERNEL, ARG0 .. $#_];

    my $id = $self->_child_id($child);

    $self->logger->notice("child $id exited on its own");

    if ( $self->should_restart_child($child, @args) ) {
        if ( $self->child_exit_is_fatal($child, @args) ) {
            $self->logger->error("child $id exit is fatal, raising error");
            $self->yield( fatal_exit => $child, @args );
        } else {
            my $policy = $self->restart_policy;
            $self->logger->info("child $id will be restarted, restart policy is $policy");
            $self->yield( "restart_$policy" => $child, @args );
        }
    } else {
        $self->logger->info("child $id won't be restarted");
        $self->_unregister_child($child);
        $kernel->refcount_decrement( $self->get_session_id(), "children" );
    }
};

event stopped_for_restart => sub {
    my ( $self, $child, %args ) = @_[OBJECT, ARG0 .. $#_];

    $self->logger->info("child " . $self->_child_id($child) . " exited for restart as requested");

    $self->yield( respawn => $child );
};

event restart_one => sub {
    my ( $self, $child, %args ) = @_[OBJECT, ARG0 .. $#_];

    if ( my $handle = $self->_child_handle($child) ) {
        $self->logger->info("stopping child " . $self->_child_id($child) . " for restart");
        $self->_stopping_for_restart->{$child} = 1;
        $handle->stop_for_restart();
    } else {
        $self->logger->debug("child " . $self->_child_id($child) . " is already dead, marking for respawn");
        $self->yield( respawn => $child );
    }
};

event restart_all => sub {
    my ( $self, $child, %args ) = @_[OBJECT, ARG0 .. $#_];

    foreach my $child ( reverse $self->children ) {
        $self->yield( restart_one => $child );
    }
};

event restart_rest => sub {
    my ( $self, $child, %args ) = @_[OBJECT, ARG0 .. $#_];

    my @children = $self->children;

    shift @children while $children[0] != $child;

    foreach my $child ( reverse @children ) {
        $self->yield( restart_one => $child );
    }
};

event fatal_exit => sub {
    # stop everything
    # exit with error
    # FIXME how do we exit abstractly? yield to some callback?

    die "supervisor seppuku";
};

sub child_exit_is_fatal {
    my ( $self, $child, @args ) = @_;

    # check if the child exceeded the maximal number of restarts by looking at
    # $self->_children_hash->{$child}{token_bucket}, the child descriptor's
    # restart policy (if its transient or not, etc), $args{exit_code} being an
    # error, etc

    return 0;
}

sub should_restart_child {
    my ( $self, $child, @args ) = @_;

    $child->should_restart(@args);
}

event _child => sub {
    my ( $self, $verb, $child ) = @_[OBJECT, ARG0, ARG1];

    $self->logger->debug("supervisor $self had child event for $child: $verb");
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

POE::Component::Supervisor - Erlang-inspired babysitting

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use POE;

    use POE::Component::Supervisor;

    POE::Component::Supervisor->new(
        children => [
            POE::Component::Supervisor::Supervised::Proc->new( ... ),    # monitor UNIX procs
            POE::Component::Supervisor::Supervised::Session->new( ... ), # monitor POE sessions
        ],
    );

=head1 DESCRIPTION

This is a port of the Erlang process supervisor
(L<http://www.erlang.org/doc/design_principles/sup_princ.html>).

This will monitor instances of children, restarting them as necessary should
they exit.

Restart throttling is not yet implemented but planned for a future version.

=head1 OBJECT HIERARCHY

A supervisor has any number of supervised child descriptors, which in turn
instantiate handles for each spawned instance of the child.

Supervised children are essential object factories for handles. They spawn new
instances of the child they describe by instantiating handles.

A handle will do the actual management of the child, sending events to the
supervisor when the child is terminated, and also facilitate explicit
termination of the child's instance.

=for stopwords respawn

Based on its C<restart_policy> the supervisor may order other handles to also
stop, and ask various child descriptors to respawn certain children.

=head1 POE REFERENCE COUNTING

When no more children are being supervised the L<POE> reference count for the
supervisor's session will go down to zero. If no C<alias> is set up then the
session will close. If an C<alias> is set and no other sessions are doing
anything the session will also close. See L<POE>, and L<MooseX::POE::Aliased>.

=head1 ATTRIBUTES

=over 4

=item alias

See L<MooseX::POE::Aliased>.

This defaults to C<undef>, unlike the role, so that a supervisor session will
close automatically once it has no more children to supervise.

=item use_logger_singleton

See L<MooseX::LogDispatch>.

Changes the default to true, to allow usage of an already configured
L<Log::Dispatch::Config> setup.

=item restart_policy

This is one of C<one>, C<all> or C<rest>.

If the L<POE::Component::Supervisor::Supervised> object describing the child
deems the child should be restarted, then the value of this attribute controls
which other children to also restart.

C<one> denotes that only the child which died will be restarted.

C<rest> will cause all the children appearing after the child which died in the
children array to be restarted, but not the children preceding it.

C<all> will restart all the children.

=item children

This is the array of children being supervised.

It is a required argument.

Note that the array reference will be modified if new children are introduced
and when children are removed (even during normal shutdown), so pass in a copy
of an array if this is a problem for you.

The order of the children matters, see C<restart_policy>.

=back

=head1 METHODS

=over 4

=item new %args

=item start @children

Spawn and supervise the children described by the descriptors in @children.

=item stop [ @children ]

Stop the specified children.

If no arguments are provided all the children are stopped.

=item should_restart_child $child, %args

Delegates to C<$child> by calling
L<POE::Component::Supervisor::Supervised/should_restart>.

=item child_exit_is_fatal

Currently always returns false. In the future restart throttling will be
implemented using this method.

If C<true> is returned an error will be thrown by the supervisor.

=back

=head1 EVENTS

The L<POE> event API is currently internal. All manipulation of the supervisor
object should be done using the API described in L<METHODS>.

=head1 SEE ALSO

L<http://www.erlang.org/doc/design_principles/sup_princ.html>

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>yuval.kogman@iinteractive.com<gt>

=head1 COPYRIGHT

    Copyright (c) 2008, 2010 Infinity Interactive, Yuval Kogman. All rights
    reserved This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
